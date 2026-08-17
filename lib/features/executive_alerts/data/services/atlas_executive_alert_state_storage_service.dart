import 'dart:convert';

import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutiveAlertStateStorageService {
  const AtlasExecutiveAlertStateStorageService();

  static const String _keyPrefix = 'atlas_executive_alert_states_v1';

  static const int maximumStatesPerFarm = 300;

  Future<List<AtlasExecutiveAlertState>> load({
    required String farmName,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final value = preferences.getString(_storageKey(farmName));

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      final states = decoded
          .whereType<Map>()
          .map((item) {
            return AtlasExecutiveAlertState.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .where((item) {
            return item.alertId.trim().isNotEmpty;
          })
          .take(maximumStatesPerFarm)
          .toList();

      states.sort(
        (first, second) => second.updatedAt.compareTo(first.updatedAt),
      );

      return states;
    } catch (_) {
      return [];
    }
  }

  Future<void> save({
    required String farmName,
    required List<AtlasExecutiveAlertState> states,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final ordered = [...states]
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));

    final limited = ordered.take(maximumStatesPerFarm).toList();

    await preferences.setString(
      _storageKey(farmName),
      jsonEncode(
        limited.map((item) {
          return item.toJson();
        }).toList(),
      ),
    );
  }

  Future<void> clear({required String farmName}) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey(farmName));
  }

  String _storageKey(String farmName) {
    return '${_keyPrefix}_${_normalize(farmName)}';
  }

  String _normalize(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return normalized.isEmpty ? 'farm' : normalized;
  }
}
