import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_forecast.dart';

class AtlasBiForecastService {
  const AtlasBiForecastService();

  AtlasBiForecastDashboardData buildDashboard({
    required List<AtlasBiIndicator> indicators,
    int horizonDays = 90,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final forecasts = indicators.map((indicator) {
      return buildForecast(
        indicator: indicator,
        horizonDays: horizonDays,
        now: currentTime,
      );
    }).toList()
      ..sort(_compareForecasts);

    final positiveCount = forecasts.where((item) {
      return item.trend ==
              AtlasBiForecastTrend.strongGrowth ||
          item.trend ==
              AtlasBiForecastTrend.growth;
    }).length;

    final stableCount = forecasts.where((item) {
      return item.trend ==
          AtlasBiForecastTrend.stable;
    }).length;

    final negativeCount = forecasts.where((item) {
      return item.trend ==
              AtlasBiForecastTrend.decline ||
          item.trend ==
              AtlasBiForecastTrend.strongDecline;
    }).length;

    final highRiskCount = forecasts.where((item) {
      return item.risk ==
              AtlasBiForecastRisk.high ||
          item.risk ==
              AtlasBiForecastRisk.critical;
    }).length;

    return AtlasBiForecastDashboardData(
      generatedAt: currentTime,
      summary: _dashboardSummary(
        total: forecasts.length,
        positive: positiveCount,
        stable: stableCount,
        negative: negativeCount,
        highRisk: highRiskCount,
        horizonDays: horizonDays,
      ),
      forecasts: forecasts,
      positiveCount: positiveCount,
      stableCount: stableCount,
      negativeCount: negativeCount,
      highRiskCount: highRiskCount,
    );
  }

  AtlasBiForecast buildForecast({
    required AtlasBiIndicator indicator,
    int horizonDays = 90,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final orderedSeries = [...indicator.series]
      ..sort(
        (first, second) =>
            first.recordedAt.compareTo(
          second.recordedAt,
        ),
      );

    final regression = _linearRegression(
      orderedSeries,
    );

    final projectedValue = orderedSeries.length < 2
        ? indicator.currentValue
        : regression.intercept +
            regression.slope *
                (orderedSeries.length - 1 +
                    horizonDays);

    final safeProjectedValue =
        projectedValue.isFinite
            ? projectedValue
            : indicator.currentValue;

    final variationPercent =
        indicator.currentValue == 0
            ? 0.0
            : (safeProjectedValue -
                    indicator.currentValue) /
                indicator.currentValue.abs() *
                100;

    final trend = _trendFromVariation(
      variationPercent,
      orderedSeries.length >= 2,
    );

    final confidence = _confidence(
      sampleCount: orderedSeries.length,
      determinationCoefficient:
          regression.determinationCoefficient,
    );

    final targetProbability =
        _targetProbability(
      projectedValue: safeProjectedValue,
      targetValue: indicator.targetValue,
      currentValue: indicator.currentValue,
      confidencePercent: confidence,
    );

    final risk = _risk(
      status: indicator.status,
      trend: trend,
      targetProbabilityPercent:
          targetProbability,
      confidencePercent: confidence,
    );

    final points = _forecastPoints(
      currentTime: currentTime,
      currentValue: indicator.currentValue,
      finalProjectedValue:
          safeProjectedValue,
      horizonDays: horizonDays,
      confidencePercent: confidence,
    );

    return AtlasBiForecast(
      generatedAt: currentTime,
      indicatorId: indicator.id,
      farmName: indicator.farmName,
      title: indicator.title,
      category: indicator.category,
      unit: indicator.unit,
      currentValue: indicator.currentValue,
      targetValue: indicator.targetValue,
      horizonDays: horizonDays,
      projectedValue: safeProjectedValue,
      projectedVariationPercent:
          variationPercent,
      targetProbabilityPercent:
          targetProbability,
      confidencePercent: confidence,
      trend: trend,
      risk: risk,
      summary: _forecastSummary(
        indicator: indicator,
        projectedValue: safeProjectedValue,
        variationPercent:
            variationPercent,
        trend: trend,
        risk: risk,
        horizonDays: horizonDays,
      ),
      recommendation: _recommendation(
        indicator: indicator,
        trend: trend,
        risk: risk,
        targetProbabilityPercent:
            targetProbability,
      ),
      points: points,
    );
  }

  _RegressionResult _linearRegression(
    List<AtlasBiSeriesPoint> series,
  ) {
    if (series.length < 2) {
      return _RegressionResult(
        slope: 0,
        intercept:
            series.isEmpty ? 0 : series.last.value,
        determinationCoefficient: 0,
      );
    }

    final count = series.length.toDouble();

    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumXX = 0.0;

    for (var index = 0;
        index < series.length;
        index++) {
      final x = index.toDouble();
      final y = series[index].value;

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final denominator =
        count * sumXX - sumX * sumX;

    if (denominator == 0) {
      return _RegressionResult(
        slope: 0,
        intercept: series.last.value,
        determinationCoefficient: 0,
      );
    }

    final slope =
        (count * sumXY - sumX * sumY) /
            denominator;

    final intercept =
        (sumY - slope * sumX) / count;

    final meanY = sumY / count;

    var totalVariation = 0.0;
    var residualVariation = 0.0;

    for (var index = 0;
        index < series.length;
        index++) {
      final actual = series[index].value;
      final predicted =
          intercept + slope * index;

      totalVariation +=
          math.pow(actual - meanY, 2).toDouble();

      residualVariation +=
          math.pow(
            actual - predicted,
            2,
          ).toDouble();
    }

    final determinationCoefficient =
        totalVariation == 0
            ? 1.0
            : 1 -
                residualVariation /
                    totalVariation;

    return _RegressionResult(
      slope: slope,
      intercept: intercept,
      determinationCoefficient:
          determinationCoefficient
              .clamp(0.0, 1.0)
              .toDouble(),
    );
  }

  double _confidence({
    required int sampleCount,
    required double determinationCoefficient,
  }) {
    if (sampleCount < 2) {
      return 20;
    }

    final sampleScore =
        (sampleCount / 12 * 100)
            .clamp(0.0, 100.0)
            .toDouble();

    final value =
        sampleScore * 0.45 +
            determinationCoefficient * 100 * 0.55;

    return value.clamp(20.0, 98.0).toDouble();
  }

  double _targetProbability({
    required double projectedValue,
    required double targetValue,
    required double currentValue,
    required double confidencePercent,
  }) {
    if (targetValue == 0) {
      return 0;
    }

    final distanceToTarget =
        (targetValue - currentValue).abs();

    if (distanceToTarget == 0) {
      return 100;
    }

    final projectedProgress =
        1 -
            (targetValue - projectedValue).abs() /
                distanceToTarget;

    final baseProbability =
        projectedProgress * 100;

    final adjusted =
        baseProbability * 0.70 +
            confidencePercent * 0.30;

    return adjusted.clamp(0.0, 100.0).toDouble();
  }

  AtlasBiForecastTrend _trendFromVariation(
    double variationPercent,
    bool hasHistory,
  ) {
    if (!hasHistory) {
      return AtlasBiForecastTrend.unavailable;
    }

    if (variationPercent >= 12) {
      return AtlasBiForecastTrend.strongGrowth;
    }

    if (variationPercent >= 3) {
      return AtlasBiForecastTrend.growth;
    }

    if (variationPercent <= -12) {
      return AtlasBiForecastTrend.strongDecline;
    }

    if (variationPercent <= -3) {
      return AtlasBiForecastTrend.decline;
    }

    return AtlasBiForecastTrend.stable;
  }

  AtlasBiForecastRisk _risk({
    required AtlasBiStatus status,
    required AtlasBiForecastTrend trend,
    required double targetProbabilityPercent,
    required double confidencePercent,
  }) {
    if (status == AtlasBiStatus.critical &&
        targetProbabilityPercent < 35) {
      return AtlasBiForecastRisk.critical;
    }

    if (trend ==
            AtlasBiForecastTrend.strongDecline ||
        targetProbabilityPercent < 50) {
      return AtlasBiForecastRisk.high;
    }

    if (trend == AtlasBiForecastTrend.decline ||
        confidencePercent < 55 ||
        targetProbabilityPercent < 70) {
      return AtlasBiForecastRisk.medium;
    }

    return AtlasBiForecastRisk.low;
  }

  List<AtlasBiForecastPoint> _forecastPoints({
    required DateTime currentTime,
    required double currentValue,
    required double finalProjectedValue,
    required int horizonDays,
    required double confidencePercent,
  }) {
    const pointCount = 6;

    final points =
        <AtlasBiForecastPoint>[];

    final uncertaintyPercent =
        (100 - confidencePercent) / 100;

    for (var index = 1;
        index <= pointCount;
        index++) {
      final progress = index / pointCount;

      final projectedValue =
          currentValue +
              (finalProjectedValue -
                      currentValue) *
                  progress;

      final uncertainty =
          projectedValue.abs() *
              uncertaintyPercent *
              progress *
              0.35;

      points.add(
        AtlasBiForecastPoint(
          date: currentTime.add(
            Duration(
              days:
                  (horizonDays * progress).round(),
            ),
          ),
          projectedValue: projectedValue,
          lowerBound:
              projectedValue - uncertainty,
          upperBound:
              projectedValue + uncertainty,
        ),
      );
    }

    return points;
  }

  int _compareForecasts(
    AtlasBiForecast first,
    AtlasBiForecast second,
  ) {
    final firstRisk =
        _riskWeight(first.risk);

    final secondRisk =
        _riskWeight(second.risk);

    if (firstRisk != secondRisk) {
      return secondRisk.compareTo(firstRisk);
    }

    return first.targetProbabilityPercent
        .compareTo(
      second.targetProbabilityPercent,
    );
  }

  int _riskWeight(
    AtlasBiForecastRisk risk,
  ) {
    switch (risk) {
      case AtlasBiForecastRisk.low:
        return 1;

      case AtlasBiForecastRisk.medium:
        return 2;

      case AtlasBiForecastRisk.high:
        return 3;

      case AtlasBiForecastRisk.critical:
        return 4;
    }
  }

  String _forecastSummary({
    required AtlasBiIndicator indicator,
    required double projectedValue,
    required double variationPercent,
    required AtlasBiForecastTrend trend,
    required AtlasBiForecastRisk risk,
    required int horizonDays,
  }) {
    final variationLabel =
        variationPercent >= 0
            ? 'aumento'
            : 'redução';

    return 'Nos próximos $horizonDays dias, '
        '${indicator.title} apresenta '
        '${atlasBiForecastTrendLabel(trend).toLowerCase()}, '
        'com $variationLabel estimado de '
        '${variationPercent.abs().toStringAsFixed(1)}% '
        'e valor projetado de '
        '${projectedValue.toStringAsFixed(1)} '
        '${indicator.unit}. '
        'O risco da projeção é '
        '${atlasBiForecastRiskLabel(risk).toLowerCase()}.';
  }

  String _recommendation({
    required AtlasBiIndicator indicator,
    required AtlasBiForecastTrend trend,
    required AtlasBiForecastRisk risk,
    required double targetProbabilityPercent,
  }) {
    if (risk == AtlasBiForecastRisk.critical) {
      return 'Criar uma intervenção imediata, definir responsável e acompanhar o indicador semanalmente.';
    }

    if (risk == AtlasBiForecastRisk.high) {
      return 'Revisar as causas da tendência, ajustar o plano de ação e reduzir o intervalo entre medições.';
    }

    if (targetProbabilityPercent < 70) {
      return 'Reavaliar a meta e reforçar as ações com maior impacto esperado.';
    }

    if (trend ==
            AtlasBiForecastTrend.strongGrowth ||
        trend == AtlasBiForecastTrend.growth) {
      return 'Manter o plano atual, documentar as práticas responsáveis pelo avanço e validar a consistência do resultado.';
    }

    return 'Manter o acompanhamento periódico e revisar a projeção quando novos dados forem registrados.';
  }

  String _dashboardSummary({
    required int total,
    required int positive,
    required int stable,
    required int negative,
    required int highRisk,
    required int horizonDays,
  }) {
    if (total == 0) {
      return 'Ainda não existem indicadores suficientes para gerar previsões.';
    }

    return 'O forecast analisou $total indicadores para os próximos '
        '$horizonDays dias: $positive com tendência positiva, '
        '$stable estáveis, $negative com tendência negativa e '
        '$highRisk em risco alto ou crítico.';
  }
}

class _RegressionResult {
  const _RegressionResult({
    required this.slope,
    required this.intercept,
    required this.determinationCoefficient,
  });

  final double slope;
  final double intercept;
  final double determinationCoefficient;
}
