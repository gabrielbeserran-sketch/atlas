import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/database/atlas_offline_database.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_lookup_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_reconciliation.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_sync_decision_service.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DairyProductionStorageService production;
  late DairyOfflineReviewService review;
  late DairySyncDecisionService decisions;
  final day = DateTime(2026, 9, 30);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE operation_queue (id TEXT PRIMARY KEY, company_id TEXT, tenant_id TEXT, farm_id TEXT, entity_type TEXT, entity_id TEXT, status TEXT)',
    );
    await db.execute(
      'CREATE TABLE entity_cache (company_id TEXT, tenant_id TEXT, farm_id TEXT, entity_type TEXT, entity_id TEXT, version INTEGER, payload_json TEXT, deleted INTEGER, updated_at TEXT)',
    );
    await AtlasOfflineDatabase.upgradeToVersion3(db);
    await AtlasOfflineDatabase.upgradeToVersion4(db);
    production = DairyProductionStorageService();
    review = DairyOfflineReviewService(
      database: db,
      productionStorage: production,
    );
    decisions = DairySyncDecisionService(database: db, reviewService: review);
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
  });
  tearDown(() async => db.close());

  Future<DairyRemoteReviewEntry> entry() async {
    final local = (await review.review(
      companyId: 'company-a',
      tenantId: 'tenant-a',
      farmId: 'farm-a',
    )).items.single;
    return DairyRemoteReviewEntry(
      local: local,
      remote: DairyRemoteState(
        key: DairyLookupKey(
          entityType: local.entityType,
          entityId: local.entityId,
        ),
        found: false,
        version: 0,
        deleted: false,
        payload: const {},
        readAt: DateTime.utc(2026, 10, 5),
      ),
      status: DairyRemoteReviewStatus.absentOnServer,
    );
  }

  Future<DairySavedDecision> save(
    DairyRemoteReviewEntry value, {
    String company = 'company-a',
    bool Function()? current,
    DairyDecisionChoice choice = DairyDecisionChoice.preferLocal,
  }) => decisions.save(
    companyId: company,
    tenantId: 'tenant-a',
    farmId: 'farm-a',
    userId: 'user-a',
    entry: value,
    choice: choice,
    isScopeCurrent: current ?? () => true,
  );

  test(
    'upgrade v3 para v4 conserva fila, cache e staging existentes',
    () async {
      final older = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await older.execute(
          'CREATE TABLE operation_queue (id TEXT PRIMARY KEY)',
        );
        await older.execute('CREATE TABLE entity_cache (id TEXT PRIMARY KEY)');
        await AtlasOfflineDatabase.upgradeToVersion3(older);
        await older.insert('operation_queue', {'id': 'existing-op'});
        await older.insert('entity_cache', {'id': 'existing-cache'});
        await older.insert('dairy_sync_stage', {
          'company_id': 'company-a',
          'tenant_id': 'tenant-a',
          'farm_id': 'farm-a',
          'entity_type': 'dairy_daily_production',
          'entity_id': 'farm-a:2026-09-30',
          'payload_json': '{}',
          'staged_at': '2026-10-05T00:00:00Z',
        });
        await AtlasOfflineDatabase.upgradeToVersion4(older);
        expect(
          (await older.query('operation_queue')).single['id'],
          'existing-op',
        );
        expect(
          (await older.query('entity_cache')).single['id'],
          'existing-cache',
        );
        expect((await older.query('dairy_sync_stage')).length, 1);
        expect(await older.query('dairy_sync_decision'), isEmpty);
      } finally {
        await older.close();
      }
    },
  );

  test(
    'v4 preserva staging e fila, salva intenção sem enfileirar e repetição é idempotente',
    () async {
      final before = await db.query('dairy_sync_stage');
      await AtlasOfflineDatabase.upgradeToVersion4(db);
      final value = await entry();
      final first = await save(value);
      final second = await save(value);
      expect(first.choice, DairyDecisionChoice.preferLocal);
      expect(first.decidedAt, second.decidedAt);
      final changed = await save(value, choice: DairyDecisionChoice.keepServer);
      expect(changed.choice, DairyDecisionChoice.keepServer);
      expect(
        (await decisions.list(
          companyId: 'company-a',
          tenantId: 'tenant-a',
          farmId: 'farm-a',
        )).length,
        1,
      );
      expect(
        await decisions.list(
          companyId: 'company-b',
          tenantId: 'tenant-a',
          farmId: 'farm-a',
        ),
        isEmpty,
      );
      expect(await db.query('dairy_sync_stage'), before);
      expect(await db.query('operation_queue'), isEmpty);
    },
  );

  test('alteração local e troca de escopo impedem decisão', () async {
    final value = await entry();
    await production.upsert(
      'farm-a',
      DairyDailyProductionData(
        date: day,
        morningLiters: 11,
        afternoonLiters: 8,
        cowsMilked: 3,
      ),
    );
    await expectLater(save(value), throwsStateError);
    await expectLater(save(value, current: () => false), throwsStateError);
    expect(await db.query('dairy_sync_decision'), isEmpty);
  });

  test('fila existente e escopo de outra empresa não são ignorados', () async {
    final value = await entry();
    await db.insert('operation_queue', {
      'id': 'op-1',
      'company_id': 'company-a',
      'tenant_id': 'tenant-a',
      'farm_id': 'farm-a',
      'entity_type': value.local.entityType,
      'entity_id': value.local.entityId,
      'status': 'pending',
    });
    await expectLater(save(value), throwsStateError);
    await expectLater(save(value, company: 'company-b'), throwsStateError);
    expect(await db.query('dairy_sync_decision'), isEmpty);
  });

  test(
    'preferência é reversível e não vira autorização após editar dado local',
    () async {
      final value = await entry();
      final decision = await save(
        value,
        choice: DairyDecisionChoice.keepServer,
      );
      expect(decision.matchesLocal(value.local), isTrue);
      await production.upsert(
        'farm-a',
        DairyDailyProductionData(
          date: day,
          morningLiters: 12,
          afternoonLiters: 8,
          cowsMilked: 3,
        ),
      );
      final changed = (await review.review(
        companyId: 'company-a',
        tenantId: 'tenant-a',
        farmId: 'farm-a',
      )).items.single;
      expect(decision.matchesLocal(changed), isFalse);
      await decisions.remove(
        companyId: 'company-a',
        tenantId: 'tenant-a',
        farmId: 'farm-a',
        entityType: value.local.entityType,
        entityId: value.local.entityId,
      );
      expect(await db.query('dairy_sync_decision'), isEmpty);
      expect(await db.query('operation_queue'), isEmpty);
    },
  );
}
