import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_benchmark.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_forecast.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/models/atlas_bi_analytics_data.dart';
import 'package:projeto_atlas/features/executive_ai_advisor/domain/models/atlas_executive_ai_advisor_data.dart';
import 'package:projeto_atlas/features/executive_intelligence/domain/models/atlas_executive_intelligence_data.dart';

class AtlasExecutiveAiAdvisorService {
  const AtlasExecutiveAiAdvisorService();

  AtlasExecutiveAiAdvisorData build({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    required AtlasExecutiveIntelligenceData intelligence,
    DateTime? now,
  }) {
    final weeklyPriorities = _buildWeeklyPriorities(intelligence);

    final monthlyPriorities = _buildMonthlyPriorities(intelligence);

    final financialOpportunities = _buildFinancialOpportunities(analytics);

    final hiddenRisks = _buildHiddenRisks(
      forecast: forecast,
      intelligence: intelligence,
    );

    final operationalBottlenecks = _buildOperationalBottlenecks(intelligence);

    final strategicRecommendations = _buildStrategicRecommendations(
      bi: bi,
      benchmark: benchmark,
      analytics: analytics,
      intelligence: intelligence,
    );

    final actionPlan = _buildActionPlan(
      weeklyPriorities: weeklyPriorities,
      monthlyPriorities: monthlyPriorities,
      financialOpportunities: financialOpportunities,
      hiddenRisks: hiddenRisks,
    );

    final score = _advisorScore(
      bi: bi,
      forecast: forecast,
      benchmark: benchmark,
      analytics: analytics,
      intelligence: intelligence,
    );

    final confidence = _advisorConfidence(
      bi: bi,
      forecast: forecast,
      benchmark: benchmark,
      analytics: analytics,
      intelligence: intelligence,
    );

    final status = _statusFromScore(score);

    return AtlasExecutiveAiAdvisorData(
      generatedAt: now ?? DateTime.now(),
      title: 'Parecer Executivo Atlas',
      executiveSummary: _executiveSummary(
        score: score,
        confidence: confidence,
        status: status,
        weeklyPriorities: weeklyPriorities,
        financialOpportunities: financialOpportunities,
        hiddenRisks: hiddenRisks,
      ),
      diagnostic: _diagnostic(
        bi: bi,
        forecast: forecast,
        benchmark: benchmark,
        analytics: analytics,
        intelligence: intelligence,
      ),
      weeklyPriorities: weeklyPriorities,
      monthlyPriorities: monthlyPriorities,
      financialOpportunities: financialOpportunities,
      hiddenRisks: hiddenRisks,
      operationalBottlenecks: operationalBottlenecks,
      strategicRecommendations: strategicRecommendations,
      actionPlan: actionPlan,
      advisorScore: score,
      confidencePercent: confidence,
      status: status,
    );
  }

  List<AtlasExecutiveAdvisorPriority> _buildWeeklyPriorities(
    AtlasExecutiveIntelligenceData intelligence,
  ) {
    final items = intelligence.priorities
        .where((item) => item.deadlineDays <= 30)
        .take(6)
        .toList();

    return List.generate(items.length, (index) {
      final item = items[index];

      return AtlasExecutiveAdvisorPriority(
        position: index + 1,
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        priority: _priorityFromSeverity(item.severity),
        deadlineDays: math.min(item.deadlineDays, 7),
        confidencePercent: item.confidencePercent,
        expectedImpact:
            'Impacto econômico estimado em '
            'R\$ ${item.expectedFinancialImpact.toStringAsFixed(2)}.',
      );
    });
  }

  List<AtlasExecutiveAdvisorPriority> _buildMonthlyPriorities(
    AtlasExecutiveIntelligenceData intelligence,
  ) {
    final items = intelligence.priorities
        .where((item) => item.deadlineDays > 7)
        .take(8)
        .toList();

    return List.generate(items.length, (index) {
      final item = items[index];

      return AtlasExecutiveAdvisorPriority(
        position: index + 1,
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        priority: _priorityFromSeverity(item.severity),
        deadlineDays: item.deadlineDays,
        confidencePercent: item.confidencePercent,
        expectedImpact:
            'Impacto econômico estimado em '
            'R\$ ${item.expectedFinancialImpact.toStringAsFixed(2)}.',
      );
    });
  }

  List<AtlasExecutiveAdvisorFinancialOpportunity> _buildFinancialOpportunities(
    AtlasBiAnalyticsData analytics,
  ) {
    final items = analytics.investments.take(8).toList();

    return List.generate(items.length, (index) {
      final item = items[index];

      return AtlasExecutiveAdvisorFinancialOpportunity(
        position: index + 1,
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        investmentValue: item.investmentValue,
        expectedReturnValue: item.expectedReturnValue,
        roiPercent: item.roiPercent,
        paybackDays: item.paybackDays,
        confidencePercent: item.confidencePercent,
        recommendation: item.recommendation,
      );
    });
  }

