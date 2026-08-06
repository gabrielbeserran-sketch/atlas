import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasBiForecast {
  const AtlasBiForecast({
    required this.generatedAt,
    required this.indicatorId,
    required this.farmName,
    required this.title,
    required this.category,
    required this.unit,
    required this.currentValue,
    required this.targetValue,
    required this.horizonDays,
    required this.projectedValue,
    required this.projectedVariationPercent,
    required this.targetProbabilityPercent,
    required this.confidencePercent,
    required this.trend,
    required this.risk,
    required this.summary,
    required this.recommendation,
    required this.points,
  });

  final DateTime generatedAt;

  final String indicatorId;
  final String farmName;
  final String title;

  final AtlasBiCategory category;
  final String unit;

  final double currentValue;
  final double targetValue;

  final int horizonDays;

  final double projectedValue;
  final double projectedVariationPercent;
  final double targetProbabilityPercent;
  final double confidencePercent;

  final AtlasBiForecastTrend trend;
  final AtlasBiForecastRisk risk;

  final String summary;
  final String recommendation;

  final List<AtlasBiForecastPoint> points;

  bool get isPositive {
    return projectedVariationPercent > 0;
  }

  bool get likelyToReachTarget {
    return targetProbabilityPercent >= 70;
  }
}

class AtlasBiForecastPoint {
  const AtlasBiForecastPoint({
    required this.date,
    required this.projectedValue,
    required this.lowerBound,
    required this.upperBound,
  });

  final DateTime date;

  final double projectedValue;
  final double lowerBound;
  final double upperBound;
}

class AtlasBiForecastDashboardData {
  const AtlasBiForecastDashboardData({
    required this.generatedAt,
    required this.summary,
    required this.forecasts,
    required this.positiveCount,
    required this.stableCount,
    required this.negativeCount,
    required this.highRiskCount,
  });

  final DateTime generatedAt;
  final String summary;

  final List<AtlasBiForecast> forecasts;

  final int positiveCount;
  final int stableCount;
  final int negativeCount;
  final int highRiskCount;

  bool get hasData {
    return forecasts.isNotEmpty;
  }

  AtlasBiForecast? get priorityForecast {
    if (forecasts.isEmpty) {
      return null;
    }

    return forecasts.first;
  }
}

enum AtlasBiForecastTrend {
  strongGrowth,
  growth,
  stable,
  decline,
  strongDecline,
  unavailable,
}

enum AtlasBiForecastRisk {
  low,
  medium,
  high,
  critical,
}

String atlasBiForecastTrendLabel(
  AtlasBiForecastTrend trend,
) {
  switch (trend) {
    case AtlasBiForecastTrend.strongGrowth:
      return 'Crescimento forte';

    case AtlasBiForecastTrend.growth:
      return 'Crescimento';

    case AtlasBiForecastTrend.stable:
      return 'Estável';

    case AtlasBiForecastTrend.decline:
      return 'Queda';

    case AtlasBiForecastTrend.strongDecline:
      return 'Queda forte';

    case AtlasBiForecastTrend.unavailable:
      return 'Histórico insuficiente';
  }
}

String atlasBiForecastRiskLabel(
  AtlasBiForecastRisk risk,
) {
  switch (risk) {
    case AtlasBiForecastRisk.low:
      return 'Baixo';

    case AtlasBiForecastRisk.medium:
      return 'Médio';

    case AtlasBiForecastRisk.high:
      return 'Alto';

    case AtlasBiForecastRisk.critical:
      return 'Crítico';
  }
}
