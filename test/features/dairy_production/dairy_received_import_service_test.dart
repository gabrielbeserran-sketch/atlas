import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/services/offline_repository.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_herd_snapshot_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_received_cache_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_received_import_service.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DairyProductionStorageService productionStorage;
  late DairyHerdSnapshotStorageService snapshotStorage;
  late DairyReceivedCacheService cache;
  late DairyReceivedImportService importer;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE entity_cache ('
      'company_id TEXT NOT NULL, tenant_id TEXT NOT NULL, farm_id TEXT, '
      'entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, '
      'version INTEGER NOT NULL, payload_json TEXT NOT NULL, '
      'deleted INTEGER NOT NULL, updated_at TEXT NOT NULL, '
      'PRIMARY KEY(company_id, entity_type, entity_id))',
    );
    productionStorage = DairyProductionStorageService();
    snapshotStorage = DairyHerdSnapshotStorageService();
    cache = DairyReceivedCacheService(database: db);
    importer = DairyReceivedImportService(
      cache: cache,
      productionStorage: productionStorage,
      snapshotStorage: snapshotStorage,
    );
  });

  tearDown(() async => db.close());

  Future<void> putProduction({
    int version = 1,
    double liters = 220,
    bool deleted = false,
  }) async {
    const farm = 'farm-a';
    await OfflineRepository.applyChangeInDatabase(
      db,
      companyId: 'company-a',
      tenantId: 'tenant-a',
      farmId: farm,
      change: <String, dynamic>{
        'farm_id': farm,
        'entity_type': 'dairy_daily_production',
        'entity_id': '$farm:2026-10-05',
        'version': version,
        'payload': <String, dynamic>{
          'farm_id': farm,
          'date': '2026-10-05',
          'morning_liters': liters / 2,
          'afternoon_liters': liters / 2,
          'cows_milked': 16,
          'notes': 'recebido',
        },
        'deleted': deleted,
      },
    );
  }

  Future<void> putSnapshot({int version = 1}) async {
    const farm = 'farm-a';
    await OfflineRepository.applyChangeInDatabase(
      db,
      companyId: 'company-a',
      tenantId: 'tenant-a',
      farmId: farm,
      change: <String, dynamic>{
        'farm_id': farm,
        'entity_type': 'dairy_herd_snapshot',
        'entity_id': '$farm:2026-10-05',
        'version': version,
        'payload': <String, dynamic>{
          'farm_id': farm,
          'date': '2026-10-05',
          'eligible_cows': 20,
          'lactating_cows': 15,
          'dry_cows': 5,
          'pregnancies_monitored': 4,
          'pregnancy_losses': 1,
        },
        'deleted': false,
      },
    );
  }

  Future<DairyReceivedCacheRecord> selected() async => (await cache.load(
    companyId: 'company-a',
    tenantId: 'tenant-a',
    farmId: 'farm-a',
  )).single;

  Future<void> add(
    DairyReceivedCacheRecord record, {
    bool Function()? inScope,
  }) => importer.add(
    selected: record,
    companyId: 'company-a',
    tenantId: 'tenant-a',
    farmId: 'farm-a',
    isScopeCurrent: inScope ?? () => true,
  );

  test(
    'adição explícita grava no histórico local sem criar fila de envio',
    () async {
      await putProduction();
      final remote = await selected();

      await add(remote);

      final local = await productionStorage.load('farm-a', strict: true);
      expect(local, hasLength(1));
      expect(local.single.totalLiters, 220);
      expect(local.single.notes, 'recebido');
      expect(
        await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'operation_queue'",
        ),
        isEmpty,
      );
    },
  );

  test(
    'estado do lote recebido pode ser adicionado ao histórico local',
    () async {
      await putSnapshot();
      final remote = await selected();

      await add(remote);

      final local = await snapshotStorage.load('farm-a', strict: true);
      expect(local, hasLength(1));
      expect(local.single.lactatingCows, 15);
      expect(local.single.pregnanciesMonitored, 4);
      expect(local.single.pregnancyLosses, 1);
    },
  );

  test('colisão de estado de lote também preserva o valor local', () async {
    await putSnapshot();
    final remote = await selected();
    await snapshotStorage.upsert(
      'farm-a',
      DairyHerdSnapshotData(
        date: DateTime(2026, 10, 5),
        eligibleCows: 10,
        lactatingCows: 6,
        dryCows: 4,
      ),
    );

    await expectLater(add(remote), throwsStateError);

    final local = await snapshotStorage.load('farm-a', strict: true);
    expect(local, hasLength(1));
    expect(local.single.eligibleCows, 10);
  });

  test('colisão local é recusada sem substituir a ordenha existente', () async {
    await putProduction();
    final remote = await selected();
    await productionStorage.upsert(
      'farm-a',
      DairyDailyProductionData(
        date: DateTime(2026, 10, 5),
        morningLiters: 777,
        afternoonLiters: 0,
        cowsMilked: 12,
      ),
    );

    await expectLater(add(remote), throwsStateError);

    final local = await productionStorage.load('farm-a', strict: true);
    expect(local, hasLength(1));
    expect(local.single.totalLiters, 777);
  });

  test('cópia atualizada após abertura não é adicionada', () async {
    await putProduction();
    final stale = await selected();
    await putProduction(version: 2, liters: 300);

    await expectLater(add(stale), throwsStateError);
    expect(await productionStorage.load('farm-a', strict: true), isEmpty);
  });

  test('tombstone recebido após abertura bloqueia a adição da cópia', () async {
    await putProduction();
    final stale = await selected();
    await putProduction(version: 2, deleted: true);

    await expectLater(add(stale), throwsStateError);
    expect(await productionStorage.load('farm-a', strict: true), isEmpty);
  });

  test(
    'troca de contexto antes da gravação preserva o histórico local',
    () async {
      await putProduction();

      await expectLater(
        add(await selected(), inScope: () => false),
        throwsStateError,
      );

      expect(await productionStorage.load('farm-a', strict: true), isEmpty);
    },
  );
}