  List<AtlasExecutiveAdvisorRisk> _buildHiddenRisks({
    required AtlasBiForecastDashboardData forecast,
    required AtlasExecutiveIntelligenceData intelligence,
  }) {
    final result = <AtlasExecutiveAdvisorRisk>[];

    for (final item in intelligence.consequences.take(8)) {
      result.add(
        AtlasExecutiveAdvisorRisk(
          id: 'risk_${item.id}',
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          severity: _severityFromIntelligence(item.severity),
          probabilityPercent: item.probabilityPercent,
          financialImpactValue: item.financialImpactValue,
          horizonDays: item.horizonDays,
          recommendation: item.recommendation,
        ),
      );
    }

    for (final item
        in forecast.forecasts
            .where((forecastItem) {
              return forecastItem.risk == AtlasBiForecastRisk.critical ||
                  forecastItem.risk == AtlasBiForecastRisk.high;
            })
            .take(6)) {
      final id = 'risk_forecast_${item.farmName}_${item.indicatorId}';

      if (result.any((risk) => risk.id == id)) {
        continue;
      }

      result.add(
        AtlasExecutiveAdvisorRisk(
          id: id,
          farmName: item.farmName,
          title: 'Risco futuro em ${item.title}',
          description:
              'A probabilidade atual de alcançar a meta é '
              '${item.targetProbabilityPercent.toStringAsFixed(0)}%.',
          category: item.category,
          severity: item.risk == AtlasBiForecastRisk.critical
              ? AtlasExecutiveAdvisorSeverity.critical
              : AtlasExecutiveAdvisorSeverity.high,
          probabilityPercent: 100 - item.targetProbabilityPercent,
          financialImpactValue: item.projectedVariationPercent.abs() * 1000,
          horizonDays: item.horizonDays,
          recommendation: item.recommendation,
        ),
      );
    }

    result.sort((first, second) {
      final severityComparison = _severityWeight(
        second.severity,
      ).compareTo(_severityWeight(first.severity));

      if (severityComparison != 0) {
        return severityComparison;
      }

      return second.probabilityPercent.compareTo(first.probabilityPercent);
    });

    return result.take(12).toList();
  }

  List<AtlasExecutiveAdvisorBottleneck> _buildOperationalBottlenecks(
    AtlasExecutiveIntelligenceData intelligence,
  ) {
    return intelligence.rootCauses.take(10).map((item) {
      return AtlasExecutiveAdvisorBottleneck(
        id: 'bottleneck_${item.id}',
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        severity: _severityFromIntelligence(item.severity),
        impactScore: item.impactScore,
        confidencePercent: item.confidencePercent,
        rootCause: item.evidences.join(' '),
        recommendation: item.recommendation,
      );
    }).toList();
  }

  List<AtlasExecutiveAdvisorRecommendation> _buildStrategicRecommendations({
    required AtlasBiData bi,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    required AtlasExecutiveIntelligenceData intelligence,
  }) {
    final result = <AtlasExecutiveAdvisorRecommendation>[];

    for (final insight in intelligence.insights.take(10)) {
      result.add(
        AtlasExecutiveAdvisorRecommendation(
          id: 'recommendation_${insight.id}',
          farmName: insight.farmName,
          title: insight.title,
          description: insight.description,
          category: insight.category,
          priority: _priorityFromInsight(insight.priority),
          confidencePercent: insight.confidencePercent,
          expectedImpact: insight.recommendation,
        ),
      );
    }

    if (benchmark.leadingFarmName != null) {
      result.add(
        AtlasExecutiveAdvisorRecommendation(
          id: 'recommendation_benchmark_leader',
          farmName: benchmark.leadingFarmName!,
          title: 'Transformar a fazenda líder em referência interna',
          description:
              'Documentar processos, rotinas e decisões responsáveis pelo melhor desempenho.',
          category: AtlasBiCategory.management,
          priority: AtlasExecutiveAdvisorPriorityLevel.medium,
          confidencePercent: 86,
          expectedImpact:
              'Reduzir diferenças de desempenho entre propriedades.',
        ),
      );
    }

    for (final item in analytics.scenarios.take(4)) {
      result.add(
        AtlasExecutiveAdvisorRecommendation(
          id: 'recommendation_scenario_${item.id}',
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          priority: item.projectedFinancialImpact >= 50000
              ? AtlasExecutiveAdvisorPriorityLevel.high
              : AtlasExecutiveAdvisorPriorityLevel.medium,
          confidencePercent: item.confidencePercent,
          expectedImpact:
              'Impacto projetado de '
              'R\$ ${item.projectedFinancialImpact.toStringAsFixed(2)}.',
        ),
      );
    }

    for (final insight in bi.insights.take(4)) {
      final id = 'recommendation_bi_${insight.id}';

      if (result.any((item) => item.id == id)) {
        continue;
      }

      result.add(
        AtlasExecutiveAdvisorRecommendation(
          id: id,
          farmName: insight.farmName ?? 'Operação',
          title: insight.title,
          description: insight.description,
          category: insight.category,
          priority: _priorityFromBi(insight.priority),
          confidencePercent: insight.confidencePercent,
          expectedImpact: insight.recommendation,
        ),
      );
    }

    return result.take(16).toList();
  }

