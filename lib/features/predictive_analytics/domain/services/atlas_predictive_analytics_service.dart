import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart';

class AtlasPredictiveAnalyticsService {
  const AtlasPredictiveAnalyticsService();

  AtlasPredictiveAnalyticsData build({
    required List<AtlasBiIndicator> indicators,
    int horizonDays = 90,
    DateTime? now,
  }) {
    final safeHorizon = horizonDays <= 0
        ? 90
        : horizonDays;

    final forecasts = _buildForecasts(
      indicators: indicators,
      horizonDays: safeHorizon,
    );

    final scenarios = _buildScenarios(
      forecasts,
    );

    final risks = _buildRisks(
      forecasts,
    );

    final recommendations =
        _buildRecommendations(
      forecasts: forecasts,
      risks: risks,
      scenarios: scenarios,
    );

    final score = _buildScore(
      forecasts: forecasts,
      risks: risks,
    );

    final confidence = _buildConfidence(
      indicators,
    );

    final status = _statusFromScore(score);

    return AtlasPredictiveAnalyticsData(
      generatedAt: now ?? DateTime.now(),
      summary: _buildSummary(
        forecasts: forecasts,
        risks: risks,
        scenarios: scenarios,
        score: score,
        confidence: confidence,
        horizonDays: safeHorizon,
      ),
      horizonDays: safeHorizon,
      score: score,
      confidencePercent: confidence,
      status: status,
      forecasts: forecasts,
      scenarios: scenarios,
      risks: risks,
      recommendations: recommendations,
    );
  }

  List<AtlasPredictiveForecast> _buildForecasts({
    required List<AtlasBiIndicator> indicators,
    required int horizonDays,
  }) {
    final result =
        <AtlasPredictiveForecast>[];

    for (final indicator in indicators) {
      final slope = _linearSlope(
        indicator.series,
      );

      final periods = math.max(
        1,
        horizonDays ~/ 30,
      );

      final projectedValue =
          indicator.currentValue +
              slope * periods;

      final variationPercent =
          indicator.currentValue == 0
              ? 0.0
              : (projectedValue -
                          indicator.currentValue) /
                      indicator.currentValue *
                      100;

      final uncertainty =
          _uncertainty(indicator.series);

      final optimisticValue =
          projectedValue +
              uncertainty * 1.25;

      final pessimisticValue =
          projectedValue -
              uncertainty * 1.25;

      final confidence =
          _indicatorConfidence(
        indicator,
      );

      final risk = _riskLevel(
        indicator: indicator,
        projectedValue: projectedValue,
        variationPercent: variationPercent,
      );

      final kind = _kindFromCategory(
        indicator.category,
        indicator.title,
      );

      final financialImpact =
          _financialImpact(
        indicator: indicator,
        variationPercent: variationPercent,
        kind: kind,
      );

      result.add(
        AtlasPredictiveForecast(
          id:
              'predictive_${indicator.farmName}_${indicator.id}_$horizonDays',
          farmName: indicator.farmName,
          title: indicator.title,
          description:
              'Projeção baseada no histórico disponível do indicador.',
          category: indicator.category,
          kind: kind,
          currentValue:
              indicator.currentValue,
          projectedValue:
              projectedValue,
          expectedVariationPercent:
              variationPercent,
          optimisticValue:
              optimisticValue,
          pessimisticValue:
              pessimisticValue,
          unit: indicator.unit,
          horizonDays: horizonDays,
          confidencePercent: confidence,
          risk: risk,
          financialImpactValue:
              financialImpact,
          recommendation:
              _forecastRecommendation(
            indicator: indicator,
            risk: risk,
            variationPercent:
                variationPercent,
          ),
        ),
      );
    }

    result.sort(
      (first, second) {
        final riskComparison =
            _riskWeight(second.risk)
                .compareTo(
          _riskWeight(first.risk),
        );

        if (riskComparison != 0) {
          return riskComparison;
        }

        return second.financialImpactValue
            .abs()
            .compareTo(
          first.financialImpactValue.abs(),
        );
      },
    );

    return result;
  }

