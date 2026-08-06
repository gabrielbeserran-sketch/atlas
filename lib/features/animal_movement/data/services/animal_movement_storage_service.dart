import 'dart:convert';

import 'package:projeto_atlas/features/animal_movement/domain/models/animal_movement_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalMovementStorageService {
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

    return 'atlas_animal_movements_'
        '${normalizedFarm}_'
        '${normalizedGroup}_'
        '$normalizedAnimal';
  }

  Future<List<AnimalMovementData>> loadRecords({
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
      final decodedData = jsonDecode(savedData) as List<dynamic>;

      return decodedData
          .map(
            (item) => AnimalMovementData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecords({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalMovementData> records,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
    );

    final encodedData = jsonEncode(
      records.map((record) => record.toMap()).toList(),
    );

    await _preferences.setString(storageKey, encodedData);
  }
}