  List<AtlasExecutiveAdvisorAction> _buildActionPlan({
    required List<AtlasExecutiveAdvisorPriority> weeklyPriorities,
    required List<AtlasExecutiveAdvisorPriority> monthlyPriorities,
    required List<AtlasExecutiveAdvisorFinancialOpportunity>
    financialOpportunities,
    required List<AtlasExecutiveAdvisorRisk> hiddenRisks,
  }) {
    final actions = <AtlasExecutiveAdvisorAction>[];

    for (final item in weeklyPriorities) {
      actions.add(
        AtlasExecutiveAdvisorAction(
          position: actions.length + 1,
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          priority: item.priority,
          deadlineDays: item.deadlineDays,
          expectedResult: item.expectedImpact,
          source: AtlasExecutiveAdvisorActionSource.rootCause,
        ),
      );
    }

    for (final risk in hiddenRisks.take(4)) {
      actions.add(
        AtlasExecutiveAdvisorAction(
          position: actions.length + 1,
          farmName: risk.farmName,
          title: 'Mitigar ${risk.title}',
          description: risk.recommendation,
          category: risk.category,
          priority: risk.severity == AtlasExecutiveAdvisorSeverity.critical
              ? AtlasExecutiveAdvisorPriorityLevel.critical
              : AtlasExecutiveAdvisorPriorityLevel.high,
          deadlineDays: risk.severity == AtlasExecutiveAdvisorSeverity.critical
              ? 7
              : 14,
          expectedResult:
              'Reduzir a probabilidade de risco em '
              '${risk.probabilityPercent.toStringAsFixed(0)}%.',
          source: AtlasExecutiveAdvisorActionSource.forecast,
        ),
      );
    }

    for (final item in financialOpportunities.take(3)) {
      actions.add(
        AtlasExecutiveAdvisorAction(
          position: actions.length + 1,
          farmName: item.farmName,
          title: 'Avaliar ${item.title}',
          description: item.recommendation,
          category: item.category,
          priority: item.roiPercent >= 50
              ? AtlasExecutiveAdvisorPriorityLevel.high
              : AtlasExecutiveAdvisorPriorityLevel.medium,
          deadlineDays: 30,
          expectedResult:
              'Retorno esperado de '
              'R\$ ${item.expectedReturnValue.toStringAsFixed(2)}.',
          source: AtlasExecutiveAdvisorActionSource.financial,
        ),
      );
    }

    for (final item in monthlyPriorities.take(3)) {
      actions.add(
        AtlasExecutiveAdvisorAction(
          position: actions.length + 1,
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          priority: item.priority,
          deadlineDays: item.deadlineDays,
          expectedResult: item.expectedImpact,
          source: AtlasExecutiveAdvisorActionSource.strategy,
        ),
      );
    }

    return actions.take(15).toList();
  }