  List<AtlasPredictiveScenario>
      _buildScenarios(
    List<AtlasPredictiveForecast> forecasts,
  ) {
    final result =
        <AtlasPredictiveScenario>[];

    for (final forecast in forecasts.take(15)) {
      final baseImpact =
          forecast.financialImpactValue.abs();

      result.addAll([
        AtlasPredictiveScenario(
          id:
              '${forecast.id}_optimistic',
          farmName: forecast.farmName,
          title:
              '${forecast.title} — cenário otimista',
          description:
              'Projeção com desempenho superior ao esperado.',
          category: forecast.category,
          type:
              AtlasPredictiveScenarioType.optimistic,
          changePercent:
              forecast.expectedVariationPercent +
                  10,
          projectedValue:
              forecast.optimisticValue,
          projectedFinancialImpact:
              baseImpact * 1.25,
          riskReductionPercent: 45,
          confidencePercent:
              (forecast.confidencePercent - 8)
                  .clamp(35.0, 92.0)
                  .toDouble(),
          recommendation:
              'Preparar a operação para capturar o ganho adicional caso a tendência positiva se confirme.',
        ),
        AtlasPredictiveScenario(
          id:
              '${forecast.id}_expected',
          farmName: forecast.farmName,
          title:
              '${forecast.title} — cenário esperado',
          description:
              'Projeção central baseada na tendência atual.',
          category: forecast.category,
          type:
              AtlasPredictiveScenarioType.expected,
          changePercent:
              forecast.expectedVariationPercent,
          projectedValue:
              forecast.projectedValue,
          projectedFinancialImpact:
              baseImpact,
          riskReductionPercent: 25,
          confidencePercent:
              forecast.confidencePercent,
          recommendation:
              forecast.recommendation,
        ),
        AtlasPredictiveScenario(
          id:
              '${forecast.id}_pessimistic',
          farmName: forecast.farmName,
          title:
              '${forecast.title} — cenário pessimista',
          description:
              'Projeção de deterioração ou desempenho abaixo do esperado.',
          category: forecast.category,
          type:
              AtlasPredictiveScenarioType.pessimistic,
          changePercent:
              forecast.expectedVariationPercent -
                  10,
          projectedValue:
              forecast.pessimisticValue,
          projectedFinancialImpact:
              -baseImpact * 1.30,
          riskReductionPercent: 0,
          confidencePercent:
              (forecast.confidencePercent - 5)
                  .clamp(35.0, 95.0)
                  .toDouble(),
          recommendation:
              'Criar um plano preventivo para reduzir perdas caso o cenário negativo comece a se confirmar.',
        ),
        AtlasPredictiveScenario(
          id:
              '${forecast.id}_what_if',
          farmName: forecast.farmName,
          title:
              'E se ${forecast.title} melhorar 10%?',
          description:
              'Simulação de intervenção sobre o indicador.',
          category: forecast.category,
          type:
              AtlasPredictiveScenarioType.whatIf,
          changePercent: 10,
          projectedValue:
              forecast.currentValue * 1.10,
          projectedFinancialImpact:
              baseImpact * 0.85,
          riskReductionPercent: 35,
          confidencePercent:
              (forecast.confidencePercent - 3)
                  .clamp(40.0, 95.0)
                  .toDouble(),
          recommendation:
              'Executar uma intervenção piloto, medir o resultado e ampliar somente após validação.',
        ),
      ]);
    }

    result.sort(
      (first, second) =>
          second.projectedFinancialImpact
              .compareTo(
        first.projectedFinancialImpact,
      ),
    );

    return result;
  }

  List<AtlasPredictiveRisk> _buildRisks(
    List<AtlasPredictiveForecast> forecasts,
  ) {
    final result = forecasts
        .where((item) {
          return item.risk ==
                  AtlasPredictiveAnalyticsRiskLevel
                      .high ||
              item.risk ==
                  AtlasPredictiveAnalyticsRiskLevel
                      .critical;
        })
        .map((item) {
          final probability =
              _riskProbability(item);

          return AtlasPredictiveRisk(
            id: 'risk_${item.id}',
            farmName: item.farmName,
            title:
                'Risco preditivo em ${item.title}',
            description:
                'A tendência indica possibilidade de desvio relevante no horizonte analisado.',
            category: item.category,
            level: item.risk,
            probabilityPercent:
                probability,
            financialImpactValue:
                item.financialImpactValue.abs(),
            horizonDays: item.horizonDays,
            recommendation:
                item.recommendation,
          );
        })
        .toList()
      ..sort(
        (first, second) {
          final riskComparison =
              _riskWeight(second.level)
                  .compareTo(
            _riskWeight(first.level),
          );

          if (riskComparison != 0) {
            return riskComparison;
          }

          return second.probabilityPercent
              .compareTo(
            first.probabilityPercent,
          );
        },
      );

    return result;
  }

