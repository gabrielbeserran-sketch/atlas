import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/database/atlas_offline_database.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_herd_snapshot_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DairyProductionStorageService production;
  late DairyHerdSnapshotStorageService herd;
  late DairyOfflineStageService stage;
  late DairyOfflineReviewService review;

  const farm = 'farm-a';
  final day = DateTime(2026, 9, 30);

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE operation_queue (id TEXT PRIMARY KEY)');
    await db.execute(
      'CREATE TABLE entity_cache ('
      'company_id TEXT, tenant_id TEXT, farm_id TEXT, '
      'entity_type TEXT, entity_id TEXT, version INTEGER, '
      'payload_json TEXT, deleted INTEGER, updated_at TEXT, '
      'PRIMARY KEY(company_id, entity_type, entity_id))',
    );
    await AtlasOfflineDatabase.upgradeToVersion3(db);
    production = DairyProductionStorageService();
    herd = DairyHerdSnapshotStorageService();
    stage = DairyOfflineStageService(
      database: db,
      productionStorage: production,
      snapshotStorage: herd,
    );
    review = DairyOfflineReviewService(
      database: db,
      productionStorage: production,
      snapshotStorage: herd,
    );
  });

  tearDown(() async => db.close());

  Future<DairyStageReport> run({
    String company = 'company-a',
    String farmId = farm,
  }) => stage.stage(companyId: company, tenantId: 'tenant-a', farmId: farmId);

  Future<DairyReviewReport> inspect() =>
      review.review(companyId: 'company-a', tenantId: 'tenant-a', farmId: farm);

  Future<void> saveCache({
    required Map<String, dynamic> payload,
    String tenant = 'tenant-a',
    String farmId = farm,
    bool deleted = false,
  }) async {
    await db.insert('entity_cache', <String, Object?>{
      'company_id': 'company-a',
      'tenant_id': tenant,
      'farm_id': farmId,
      'entity_type': 'dairy_daily_production',
      'entity_id': 'farm-a:2026-09-30',
      'version': 1,
      'payload_json': jsonEncode(payload),
      'deleted': deleted ? 1 : 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  test(
    'copia os dois tipos por dia sem enfileirar envio e sem apagar legado',
    () async {
      await production.upsert(
        farm,
        DairyDailyProductionData(
          date: day,
          morningLiters: 120,
          afternoonLiters: 115,
          cowsMilked: 40,
        ),
      );
      await herd.upsert(
        farm,
        DairyHerdSnapshotData(
          date: day,
          eligibleCows: 50,
          lactatingCows: 40,
          dryCows: 10,
        ),
      );

      final first = await run();
      final repeat = await run();
      final rows = await db.query('dairy_sync_stage', orderBy: 'entity_type');
      expect(first.added, 2);
      expect(first.needsReview, 0);
      expect(repeat.added, 0);
      expect(repeat.unchanged, 2);
      expect(rows.length, 2);
      expect(rows.map((row) => row['entity_id']).toSet(), {
        'farm-a:2026-09-30',
      });
      expect(rows.map((row) => row['entity_type']).toSet(), {
        'dairy_daily_production',
        'dairy_herd_snapshot',
      });
      expect(await db.query('operation_queue'), isEmpty);
      expect((await production.load(farm)).length, 1);
      expect((await herd.load(farm)).length, 1);
    },
  );

  test(
    'mudança após cópia pede revisão e não substitui nenhum dos lados',
    () async {
      await production.upsert(
        farm,
        DairyDailyProductionData(
          date: day,
          morningLiters: 100,
          afternoonLiters: 50,
          cowsMilked: 10,
        ),
      );
      await run();
      final before = (await db.query('dairy_sync_stage')).single;
      await production.upsert(
        farm,
        DairyDailyProductionData(
          date: day,
          morningLiters: 150,
          afternoonLiters: 50,
          cowsMilked: 10,
        ),
      );

      final report = await run();
      expect(report.needsReview, 1);
      expect((await db.query('dairy_sync_stage')).single, before);
      expect((await production.load(farm)).single.totalLiters, 200);
    },
  );

  test(
    'registro legado inválido fica no aparelho mas não é preparado',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(
        'atlas_dairy_daily_production_farm_a',
        jsonEncode([
          {
            'date': '2026-09-30',
            'morning_liters': 30,
            'afternoon_liters': 20,
            'cows_milked': 0,
          },
        ]),
      );
      final report = await run();
      expect(report.needsReview, 1);
      expect(await db.query('dairy_sync_stage'), isEmpty);
      expect((await production.load(farm)).single.cowsMilked, 0);
    },
  );

  test(
    'fonte ilegível interrompe preparação sem substituir cópia anterior',
    () async {
      await production.upsert(
        farm,
        DairyDailyProductionData(
          date: day,
          morningLiters: 30,
          afternoonLiters: 20,
          cowsMilked: 5,
        ),
      );
      await run();
      final before = (await db.query('dairy_sync_stage')).single;
      await SharedPreferencesAsync().setString(
        'atlas_dairy_daily_production_farm_a',
        '[quebrado',
      );
      await expectLater(run(), throwsFormatException);
      expect((await db.query('dairy_sync_stage')).single, before);
    },
  );

  test('empresa e fazenda isolam cópias e não aceitam escopo vazio', () async {
    await production.upsert(
      farm,
      DairyDailyProductionData(
        date: day,
        morningLiters: 30,
        afternoonLiters: 20,
        cowsMilked: 5,
      ),
    );
    await run();
    await run(company: 'company-b');
    expect((await db.query('dairy_sync_stage')).length, 2);
    await expectLater(run(farmId: ''), throwsStateError);
    expect((await db.query('dairy_sync_stage')).length, 2);
  });

  test('upgrade v2 para v3 preserva a fila existente', () async {
    await db.insert('operation_queue', {'id': 'pending-before-upgrade'});
    await AtlasOfflineDatabase.upgradeToVersion3(db);
    expect(
      (await db.query('operation_queue')).single['id'],
      'pending-before-upgrade',
    );
    expect(await db.query('dairy_sync_stage'), isEmpty);
  });

  test('ausência no cache é espera, jamais autorização de envio', () async {
    await production.upsert(
      farm,
      DairyDailyProductionData(
        date: day,
        morningLiters: 30,
        afternoonLiters: 20,
        cowsMilked: 5,
      ),
    );
    await run();
    final result = await inspect();
    expect(result.waiting, 1);
    expect(result.needingDecision, 0);
    expect(await db.query('operation_queue'), isEmpty);
  });

  test('cache igual, divergente e excluído têm estados distintos', () async {
    await production.upsert(
      farm,
      DairyDailyProductionData(
        date: day,
        morningLiters: 30,
        afternoonLiters: 20,
        cowsMilked: 5,
      ),
    );
    await run();
    final staged = (await db.query('dairy_sync_stage')).single;
    final original = Map<String, dynamic>.from(
      jsonDecode(staged['payload_json']! as String) as Map,
    );
    await saveCache(
      payload: Map<String, dynamic>.fromEntries(
        original.entries.toList().reversed,
      ),
    );
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.sameAsCached,
    );

    await saveCache(payload: {...original, 'morning_liters': 99});
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.differsFromCached,
    );
    await saveCache(payload: {}, deleted: true);
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.deletedInCache,
    );
    expect(await db.query('operation_queue'), isEmpty);
  });

  test('alteração e exclusão locais têm prioridade sem perder cópia', () async {
    await production.upsert(
      farm,
      DairyDailyProductionData(
        date: day,
        morningLiters: 30,
        afternoonLiters: 20,
        cowsMilked: 5,
      ),
    );
    await run();
    await production.upsert(
      farm,
      DairyDailyProductionData(
        date: day,
        morningLiters: 40,
        afternoonLiters: 20,
        cowsMilked: 5,
      ),
    );
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.localChanged,
    );
    await production.delete(farm, day);
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.localMissing,
    );
    expect((await db.query('dairy_sync_stage')).length, 1);
  });

  test('cache de outro escopo e cópia malformada exigem revisão', () async {
    await production.upsert(
      farm,
      DairyDailyProductionData(
        date: day,
        morningLiters: 30,
        afternoonLiters: 20,
        cowsMilked: 5,
      ),
    );
    await run();
    final staged = (await db.query('dairy_sync_stage')).single;
    final original = Map<String, dynamic>.from(
      jsonDecode(staged['payload_json']! as String) as Map,
    );
    await saveCache(payload: original, tenant: 'tenant-b');
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.scopeConflict,
    );
    await saveCache(payload: original);
    await db.update('entity_cache', {'payload_json': 'broken'});
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.invalidCache,
    );
    await db.update('entity_cache', {
      'payload_json': jsonEncode(original),
      'version': 0,
    });
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.invalidCache,
    );
    await db.update('dairy_sync_stage', {'payload_json': '{'});
    expect(
      (await inspect()).items.single.status,
      DairyReviewStatus.invalidStage,
    );
  });
}