  double _advisorScore({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    required AtlasExecutiveIntelligenceData intelligence,
  }) {
    final forecastScore = forecast.forecasts.isEmpty
        ? 0.0
        : (100 - forecast.highRiskCount / forecast.forecasts.length * 100)
              .clamp(0.0, 100.0)
              .toDouble();

    return (bi.score * 0.20 +
            forecastScore * 0.15 +
            benchmark.averageScore * 0.15 +
            analytics.score * 0.20 +
            intelligence.intelligenceScore * 0.30)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _advisorConfidence({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    required AtlasExecutiveIntelligenceData intelligence,
  }) {
    final coverage =
        bi.indicators.length * 2 +
        forecast.forecasts.length * 2 +
        benchmark.farms.length * 8 +
        analytics.correlations.length * 2 +
        intelligence.insights.length * 2;

    return coverage.clamp(45, 98).toDouble();
  }

  AtlasExecutiveAdvisorStatus _statusFromScore(double score) {
    if (score >= 90) {
      return AtlasExecutiveAdvisorStatus.excellent;
    }

    if (score >= 75) {
      return AtlasExecutiveAdvisorStatus.adequate;
    }

    if (score >= 55) {
      return AtlasExecutiveAdvisorStatus.attention;
    }

    return AtlasExecutiveAdvisorStatus.critical;
  }

  AtlasExecutiveAdvisorSeverity _severityFromIntelligence(
    AtlasExecutiveIntelligenceSeverity severity,
  ) {
    switch (severity) {
      case AtlasExecutiveIntelligenceSeverity.low:
        return AtlasExecutiveAdvisorSeverity.low;

      case AtlasExecutiveIntelligenceSeverity.medium:
        return AtlasExecutiveAdvisorSeverity.medium;

      case AtlasExecutiveIntelligenceSeverity.high:
        return AtlasExecutiveAdvisorSeverity.high;

      case AtlasExecutiveIntelligenceSeverity.critical:
        return AtlasExecutiveAdvisorSeverity.critical;
    }
  }

  AtlasExecutiveAdvisorPriorityLevel _priorityFromSeverity(
    AtlasExecutiveIntelligenceSeverity severity,
  ) {
    switch (severity) {
      case AtlasExecutiveIntelligenceSeverity.low:
        return AtlasExecutiveAdvisorPriorityLevel.low;

      case AtlasExecutiveIntelligenceSeverity.medium:
        return AtlasExecutiveAdvisorPriorityLevel.medium;

      case AtlasExecutiveIntelligenceSeverity.high:
        return AtlasExecutiveAdvisorPriorityLevel.high;

      case AtlasExecutiveIntelligenceSeverity.critical:
        return AtlasExecutiveAdvisorPriorityLevel.critical;
    }
  }

  AtlasExecutiveAdvisorPriorityLevel _priorityFromInsight(
    AtlasExecutiveInsightPriority priority,
  ) {
    switch (priority) {
      case AtlasExecutiveInsightPriority.low:
        return AtlasExecutiveAdvisorPriorityLevel.low;

      case AtlasExecutiveInsightPriority.medium:
        return AtlasExecutiveAdvisorPriorityLevel.medium;

      case AtlasExecutiveInsightPriority.high:
        return AtlasExecutiveAdvisorPriorityLevel.high;

      case AtlasExecutiveInsightPriority.critical:
        return AtlasExecutiveAdvisorPriorityLevel.critical;
    }
  }

  AtlasExecutiveAdvisorPriorityLevel _priorityFromBi(AtlasBiPriority priority) {
    switch (priority) {
      case AtlasBiPriority.low:
        return AtlasExecutiveAdvisorPriorityLevel.low;

      case AtlasBiPriority.medium:
        return AtlasExecutiveAdvisorPriorityLevel.medium;

      case AtlasBiPriority.high:
        return AtlasExecutiveAdvisorPriorityLevel.high;

      case AtlasBiPriority.critical:
        return AtlasExecutiveAdvisorPriorityLevel.critical;
    }
  }

  int _severityWeight(AtlasExecutiveAdvisorSeverity severity) {
    switch (severity) {
      case AtlasExecutiveAdvisorSeverity.low:
        return 1;

      case AtlasExecutiveAdvisorSeverity.medium:
        return 2;

      case AtlasExecutiveAdvisorSeverity.high:
        return 3;

      case AtlasExecutiveAdvisorSeverity.critical:
        return 4;
    }
  }

  String _executiveSummary({
    required double score,
    required double confidence,
    required AtlasExecutiveAdvisorStatus status,
    required List<AtlasExecutiveAdvisorPriority> weeklyPriorities,
    required List<AtlasExecutiveAdvisorFinancialOpportunity>
    financialOpportunities,
    required List<AtlasExecutiveAdvisorRisk> hiddenRisks,
  }) {
    return 'O parecer executivo apresenta score de '
        '${score.toStringAsFixed(0)}/100, situação '
        '${atlasExecutiveAdvisorStatusLabel(status).toLowerCase()}, '
        '${weeklyPriorities.length} prioridades para a semana, '
        '${financialOpportunities.length} oportunidades financeiras, '
        '${hiddenRisks.length} riscos ocultos e '
        '${confidence.toStringAsFixed(0)}% de confiança analítica.';
  }

  String _diagnostic({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    required AtlasExecutiveIntelligenceData intelligence,
  }) {
    final leader = benchmark.leadingFarmName ?? 'nenhuma fazenda';

    final mainRootCause =
        intelligence.mainRootCause?.title ?? 'nenhuma causa-raiz principal';

    final mainInvestment =
        analytics.bestInvestment?.title ?? 'nenhuma oportunidade prioritária';

    return 'A operação possui ${bi.indicators.length} indicadores analisados, '
        '${forecast.highRiskCount} previsões em risco alto ou crítico, '
        '$leader como referência interna, '
        '$mainRootCause como hipótese central e '
        '$mainInvestment como melhor oportunidade econômica atual.';
  }
}
