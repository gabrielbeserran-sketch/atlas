import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/models/atlas_bi_analytics_data.dart';

class AtlasBiAnalyticsService {
  const AtlasBiAnalyticsService();

  AtlasBiAnalyticsData build({
    required AtlasBiAnalyticsInput input,
    DateTime? now,
  }) {
    final bottlenecks = _buildBottlenecks(indicators: input.indicators);

    final investments = _buildInvestments(
      bottlenecks: bottlenecks,
      defaultInvestmentValue: input.defaultInvestmentValue,
    );

    final correlations = _buildCorrelations(input.indicators);

    final scenarios = _buildScenarios(input.indicators);

    final score = _analyticsScore(
      bottlenecks: bottlenecks,
      investments: investments,
    );

    return AtlasBiAnalyticsData(
      generatedAt: now ?? DateTime.now(),
      summary: _buildSummary(
        score: score,
        bottlenecks: bottlenecks,
        investments: investments,
        correlations: correlations,
        scenarios: scenarios,
      ),
      score: score,
      bottlenecks: bottlenecks,
      investments: investments,
      correlations: correlations,
      scenarios: scenarios,
    );
  }

  List<AtlasBiBottleneck> _buildBottlenecks({
    required List<AtlasBiIndicator> indicators,
  }) {
    final result =
        indicators
            .where((indicator) {
              return indicator.status == AtlasBiStatus.attention ||
                  indicator.status == AtlasBiStatus.critical;
            })
            .map((indicator) {
              final gap = (100 - indicator.targetAchievementPercent)
                  .clamp(0.0, 100.0)
                  .toDouble();

              final trendPenalty = _trendPenalty(indicator.trend);

              final financialImpact = _estimateFinancialImpact(
                indicator: indicator,
                performanceGapPercent: gap,
              );

              final priorityScore =
                  (gap * 0.55 +
                          trendPenalty * 0.20 +
                          math.min(financialImpact / 1000, 25) * 0.25)
                      .clamp(0.0, 100.0)
                      .toDouble();

              return AtlasBiBottleneck(
                id: 'bottleneck_${indicator.farmName}_${indicator.id}',
                farmName: indicator.farmName,
                indicatorId: indicator.id,
                indicatorTitle: indicator.title,
                category: indicator.category,
                currentValue: indicator.currentValue,
                targetValue: indicator.targetValue,
                unit: indicator.unit,
                performanceGapPercent: gap,
                financialImpactValue: financialImpact,
                priorityScore: priorityScore,
                severity: _severityFromScore(priorityScore),
                cause: _causeFromIndicator(indicator),
                recommendation: _bottleneckRecommendation(indicator, gap),
              );
            })
            .toList()
          ..sort(
            (first, second) =>
                second.priorityScore.compareTo(first.priorityScore),
          );

    return result;
  }

  List<AtlasBiInvestmentOpportunity> _buildInvestments({
    required List<AtlasBiBottleneck> bottlenecks,
    required double defaultInvestmentValue,
  }) {
    final safeInvestment = defaultInvestmentValue <= 0
        ? 10000.0
        : defaultInvestmentValue;

    final result =
        bottlenecks.map((item) {
          final effort = _effortFromGap(item.performanceGapPercent);

          final effortWeight = switch (effort) {
            AtlasBiAnalyticsEffort.low => 0.65,
            AtlasBiAnalyticsEffort.medium => 1.0,
            AtlasBiAnalyticsEffort.high => 1.45,
          };

          final investment = safeInvestment * effortWeight;

          final expectedReturn = math.max(
            item.financialImpactValue * 0.65,
            investment * 1.05,
          );

          final roi = investment <= 0
              ? 0.0
              : (expectedReturn - investment) / investment * 100;

          final dailyReturn = expectedReturn / 365;

          final paybackDays = dailyReturn > 0
              ? (investment / dailyReturn).ceil()
              : null;

          final confidence = (55 + item.priorityScore * 0.35)
              .clamp(40.0, 95.0)
              .toDouble();

          final impactScore =
              (item.priorityScore * 0.55 +
                      roi.clamp(0.0, 150.0) * 0.30 +
                      confidence * 0.15)
                  .clamp(0.0, 100.0)
                  .toDouble();

          return AtlasBiInvestmentOpportunity(
            id: 'investment_${item.id}',
            farmName: item.farmName,
            title: 'Intervenção — ${item.indicatorTitle}',
            description:
                'Investimento direcionado para reduzir o gargalo identificado.',
            category: item.category,
            investmentValue: investment,
            expectedReturnValue: expectedReturn,
            roiPercent: roi,
            paybackDays: paybackDays,
            confidencePercent: confidence,
            impactScore: impactScore,
            effort: effort,
            recommendation:
                'Priorizar ações com maior impacto mensurável, definir responsável e acompanhar o indicador mensalmente.',
          );
        }).toList()..sort(
          (first, second) => second.impactScore.compareTo(first.impactScore),
        );

    return result;
  }

