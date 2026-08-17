import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/models/offline_operation.dart';

void main() {
  test('operação preserva idempotência e escopo na API', () {
    final operation = OfflineOperation(
      id: 'op-1',
      idempotencyKey: 'idem-1',
      entityType: 'animal',
      entityId: 'animal-1',
      operationType: 'update',
      payload: const <String, dynamic>{'weight': 420},
      baseVersion: 3,
      companyId: 'company-1',
      tenantId: 'tenant-1',
      farmId: 'farm-1',
      deviceId: 'device-1',
      createdAt: DateTime.utc(2026, 8, 6),
    );
    final api = operation.toApi();
    expect(api['operation_id'], 'op-1');
    expect(api['idempotency_key'], 'idem-1');
    expect(api['company_id'], 'company-1');
    expect(api['farm_id'], 'farm-1');
    expect(api['base_version'], 3);
  });
}
