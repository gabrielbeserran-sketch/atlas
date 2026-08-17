import 'dart:convert';

import 'package:projeto_atlas/features/predictive/domain/models/atlas_predictive_scenario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasPredictiveScenarioStorageService {
  const AtlasPredictiveScenarioStorageService();

  static const String _keyPrefix = 'atlas_predictive_custom_scenarios_v1';

  static const int maximumScenariosPerFarm = 30;

  Future<List<AtlasPredictiveScenarioRequest>> load({
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

      return decoded
          .whereType<Map>()
          .map((item) {
            return _fromJson(Map<String, dynamic>.from(item));
          })
          .where((item) {
            return item.title.trim().isNotEmpty;
          })
          .take(maximumScenariosPerFarm)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save({
    required String farmName,
    required List<AtlasPredictiveScenarioRequest> scenarios,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final limited = scenarios.length > maximumScenariosPerFarm
        ? scenarios.sublist(scenarios.length - maximumScenariosPerFarm)
        : scenarios;

    final value = jsonEncode(limited.map(_toJson).toList());

    await preferences.setString(_storageKey(farmName), value);
  }

  Future<void> clear({required String farmName}) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey(farmName));
  }

  Map<String, dynamic> _toJson(AtlasPredictiveScenarioRequest request) {
    return {
      'type': request.type.name,
      'title': request.title,
      'description': request.description,
      'changePercent': request.changePercent,
      'investmentValue': request.investmentValue,
      'executionDays': request.executionDays,
    };
  }

  AtlasPredictiveScenarioRequest _fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? '';

    return AtlasPredictiveScenarioRequest(
      type: AtlasPredictiveScenarioType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => AtlasPredictiveScenarioType.custom,
      ),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      changePercent: _readDouble(json['changePercent']),
      investmentValue: _readDouble(json['investmentValue']),
      executionDays: _readInt(json['executionDays'], 30),
    );
  }

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
