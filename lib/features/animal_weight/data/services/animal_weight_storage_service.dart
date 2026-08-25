import 'dart:convert';

import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalWeightStorageService {
  AnimalWeightStorageService({
    SharedPreferencesAsync? preferences,
    AnimalWeightEnterpriseService? enterprise,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _enterprise = enterprise ?? AnimalWeightEnterpriseService();

  final SharedPreferencesAsync _preferences;
  final AnimalWeightEnterpriseService _enterprise;

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

    return 'atlas_animal_weights_'
        '${normalizedFarm}_'
        '${normalizedGroup}_'
        '$normalizedAnimal';
  }

  Future<List<AnimalWeightData>> loadWeights({
    required String farmName,
    required String groupName,
    required String animalId,
    bool preferRemote = true,
  }) async {
    final normalizedAnimalId = animalId.trim();

    if (preferRemote && normalizedAnimalId.isNotEmpty) {
      try {
        final remoteWeights = await _enterprise.listWeights(
          animalId: normalizedAnimalId,
        );

        await saveWeights(
          farmName: farmName,
          groupName: groupName,
          animalId: normalizedAnimalId,
          weights: remoteWeights,
        );

        return remoteWeights;
      } catch (_) {
        // A leitura local abaixo mantém o aplicativo operacional sem internet.
      }
    }

    return _loadLocalWeights(
      farmName: farmName,
      groupName: groupName,
      animalId: normalizedAnimalId,
    );
  }

  Future<List<AnimalWeightData>> _loadLocalWeights({
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
      return <AnimalWeightData>[];
    }

    try {
      final decodedData = AtlasTextNormalizer.normalize(jsonDecode(savedData)) as List<dynamic>;

      return decodedData
          .map(
            (item) => AnimalWeightData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AnimalWeightData>[];
    }
  }

  Future<void> saveWeights({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalWeightData> weights,
  }) async {
    final storageKey = _createStorageKey(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
    );

    final encodedData = jsonEncode(
      weights.map((weight) => weight.toMap()).toList(),
    );

    await _preferences.setString(storageKey, encodedData);
  }
}
