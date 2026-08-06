import 'dart:convert';

import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmInventoryStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _createStorageKey(String farmName) {
    final normalizedFarm = _normalize(farmName);

    return 'atlas_farm_inventory_$normalizedFarm';
  }

  Future<List<FarmInventoryData>> loadItems(String farmName) async {
    final storageKey = _createStorageKey(farmName);

    final savedData = await _preferences.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;

      return decodedData
          .map(
            (item) => FarmInventoryData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveItems({
    required String farmName,
    required List<FarmInventoryData> items,
  }) async {
    final storageKey = _createStorageKey(farmName);

    final encodedData = jsonEncode(items.map((item) => item.toMap()).toList());

    await _preferences.setString(storageKey, encodedData);
  }
}