  List<AtlasPredictiveRecommendation>
      _buildRecommendations({
    required List<AtlasPredictiveForecast>
        forecasts,
    required List<AtlasPredictiveRisk> risks,
    required List<AtlasPredictiveScenario>
        scenarios,
  }) {
    final result =
        <AtlasPredictiveRecommendation>[];

    for (final risk in risks.take(8)) {
      result.add(
        AtlasPredictiveRecommendation(
          id: 'recommendation_${risk.id}',
          farmName: risk.farmName,
          title:
              'Mitigar ${risk.title}',
          description:
              risk.recommendation,
          category: risk.category,
          priority:
              risk.level ==
                      AtlasPredictiveAnalyticsRiskLevel
                          .critical
                  ? AtlasPredictiveAnalyticsPriority
                      .critical
                  : AtlasPredictiveAnalyticsPriority
                      .high,
          confidencePercent:
              (100 - risk.probabilityPercent * 0.20)
                  .clamp(45.0, 95.0)
                  .toDouble(),
          expectedImpact:
              'Evitar impacto estimado de '
              'R\$ ${risk.financialImpactValue.toStringAsFixed(2)}.',
        ),
      );
    }

    for (final scenario in scenarios
        .where((item) {
      return item.type ==
          AtlasPredictiveScenarioType.whatIf;
    }).take(6)) {
      result.add(
        AtlasPredictiveRecommendation(
          id:
              'recommendation_${scenario.id}',
          farmName: scenario.farmName,
          title: scenario.title,
          description:
              scenario.recommendation,
          category: scenario.category,
          priority:
              scenario.projectedFinancialImpact >=
                      50000
                  ? AtlasPredictiveAnalyticsPriority
                      .high
                  : AtlasPredictiveAnalyticsPriority
                      .medium,
          confidencePercent:
              scenario.confidencePercent,
          expectedImpact:
              'Impacto projetado de '
              'R\$ ${scenario.projectedFinancialImpact.toStringAsFixed(2)}.',
        ),
      );
    }

    if (result.isEmpty) {
      for (final forecast in forecasts.take(5)) {
        result.add(
          AtlasPredictiveRecommendation(
            id:
                'recommendation_monitor_${forecast.id}',
            farmName: forecast.farmName,
            title:
                'Monitorar ${forecast.title}',
            description:
                forecast.recommendation,
            category: forecast.category,
            priority:
                AtlasPredictiveAnalyticsPriority
                    .low,
            confidencePercent:
                forecast.confidencePercent,
            expectedImpact:
                'Manter o indicador dentro da faixa esperada.',
          ),
        );
      }
    }

    return result.take(15).toList();
  }

  double _linearSlope(
    List<AtlasBiSeriesPoint> series,
  ) {
    if (series.length < 2) {
      return 0;
    }

    final count = series.length;
    final xMean = (count - 1) / 2;

    final yMean =
        series.fold<double>(
              0,
              (sum, item) => sum + item.value,
            ) /
            count;

    var numerator = 0.0;
    var denominator = 0.0;

    for (var index = 0;
        index < count;
        index++) {
      final xDiff = index - xMean;
      final yDiff =
          series[index].value - yMean;

      numerator += xDiff * yDiff;
      denominator += xDiff * xDiff;
    }

    if (denominator == 0) {
      return 0;
    }

    return numerator / denominator;
  }

  double _uncertainty(
    List<AtlasBiSeriesPoint> series,
  ) {
    if (series.length < 2) {
      return 0;
    }

    final mean =
        series.fold<double>(
              0,
              (sum, item) => sum + item.value,
            ) /
            series.length;

    final variance =
        series.fold<double>(
              0,
              (sum, item) {
                final difference =
                    item.value - mean;

                return sum +
                    difference * difference;
              },
            ) /
            series.length;

    return math.sqrt(variance);
  }