  List<AtlasBiCorrelation> _buildCorrelations(
    List<AtlasBiIndicator> indicators,
  ) {
    final result = <AtlasBiCorrelation>[];

    for (var firstIndex = 0; firstIndex < indicators.length; firstIndex++) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < indicators.length;
        secondIndex++
      ) {
        final first = indicators[firstIndex];
        final second = indicators[secondIndex];

        if (first.farmName != second.farmName) {
          continue;
        }

        final coefficient = _correlation(first.series, second.series);

        if (coefficient.abs() < 0.30) {
          continue;
        }

        result.add(
          AtlasBiCorrelation(
            firstIndicatorId: first.id,
            firstIndicatorTitle: first.title,
            secondIndicatorId: second.id,
            secondIndicatorTitle: second.title,
            category: first.category,
            coefficient: coefficient,
            strength: _correlationStrength(coefficient.abs()),
            direction: _correlationDirection(coefficient),
            explanation: _correlationExplanation(
              first: first,
              second: second,
              coefficient: coefficient,
            ),
          ),
        );
      }
    }

    result.sort(
      (first, second) =>
          second.coefficient.abs().compareTo(first.coefficient.abs()),
    );

    return result.take(30).toList();
  }

  List<AtlasBiScenarioAnalysis> _buildScenarios(
    List<AtlasBiIndicator> indicators,
  ) {
    final scenarios = <AtlasBiScenarioAnalysis>[];

    for (final indicator in indicators) {
      final improvementPercent = indicator.status == AtlasBiStatus.critical
          ? 15.0
          : indicator.status == AtlasBiStatus.attention
          ? 10.0
          : 5.0;

      final simulatedValue =
          indicator.currentValue * (1 + improvementPercent / 100);

      final financialImpact = _estimateFinancialImpact(
        indicator: indicator,
        performanceGapPercent: improvementPercent,
      );

      scenarios.add(
        AtlasBiScenarioAnalysis(
          id: 'scenario_${indicator.farmName}_${indicator.id}',
          farmName: indicator.farmName,
          title: 'Melhorar ${indicator.title}',
          description:
              'Simulação de aumento de ${improvementPercent.toStringAsFixed(0)}% no indicador.',
          category: indicator.category,
          currentValue: indicator.currentValue,
          simulatedValue: simulatedValue,
          changePercent: improvementPercent,
          projectedFinancialImpact: financialImpact,
          riskReductionPercent: (improvementPercent * 1.8)
              .clamp(0.0, 60.0)
              .toDouble(),
          confidencePercent: _scenarioConfidence(indicator),
          recommendation:
              'Executar primeiro uma intervenção piloto e validar o impacto antes de ampliar.',
        ),
      );
    }

    scenarios.sort(
      (first, second) => second.projectedFinancialImpact.compareTo(
        first.projectedFinancialImpact,
      ),
    );

    return scenarios.take(20).toList();
  }

  double _correlation(
    List<AtlasBiSeriesPoint> first,
    List<AtlasBiSeriesPoint> second,
  ) {
    final count = math.min(first.length, second.length);

    if (count < 3) {
      return 0;
    }

    final firstValues = first
        .sublist(first.length - count)
        .map((item) => item.value)
        .toList();

    final secondValues = second
        .sublist(second.length - count)
        .map((item) => item.value)
        .toList();

    final firstMean = firstValues.reduce((a, b) => a + b) / count;

    final secondMean = secondValues.reduce((a, b) => a + b) / count;

    var numerator = 0.0;
    var firstDenominator = 0.0;
    var secondDenominator = 0.0;

    for (var index = 0; index < count; index++) {
      final firstDifference = firstValues[index] - firstMean;

      final secondDifference = secondValues[index] - secondMean;

      numerator += firstDifference * secondDifference;

      firstDenominator += firstDifference * firstDifference;

      secondDenominator += secondDifference * secondDifference;
    }

    final denominator = math.sqrt(firstDenominator * secondDenominator);

    if (denominator == 0) {
      return 0;
    }

    return (numerator / denominator).clamp(-1.0, 1.0).toDouble();
  }

  double _estimateFinancialImpact({
    required AtlasBiIndicator indicator,
    required double performanceGapPercent,
  }) {
    final categoryWeight = switch (indicator.category) {
      AtlasBiCategory.finance => 1800.0,
      AtlasBiCategory.production => 1500.0,
      AtlasBiCategory.reproduction => 1400.0,
      AtlasBiCategory.health => 1100.0,
      AtlasBiCategory.inventory => 900.0,
      AtlasBiCategory.pasture => 850.0,
      AtlasBiCategory.management => 700.0,
      AtlasBiCategory.intelligence => 650.0,
    };

    return performanceGapPercent * categoryWeight;
  }

  double _trendPenalty(AtlasBiTrend trend) {
    switch (trend) {
      case AtlasBiTrend.strongDown:
        return 100;

      case AtlasBiTrend.down:
        return 75;

      case AtlasBiTrend.stable:
        return 45;

      case AtlasBiTrend.up:
        return 20;

      case AtlasBiTrend.strongUp:
        return 10;

      case AtlasBiTrend.unavailable:
        return 50;
    }
  }

  AtlasBiAnalyticsSeverity _severityFromScore(double score) {
    if (score >= 80) {
      return AtlasBiAnalyticsSeverity.critical;
    }

    if (score >= 60) {
      return AtlasBiAnalyticsSeverity.high;
    }

    if (score >= 35) {
      return AtlasBiAnalyticsSeverity.medium;
    }

    return AtlasBiAnalyticsSeverity.low;
  }

  AtlasBiAnalyticsEffort _effortFromGap(double gap) {
    if (gap >= 40) {
      return AtlasBiAnalyticsEffort.high;
    }

    if (gap >= 20) {
      return AtlasBiAnalyticsEffort.medium;
    }

    return AtlasBiAnalyticsEffort.low;
  }

  AtlasBiCorrelationStrength _correlationStrength(double value) {
    if (value >= 0.85) {
      return AtlasBiCorrelationStrength.veryStrong;
    }

    if (value >= 0.70) {
      return AtlasBiCorrelationStrength.strong;
    }

    if (value >= 0.45) {
      return AtlasBiCorrelationStrength.moderate;
    }

    return AtlasBiCorrelationStrength.weak;
  }

  AtlasBiCorrelationDirection _correlationDirection(double value) {
    if (value > 0.05) {
      return AtlasBiCorrelationDirection.positive;
    }

    if (value < -0.05) {
      return AtlasBiCorrelationDirection.negative;
    }

    return AtlasBiCorrelationDirection.neutral;
  }

  String _correlationExplanation({
    required AtlasBiIndicator first,
    required AtlasBiIndicator second,
    required double coefficient,
  }) {
    final direction = coefficient >= 0
        ? 'movem-se na mesma direção'
        : 'movem-se em direções opostas';

    return '${first.title} e ${second.title} '
        '$direction, com correlação de '
        '${coefficient.toStringAsFixed(2)}.';
  }

  String _causeFromIndicator(AtlasBiIndicator indicator) {
    if (indicator.series.length < 3) {
      return 'Histórico insuficiente para identificar uma causa estatística confiável.';
    }

    if (indicator.trend == AtlasBiTrend.strongDown ||
        indicator.trend == AtlasBiTrend.down) {
      return 'A tendência histórica indica deterioração progressiva do indicador.';
    }

    return 'O indicador permanece abaixo do nível esperado e exige investigação operacional.';
  }

  String _bottleneckRecommendation(AtlasBiIndicator indicator, double gap) {
    if (gap >= 40) {
      return 'Criar um plano de ação emergencial, com responsável, prazo curto e acompanhamento semanal.';
    }

    if (gap >= 20) {
      return 'Definir uma meta intermediária e atacar as causas com maior impacto operacional.';
    }

    return 'Acompanhar mensalmente e aplicar ajustes graduais até alcançar a meta.';
  }

  double _scenarioConfidence(AtlasBiIndicator indicator) {
    final historyBonus = math.min(indicator.series.length * 5, 30);

    final statusBase = indicator.status == AtlasBiStatus.critical ? 55 : 65;

    return (statusBase + historyBonus).clamp(40, 95).toDouble();
  }

  double _analyticsScore({
    required List<AtlasBiBottleneck> bottlenecks,
    required List<AtlasBiInvestmentOpportunity> investments,
  }) {
    if (bottlenecks.isEmpty) {
      return 100;
    }

    final averageSeverity =
        bottlenecks.fold<double>(0, (sum, item) => sum + item.priorityScore) /
        bottlenecks.length;

    final averageOpportunity = investments.isEmpty
        ? 0.0
        : investments.fold<double>(0, (sum, item) => sum + item.impactScore) /
              investments.length;

    return (100 - averageSeverity * 0.65 + averageOpportunity * 0.20)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  String _buildSummary({
    required double score,
    required List<AtlasBiBottleneck> bottlenecks,
    required List<AtlasBiInvestmentOpportunity> investments,
    required List<AtlasBiCorrelation> correlations,
    required List<AtlasBiScenarioAnalysis> scenarios,
  }) {
    return 'O Atlas BI Analytics identificou '
        '${bottlenecks.length} gargalos, '
        '${investments.length} oportunidades de investimento, '
        '${correlations.length} relações relevantes e '
        '${scenarios.length} cenários simulados. '
        'O score analítico atual é '
        '${score.toStringAsFixed(0)}/100.';
  }
}
