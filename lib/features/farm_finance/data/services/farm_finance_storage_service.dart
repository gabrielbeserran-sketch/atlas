import 'dart:convert';

import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmFinanceStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _createStorageKey(String farmName) {
    final normalizedFarm = _normalize(farmName);

    return 'atlas_farm_finance_$normalizedFarm';
  }

  Future<List<FarmFinanceData>> loadRecords(String farmName) async {
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
                FarmFinanceData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecords({
    required String farmName,
    required List<FarmFinanceData> records,
  }) async {
    final storageKey = _createStorageKey(farmName);

    final encodedData = jsonEncode(
      records.map((record) => record.toMap()).toList(),
    );

    await _preferences.setString(storageKey, encodedData);
  }
}