  double _indicatorConfidence(
    AtlasBiIndicator indicator,
  ) {
    final historyScore =
        math.min(
          indicator.series.length * 7,
          42,
        ).toDouble();

    final statusScore =
        indicator.status ==
                AtlasBiStatus.critical
            ? 38.0
            : indicator.status ==
                    AtlasBiStatus.attention
                ? 48.0
                : 55.0;

    return (historyScore + statusScore)
        .clamp(40.0, 96.0)
        .toDouble();
  }

  AtlasPredictiveAnalyticsRiskLevel
      _riskLevel({
    required AtlasBiIndicator indicator,
    required double projectedValue,
    required double variationPercent,
  }) {
    final targetGap = indicator.targetValue == 0
        ? 0.0
        : (indicator.targetValue -
                    projectedValue)
                .abs() /
            indicator.targetValue *
            100;

    final riskScore =
        targetGap * 0.60 +
            variationPercent.abs() * 0.25 +
            _statusWeight(indicator.status) *
                5;

    if (riskScore >= 75) {
      return AtlasPredictiveAnalyticsRiskLevel
          .critical;
    }

    if (riskScore >= 50) {
      return AtlasPredictiveAnalyticsRiskLevel
          .high;
    }

    if (riskScore >= 25) {
      return AtlasPredictiveAnalyticsRiskLevel
          .medium;
    }

    return AtlasPredictiveAnalyticsRiskLevel.low;
  }

  AtlasPredictiveForecastKind _kindFromCategory(
    AtlasBiCategory category,
    String title,
  ) {
    final normalized = title.toLowerCase();

    if (normalized.contains('peso') ||
        normalized.contains('ganho')) {
      return AtlasPredictiveForecastKind
          .weightGain;
    }

    if (normalized.contains('mortal')) {
      return AtlasPredictiveForecastKind
          .mortalityRisk;
    }

    if (normalized.contains('suplement')) {
      return AtlasPredictiveForecastKind
          .supplementConsumption;
    }

    if (normalized.contains('compra') ||
        normalized.contains('estoque')) {
      return AtlasPredictiveForecastKind
          .purchaseNeed;
    }

    if (normalized.contains('lotação') ||
        normalized.contains('pasto') ||
        normalized.contains('piquete')) {
      return AtlasPredictiveForecastKind
          .pastureCapacity;
    }

    switch (category) {
      case AtlasBiCategory.finance:
        return AtlasPredictiveForecastKind.finance;

      case AtlasBiCategory.production:
        return AtlasPredictiveForecastKind.production;

      case AtlasBiCategory.reproduction:
        return AtlasPredictiveForecastKind.reproduction;

      case AtlasBiCategory.health:
        return AtlasPredictiveForecastKind.health;

      case AtlasBiCategory.inventory:
        return AtlasPredictiveForecastKind
            .purchaseNeed;

      case AtlasBiCategory.pasture:
        return AtlasPredictiveForecastKind
            .pastureCapacity;

      case AtlasBiCategory.management:
        return AtlasPredictiveForecastKind
            .operationalBottleneck;

      case AtlasBiCategory.intelligence:
        return AtlasPredictiveForecastKind
            .operationalBottleneck;
    }
  }

  double _financialImpact({
    required AtlasBiIndicator indicator,
    required double variationPercent,
    required AtlasPredictiveForecastKind kind,
  }) {
    final weight = switch (kind) {
      AtlasPredictiveForecastKind.finance =>
        2200.0,
      AtlasPredictiveForecastKind.cashFlow =>
        2100.0,
      AtlasPredictiveForecastKind.production =>
        1800.0,
      AtlasPredictiveForecastKind.weightGain =>
        1700.0,
      AtlasPredictiveForecastKind.reproduction =>
        1600.0,
      AtlasPredictiveForecastKind.health =>
        1300.0,
      AtlasPredictiveForecastKind.mortalityRisk =>
        2000.0,
      AtlasPredictiveForecastKind.pastureCapacity =>
        1100.0,
      AtlasPredictiveForecastKind.supplementConsumption =>
        900.0,
      AtlasPredictiveForecastKind.purchaseNeed =>
        1000.0,
      AtlasPredictiveForecastKind.operationalBottleneck =>
        800.0,
    };

    return variationPercent * weight;
  }

