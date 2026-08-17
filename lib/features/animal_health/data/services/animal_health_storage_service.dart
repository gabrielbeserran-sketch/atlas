import 'dart:convert';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalHealthStorageService {
  AnimalHealthStorageService({AtlasHttpClient? httpClient})
    : _http = httpClient ?? AtlasHttpClient();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasHttpClient _http;

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _key(String farmName, String groupName, String animalId) =>
      'atlas_animal_health_${_normalize(farmName)}_'
      '${_normalize(groupName)}_${_normalize(animalId)}';

  Future<List<AnimalHealthData>> loadRecords({
    required String farmName,
    required String groupName,
    required String animalId,
    String farmId = '',
  }) async {
    final key = _key(farmName, groupName, animalId);
    if (farmId.trim().isNotEmpty) {
      try {
        final remote = await _fetchRemote(
          farmId: farmId.trim(),
          animalId: animalId,
        );
        await _saveLocal(key, remote);
        return remote;
      } catch (_) {
        // Em contingência offline usa apenas o último cache confirmado.
      }
    }
    return _loadLocal(key);
  }

  Future<AnimalHealthData> createRecord({
    required String farmName,
    required String groupName,
    required String farmId,
    required String animalId,
    required String lotId,
    required AnimalHealthData record,
  }) async {
    final response = await _http.send(
      'POST',
      '/livestock/health',
      body: record.toApi(
        farmId: farmId,
        animalId: animalId,
        lotId: lotId.isEmpty ? null : lotId,
      ),
    );
    final created = AnimalHealthData.fromMap(response.asMap());
    return _verifyAndCache(
      farmName: farmName,
      groupName: groupName,
      farmId: farmId,
      animalId: animalId,
      recordId: created.id,
    );
  }

  Future<AnimalHealthData> updateRecord({
    required String farmName,
    required String groupName,
    required String farmId,
    required String animalId,
    required AnimalHealthData record,
  }) async {
    await _http.send(
      'PATCH',
      '/livestock/health/${record.id}',
      body: record.toUpdateApi(),
    );
    return _verifyAndCache(
      farmName: farmName,
      groupName: groupName,
      farmId: farmId,
      animalId: animalId,
      recordId: record.id,
    );
  }

  Future<void> deleteRecord({
    required String farmName,
    required String groupName,
    required String farmId,
    required String animalId,
    required String recordId,
  }) async {
    await _http.send('DELETE', '/livestock/health/$recordId');
    final remote = await _fetchRemote(farmId: farmId, animalId: animalId);
    if (remote.any((item) => item.id == recordId)) {
      throw StateError(
        'O registro sanitário ainda existe após a exclusão no servidor.',
      );
    }
    await _saveLocal(_key(farmName, groupName, animalId), remote);
  }

  Future<List<AnimalHealthData>> saveRecords({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalHealthData> records,
    String farmId = '',
    String lotId = '',
  }) async {
    if (farmId.trim().isEmpty) {
      await _saveLocal(_key(farmName, groupName, animalId), records);
      return records;
    }
    final remote = await _fetchRemote(farmId: farmId, animalId: animalId);
    final remoteIds = remote.map((item) => item.id).toSet();
    for (final record in records) {
      if (remoteIds.contains(record.id) || record.synced) continue;
      await createRecord(
        farmName: farmName,
        groupName: groupName,
        farmId: farmId,
        animalId: animalId,
        lotId: lotId,
        record: record,
      );
    }
    final refreshed = await _fetchRemote(farmId: farmId, animalId: animalId);
    await _saveLocal(_key(farmName, groupName, animalId), refreshed);
    return refreshed;
  }

  Future<AnimalHealthData> _verifyAndCache({
    required String farmName,
    required String groupName,
    required String farmId,
    required String animalId,
    required String recordId,
  }) async {
    final remote = await _fetchRemote(farmId: farmId, animalId: animalId);
    final saved = remote.firstWhere(
      (item) => item.id == recordId,
      orElse: () => throw StateError(
        'O registro sanitário não foi confirmado após nova leitura do servidor.',
      ),
    );
    await _saveLocal(_key(farmName, groupName, animalId), remote);
    return saved;
  }

  Future<List<AnimalHealthData>> _fetchRemote({
    required String farmId,
    required String animalId,
  }) async {
    final response = await _http.send(
      'GET',
      '/livestock/health',
      queryParameters: {'farm_id': farmId, 'animal_id': animalId},
    );
    return response.asMapList().map(AnimalHealthData.fromMap).toList();
  }

  Future<List<AnimalHealthData>> _loadLocal(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) return <AnimalHealthData>[];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) => AnimalHealthData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AnimalHealthData>[];
    }
  }

  Future<void> _saveLocal(String key, List<AnimalHealthData> records) =>
      _preferences.setString(
        key,
        jsonEncode(records.map((record) => record.toMap()).toList()),
      );
}
