import 'package:projeto_atlas/core/database/atlas_local_database.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/core/sync/atlas_sync_engine.dart';

class AtlasConnectedRepository {
  AtlasConnectedRepository({
    required this.entityType,
    required this.baseEndpoint,
    AtlasHttpClient? httpClient,
    AtlasLocalDatabase? localDatabase,
    AtlasSyncEngine? syncEngine,
  })  : _httpClient = httpClient ?? AtlasHttpClient(),
        _localDatabase =
            localDatabase ?? AtlasLocalDatabase.instance,
        _syncEngine = syncEngine ?? AtlasSyncEngine();

  final String entityType;
  final String baseEndpoint;
  final AtlasHttpClient _httpClient;
  final AtlasLocalDatabase _localDatabase;
  final AtlasSyncEngine _syncEngine;

  Future<List<Map<String, dynamic>>> list({
    required String companyId,
    required String farmId,
    Map<String, String>? additionalQuery,
  }) async {
    try {
      final response = await _httpClient.send(
        'GET',
        baseEndpoint,
        queryParameters: {
          'farm_id': farmId,
          ...?additionalQuery,
        },
      );

      final items = response.asMapList();

      for (final item in items) {
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) continue;

        await _localDatabase.cacheEntity(
          entityType: entityType,
          companyId: companyId,
          farmId: farmId,
          entityId: id,
          payload: item,
          remoteVersion:
              item['updated_at']?.toString(),
        );
      }

      return items;
    } catch (_) {
      return _localDatabase.cachedEntities(
        entityType: entityType,
        companyId: companyId,
        farmId: farmId,
      );
    }
  }

  Future<Map<String, dynamic>> create({
    required String companyId,
    required String farmId,
    required Map<String, dynamic> payload,
    required String localId,
  }) async {
    final localPayload = {
      ...payload,
      'id': localId,
      '_sync_status': 'pending',
    };

    await _localDatabase.cacheEntity(
      entityType: entityType,
      companyId: companyId,
      farmId: farmId,
      entityId: localId,
      payload: localPayload,
      remoteVersion:
          DateTime.now().toIso8601String(),
    );

    try {
      final response = await _httpClient.send(
        'POST',
        baseEndpoint,
        body: payload,
      );

      final remote = response.asMap();
      final remoteId =
          remote['id']?.toString() ?? localId;

      if (remoteId != localId) {
        await _localDatabase.removeCachedEntity(
          entityType: entityType,
          companyId: companyId,
          farmId: farmId,
          entityId: localId,
        );
      }

      await _localDatabase.cacheEntity(
        entityType: entityType,
        companyId: companyId,
        farmId: farmId,
        entityId: remoteId,
        payload: remote,
        remoteVersion:
            remote['updated_at']?.toString(),
      );

      return remote;
    } catch (_) {
      await _syncEngine.enqueue(
        companyId: companyId,
        farmId: farmId,
        method: 'POST',
        endpoint: baseEndpoint,
        entityType: entityType,
        entityId: localId,
        localVersion:
            DateTime.now().toIso8601String(),
        payload: payload,
      );

      return localPayload;
    }
  }

  Future<Map<String, dynamic>> update({
    required String companyId,
    required String farmId,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final localPayload = {
      ...payload,
      'id': entityId,
      '_sync_status': 'pending',
    };

    await _localDatabase.cacheEntity(
      entityType: entityType,
      companyId: companyId,
      farmId: farmId,
      entityId: entityId,
      payload: localPayload,
      remoteVersion:
          DateTime.now().toIso8601String(),
    );

    try {
      final response = await _httpClient.send(
        'PATCH',
        '$baseEndpoint/$entityId',
        body: payload,
      );

      final remote = response.asMap();

      await _localDatabase.cacheEntity(
        entityType: entityType,
        companyId: companyId,
        farmId: farmId,
        entityId: entityId,
        payload: remote,
        remoteVersion:
            remote['updated_at']?.toString(),
      );

      return remote;
    } catch (_) {
      await _syncEngine.enqueue(
        companyId: companyId,
        farmId: farmId,
        method: 'PATCH',
        endpoint: '$baseEndpoint/$entityId',
        entityType: entityType,
        entityId: entityId,
        localVersion:
            DateTime.now().toIso8601String(),
        payload: payload,
      );

      return localPayload;
    }
  }
}
