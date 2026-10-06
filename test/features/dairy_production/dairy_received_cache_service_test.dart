import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/services/offline_repository.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_received_cache_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DairyReceivedCacheService service;

  setUp(() async {
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
    service = DairyReceivedCacheService(database: db);
  });

  tearDown(() async => db.close());

  Future<void> cache({
    String tenant = 'tenant-a',
    String farm = 'farm-a',
    String type = 'dairy_daily_production',
    String date = '2026-10-05',
    int version = 1,
    bool deleted = false,
    Map<String, dynamic>? payload,
  }) async {
    final entityId = '$farm:$date';
    await OfflineRepository.applyChangeInDatabase(
      db,
      companyId: 'company-a',
      tenantId: tenant,
      farmId: farm,
      change: <String, dynamic>{
        'farm_id': farm,
        'entity_type': type,
        'entity_id': entityId,
        'version': version,
        'payload':
            payload ??
            (type == 'dairy_herd_snapshot'
                ? <String, dynamic>{
                    'farm_id': farm,
                    'date': date,
                    'eligible_cows': 20,
                    'lactating_cows': 15,
                    'dry_cows': 5,
                    'pregnancies_monitored': 4,
                    'pregnancy_losses': 1,
                  }
                : <String, dynamic>{
                    'farm_id': farm,
                    'date': date,
                    'morning_liters': 120,
                    'afternoon_liters': 100,
                    'cows_milked': 16,
                    'notes': '',
                  }),
        'deleted': deleted,
      },
    );
  }

  Future<List<DairyReceivedCacheRecord>> load({
    String company = 'company-a',
    String tenant = 'tenant-a',
    String farm = 'farm-a',
    Set<String> localKeys = const <String>{},
  }) => service.load(
    companyId: company,
    tenantId: tenant,
    farmId: farm,
    locallyPresentKeys: localKeys,
  );

  test(
    'lista ordenha e estado de lote recebidos sem alterar dados locais',
    () async {
      await cache();
      await cache(type: 'dairy_herd_snapshot');

      final received = await load();

      expect(received, hasLength(2));
      expect(received.map((item) => item.version), everyElement(1));
      expect(
        received
            .where((item) => item.production != null)
            .single
            .production!
            .totalLiters,
        220,
      );
      expect(
        received
            .where((item) => item.snapshot != null)
            .single
            .snapshot!
            .eligibleCows,
        20,
      );
    },
  );

  test(
    'respeita tenant, empresa, fazenda, presença local e tombstone',
    () async {
      await cache();
      await cache(tenant: 'tenant-b', date: '2026-10-04');
      await cache(farm: 'farm-b', date: '2026-10-03');
      await cache(date: '2026-10-02', deleted: true);
      await cache(date: '2026-10-01');

      final received = await load(
        localKeys: const <String>{'dairy_daily_production:farm-a:2026-10-01'},
      );

      expect(received.map((item) => item.entityId), <String>[
        'farm-a:2026-10-05',
      ]);
      expect(await load(company: 'company-b'), isEmpty);
      expect(
        (await load(tenant: 'tenant-b')).map((item) => item.entityId),
        <String>['farm-a:2026-10-04'],
      );
      expect(
        (await load(farm: 'farm-b')).map((item) => item.entityId),
        <String>['farm-b:2026-10-03'],
      );
    },
  );

  test(
    'não mostra payload incompatível ou divergente do identificador',
    () async {
      await cache(
        payload: <String, dynamic>{
          'farm_id': 'farm-a',
          'date': '2026-10-04',
          'morning_liters': 120,
          'afternoon_liters': 100,
          'cows_milked': 16,
        },
      );
      await cache(
        date: '2026-10-04',
        payload: <String, dynamic>{
          'farm_id': 'farm-a',
          'date': '2026-10-04',
          'morning_liters': -1,
          'afternoon_liters': 100,
          'cows_milked': 16,
        },
      );

      expect(await load(), isEmpty);
    },
  );

  test('exige contexto completo da fazenda', () async {
    await expectLater(load(farm: ''), throwsStateError);
  });
}
