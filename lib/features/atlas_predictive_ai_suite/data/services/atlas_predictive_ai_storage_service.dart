import 'dart:convert';

import 'package:projeto_atlas/features/atlas_predictive_ai_suite/domain/models/atlas_predictive_ai_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasPredictiveAiStorageService {
  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _key({
    required String farmName,
    required String animalId,
  }) {
    return 'atlas_predictive_ai_suite_'
        '${_normalize(farmName)}_'
        '${_normalize(animalId)}';
  }

  Future<List<AtlasPredictiveAiRecord>> load({
    required String farmName,
    required String animalId,
  }) async {
    final raw = await _preferences.getString(
      _key(
        farmName: farmName,
        animalId: animalId,
      ),
    );

    if (raw == null || raw.trim().isEmpty) return [];

    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) => AtlasPredictiveAiRecord.fromMap(
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
    required List<AtlasPredictiveAiRecord> records,
  }) async {
    await _preferences.setString(
      _key(
        farmName: farmName,
        animalId: animalId,
      ),
      jsonEncode(
        records.map((record) => record.toMap()).toList(),
      ),
    );
  }
}
