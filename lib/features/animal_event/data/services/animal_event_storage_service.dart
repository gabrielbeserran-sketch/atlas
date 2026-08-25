import 'dart:convert';

import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/animal_event/domain/models/animal_event_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalEventStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _createStorageKey({
    required String farmName,
    required String groupName,
    required String animalId,
  }) {
    final normalizedFarm = _normalize(farmName);
    final normalizedGroup = _normalize(groupName);
    final normalizedAnimal = _normalize(animalId);

    return 'atlas_animal_events_'
        '${normalizedFarm}_'
        '${normalizedGroup}_'
        '$normalizedAnimal';
  }

  Future<List<AnimalEventData>> loadEvents({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
    );

    final savedData = await _preferences.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final decodedData = AtlasTextNormalizer.normalize(jsonDecode(savedData)) as List<dynamic>;

      return decodedData
          .map(
            (item) =>
                AnimalEventData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEvents({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalEventData> events,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
    );

    final encodedData = jsonEncode(
      events.map((event) => event.toMap()).toList(),
    );

    await _preferences.setString(storageKey, encodedData);
  }
}