  String _forecastRecommendation({
    required AtlasBiIndicator indicator,
    required AtlasPredictiveAnalyticsRiskLevel risk,
    required double variationPercent,
  }) {
    if (risk ==
        AtlasPredictiveAnalyticsRiskLevel
            .critical) {
      return 'Criar plano corretivo imediato, validar causas em campo e acompanhar semanalmente.';
    }

    if (risk ==
        AtlasPredictiveAnalyticsRiskLevel.high) {
      return 'Definir ação preventiva, responsável e meta intermediária para reduzir o risco.';
    }

    if (variationPercent < 0) {
      return 'Monitorar a tendência de queda e agir antes que o indicador se torne crítico.';
    }

    return 'Manter o acompanhamento e revisar a projeção quando novos dados forem registrados.';
  }

  double _riskProbability(
    AtlasPredictiveForecast forecast,
  ) {
    final base = switch (forecast.risk) {
      AtlasPredictiveAnalyticsRiskLevel.low =>
        20.0,
      AtlasPredictiveAnalyticsRiskLevel.medium =>
        45.0,
      AtlasPredictiveAnalyticsRiskLevel.high =>
        70.0,
      AtlasPredictiveAnalyticsRiskLevel.critical =>
        88.0,
    };

    return (base +
            forecast
                    .expectedVariationPercent
                    .abs() *
                0.25)
        .clamp(10.0, 98.0)
        .toDouble();
  }

  double _buildScore({
    required List<AtlasPredictiveForecast>
        forecasts,
    required List<AtlasPredictiveRisk> risks,
  }) {
    if (forecasts.isEmpty) {
      return 0;
    }

    final riskPenalty =
        risks.fold<double>(
      0,
      (sum, item) =>
          sum + _riskWeight(item.level) * 6,
    );

    final averageConfidence =
        forecasts.fold<double>(
              0,
              (sum, item) =>
                  sum + item.confidencePercent,
            ) /
            forecasts.length;

    return (averageConfidence - riskPenalty)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _buildConfidence(
    List<AtlasBiIndicator> indicators,
  ) {
    if (indicators.isEmpty) {
      return 0;
    }

    final average =
        indicators.fold<double>(
              0,
              (sum, item) =>
                  sum +
                  _indicatorConfidence(item),
            ) /
            indicators.length;

    return average
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasPredictiveAnalyticsStatus
      _statusFromScore(
    double score,
  ) {
    if (score >= 85) {
      return AtlasPredictiveAnalyticsStatus
          .excellent;
    }

    if (score >= 70) {
      return AtlasPredictiveAnalyticsStatus
          .adequate;
    }

    if (score >= 50) {
      return AtlasPredictiveAnalyticsStatus
          .attention;
    }

    return AtlasPredictiveAnalyticsStatus
        .critical;
  }

  int _riskWeight(
    AtlasPredictiveAnalyticsRiskLevel risk,
  ) {
    switch (risk) {
      case AtlasPredictiveAnalyticsRiskLevel.low:
        return 1;

      case AtlasPredictiveAnalyticsRiskLevel.medium:
        return 2;

      case AtlasPredictiveAnalyticsRiskLevel.high:
        return 3;

      case AtlasPredictiveAnalyticsRiskLevel.critical:
        return 4;
    }
  }

  int _statusWeight(
    AtlasBiStatus status,
  ) {
    switch (status) {
      case AtlasBiStatus.excellent:
        return 1;

      case AtlasBiStatus.adequate:
        return 2;

      case AtlasBiStatus.attention:
        return 3;

      case AtlasBiStatus.critical:
        return 4;
    }
  }

  String _buildSummary({
    required List<AtlasPredictiveForecast>
        forecasts,
    required List<AtlasPredictiveRisk> risks,
    required List<AtlasPredictiveScenario>
        scenarios,
    required double score,
    required double confidence,
    required int horizonDays,
  }) {
    return 'O Predictive Analytics Engine gerou '
        '${forecasts.length} previsões, '
        '${risks.length} riscos relevantes, '
        '${scenarios.length} cenários e '
        'score de ${score.toStringAsFixed(0)}/100 '
        'para o horizonte de $horizonDays dias, '
        'com ${confidence.toStringAsFixed(0)}% de confiança.';
  }
}
