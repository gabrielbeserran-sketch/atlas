import '../../data/services/atlas_enterprise_sync_repository.dart';
import '../models/atlas_enterprise_sync_data.dart';
import '../models/atlas_enterprise_version_data.dart';
import 'atlas_enterprise_audit_service.dart';
import 'atlas_enterprise_session_service.dart';
import 'atlas_enterprise_version_service.dart';

class AtlasEnterpriseConflictResolutionService {
  AtlasEnterpriseConflictResolutionService._();

  static final AtlasEnterpriseConflictResolutionService instance =
      AtlasEnterpriseConflictResolutionService._();

  final AtlasEnterpriseSyncRepository repository =
      AtlasEnterpriseSyncRepository.instance;
  final AtlasEnterpriseVersionService versions =
      AtlasEnterpriseVersionService.instance;

  Future<void> resolve({
    required AtlasEnterpriseSyncConflict conflict,
    required AtlasEnterpriseConflictResolution resolution,
    Map<String, dynamic>? mergedPayload,
  }) async {
    if (resolution ==
        AtlasEnterpriseConflictResolution.unresolved) {
      throw StateError(
        'Selecione uma resolução válida para o conflito.',
      );
    }

    final session = AtlasEnterpriseSessionService.instance;
    await session.ensureInitialized();

    Map<String, dynamic> selectedPayload;
    switch (resolution) {
      case AtlasEnterpriseConflictResolution.keepLocal:
        selectedPayload =
            Map<String, dynamic>.from(conflict.localPayload);
      case AtlasEnterpriseConflictResolution.keepRemote:
        selectedPayload =
            Map<String, dynamic>.from(conflict.remotePayload);
      case AtlasEnterpriseConflictResolution.merge:
        selectedPayload = <String, dynamic>{
          ...conflict.remotePayload,
          ...conflict.localPayload,
          ...?mergedPayload,
        };
      case AtlasEnterpriseConflictResolution.unresolved:
        throw StateError('Conflito não resolvido.');
    }

    final history = await versions.history(
      companyId: conflict.companyId,
      entityType: conflict.entityType,
      entityId: conflict.entityId,
    );
    final currentVersion =
        history.isEmpty ? 0 : history.first.version;

    await versions.commit(
      tenantId: conflict.companyId,
      companyId: conflict.companyId,
      farmId: conflict.farmId,
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      payload: selectedPayload,
      baseVersion: currentVersion,
      mutationType: AtlasVersionMutationType.merge,
      reason:
          'Conflito resolvido: ${resolution.name}.',
      force: true,
    );

    final resolved = conflict.copyWith(
      resolution: resolution,
      resolvedAt: DateTime.now(),
      resolvedBy: session.currentUserId ?? 'system',
    );
    await repository.saveConflict(resolved);

    final queue = await repository.loadQueue();
    for (final operation in queue) {
      if (operation.operationId == conflict.operationId) {
        await repository.saveOperation(
          operation.copyWith(
            status: AtlasEnterpriseSyncStatus.synchronized,
            lastError: '',
            baseVersion:
                conflict.remoteVersion > conflict.localVersion
                    ? conflict.remoteVersion
                    : conflict.localVersion,
            payload: selectedPayload,
          ),
        );
        break;
      }
    }

    await AtlasEnterpriseAuditService.instance.record(
      action: 'resolve_conflict',
      module: 'sync',
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      description: 'Conflito de sincronização resolvido.',
      companyId: conflict.companyId,
      farmId: conflict.farmId,
      before: <String, dynamic>{
        'local': conflict.localPayload,
        'remote': conflict.remotePayload,
      },
      after: selectedPayload,
      justification: resolution.name,
    );
  }
}
