import 'dart:convert';

import 'package:projeto_atlas/features/animal_operations_center/domain/models/animal_operational_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalOperationalTaskStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _key({
    required String farmName,
    required String groupName,
    required String animalId,
  }) {
    return 'atlas_animal_operational_tasks_'
        '${_normalize(farmName)}_'
        '${_normalize(groupName)}_'
        '${_normalize(animalId)}';
  }

  Future<List<AnimalOperationalTask>> load({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    final raw = await _preferences.getString(
      _key(farmName: farmName, groupName: groupName, animalId: animalId),
    );

    if (raw == null || raw.isEmpty) return [];

    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) => AnimalOperationalTask.fromMap(
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
    required String groupName,
    required String animalId,
    required List<AnimalOperationalTask> tasks,
  }) async {
    await _preferences.setString(
      _key(farmName: farmName, groupName: groupName, animalId: animalId),
      jsonEncode(tasks.map((task) => task.toMap()).toList()),
    );
  }
}
