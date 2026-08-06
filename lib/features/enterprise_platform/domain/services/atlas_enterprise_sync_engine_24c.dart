import '../../data/services/atlas_enterprise_sync_repository.dart';
import '../models/atlas_enterprise_sync_data.dart';
import '../models/atlas_enterprise_version_data.dart';
import 'atlas_enterprise_audit_service.dart';
import 'atlas_enterprise_session_service.dart';
import 'atlas_enterprise_sync_transport.dart';
import 'atlas_enterprise_version_service.dart';

class AtlasEnterpriseSyncEngine24C {
  AtlasEnterpriseSyncEngine24C({
    AtlasEnterpriseSyncTransport? transport,
  }) : transport =
            transport ?? AtlasLocalLoopbackSyncTransport.instance;

  final AtlasEnterpriseSyncTransport transport;
  final AtlasEnterpriseSyncRepository repository =
      AtlasEnterpriseSyncRepository.instance;
  final AtlasEnterpriseVersionService versions =
      AtlasEnterpriseVersionService.instance;

  Future<AtlasEnterpriseSyncOperation> enqueue({
    required String tenantId,
    required String companyId,
    required String? farmId,
    required String entityType,
    required String entityId,
    required AtlasEnterpriseSyncOperationType operationType,
    required Map<String, dynamic> payload,
    required int baseVersion,
    String deviceId = 'local_device',
  }) async {
    final now = DateTime.now();
    final idempotencyKey =
        '$tenantId|$entityType|$entityId|$baseVersion|'
        '${operationType.name}|${payload.hashCode}';

    final operation = AtlasEnterpriseSyncOperation(
      operationId: 'sync_${now.microsecondsSinceEpoch}',
      tenantId: tenantId,
      companyId: companyId,
      farmId: farmId,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      payload: Map<String, dynamic>.from(payload),
      baseVersion: baseVersion,
      createdAt: now,
      deviceId: deviceId,
      status: AtlasEnterpriseSyncStatus.pending,
      retryCount: 0,
      lastError: '',
      idempotencyKey: idempotencyKey,
      lastAttemptAt: null,
    );

    await repository.saveOperation(operation);

    await AtlasEnterpriseAuditService.instance.record(
      action: 'queue_sync',
      module: 'sync',
      entityType: entityType,
      entityId: entityId,
      description: 'Operação adicionada à fila offline.',
      companyId: companyId,
      farmId: farmId,
      after: operation.toMap(),
    );

    return operation;
  }

