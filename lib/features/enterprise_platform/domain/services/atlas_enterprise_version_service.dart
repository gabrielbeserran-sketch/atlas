import 'dart:convert';

import '../../data/services/atlas_enterprise_version_repository.dart';
import '../models/atlas_enterprise_version_data.dart';
import 'atlas_enterprise_audit_service.dart';
import 'atlas_enterprise_session_service.dart';

class AtlasEnterpriseVersionService {
  AtlasEnterpriseVersionService._();

  static final AtlasEnterpriseVersionService instance =
      AtlasEnterpriseVersionService._();

  final AtlasEnterpriseVersionRepository _repository =
      AtlasEnterpriseVersionRepository.instance;

  Future<AtlasConcurrencyCheck> checkConcurrency({
    required String companyId,
    required String entityType,
    required String entityId,
    required int baseVersion,
  }) async {
    final latest = await _repository.latest(
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
    );
    final current = latest?.version ?? 0;

    return AtlasConcurrencyCheck(
      allowed: current == baseVersion,
      expectedVersion: baseVersion,
      currentVersion: current,
      message: current == baseVersion
          ? 'Versão compatível.'
          : 'Conflito de concorrência: base $baseVersion, '
                'atual $current.',
    );
  }

  Future<AtlasVersionedEntitySnapshot> commit({
    required String tenantId,
    required String companyId,
    required String? farmId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    required int baseVersion,
    required AtlasVersionMutationType mutationType,
    required String reason,
    bool deleted = false,
    bool force = false,
  }) async {
    final session = AtlasEnterpriseSessionService.instance;
    await session.ensureInitialized();

    final concurrency = await checkConcurrency(
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
      baseVersion: baseVersion,
    );

    if (!concurrency.allowed && !force) {
      throw StateError(concurrency.message);
    }

    final previous = await _repository.latest(
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
    );
    final now = DateTime.now();
    final nextVersion = (previous?.version ?? 0) + 1;

    final canonical = jsonEncode(<String, dynamic>{
      'tenantId': tenantId,
      'companyId': companyId,
      'farmId': farmId,
      'entityType': entityType,
      'entityId': entityId,
      'version': nextVersion,
      'mutationType': mutationType.name,
      'payload': payload,
      'deleted': deleted,
      'reason': reason,
    });

    final snapshot = AtlasVersionedEntitySnapshot(
      versionId:
          'version_${entityType}_${entityId}_'
          '${now.microsecondsSinceEpoch}',
      tenantId: tenantId,
      companyId: companyId,
      farmId: farmId,
      entityType: entityType,
      entityId: entityId,
      version: nextVersion,
      mutationType: mutationType,
      payload: Map<String, dynamic>.from(payload),
      deleted: deleted,
      reason: reason,
      createdBy: session.currentUserId ?? 'system',
      createdAt: now,
      previousVersionId: previous?.versionId,
      contentHash: _fnv1a64(canonical),
    );

    await _repository.append(snapshot);

    await AtlasEnterpriseAuditService.instance.record(
      action: 'version_commit',
      module: 'versioning',
      entityType: entityType,
      entityId: entityId,
      description: 'Versão $nextVersion registrada para $entityType.',
      companyId: companyId,
      farmId: farmId,
      before: previous?.payload ?? const <String, dynamic>{},
      after: snapshot.payload,
      justification: reason,
    );

    return snapshot;
  }

  Future<AtlasVersionRestoreResult> restore({
    required AtlasVersionedEntitySnapshot source,
    required String reason,
  }) async {
    final latest = await _repository.latest(
      companyId: source.companyId,
      entityType: source.entityType,
      entityId: source.entityId,
    );

    final restored = await commit(
      tenantId: source.tenantId,
      companyId: source.companyId,
      farmId: source.farmId,
      entityType: source.entityType,
      entityId: source.entityId,
      payload: source.payload,
      baseVersion: latest?.version ?? 0,
      mutationType: AtlasVersionMutationType.restore,
      reason: reason,
      deleted: false,
    );

    return AtlasVersionRestoreResult(
      restored: true,
      sourceVersion: source,
      newVersion: restored,
    );
  }

  Future<List<AtlasVersionedEntitySnapshot>> history({
    required String companyId,
    required String entityType,
    required String entityId,
  }) {
    return _repository.history(
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
    );
  }

  String _fnv1a64(String input) {
    final offset = BigInt.parse('1469598103934665603');
    final prime = BigInt.from(1099511628211);
    final mask63 = (BigInt.one << 63) - BigInt.one;
    var hash = offset;

    for (final unit in utf8.encode(input)) {
      hash ^= BigInt.from(unit);
      hash = (hash * prime) & mask63;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }
}
