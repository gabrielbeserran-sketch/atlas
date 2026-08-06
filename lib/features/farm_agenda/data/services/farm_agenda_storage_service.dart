import 'dart:convert';

import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmAgendaStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _createStorageKey(String farmName) {
    final normalizedFarm = _normalize(farmName);

    return 'atlas_farm_agenda_$normalizedFarm';
  }

  Future<List<FarmAgendaData>> loadTasks(String farmName) async {
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
                FarmAgendaData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks({
    required String farmName,
    required List<FarmAgendaData> tasks,
  }) async {
    final storageKey = _createStorageKey(farmName);

    final encodedData = jsonEncode(tasks.map((task) => task.toMap()).toList());

    await _preferences.setString(storageKey, encodedData);
  }
}
