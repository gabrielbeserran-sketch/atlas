import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/database/atlas_offline_database.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_lookup_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_reconciliation.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_sync_decision_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_sync_promotion_service.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Lookup extends DairyRemoteLookupService {
  _Lookup(this.state);
  DairyRemoteState state;
  bool supported = true;
  int calls = 0;
  void Function()? onLookup;

  @override
  Future<bool> supportsLookup({required bool Function() isScopeCurrent}) async {
    return supported;
  }

  @override
  Future<List<DairyRemoteState>> lookup({
    required String farmId,
    required List<DairyLookupKey> keys,
    required bool Function() isScopeCurrent,
  }) async {
    calls++;
    onLookup?.call();
    expect(farmId, 'farm-a');
    expect(keys.single.composite, state.key.composite);
    return [state];
  }
}

void main() {
  late Database db;
  late DairyProductionStorageService production;
  late DairyOfflineReviewService review;
  late DairySyncDecisionService decisions;
  late _Lookup lookup;
  late DairySyncPromotionService promotion;
  final day = DateTime(2026, 9, 30);
  const key = DairyLookupKey(
    entityType: 'dairy_daily_production',
    entityId: 'farm-a:2026-09-30',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE operation_queue ('
      'id TEXT PRIMARY KEY, idempotency_key TEXT UNIQUE, '
      'entity_type TEXT, entity_id TEXT, operation_type TEXT, '
      'payload_json TEXT, base_version INTEGER, company_id TEXT, '
      'tenant_id TEXT, farm_id TEXT, device_id TEXT, created_at TEXT, '
      'attempts INTEGER, status TEXT, last_error TEXT, next_attempt_at TEXT)',
    );
    await db.execute(
      'CREATE TABLE entity_cache ('
      'company_id TEXT, tenant_id TEXT, farm_id TEXT, entity_type TEXT, '
      'entity_id TEXT, version INTEGER, payload_json TEXT, deleted INTEGER, '
      'updated_at TEXT)',
    );
    await AtlasOfflineDatabase.upgradeToVersion3(db);
    await AtlasOfflineDatabase.upgradeToVersion4(db);
    await AtlasOfflineDatabase.upgradeToVersion5(db);
    production = DairyProductionStorageService();
    review = DairyOfflineReviewService(
      database: db,
      productionStorage: production,
    );
    decisions = DairySyncDecisionService(database: db, reviewService: review);
    lookup = _Lookup(
      DairyRemoteState(
        key: key,
        found: false,
        version: 0,
        deleted: false,
        payload: const {},
        readAt: DateTime.utc(2026, 10, 5),
      ),
    );
    promotion = DairySyncPromotionService(
      database: db,
      reviewService: review,
      lookupService: lookup,
    );
    await production.upsert(
      'farm-a',
      DairyDailyProductionData(
        date: day,
        morningLiters: 10,
        afternoonLiters: 8,
        cowsMilked: 3,
      ),
    );
    await DairyOfflineStageService(
      database: db,
      productionStorage: production,
    ).stage(companyId: 'company-a', tenantId: 'tenant-a', farmId: 'farm-a');
    final local = (await review.review(
      companyId: 'company-a',
      tenantId: 'tenant-a',
      farmId: 'farm-a',
    )).items.single;
    await decisions.save(
      companyId: 'company-a',
      tenantId: 'tenant-a',
      farmId: 'farm-a',
      userId: 'user-a',
      entry: DairyRemoteReviewEntry(
        local: local,
        remote: lookup.state,
        status: DairyRemoteReviewStatus.absentOnServer,
      ),
      choice: DairyDecisionChoice.preferLocal,
      isScopeCurrent: () => true,
    );
  });
  tearDown(() async => db.close());

  Future<DairyPromotionResult> approve({
    bool Function()? current,
    Future<String> Function()? device,
  }) => promotion.approve(
    companyId: 'company-a',
    tenantId: 'tenant-a',
    farmId: 'farm-a',
    entityType: key.entityType,
    entityId: key.entityId,
    isScopeCurrent: current ?? () => true,
    resolveDeviceId: device ?? () async => 'device-1',
  );

  test(
    'reconsulta e promove uma única operação create, repetição não duplica',
    () async {
      final first = await approve();
      final second = await approve();
      expect(first.alreadyQueued, isFalse);
      expect(second.alreadyQueued, isTrue);
      expect(second.operationId, first.operationId);
      expect(lookup.calls, 1);
      final queue = await db.query('operation_queue');
      expect(queue.length, 1);
      expect(queue.single['base_version'], 0);
      expect(queue.single['operation_type'], 'create');
      expect(queue.single['device_id'], 'device-1');
      expect(queue.single['farm_id'], 'farm-a');
      expect(queue.single['idempotency_key'], 'company-a_${first.operationId}');
      expect(
        (await db.query('dairy_sync_decision')).single['promoted_operation_id'],
        first.operationId,
      );
      await expectLater(
        decisions.remove(
          companyId: 'company-a',
          tenantId: 'tenant-a',
          farmId: 'farm-a',
          entityType: key.entityType,
          entityId: key.entityId,
        ),
        throwsStateError,
      );
    },
  );

  test('servidor alterado ou sem capacidade não cria fila', () async {
    lookup.state = DairyRemoteState(
      key: key,
      found: true,
      version: 2,
      deleted: false,
      payload: const {
        'farm_id': 'farm-a',
        'date': '2026-09-30',
        'morning_liters': 11,
        'afternoon_liters': 8,
        'cows_milked': 3,
      },
      readAt: DateTime.utc(2026, 10, 5),
    );
    var deviceCalls = 0;
    await expectLater(
      approve(
        device: () async {
          deviceCalls++;
          return 'device-1';
        },
      ),
      throwsStateError,
    );
    expect(deviceCalls, 0);
    lookup.supported = false;
    await expectLater(approve(), throwsStateError);
    expect(await db.query('operation_queue'), isEmpty);
  });

  test(
    'edição local e mudança de escopo deixam decisão intacta e fila vazia',
    () async {
      await production.upsert(
        'farm-a',
        DairyDailyProductionData(
          date: day,
          morningLiters: 12,
          afternoonLiters: 8,
          cowsMilked: 3,
        ),
      );
      await expectLater(approve(), throwsStateError);
      await expectLater(approve(current: () => false), throwsStateError);
      expect(await db.query('operation_queue'), isEmpty);
      expect(
        (await db.query('dairy_sync_decision')).single['promoted_operation_id'],
        isNull,
      );
    },
  );

  test('duas aprovações simultâneas produzem só uma operação', () async {
    final results = await Future.wait([approve(), approve()]);
    expect(results.map((item) => item.operationId).toSet().length, 1);
    expect((await db.query('operation_queue')).length, 1);
  });

  test(
    'operação concorrente pendente bloqueia promoção sem marca parcial',
    () async {
      await db.insert('operation_queue', {
        'id': 'older',
        'company_id': 'company-a',
        'tenant_id': 'tenant-a',
        'farm_id': 'farm-a',
        'entity_type': key.entityType,
        'entity_id': key.entityId,
        'status': 'accepted',
      });
      await expectLater(approve(), throwsStateError);
      expect((await db.query('operation_queue')).length, 1);
      expect(
        (await db.query('dairy_sync_decision')).single['promoted_operation_id'],
        isNull,
      );
    },
  );

  test('revalida a fonte após cadastrar o dispositivo', () async {
    await expectLater(
      approve(
        device: () async {
          await production.upsert(
            'farm-a',
            DairyDailyProductionData(
              date: day,
              morningLiters: 13,
              afternoonLiters: 8,
              cowsMilked: 3,
            ),
          );
          return 'device-1';
        },
      ),
      throwsStateError,
    );
    expect(await db.query('operation_queue'), isEmpty);
  });

  test('preferência para manter servidor nunca cria operação local', () async {
    await db.update('dairy_sync_decision', {'choice': 'keep_server'});
    await expectLater(approve(), throwsStateError);
    expect(await db.query('operation_queue'), isEmpty);
  });

  test('tombstone confirmado usa update com versão-base observada', () async {
    await db.update('dairy_sync_decision', {
      'remote_version': 3,
      'remote_deleted': 1,
      'remote_payload_json': '{}',
    });
    lookup.state = DairyRemoteState(
      key: key,
      found: true,
      version: 3,
      deleted: true,
      payload: const {},
      readAt: DateTime.utc(2026, 10, 5),
    );
    await approve();
    final operation = (await db.query('operation_queue')).single;
    expect(operation['operation_type'], 'update');
    expect(operation['base_version'], 3);
  });

  test('staging alterado e dispositivo vazio não geram fila', () async {
    final oldStage = (await db.query('dairy_sync_stage')).single;
    await AtlasOfflineDatabase.upgradeToVersion5(db);
    expect((await db.query('dairy_sync_stage')).single, oldStage);
    await expectLater(approve(device: () async => ''), throwsStateError);
    expect(await db.query('operation_queue'), isEmpty);
    await db.update('dairy_sync_stage', {'payload_json': '{}'});
    await expectLater(approve(), throwsStateError);
    expect(
      (await db.query('dairy_sync_decision')).single['promoted_operation_id'],
      isNull,
    );
  });
}