  Future<AtlasEnterpriseSyncSummary> synchronize({
    required bool online,
    String? companyId,
  }) async {
    final session = AtlasEnterpriseSessionService.instance;
    await session.ensureInitialized();
    final resolvedCompanyId =
        companyId ?? session.currentCompanyId;

    if (resolvedCompanyId == null) {
      return const AtlasEnterpriseSyncSummary(
        total: 0,
        pending: 0,
        syncing: 0,
        synchronized: 0,
        conflicts: 0,
        errors: 0,
      );
    }

    final queue = await repository.loadQueue();
    final scoped = queue
        .where(
          (item) => item.companyId == resolvedCompanyId,
        )
        .toList();

    if (!online) {
      return summarize(scoped);
    }

    for (final operation in scoped) {
      if (operation.status ==
              AtlasEnterpriseSyncStatus.synchronized ||
          operation.status ==
              AtlasEnterpriseSyncStatus.conflict) {
        continue;
      }

      final syncing = operation.copyWith(
        status: AtlasEnterpriseSyncStatus.syncing,
        retryCount: operation.retryCount + 1,
        lastAttemptAt: DateTime.now(),
        lastError: '',
      );
      await repository.saveOperation(syncing);

      try {
        final result = await transport.push(syncing);

        if (result.conflict) {
          final conflict =
              AtlasEnterpriseSyncConflict(
            id: 'conflict_${DateTime.now().microsecondsSinceEpoch}',
            operationId: operation.operationId,
            companyId: operation.companyId,
            farmId: operation.farmId,
            entityType: operation.entityType,
            entityId: operation.entityId,
            localVersion: operation.baseVersion,
            remoteVersion: result.remoteVersion,
            localPayload: operation.payload,
            remotePayload: result.remotePayload,
            detectedAt: DateTime.now(),
            resolution:
                AtlasEnterpriseConflictResolution.unresolved,
            resolvedAt: null,
            resolvedBy: null,
          );
          await repository.saveConflict(conflict);
          await repository.saveOperation(
            syncing.copyWith(
              status: AtlasEnterpriseSyncStatus.conflict,
              lastError: result.error,
            ),
          );
          await AtlasEnterpriseAuditService.instance.record(
            action: 'sync_conflict',
            module: 'sync',
            entityType: operation.entityType,
            entityId: operation.entityId,
            description:
                'Conflito detectado durante sincronização.',
            companyId: operation.companyId,
            farmId: operation.farmId,
            after: conflict.toMap(),
            result: 'conflict',
          );
          continue;
        }

        if (!result.accepted) {
          await repository.saveOperation(
            syncing.copyWith(
              status: AtlasEnterpriseSyncStatus.error,
              lastError: result.error,
            ),
          );
          continue;
        }

        await repository.saveOperation(
          syncing.copyWith(
            status:
                AtlasEnterpriseSyncStatus.synchronized,
            lastError: '',
          ),
        );
      } catch (error) {
        await repository.saveOperation(
          syncing.copyWith(
            status: AtlasEnterpriseSyncStatus.error,
            lastError: error.toString(),
          ),
        );
      }
    }

    await _pullIncremental(resolvedCompanyId);

    final refreshed = (await repository.loadQueue())
        .where(
          (item) => item.companyId == resolvedCompanyId,
        )
        .toList();

    return summarize(refreshed);
  }

  Future<void> _pullIncremental(String companyId) async {
    final checkpoint =
        await repository.checkpoint(companyId);
    final changes = await transport.pull(
      companyId: companyId,
      cursor: checkpoint.cursor,
    );

    var cursor = checkpoint.cursor;

    for (final change in changes) {
      cursor = change.cursor;

      final latest = await versions.history(
        companyId: companyId,
        entityType: change.entityType,
        entityId: change.entityId,
      );
      final currentVersion =
          latest.isEmpty ? 0 : latest.first.version;

      if (currentVersion >= change.version) {
        continue;
      }

      await versions.commit(
        tenantId: companyId,
        companyId: companyId,
        farmId: null,
        entityType: change.entityType,
        entityId: change.entityId,
        payload: change.payload,
        baseVersion: currentVersion,
        mutationType: change.deleted
            ? AtlasVersionMutationType.delete
            : AtlasVersionMutationType.update,
        reason: 'Sincronização incremental recebida.',
        deleted: change.deleted,
      );
    }

    await repository.saveCheckpoint(
      checkpoint.copyWith(
        cursor: cursor,
        lastPulledAt: DateTime.now(),
        lastPushedAt: DateTime.now(),
      ),
    );
  }

  AtlasEnterpriseSyncSummary summarize(
    List<AtlasEnterpriseSyncOperation> values,
  ) {
    int count(AtlasEnterpriseSyncStatus status) =>
        values.where((item) => item.status == status).length;

    return AtlasEnterpriseSyncSummary(
      total: values.length,
      pending: count(AtlasEnterpriseSyncStatus.pending),
      syncing: count(AtlasEnterpriseSyncStatus.syncing),
      synchronized:
          count(AtlasEnterpriseSyncStatus.synchronized),
      conflicts:
          count(AtlasEnterpriseSyncStatus.conflict),
      errors: count(AtlasEnterpriseSyncStatus.error),
    );
  }
}
