import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_benchmark.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_forecast.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/models/atlas_bi_analytics_data.dart';
import 'package:projeto_atlas/features/executive_intelligence/domain/models/atlas_executive_intelligence_data.dart';

class AtlasExecutiveIntelligenceService {
  const AtlasExecutiveIntelligenceService();

  AtlasExecutiveIntelligenceData build({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    DateTime? now,
  }) {
    final rootCauses = _buildRootCauses(
      bi: bi,
      analytics: analytics,
    );

    final cascadeEffects = _buildCascadeEffects(
      analytics: analytics,
      rootCauses: rootCauses,
    );

    final consequences = _buildConsequences(
      forecast: forecast,
      analytics: analytics,
    );

    final priorities = _buildPriorities(
      rootCauses: rootCauses,
      consequences: consequences,
      benchmark: benchmark,
      analytics: analytics,
    );

    final insights = _buildInsights(
      bi: bi,
      forecast: forecast,
      benchmark: benchmark,
      analytics: analytics,
      rootCauses: rootCauses,
      cascadeEffects: cascadeEffects,
    );

    final score = _intelligenceScore(
      bi: bi,
      forecast: forecast,
      benchmark: benchmark,
      analytics: analytics,
      insights: insights,
    );

    final maturity = _maturityFromScore(score);

    return AtlasExecutiveIntelligenceData(
      generatedAt: now ?? DateTime.now(),
      summary: _buildSummary(
        score: score,
        maturity: maturity,
        rootCauses: rootCauses,
        cascadeEffects: cascadeEffects,
        consequences: consequences,
        priorities: priorities,
        insights: insights,
      ),
      intelligenceScore: score,
      maturity: maturity,
      rootCauses: rootCauses,
      cascadeEffects: cascadeEffects,
      consequences: consequences,
      priorities: priorities,
      insights: insights,
    );
  }

  List<AtlasExecutiveRootCause> _buildRootCauses({
    required AtlasBiData bi,
    required AtlasBiAnalyticsData analytics,
  }) {
    final result = <AtlasExecutiveRootCause>[];

    for (final bottleneck in analytics.bottlenecks.take(10)) {
      final evidences = <String>[
        'Lacuna de desempenho de '
            '${bottleneck.performanceGapPercent.toStringAsFixed(1)}%.',
        'Impacto financeiro estimado em '
            'R\$ ${bottleneck.financialImpactValue.toStringAsFixed(2)}.',
        'Prioridade analítica de '
            '${bottleneck.priorityScore.toStringAsFixed(1)}/100.',
      ];

      final relatedIndicator = bi.indicators.cast<AtlasBiIndicator?>().firstWhere(
            (indicator) =>
                indicator?.id == bottleneck.indicatorId &&
                indicator?.farmName == bottleneck.farmName,
            orElse: () => null,
          );

      if (relatedIndicator != null) {
        evidences.add(
          'Situação atual: '
          '${atlasBiStatusLabel(relatedIndicator.status)}.',
        );

        evidences.add(
          'Tendência: '
          '${atlasBiTrendLabel(relatedIndicator.trend)}.',
        );
      }

      result.add(
        AtlasExecutiveRootCause(
          id: 'root_${bottleneck.id}',
          farmName: bottleneck.farmName,
          title:
              'Causa provável em ${bottleneck.indicatorTitle}',
          description: bottleneck.cause,
          category: bottleneck.category,
          confidencePercent:
              (60 + bottleneck.priorityScore * 0.35)
                  .clamp(45.0, 96.0)
                  .toDouble(),
          impactScore: bottleneck.priorityScore,
          severity: _severityFromAnalytics(
            bottleneck.severity,
          ),
          evidences: evidences,
          recommendation: bottleneck.recommendation,
        ),
      );
    }

    result.sort(
      (first, second) =>
          second.impactScore.compareTo(
        first.impactScore,
      ),
    );

    return result;
  }

