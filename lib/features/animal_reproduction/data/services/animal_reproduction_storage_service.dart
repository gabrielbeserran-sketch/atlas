import 'dart:convert';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalReproductionStorageService {
  AnimalReproductionStorageService({AtlasHttpClient? httpClient})
    : _http = httpClient ?? AtlasHttpClient();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasHttpClient _http;

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _key(String farmName, String groupName, String animalId) =>
      'atlas_animal_reproduction_${_normalize(farmName)}_'
      '${_normalize(groupName)}_${_normalize(animalId)}';

  Future<List<AnimalReproductionData>> loadRecords({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    final key = _key(farmName, groupName, animalId);
    try {
      final remote = await _fetchRemote(animalId);
      await _saveLocal(key, remote);
      return remote;
    } catch (_) {
      return _loadLocal(key);
    }
  }

  Future<AnimalReproductionData> createRecord({
    required String farmName,
    required String groupName,
    required String animalId,
    required AnimalReproductionData record,
  }) async {
    final response = await _http.send(
      'POST',
      '/livestock/animals/$animalId/reproduction',
      body: record.toApi(),
    );
    final created = AnimalReproductionData.fromMap(response.asMap());
    return _verifyAndCache(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
      recordId: created.id,
    );
  }

  Future<AnimalReproductionData> updateRecord({
    required String farmName,
    required String groupName,
    required String animalId,
    required AnimalReproductionData record,
  }) async {
    await _http.send(
      'PATCH',
      '/livestock/animals/$animalId/reproduction/${record.id}',
      body: record.toApi(),
    );
    return _verifyAndCache(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
      recordId: record.id,
    );
  }

  Future<void> deleteRecord({
    required String farmName,
    required String groupName,
    required String animalId,
    required String recordId,
  }) async {
    await _http.send(
      'DELETE',
      '/livestock/animals/$animalId/reproduction/$recordId',
    );
    final remote = await _fetchRemote(animalId);
    if (remote.any((item) => item.id == recordId)) {
      throw StateError(
        'O registro reprodutivo ainda existe após a exclusão no servidor.',
      );
    }
    await _saveLocal(_key(farmName, groupName, animalId), remote);
  }

  Future<List<AnimalReproductionData>> saveRecords({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalReproductionData> records,
  }) async {
    final remote = await _fetchRemote(animalId);
    final remoteIds = remote.map((item) => item.id).toSet();
    final created = <AnimalReproductionData>[];
    for (final record in records) {
      if (remoteIds.contains(record.id) || record.synced) {
        continue;
      }
      created.add(
        await createRecord(
          farmName: farmName,
          groupName: groupName,
          animalId: animalId,
          record: record,
        ),
      );
    }
    final refreshed = created.isEmpty ? remote : await _fetchRemote(animalId);
    await _saveLocal(_key(farmName, groupName, animalId), refreshed);
    return refreshed;
  }

  Future<AnimalReproductionData> _verifyAndCache({
    required String farmName,
    required String groupName,
    required String animalId,
    required String recordId,
  }) async {
    final remote = await _fetchRemote(animalId);
    final saved = remote.firstWhere(
      (item) => item.id == recordId,
      orElse: () => throw StateError(
        'O registro reprodutivo não foi confirmado após nova leitura do servidor.',
      ),
    );
    await _saveLocal(_key(farmName, groupName, animalId), remote);
    return saved;
  }

  Future<List<AnimalReproductionData>> _fetchRemote(String animalId) async {
    final response = await _http.send(
      'GET',
      '/livestock/animals/$animalId/reproduction',
    );
    return response.asMapList().map(AnimalReproductionData.fromMap).toList();
  }

  Future<List<AnimalReproductionData>> _loadLocal(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) return <AnimalReproductionData>[];
    try {
      return (AtlasTextNormalizer.normalize(jsonDecode(raw)) as List<dynamic>)
          .map(
            (item) => AnimalReproductionData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AnimalReproductionData>[];
    }
  }

  Future<void> _saveLocal(
    String key,
    List<AnimalReproductionData> records,
  ) => _preferences.setString(
    key,
    jsonEncode(records.map((record) => record.toMap()).toList()),
  );
}
