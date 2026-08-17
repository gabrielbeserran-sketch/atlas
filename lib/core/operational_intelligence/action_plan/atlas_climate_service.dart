import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_climate_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasClimateService {
  AtlasClimateService._();

  static final AtlasClimateService instance = AtlasClimateService._();

  static const String _observationsKey = 'atlas_climate_observations_v1';
  static const String _forecastsKey = 'atlas_climate_forecasts_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasClimateObservation>> loadObservations({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _observationsKey,
      AtlasClimateObservation.fromMap,
    );
    return _filterFarm(values, farmName, (item) => item.farmName)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  Future<void> saveObservation(AtlasClimateObservation observation) async {
    final values = await _decodeList(
      _observationsKey,
      AtlasClimateObservation.fromMap,
    );
    _upsert(values, observation, (item) => item.id);
    await _saveList(
      _observationsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasClimateForecast>> loadForecasts({String? farmName}) async {
    final values = await _decodeList(
      _forecastsKey,
      AtlasClimateForecast.fromMap,
    );
    return _filterFarm(values, farmName, (item) => item.farmName)
      ..sort((a, b) => a.forecastAt.compareTo(b.forecastAt));
  }

  Future<void> saveForecast(AtlasClimateForecast forecast) async {
    final values = await _decodeList(
      _forecastsKey,
      AtlasClimateForecast.fromMap,
    );
    _upsert(values, forecast, (item) => item.id);
    await _saveList(_forecastsKey, values.map((item) => item.toMap()).toList());
  }

  Future<AtlasClimateExecutiveSnapshot> buildSnapshot({
    String? farmName,
  }) async {
    final observations = await loadObservations(farmName: farmName);
    final forecasts = await loadForecasts(farmName: farmName);
    final now = DateTime.now();
    final last30Days = observations
        .where(
          (item) =>
              now.difference(item.occurredAt).inDays >= 0 &&
              now.difference(item.occurredAt).inDays <= 30,
        )
        .toList();
    final next7Days = forecasts
        .where(
          (item) =>
              item.forecastAt.isAfter(now.subtract(const Duration(days: 1))) &&
              item.forecastAt.isBefore(now.add(const Duration(days: 8))),
        )
        .toList();

    double average(
      List<AtlasClimateObservation> values,
      double Function(AtlasClimateObservation item) read,
    ) {
      if (values.isEmpty) return 0;
      return values.fold<double>(0, (total, item) => total + read(item)) /
          values.length;
    }

    final rainfall = last30Days.fold<double>(
      0,
      (total, item) => total + item.rainfallMm,
    );
    final maxTemperature = average(
      last30Days,
      (item) => item.maximumTemperatureC,
    );
    final humidity = average(
      last30Days,
      (item) => item.relativeHumidityPercent,
    );
    final maximumThi = last30Days.isEmpty
        ? 0.0
        : last30Days
              .map((item) => item.temperatureHumidityIndex)
              .reduce((a, b) => a > b ? a : b);
    final thermalStressDays = last30Days
        .where(
          (item) =>
              item.thermalStressRisk == AtlasClimateRiskLevel.high ||
              item.thermalStressRisk == AtlasClimateRiskLevel.critical,
        )
        .length;
    final dryDays = last30Days.where((item) => item.rainfallMm < 1).length;
    final forecastRainfall = next7Days.fold<double>(
      0,
      (total, item) => total + item.expectedRainfallMm,
    );

    var score = 85.0;
    score -= thermalStressDays * 3;
    score -= dryDays > 15 ? 15 : dryDays * 0.5;
    if (rainfall < 30 && last30Days.isNotEmpty) {
      score -= 15;
    }
    if (maximumThi >= 84) {
      score -= 15;
    } else if (maximumThi >= 75) {
      score -= 8;
    }
    score = score.clamp(0, 100);

    final risk = score >= 80
        ? AtlasClimateRiskLevel.low
        : score >= 60
        ? AtlasClimateRiskLevel.moderate
        : score >= 40
        ? AtlasClimateRiskLevel.high
        : AtlasClimateRiskLevel.critical;

    return AtlasClimateExecutiveSnapshot(
      totalRainfall30DaysMm: rainfall,
      averageMaximumTemperatureC: maxTemperature,
      averageHumidityPercent: humidity,
      maximumThi: maximumThi,
      thermalStressDays: thermalStressDays,
      dryDays: dryDays,
      forecastRainfall7DaysMm: forecastRainfall,
      climateScore: score,
      riskLevel: risk,
    );
  }

  Future<List<String>> buildRecommendations({
    required String? farmName,
    required AtlasClimateExecutiveSnapshot snapshot,
  }) async {
    final recommendations = <String>[];

    if (snapshot.maximumThi >= 75) {
      recommendations.add(
        'Risco de estresse térmico elevado. Reforce sombra, água, ventilação e horários de manejo.',
      );
    }
    if (snapshot.totalRainfall30DaysMm < 30) {
      recommendations.add(
        'Chuva acumulada baixa nos últimos 30 dias. Ajuste lotação, suplementação e planejamento hídrico.',
      );
    }
    if (snapshot.dryDays > 15) {
      recommendations.add(
        '${snapshot.dryDays} dias secos foram registrados no período analisado.',
      );
    }
    if (snapshot.forecastRainfall7DaysMm > 60) {
      recommendations.add(
        'Previsão de chuva intensa para sete dias. Reprograme pulverizações, movimentações e operações de solo.',
      );
    }
    if (snapshot.averageMaximumTemperatureC > 34) {
      recommendations.add(
        'Temperatura máxima média superior a 34 °C. Evite manejo nas horas mais quentes.',
      );
    }
    if (recommendations.isEmpty) {
      recommendations.add(
        'Condições climáticas dentro de faixa operacional adequada. Mantenha registros e planejamento preventivo.',
      );
    }
    return recommendations;
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) return <T>[];

    try {
      return (jsonDecode(raw) as List)
          .map((item) => fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> values) {
    return _preferences.setString(key, jsonEncode(values));
  }

  void _upsert<T>(List<T> values, T value, String Function(T) readId) {
    final index = values.indexWhere((item) => readId(item) == readId(value));
    if (index == -1) {
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  List<T> _filterFarm<T>(
    List<T> values,
    String? farmName,
    String? Function(T) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return values;
    }
    return values.where((value) {
      return readFarm(value)?.trim().toLowerCase() == normalized;
    }).toList();
  }
}