  List<AtlasExecutiveCascadeEffect> _buildCascadeEffects({
    required AtlasBiAnalyticsData analytics,
    required List<AtlasExecutiveRootCause> rootCauses,
  }) {
    final result = <AtlasExecutiveCascadeEffect>[];

    for (final correlation in analytics.correlations.take(20)) {
      final matchingRootCause = rootCauses.cast<AtlasExecutiveRootCause?>().firstWhere(
            (item) =>
                item?.title.contains(
                  correlation.firstIndicatorTitle,
                ) ??
                false,
            orElse: () => null,
          );

      final farmName =
          matchingRootCause?.farmName ?? 'Operação';

      result.add(
        AtlasExecutiveCascadeEffect(
          id:
              'cascade_${correlation.firstIndicatorId}_${correlation.secondIndicatorId}',
          farmName: farmName,
          sourceTitle:
              correlation.firstIndicatorTitle,
          targetTitle:
              correlation.secondIndicatorTitle,
          category: correlation.category,
          direction:
              _cascadeDirection(
            correlation.direction,
          ),
          strengthPercent:
              correlation.coefficient.abs() * 100,
          explanation:
              correlation.explanation,
        ),
      );
    }

    result.sort(
      (first, second) =>
          second.strengthPercent.compareTo(
        first.strengthPercent,
      ),
    );

    return result;
  }

  List<AtlasExecutiveConsequence> _buildConsequences({
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiAnalyticsData analytics,
  }) {
    final result = <AtlasExecutiveConsequence>[];

    for (final item in forecast.forecasts.take(15)) {
      final relatedScenario =
          analytics.scenarios.cast<AtlasBiScenarioAnalysis?>().firstWhere(
                (scenario) =>
                    scenario?.farmName == item.farmName &&
                    scenario?.title.contains(item.title) == true,
                orElse: () => null,
              );

      final probability =
          (100 - item.targetProbabilityPercent)
              .clamp(0.0, 100.0)
              .toDouble();

      final financialImpact =
          relatedScenario?.projectedFinancialImpact ??
              item.projectedVariationPercent.abs() * 1000;

      final riskReduction =
          relatedScenario?.riskReductionPercent ??
              math.min(
                item.confidencePercent * 0.45,
                60,
              ).toDouble();

      result.add(
        AtlasExecutiveConsequence(
          id:
              'consequence_${item.farmName}_${item.indicatorId}',
          farmName: item.farmName,
          title:
              'Consequência provável em ${item.title}',
          description:
              'Mantida a tendência atual, o indicador pode chegar a '
              '${item.projectedValue.toStringAsFixed(1)} ${item.unit} '
              'nos próximos ${item.horizonDays} dias.',
          category: item.category,
          horizonDays: item.horizonDays,
          probabilityPercent: probability,
          financialImpactValue: financialImpact,
          riskReductionPotentialPercent:
              riskReduction,
          severity: _severityFromForecast(
            item.risk,
          ),
          recommendation: item.recommendation,
        ),
      );
    }

    result.sort(
      (first, second) {
        final severityComparison =
            _severityWeight(second.severity).compareTo(
          _severityWeight(first.severity),
        );

        if (severityComparison != 0) {
          return severityComparison;
        }

        return second.probabilityPercent.compareTo(
          first.probabilityPercent,
        );
      },
    );

    return result;
  }

