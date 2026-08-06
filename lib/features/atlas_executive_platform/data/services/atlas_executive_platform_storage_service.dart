import 'dart:convert';

import 'package:projeto_atlas/features/atlas_executive_platform/domain/models/atlas_executive_platform_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutivePlatformStorageService {
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
    return 'atlas_executive_platform_'
        '${_normalize(farmName)}_'
        '${_normalize(animalId)}';
  }

  Future<List<AtlasExecutivePlatformRecord>> load({
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
            (item) => AtlasExecutivePlatformRecord.fromMap(
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
    required List<AtlasExecutivePlatformRecord> records,
  }) async {
    await _preferences.setString(
      _key(farmName: farmName, animalId: animalId),
      jsonEncode(records.map((record) => record.toMap()).toList()),
    );
  }
}
