import 'dart:convert';

import 'package:projeto_atlas/core/auth/atlas_active_context.dart';
import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_enterprise_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalWeightStorageService {
  AnimalWeightStorageService({
    SharedPreferencesAsync? preferences,
    AnimalWeightEnterpriseService? enterprise,
    String? companyId,
    String? farmId,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _enterprise = enterprise ?? AnimalWeightEnterpriseService(),
       _companyId = companyId,
       _farmId = farmId;

  final SharedPreferencesAsync _preferences;
  final AnimalWeightEnterpriseService _enterprise;
  final String? _companyId;
  final String? _farmId;

  String? _createStorageKey(String animalId, {String? farmId}) {
    final company = (_companyId ?? AtlasActiveContext.instance.companyId ?? '')
        .trim();
    final farm = (farmId ?? _farmId ?? AtlasActiveContext.instance.farmId ?? '')
        .trim();
    final animal = animalId.trim();
    if (company.isEmpty || farm.isEmpty || animal.isEmpty) return null;
    final scope = [
      company,
      farm,
      animal,
    ].map((value) => base64Url.encode(utf8.encode(value))).join('_');
    return 'atlas_animal_weights_v2_$scope';
  }

  Future<List<AnimalWeightData>> loadWeights({
    required String farmName,
    required String groupName,
    required String animalId,
    String? farmId,
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
          farmId: farmId,
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
      farmId: farmId,
    );
  }

  Future<List<AnimalWeightData>> _loadLocalWeights({
    required String farmName,
    required String groupName,
    required String animalId,
    String? farmId,
  }) async {
    final storageKey = _createStorageKey(animalId, farmId: farmId);
    if (storageKey == null) return <AnimalWeightData>[];

    final savedData = await _preferences.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return <AnimalWeightData>[];
    }

    try {
      final decodedData =
          AtlasTextNormalizer.normalize(jsonDecode(savedData)) as List<dynamic>;

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
    String? farmId,
    required List<AnimalWeightData> weights,
  }) async {
    final storageKey = _createStorageKey(animalId, farmId: farmId);
    if (storageKey == null) return;

    final encodedData = jsonEncode(
      weights.map((weight) => weight.toMap()).toList(),
    );

    await _preferences.setString(storageKey, encodedData);
  }
}