  List<AtlasExecutivePriority> _buildPriorities({
    required List<AtlasExecutiveRootCause> rootCauses,
    required List<AtlasExecutiveConsequence> consequences,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
  }) {
    final candidates = <_PriorityCandidate>[];

    for (final cause in rootCauses) {
      candidates.add(
        _PriorityCandidate(
          farmName: cause.farmName,
          title: 'Corrigir ${cause.title}',
          description: cause.description,
          category: cause.category,
          score:
              cause.impactScore * 0.65 +
                  cause.confidencePercent * 0.35,
          confidencePercent:
              cause.confidencePercent,
          expectedFinancialImpact:
              cause.impactScore * 1200,
          deadlineDays:
              cause.severity ==
                      AtlasExecutiveIntelligenceSeverity.critical
                  ? 15
                  : 30,
          severity: cause.severity,
          recommendation:
              cause.recommendation,
        ),
      );
    }

    for (final consequence in consequences.take(10)) {
      candidates.add(
        _PriorityCandidate(
          farmName: consequence.farmName,
          title: consequence.title,
          description: consequence.description,
          category: consequence.category,
          score:
              consequence.probabilityPercent * 0.55 +
                  _severityWeight(consequence.severity) *
                      10,
          confidencePercent:
              (100 - consequence.probabilityPercent * 0.25)
                  .clamp(45.0, 95.0)
                  .toDouble(),
          expectedFinancialImpact:
              consequence.financialImpactValue,
          deadlineDays:
              consequence.severity ==
                      AtlasExecutiveIntelligenceSeverity.critical
                  ? 10
                  : 20,
          severity: consequence.severity,
          recommendation:
              consequence.recommendation,
        ),
      );
    }

    if (benchmark.farms.length > 1) {
      for (final farm in benchmark.farms.skip(1).take(5)) {
        candidates.add(
          _PriorityCandidate(
            farmName: farm.farmName,
            title:
                'Reduzir distância para ${benchmark.leadingFarmName ?? 'a referência'}',
            description:
                '${farm.distanceFromLeader.toStringAsFixed(1)} pontos abaixo da fazenda líder.',
            category: AtlasBiCategory.management,
            score:
                farm.distanceFromLeader * 2.2,
            confidencePercent: 82,
            expectedFinancialImpact:
                farm.distanceFromLeader * 1500,
            deadlineDays: 60,
            severity:
                farm.distanceFromLeader >= 25
                    ? AtlasExecutiveIntelligenceSeverity.high
                    : AtlasExecutiveIntelligenceSeverity.medium,
            recommendation:
                'Comparar os principais indicadores e replicar as práticas de melhor desempenho.',
          ),
        );
      }
    }

    for (final investment in analytics.investments.take(5)) {
      candidates.add(
        _PriorityCandidate(
          farmName: investment.farmName,
          title: investment.title,
          description: investment.description,
          category: investment.category,
          score:
              investment.impactScore * 0.70 +
                  investment.confidencePercent * 0.30,
          confidencePercent:
              investment.confidencePercent,
          expectedFinancialImpact:
              investment.expectedReturnValue,
          deadlineDays:
              investment.effort ==
                      AtlasBiAnalyticsEffort.high
                  ? 90
                  : 45,
          severity:
              investment.impactScore >= 80
                  ? AtlasExecutiveIntelligenceSeverity.high
                  : AtlasExecutiveIntelligenceSeverity.medium,
          recommendation:
              investment.recommendation,
        ),
      );
    }

    candidates.sort(
      (first, second) =>
          second.score.compareTo(first.score),
    );

    return List.generate(
      math.min(candidates.length, 12),
      (index) {
        final item = candidates[index];

        return AtlasExecutivePriority(
          position: index + 1,
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          priorityScore:
              item.score.clamp(0.0, 100.0).toDouble(),
          confidencePercent:
              item.confidencePercent,
          expectedFinancialImpact:
              item.expectedFinancialImpact,
          deadlineDays: item.deadlineDays,
          severity: item.severity,
          recommendation:
              item.recommendation,
        );
      },
    );
  }

