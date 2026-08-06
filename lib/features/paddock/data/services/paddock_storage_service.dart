import 'dart:convert';

import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaddockStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _createStorageKey(String farmName) {
    final normalizedFarmName = farmName.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    return 'atlas_paddocks_$normalizedFarmName';
  }

  Future<List<PaddockData>> loadPaddocks(String farmName) async {
    final storageKey = _createStorageKey(farmName);
    final savedData = await _preferences.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final decodedData = jsonDecode(savedData) as List<dynamic>;

      return decodedData
          .map(
            (item) =>
                PaddockData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePaddocks({
    required String farmName,
    required List<PaddockData> paddocks,
  }) async {
    final storageKey = _createStorageKey(farmName);

    final encodedData = jsonEncode(
      paddocks.map((paddock) => paddock.toMap()).toList(),
    );

    await _preferences.setString(storageKey, encodedData);
  }
}
