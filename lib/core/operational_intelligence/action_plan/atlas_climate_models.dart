enum AtlasClimateRiskLevel { low, moderate, high, critical }

String atlasClimateRiskLevelLabel(AtlasClimateRiskLevel value) {
  switch (value) {
    case AtlasClimateRiskLevel.low:
      return 'Baixo';
    case AtlasClimateRiskLevel.moderate:
      return 'Moderado';
    case AtlasClimateRiskLevel.high:
      return 'Alto';
    case AtlasClimateRiskLevel.critical:
      return 'Crítico';
  }
}

class AtlasClimateObservation {
  const AtlasClimateObservation({
    required this.id,
    required this.occurredAt,
    required this.rainfallMm,
    required this.minimumTemperatureC,
    required this.maximumTemperatureC,
    required this.relativeHumidityPercent,
    required this.windSpeedKmH,
    required this.solarRadiationMjM2,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final DateTime occurredAt;
  final double rainfallMm;
  final double minimumTemperatureC;
  final double maximumTemperatureC;
  final double relativeHumidityPercent;
  final double windSpeedKmH;
  final double solarRadiationMjM2;
  final String? farmName;
  final String notes;

  double get averageTemperatureC =>
      (minimumTemperatureC + maximumTemperatureC) / 2;

  double get temperatureHumidityIndex {
    final temperature = maximumTemperatureC;
    final humidity = relativeHumidityPercent / 100;
    return (1.8 * temperature + 32) -
        ((0.55 - 0.55 * humidity) * (1.8 * temperature - 26));
  }

  AtlasClimateRiskLevel get thermalStressRisk {
    final thi = temperatureHumidityIndex;
    if (thi < 68) return AtlasClimateRiskLevel.low;
    if (thi < 75) return AtlasClimateRiskLevel.moderate;
    if (thi < 84) return AtlasClimateRiskLevel.high;
    return AtlasClimateRiskLevel.critical;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'occurredAt': occurredAt.toIso8601String(),
    'rainfallMm': rainfallMm,
    'minimumTemperatureC': minimumTemperatureC,
    'maximumTemperatureC': maximumTemperatureC,
    'relativeHumidityPercent': relativeHumidityPercent,
    'windSpeedKmH': windSpeedKmH,
    'solarRadiationMjM2': solarRadiationMjM2,
    'farmName': farmName,
    'notes': notes,
  };

  factory AtlasClimateObservation.fromMap(Map<String, dynamic> map) {
    double value(String key) => (map[key] as num?)?.toDouble() ?? 0;

    return AtlasClimateObservation(
      id: map['id']?.toString() ?? '',
      occurredAt:
          DateTime.tryParse(map['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      rainfallMm: value('rainfallMm'),
      minimumTemperatureC: value('minimumTemperatureC'),
      maximumTemperatureC: value('maximumTemperatureC'),
      relativeHumidityPercent: value('relativeHumidityPercent'),
      windSpeedKmH: value('windSpeedKmH'),
      solarRadiationMjM2: value('solarRadiationMjM2'),
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasClimateForecast {
  const AtlasClimateForecast({
    required this.id,
    required this.forecastAt,
    required this.expectedRainfallMm,
    required this.minimumTemperatureC,
    required this.maximumTemperatureC,
    required this.relativeHumidityPercent,
    required this.probabilityOfRainPercent,
    required this.source,
    required this.farmName,
  });

  final String id;
  final DateTime forecastAt;
  final double expectedRainfallMm;
  final double minimumTemperatureC;
  final double maximumTemperatureC;
  final double relativeHumidityPercent;
  final double probabilityOfRainPercent;
  final String source;
  final String? farmName;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'forecastAt': forecastAt.toIso8601String(),
    'expectedRainfallMm': expectedRainfallMm,
    'minimumTemperatureC': minimumTemperatureC,
    'maximumTemperatureC': maximumTemperatureC,
    'relativeHumidityPercent': relativeHumidityPercent,
    'probabilityOfRainPercent': probabilityOfRainPercent,
    'source': source,
    'farmName': farmName,
  };

  factory AtlasClimateForecast.fromMap(Map<String, dynamic> map) {
    double value(String key) => (map[key] as num?)?.toDouble() ?? 0;

    return AtlasClimateForecast(
      id: map['id']?.toString() ?? '',
      forecastAt:
          DateTime.tryParse(map['forecastAt']?.toString() ?? '') ??
          DateTime.now(),
      expectedRainfallMm: value('expectedRainfallMm'),
      minimumTemperatureC: value('minimumTemperatureC'),
      maximumTemperatureC: value('maximumTemperatureC'),
      relativeHumidityPercent: value('relativeHumidityPercent'),
      probabilityOfRainPercent: value('probabilityOfRainPercent'),
      source: map['source']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
    );
  }
}

class AtlasClimateExecutiveSnapshot {
  const AtlasClimateExecutiveSnapshot({
    required this.totalRainfall30DaysMm,
    required this.averageMaximumTemperatureC,
    required this.averageHumidityPercent,
    required this.maximumThi,
    required this.thermalStressDays,
    required this.dryDays,
    required this.forecastRainfall7DaysMm,
    required this.climateScore,
    required this.riskLevel,
  });

  final double totalRainfall30DaysMm;
  final double averageMaximumTemperatureC;
  final double averageHumidityPercent;
  final double maximumThi;
  final int thermalStressDays;
  final int dryDays;
  final double forecastRainfall7DaysMm;
  final double climateScore;
  final AtlasClimateRiskLevel riskLevel;
}