  List<AtlasExecutiveInsight> _buildInsights({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    required List<AtlasExecutiveRootCause> rootCauses,
    required List<AtlasExecutiveCascadeEffect> cascadeEffects,
  }) {
    final result = <AtlasExecutiveInsight>[];

    for (final cause in rootCauses.take(6)) {
      result.add(
        AtlasExecutiveInsight(
          id: 'insight_${cause.id}',
          farmName: cause.farmName,
          title: cause.title,
          description: cause.description,
          category: cause.category,
          type: AtlasExecutiveInsightType.rootCause,
          priority:
              _priorityFromSeverity(cause.severity),
          confidencePercent:
              cause.confidencePercent,
          recommendation:
              cause.recommendation,
        ),
      );
    }

    for (final effect in cascadeEffects.take(6)) {
      result.add(
        AtlasExecutiveInsight(
          id: 'insight_${effect.id}',
          farmName: effect.farmName,
          title:
              '${effect.sourceTitle} influencia ${effect.targetTitle}',
          description: effect.explanation,
          category: effect.category,
          type: AtlasExecutiveInsightType.cascade,
          priority:
              effect.strengthPercent >= 75
                  ? AtlasExecutiveInsightPriority.high
                  : AtlasExecutiveInsightPriority.medium,
          confidencePercent:
              effect.strengthPercent,
          recommendation:
              'Acompanhar os dois indicadores em conjunto antes de definir uma intervenção isolada.',
        ),
      );
    }

    for (final item in forecast.forecasts
        .where((forecastItem) {
      return forecastItem.risk ==
              AtlasBiForecastRisk.critical ||
          forecastItem.risk ==
              AtlasBiForecastRisk.high;
    }).take(5)) {
      result.add(
        AtlasExecutiveInsight(
          id:
              'insight_forecast_${item.farmName}_${item.indicatorId}',
          farmName: item.farmName,
          title:
              'Risco futuro em ${item.title}',
          description:
              'Chance de atingir a meta: '
              '${item.targetProbabilityPercent.toStringAsFixed(0)}%.',
          category: item.category,
          type: AtlasExecutiveInsightType.forecast,
          priority:
              item.risk ==
                      AtlasBiForecastRisk.critical
                  ? AtlasExecutiveInsightPriority.critical
                  : AtlasExecutiveInsightPriority.high,
          confidencePercent:
              item.confidencePercent,
          recommendation:
              item.recommendation,
        ),
      );
    }

    if (benchmark.leadingFarmName != null) {
      result.add(
        AtlasExecutiveInsight(
          id: 'insight_benchmark_leader',
          farmName:
              benchmark.leadingFarmName!,
          title:
              'Referência interna identificada',
          description:
              '${benchmark.leadingFarmName} lidera o benchmarking com média '
              '${benchmark.averageScore.toStringAsFixed(0)}/100.',
          category: AtlasBiCategory.management,
          type: AtlasExecutiveInsightType.benchmark,
          priority:
              AtlasExecutiveInsightPriority.medium,
          confidencePercent: 85,
          recommendation:
              'Documentar as práticas da fazenda líder e avaliar sua replicação.',
        ),
      );
    }

    for (final investment in analytics.investments.take(4)) {
      result.add(
        AtlasExecutiveInsight(
          id:
              'insight_economic_${investment.id}',
          farmName: investment.farmName,
          title:
              'Oportunidade econômica — ${investment.title}',
          description:
              'ROI estimado de '
              '${investment.roiPercent.toStringAsFixed(1)}%.',
          category: investment.category,
          type: AtlasExecutiveInsightType.economic,
          priority:
              investment.impactScore >= 80
                  ? AtlasExecutiveInsightPriority.high
                  : AtlasExecutiveInsightPriority.medium,
          confidencePercent:
              investment.confidencePercent,
          recommendation:
              investment.recommendation,
        ),
      );
    }

    for (final indicator in bi.criticalIndicators.take(4)) {
      result.add(
        AtlasExecutiveInsight(
          id:
              'insight_operational_${indicator.farmName}_${indicator.id}',
          farmName: indicator.farmName,
          title:
              'Indicador crítico — ${indicator.title}',
          description:
              'Desempenho atual de '
              '${indicator.targetAchievementPercent.toStringAsFixed(0)}% da meta.',
          category: indicator.category,
          type: AtlasExecutiveInsightType.operational,
          priority:
              AtlasExecutiveInsightPriority.critical,
          confidencePercent: 95,
          recommendation:
              'Criar ação corretiva com responsável, prazo e acompanhamento frequente.',
        ),
      );
    }

    final unique = <String, AtlasExecutiveInsight>{};

    for (final item in result) {
      unique[item.id] = item;
    }

    final ordered = unique.values.toList()
      ..sort((first, second) {
        final priorityComparison =
            _priorityWeight(second.priority).compareTo(
          _priorityWeight(first.priority),
        );

        if (priorityComparison != 0) {
          return priorityComparison;
        }

        return second.confidencePercent.compareTo(
          first.confidencePercent,
        );
      });

    return ordered.take(20).toList();
  }

