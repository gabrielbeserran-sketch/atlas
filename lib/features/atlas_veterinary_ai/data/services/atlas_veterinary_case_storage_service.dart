import 'dart:convert';

import 'package:projeto_atlas/features/atlas_veterinary_ai/domain/models/atlas_veterinary_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasVeterinaryCaseStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _key({required String farmName, required String animalId}) {
    return 'atlas_veterinary_ai_'
        '${_normalize(farmName)}_'
        '${_normalize(animalId)}';
  }

  Future<List<AtlasVeterinaryCase>> load({
    required String farmName,
    required String animalId,
  }) async {
    final raw = await _preferences.getString(
      _key(farmName: farmName, animalId: animalId),
    );

    if (raw == null || raw.trim().isEmpty) return [];

    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) => AtlasVeterinaryCase.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save({
    required String farmName,
    required String animalId,
    required List<AtlasVeterinaryCase> cases,
  }) async {
    await _preferences.setString(
      _key(farmName: farmName, animalId: animalId),
      jsonEncode(cases.map((item) => item.toMap()).toList()),
    );
  }
}
