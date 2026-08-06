import 'package:projeto_atlas/core/database/atlas_local_database.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/core/sync/atlas_sync_engine.dart';

class AtlasRemoteReproductionRepository {
  AtlasRemoteReproductionRepository({
    AtlasHttpClient? httpClient,
    AtlasLocalDatabase? localDatabase,
    AtlasSyncEngine? syncEngine,
  })  : _http = httpClient ?? AtlasHttpClient(),
        _database =
            localDatabase ?? AtlasLocalDatabase.instance,
        _sync = syncEngine ?? AtlasSyncEngine();

  final AtlasHttpClient _http;
  final AtlasLocalDatabase _database;
  final AtlasSyncEngine _sync;

  Future<List<Map<String, dynamic>>> list({
    required String companyId,
    required String farmId,
    required String animalId,
  }) async {
    try {
      final response = await _http.send(
        'GET',
        '/livestock/animals/$animalId/reproduction',
      );

      final items = response.asMapList();

      for (final item in items) {
        await _database.cacheEntity(
          entityType: 'reproduction_event',
          companyId: companyId,
          farmId: farmId,
          entityId: item['id'].toString(),
          payload: item,
        );
      }

      return items;
    } catch (_) {
      return _database.cachedEntities(
        entityType: 'reproduction_event',
        companyId: companyId,
        farmId: farmId,
      );
    }
  }

  Future<Map<String, dynamic>> create({
    required String companyId,
    required String farmId,
    required String animalId,
    required String localId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _http.send(
        'POST',
        '/livestock/animals/$animalId/reproduction',
        body: payload,
      );

      final item = response.asMap();

      await _database.cacheEntity(
        entityType: 'reproduction_event',
        companyId: companyId,
        farmId: farmId,
        entityId: item['id'].toString(),
        payload: item,
      );

      return item;
    } catch (_) {
      final local = {
        ...payload,
        'id': localId,
        'animal_id': animalId,
        '_sync_status': 'pending',
      };

      await _database.cacheEntity(
        entityType: 'reproduction_event',
        companyId: companyId,
        farmId: farmId,
        entityId: localId,
        payload: local,
      );

      await _sync.enqueue(
        companyId: companyId,
        farmId: farmId,
        method: 'POST',
        endpoint:
            '/livestock/animals/$animalId/reproduction',
        entityType: 'reproduction_event',
        entityId: localId,
        payload: payload,
      );

      return local;
    }
  }
}