  double _intelligenceScore({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    required List<AtlasExecutiveInsight> insights,
  }) {
    final coverageScore =
        (bi.indicators.length * 3 +
                forecast.forecasts.length * 2 +
                benchmark.farms.length * 8 +
                analytics.correlations.length * 2)
            .clamp(0, 100)
            .toDouble();

    final qualityScore =
        bi.score * 0.35 +
            analytics.score * 0.35 +
            benchmark.averageScore * 0.20 +
            (100 -
                    forecast.highRiskCount *
                        8)
                .clamp(0, 100)
                .toDouble() *
                0.10;

    final insightBonus =
        math.min(insights.length * 1.5, 15).toDouble();

    return (coverageScore * 0.35 +
            qualityScore * 0.65 +
            insightBonus)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasExecutiveIntelligenceMaturity
      _maturityFromScore(
    double score,
  ) {
    if (score >= 90) {
      return AtlasExecutiveIntelligenceMaturity.autonomous;
    }

    if (score >= 75) {
      return AtlasExecutiveIntelligenceMaturity.advanced;
    }

    if (score >= 60) {
      return AtlasExecutiveIntelligenceMaturity.structured;
    }

    if (score >= 40) {
      return AtlasExecutiveIntelligenceMaturity.developing;
    }

    return AtlasExecutiveIntelligenceMaturity.initial;
  }

  AtlasExecutiveIntelligenceSeverity
      _severityFromAnalytics(
    AtlasBiAnalyticsSeverity severity,
  ) {
    switch (severity) {
      case AtlasBiAnalyticsSeverity.low:
        return AtlasExecutiveIntelligenceSeverity.low;

      case AtlasBiAnalyticsSeverity.medium:
        return AtlasExecutiveIntelligenceSeverity.medium;

      case AtlasBiAnalyticsSeverity.high:
        return AtlasExecutiveIntelligenceSeverity.high;

      case AtlasBiAnalyticsSeverity.critical:
        return AtlasExecutiveIntelligenceSeverity.critical;
    }
  }

  AtlasExecutiveIntelligenceSeverity
      _severityFromForecast(
    AtlasBiForecastRisk risk,
  ) {
    switch (risk) {
      case AtlasBiForecastRisk.low:
        return AtlasExecutiveIntelligenceSeverity.low;

      case AtlasBiForecastRisk.medium:
        return AtlasExecutiveIntelligenceSeverity.medium;

      case AtlasBiForecastRisk.high:
        return AtlasExecutiveIntelligenceSeverity.high;

      case AtlasBiForecastRisk.critical:
        return AtlasExecutiveIntelligenceSeverity.critical;
    }
  }

  AtlasExecutiveCascadeDirection
      _cascadeDirection(
    AtlasBiCorrelationDirection direction,
  ) {
    switch (direction) {
      case AtlasBiCorrelationDirection.positive:
        return AtlasExecutiveCascadeDirection.positive;

      case AtlasBiCorrelationDirection.negative:
        return AtlasExecutiveCascadeDirection.negative;

      case AtlasBiCorrelationDirection.neutral:
        return AtlasExecutiveCascadeDirection.neutral;
    }
  }

  AtlasExecutiveInsightPriority
      _priorityFromSeverity(
    AtlasExecutiveIntelligenceSeverity severity,
  ) {
    switch (severity) {
      case AtlasExecutiveIntelligenceSeverity.low:
        return AtlasExecutiveInsightPriority.low;

      case AtlasExecutiveIntelligenceSeverity.medium:
        return AtlasExecutiveInsightPriority.medium;

      case AtlasExecutiveIntelligenceSeverity.high:
        return AtlasExecutiveInsightPriority.high;

      case AtlasExecutiveIntelligenceSeverity.critical:
        return AtlasExecutiveInsightPriority.critical;
    }
  }

  int _severityWeight(
    AtlasExecutiveIntelligenceSeverity severity,
  ) {
    switch (severity) {
      case AtlasExecutiveIntelligenceSeverity.low:
        return 1;

      case AtlasExecutiveIntelligenceSeverity.medium:
        return 2;

      case AtlasExecutiveIntelligenceSeverity.high:
        return 3;

      case AtlasExecutiveIntelligenceSeverity.critical:
        return 4;
    }
  }

  int _priorityWeight(
    AtlasExecutiveInsightPriority priority,
  ) {
    switch (priority) {
      case AtlasExecutiveInsightPriority.low:
        return 1;

      case AtlasExecutiveInsightPriority.medium:
        return 2;

      case AtlasExecutiveInsightPriority.high:
        return 3;

      case AtlasExecutiveInsightPriority.critical:
        return 4;
    }
  }

  String _buildSummary({
    required double score,
    required AtlasExecutiveIntelligenceMaturity maturity,
    required List<AtlasExecutiveRootCause> rootCauses,
    required List<AtlasExecutiveCascadeEffect> cascadeEffects,
    required List<AtlasExecutiveConsequence> consequences,
    required List<AtlasExecutivePriority> priorities,
    required List<AtlasExecutiveInsight> insights,
  }) {
    return 'O motor executivo atingiu maturidade '
        '${atlasExecutiveIntelligenceMaturityLabel(maturity).toLowerCase()} '
        'com score de ${score.toStringAsFixed(0)}/100, '
        '${rootCauses.length} causas-raiz prováveis, '
        '${cascadeEffects.length} efeitos em cadeia, '
        '${consequences.length} consequências futuras, '
        '${priorities.length} prioridades e '
        '${insights.length} insights consolidados.';
  }
}

class _PriorityCandidate {
  const _PriorityCandidate({
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.score,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineDays,
    required this.severity,
    required this.recommendation,
  });

  final String farmName;
  final String title;
  final String description;
  final AtlasBiCategory category;
  final double score;
  final double confidencePercent;
  final double expectedFinancialImpact;
  final int deadlineDays;
  final AtlasExecutiveIntelligenceSeverity severity;
  final String recommendation;
}
