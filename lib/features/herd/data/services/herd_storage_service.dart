import 'dart:convert';

import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HerdStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _createStorageKey({
    required String farmName,
    String farmId = '',
  }) {
    final source = farmId.trim().isNotEmpty ? farmId : farmName;
    final normalized = source.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return 'atlas_herd_groups_$normalized';
  }

  Future<List<HerdGroupData>> loadGroups(
    String farmName, {
    String farmId = '',
  }) async {
    final storageKey = _createStorageKey(farmName: farmName, farmId: farmId);
    var savedData = await _preferences.getString(storageKey);

    if ((savedData == null || savedData.isEmpty) && farmId.trim().isNotEmpty) {
      final legacyKey = _createStorageKey(farmName: farmName);
      savedData = await _preferences.getString(legacyKey);
    }

    if (savedData == null || savedData.isEmpty) {
      return <HerdGroupData>[];
    }

    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;
      return decodedData
          .map((item) => HerdGroupData.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (_) {
      return <HerdGroupData>[];
    }
  }

  Future<void> saveGroups({
    required String farmName,
    required List<HerdGroupData> groups,
    String farmId = '',
  }) async {
    final storageKey = _createStorageKey(farmName: farmName, farmId: farmId);
    final encodedData = jsonEncode(
      groups.map((group) => group.toMap()).toList(),
    );
    await _preferences.setString(storageKey, encodedData);
  }
}
