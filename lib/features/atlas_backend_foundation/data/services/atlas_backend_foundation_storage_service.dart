import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/atlas_backend_foundation/domain/models/atlas_backend_foundation_record.dart';

class AtlasBackendFoundationStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _key({required String farmName, required String animalId}) =>
      'atlas_backend_foundation_${_normalize(farmName)}_${_normalize(animalId)}';

  Future<List<AtlasBackendFoundationRecord>> load({
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
            (e) => AtlasBackendFoundationRecord.fromMap(
              Map<String, dynamic>.from(e as Map),
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
    required List<AtlasBackendFoundationRecord> records,
  }) async {
    await _preferences.setString(
      _key(farmName: farmName, animalId: animalId),
      jsonEncode(records.map((e) => e.toMap()).toList()),
    );
  }
}
