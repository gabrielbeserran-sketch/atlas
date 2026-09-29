import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_sync_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_sync_transport.dart';

void main() {
  test('transporte preserva fazenda da operação no pull incremental', () async {
    final transport = AtlasLocalLoopbackSyncTransport.instance;
    final operation = AtlasEnterpriseSyncOperation(
      operationId: 'op-farm-scope-test',
      tenantId: 'tenant-farm-scope-test',
      companyId: 'company-farm-scope-test',
      farmId: 'farm-A',
      entityType: 'farm_note',
      entityId: 'note-A',
      operationType: AtlasEnterpriseSyncOperationType.create,
      payload: const <String, dynamic>{'value': 1},
      baseVersion: 0,
      createdAt: DateTime.utc(2026, 9, 29),
      deviceId: 'device-A',
      status: AtlasEnterpriseSyncStatus.pending,
      retryCount: 0,
      lastError: '',
      idempotencyKey: 'key-farm-scope-test',
      lastAttemptAt: null,
    );

    final pushed = await transport.push(operation);
    final changes = await transport.pull(
      companyId: operation.companyId,
      cursor: '0',
    );

    expect(pushed.accepted, isTrue);
    expect(changes, hasLength(1));
    expect(changes.single.tenantId, operation.tenantId);
    expect(changes.single.farmId, 'farm-A');
  });
}
