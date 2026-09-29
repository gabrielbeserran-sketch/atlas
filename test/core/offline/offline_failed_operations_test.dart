import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/controllers/atlas_offline_controller.dart';
import 'package:projeto_atlas/core/offline/models/offline_operation.dart';
import 'package:projeto_atlas/core/offline/models/offline_sync_models.dart';
import 'package:projeto_atlas/core/offline/presentation/offline_failed_operations_section.dart';
import 'package:projeto_atlas/core/offline/services/offline_repository.dart';
import 'package:projeto_atlas/core/offline/services/offline_sync_coordinator.dart';
import 'package:projeto_atlas/core/session/atlas_session_controller.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

OfflineOperation failure({String id = 'op-A', String? farmId = 'farm-A'}) =>
    OfflineOperation(
      id: id,
      idempotencyKey: 'key-$id',
      entityType: 'farm_note',
      entityId: 'note-$id',
      operationType: 'update',
      payload: const <String, dynamic>{'secret': 'not-for-display'},
      baseVersion: 0,
      companyId: 'company-A',
      tenantId: 'tenant-A',
      farmId: farmId,
      deviceId: 'device-A',
      createdAt: DateTime.utc(2026, 9, 29),
      attempts: 2,
      status: 'failed',
      lastError: 'Chave de idempotência já utilizada por outra operação.',
    );

AtlasRemoteSession testSession(String companyId) => AtlasRemoteSession(
  accessToken: 'test-token',
  refreshToken: 'test-refresh',
  expiresInSeconds: 3600,
  userId: 'user-A',
  userName: 'Operador',
  email: 'test@example.invalid',
  companyId: companyId,
  tenantId: 'tenant-$companyId',
  role: 'operator',
  companies: const <AtlasRemoteCompanySession>[],
  effectivePermissions: const <String>{'sync.read'},
  farmIds: <String>['farm-$companyId'],
  savedAt: DateTime.utc(2026, 9, 29),
);

AtlasRemoteFarm farm(String companyId) => AtlasRemoteFarm(
  id: 'farm-$companyId',
  tenantId: 'tenant-$companyId',
  companyId: companyId,
  name: 'Fazenda de teste',
  city: '',
  state: '',
  animals: 0,
  area: 0,
  active: true,
);

class FakeSessionController extends AtlasSessionController {
  FakeSessionController() {
    current = testSession('company-A');
    selected = farm('company-A');
  }

  AtlasRemoteSession? current;
  AtlasRemoteFarm? selected;

  @override
  AtlasRemoteSession? get session => current;

  @override
  AtlasRemoteFarm? get activeFarm => selected;

  void switchTo(String companyId) {
    current = testSession(companyId);
    selected = farm(companyId);
    notifyListeners();
  }
}

class FakeRepository extends OfflineRepository {
  final blockedA = Completer<OfflineQueueStats>();

  @override
  Future<OfflineQueueStats> queueStats({
    required String companyId,
    String? farmId,
  }) async {
    if (companyId == 'company-A') return blockedA.future;
    return const OfflineQueueStats(
      pending: 0,
      retry: 0,
      conflicts: 0,
      failed: 1,
      accepted: 0,
    );
  }

  @override
  Future<List<OfflineConflict>> conflicts({
    required String companyId,
    String? farmId,
    String status = 'open',
  }) async => <OfflineConflict>[];

  @override
  Future<List<OfflineOperation>> failedOperations({
    required String companyId,
    String? farmId,
    int limit = 50,
  }) async => <OfflineOperation>[failure(id: 'op-$companyId', farmId: farmId)];
}

class FakeCoordinator extends OfflineSyncCoordinator {
  @override
  Future<OfflineServerStatus> serverStatus() async => const OfflineServerStatus(
    ready: false,
    activeDevices: 0,
    openConflicts: 0,
    latestCursor: 0,
    maxBatchSize: 200,
    maxPullPage: 1000,
  );
}

void main() {
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('carga atrasada da empresa anterior não aparece após troca', () async {
    final fakeSession = FakeSessionController();
    final repository = FakeRepository();
    final controller = AtlasOfflineController(
      sessionController: fakeSession,
      repository: repository,
      coordinator: FakeCoordinator(),
    );
    try {
      final oldLoad = controller.load();
      fakeSession.switchTo('company-B');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.failedOperations.single.id, 'op-company-B');

      repository.blockedA.complete(
        const OfflineQueueStats(
          pending: 0,
          retry: 0,
          conflicts: 0,
          failed: 1,
          accepted: 0,
        ),
      );
      await oldLoad;
      expect(controller.failedOperations.single.id, 'op-company-B');
    } finally {
      controller.dispose();
      fakeSession.dispose();
    }
  });

  test(
    'consulta local respeita empresa, fazenda e status sem modificar a fila',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      try {
        await db.execute(
          'CREATE TABLE operation_queue ('
          'id TEXT PRIMARY KEY, company_id TEXT, farm_id TEXT, '
          'status TEXT, last_error TEXT, created_at TEXT, payload_json TEXT)',
        );
        for (final operation in <OfflineOperation>[
          failure(),
          failure(id: 'op-B', farmId: 'farm-B'),
          failure(id: 'op-general', farmId: null),
          failure(id: 'op-other-company'),
        ]) {
          final row = operation.toDatabase();
          if (operation.id == 'op-other-company') {
            row['company_id'] = 'company-B';
          }
          await db.insert('operation_queue', <String, Object?>{
            'id': row['id'],
            'company_id': row['company_id'],
            'farm_id': row['farm_id'],
            'status': row['status'],
            'last_error': row['last_error'],
            'created_at': row['created_at'],
            'payload_json': row['payload_json'],
          });
        }
        await db.insert('operation_queue', <String, Object?>{
          'id': 'op-pending',
          'company_id': 'company-A',
          'farm_id': 'farm-A',
          'status': 'pending',
          'created_at': '2026-09-29T00:00:00Z',
          'payload_json': '{}',
        });

        final scoped = await OfflineRepository.readFailedOperations(
          db,
          companyId: 'company-A',
          farmId: 'farm-A',
        );
        final all = await OfflineRepository.readFailedOperations(
          db,
          companyId: 'company-A',
        );
      final limited = await OfflineRepository.readFailedOperations(
        db,
        companyId: 'company-A',
        limit: 1,
      );

        expect(scoped.map((item) => item.id).toSet(), {'op-A', 'op-general'});
        expect(all.map((item) => item.id).toSet(), {
          'op-A',
          'op-B',
          'op-general',
        });
      expect(limited, hasLength(1));
        expect((await db.query('operation_queue')).length, 5);
      } finally {
        await db.close();
      }
    },
  );

  testWidgets('mostra motivo e identificação sem expor payload ou apagar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineFailedOperationsSection(
            operations: <OfflineOperation>[failure()],
            total: 1,
          ),
        ),
      ),
    );

    expect(find.text('Falhas que precisam de revisão'), findsOneWidget);
    expect(find.textContaining('Chave de idempotência'), findsOneWidget);
    expect(find.textContaining('not-for-display'), findsNothing);
    expect(find.text('Reenviar'), findsNothing);
    await tester.tap(find.textContaining('farm_note'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Operação: op-A'), findsOneWidget);
    expect(find.textContaining('Tentativas: 2'), findsOneWidget);
  });
}
