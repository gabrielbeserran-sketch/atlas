import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/models/offline_operation.dart';
import 'package:projeto_atlas/core/offline/services/offline_sync_coordinator.dart';

OfflineOperation operation(String id) => OfflineOperation(
  id: id,
  idempotencyKey: 'key-$id',
  entityType: 'farm_note',
  entityId: 'note-$id',
  operationType: 'update',
  payload: const <String, dynamic>{'value': 1},
  baseVersion: 0,
  companyId: 'company-A',
  tenantId: 'tenant-A',
  farmId: 'farm-A',
  deviceId: 'device-A',
  createdAt: DateTime.utc(2026, 9, 29),
);

void main() {
  final operations = <OfflineOperation>[operation('op-A'), operation('op-B')];

  test('resultados fora de ordem são reconciliados pelo ID exato', () {
    final byId = OfflineSyncCoordinator.validatedBatchResults(operations, [
      <String, dynamic>{'operation_id': 'op-B', 'accepted': false},
      <String, dynamic>{'operation_id': 'op-A', 'accepted': true},
    ]);

    expect(byId['op-A']?['accepted'], isTrue);
    expect(byId['op-B']?['accepted'], isFalse);
  });

  test(
    'resultado ausente, estranho ou duplicado não pode baixar item errado',
    () {
      for (final results in <List<Map<String, dynamic>>>[
        <Map<String, dynamic>>[
          <String, dynamic>{'operation_id': 'op-A'},
        ],
        <Map<String, dynamic>>[
          <String, dynamic>{'operation_id': 'op-A'},
          <String, dynamic>{'operation_id': 'op-X'},
        ],
        <Map<String, dynamic>>[
          <String, dynamic>{'operation_id': 'op-A'},
          <String, dynamic>{'operation_id': 'op-A'},
        ],
      ]) {
        expect(
          () =>
              OfflineSyncCoordinator.validatedBatchResults(operations, results),
          throwsStateError,
        );
      }
    },
  );

  test('recusa permanente fica retida sem novas tentativas automáticas', () {
    expect(
      OfflineSyncCoordinator.isPermanentRejection(<String, dynamic>{
        'retryable': false,
      }),
      isTrue,
    );
    expect(
      OfflineSyncCoordinator.isPermanentRejection(<String, dynamic>{}),
      isFalse,
    );
  });
}
