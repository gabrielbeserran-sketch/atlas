import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_benchmark.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_forecast.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/models/atlas_bi_analytics_data.dart';
import 'package:projeto_atlas/features/atlas_copilot/domain/models/atlas_copilot_data.dart';

class AtlasCopilotService {
  const AtlasCopilotService();

  AtlasCopilotData build({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
    DateTime? now,
  }) {
    final mainProblem = _mainProblem(
      analytics,
    );

    final topPriority = _topPriority(
      analytics: analytics,
      forecast: forecast,
      benchmark: benchmark,
    );

    final actions = _actions(
      analytics: analytics,
      forecast: forecast,
    );

    final investments = _investments(
      analytics,
    );

    final alerts = _alerts(
      bi: bi,
      forecast: forecast,
      benchmark: benchmark,
      analytics: analytics,
    );

    final recommendations = _recommendations(
      bi: bi,
      forecast: forecast,
      benchmark: benchmark,
      analytics: analytics,
    );

    final maturityScore = _maturityScore(
      bi: bi,
      forecast: forecast,
      benchmark: benchmark,
      analytics: analytics,
    );

    final maturityLevel =
        _maturityLevel(maturityScore);

    final checklist = _checklist(
      mainProblem: mainProblem,
      topPriority: topPriority,
      alerts: alerts,
    );

    return AtlasCopilotData(
      generatedAt: now ?? DateTime.now(),
      summary: _summary(
        maturityScore: maturityScore,
        maturityLevel: maturityLevel,
        mainProblem: mainProblem,
        topPriority: topPriority,
        alerts: alerts,
      ),
      maturityScore: maturityScore,
      maturityLevel: maturityLevel,
      mainProblem: mainProblem,
      topPriority: topPriority,
      actions: actions,
      investments: investments,
      alerts: alerts,
      recommendations: recommendations,
      checklist: checklist,
    );
  }

  AtlasCopilotIssue? _mainProblem(
    AtlasBiAnalyticsData analytics,
  ) {
    final bottleneck = analytics.mainBottleneck;

    if (bottleneck == null) {
      return null;
    }

    return AtlasCopilotIssue(
      id: 'issue_${bottleneck.id}',
      farmName: bottleneck.farmName,
      title: bottleneck.indicatorTitle,
      description:
          'Este é o gargalo com maior impacto estimado na operação.',
      category: bottleneck.category,
      severity: _severity(
        bottleneck.severity,
      ),
      impactScore: bottleneck.priorityScore,
      financialImpactValue:
          bottleneck.financialImpactValue,
      cause: bottleneck.cause,
      recommendation:
          bottleneck.recommendation,
    );
  }

  AtlasCopilotPriority? _topPriority({
    required AtlasBiAnalyticsData analytics,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
  }) {
    final bottleneck = analytics.mainBottleneck;

    if (bottleneck != null) {
      return AtlasCopilotPriority(
        id: 'priority_${bottleneck.id}',
        farmName: bottleneck.farmName,
        title:
            'Atacar ${bottleneck.indicatorTitle}',
        description:
            bottleneck.recommendation,
        category: bottleneck.category,
        priority:
            bottleneck.severity ==
                    AtlasBiAnalyticsSeverity.critical
                ? AtlasCopilotPriorityLevel.critical
                : AtlasCopilotPriorityLevel.high,
        confidencePercent: 92,
        expectedResult:
            'Reduzir a lacuna de desempenho e recuperar o impacto econômico estimado.',
        deadlineDays:
            bottleneck.severity ==
                    AtlasBiAnalyticsSeverity.critical
                ? 15
                : 30,
      );
    }

    final forecastPriority =
        forecast.priorityForecast;

    if (forecastPriority != null) {
      return AtlasCopilotPriority(
        id:
            'priority_forecast_${forecastPriority.indicatorId}',
        farmName: forecastPriority.farmName,
        title:
            'Reverter risco em ${forecastPriority.title}',
        description:
            forecastPriority.recommendation,
        category: forecastPriority.category,
        priority:
            forecastPriority.risk ==
                    AtlasBiForecastRisk.critical
                ? AtlasCopilotPriorityLevel.critical
                : AtlasCopilotPriorityLevel.high,
        confidencePercent:
            forecastPriority.confidencePercent,
        expectedResult:
            'Aumentar a probabilidade de atingir a meta.',
        deadlineDays: 30,
      );
    }

    if (benchmark.farms.length > 1) {
      final lastFarm = benchmark.farms.last;

      return AtlasCopilotPriority(
        id:
            'priority_benchmark_${lastFarm.farmName}',
        farmName: lastFarm.farmName,
        title:
            'Reduzir distância para a fazenda líder',
        description:
            'Comparar práticas com ${benchmark.leadingFarmName ?? 'a referência interna'} e priorizar os maiores gaps.',
        category: AtlasBiCategory.management,
        priority: AtlasCopilotPriorityLevel.medium,
        confidencePercent: 80,
        expectedResult:
            'Melhorar o score comparativo da fazenda.',
        deadlineDays: 60,
      );
    }

    return null;
  }

  List<AtlasCopilotAction> _actions({
    required AtlasBiAnalyticsData analytics,
    required AtlasBiForecastDashboardData forecast,
  }) {
    final result = <AtlasCopilotAction>[];

    for (final bottleneck
        in analytics.bottlenecks.take(5)) {
      result.add(
        AtlasCopilotAction(
          position: result.length + 1,
          farmName: bottleneck.farmName,
          title:
              'Plano para ${bottleneck.indicatorTitle}',
          description:
              bottleneck.recommendation,
          category: bottleneck.category,
          priority:
              bottleneck.severity ==
                      AtlasBiAnalyticsSeverity.critical
                  ? AtlasCopilotPriorityLevel.critical
                  : AtlasCopilotPriorityLevel.high,
          deadlineDays:
              bottleneck.severity ==
                      AtlasBiAnalyticsSeverity.critical
                  ? 15
                  : 30,
          expectedResult:
              'Reduzir ${bottleneck.performanceGapPercent.toStringAsFixed(1)}% da lacuna atual.',
        ),
      );
    }

    for (final item in forecast.forecasts
        .where((forecast) {
      return forecast.risk ==
              AtlasBiForecastRisk.critical ||
          forecast.risk ==
              AtlasBiForecastRisk.high;
    }).take(3)) {
      result.add(
        AtlasCopilotAction(
          position: result.length + 1,
          farmName: item.farmName,
          title:
              'Revisar previsão de ${item.title}',
          description: item.recommendation,
          category: item.category,
          priority:
              item.risk ==
                      AtlasBiForecastRisk.critical
                  ? AtlasCopilotPriorityLevel.critical
                  : AtlasCopilotPriorityLevel.high,
          deadlineDays: 14,
          expectedResult:
              'Elevar a chance de atingir a meta acima de 70%.',
        ),
      );
    }

    return result.take(8).toList();
  }

  List<AtlasCopilotInvestment> _investments(
    AtlasBiAnalyticsData analytics,
  ) {
    return List.generate(
      math.min(
        analytics.investments.length,
        6,
      ),
      (index) {
        final item = analytics.investments[index];

        return AtlasCopilotInvestment(
          position: index + 1,
          farmName: item.farmName,
          title: item.title,
          category: item.category,
          investmentValue:
              item.investmentValue,
          expectedReturnValue:
              item.expectedReturnValue,
          roiPercent: item.roiPercent,
          paybackDays: item.paybackDays,
          confidencePercent:
              item.confidencePercent,
          recommendation:
              item.recommendation,
        );
      },
    );
  }

  List<AtlasCopilotAlert> _alerts({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
  }) {
    final result = <AtlasCopilotAlert>[];

    for (final indicator
        in bi.criticalIndicators.take(5)) {
      result.add(
        AtlasCopilotAlert(
          id:
              'alert_indicator_${indicator.farmName}_${indicator.id}',
          farmName: indicator.farmName,
          title:
              'Indicador crítico — ${indicator.title}',
          description:
              'O indicador atingiu ${indicator.targetAchievementPercent.toStringAsFixed(0)}% da meta.',
          category: indicator.category,
          severity: AtlasCopilotSeverity.critical,
          source:
              AtlasCopilotAlertSource.indicator,
          recommendation:
              'Investigar a causa e criar ação corretiva.',
        ),
      );
    }

    for (final item in forecast.forecasts
        .where((forecast) {
      return forecast.risk ==
              AtlasBiForecastRisk.critical ||
          forecast.risk ==
              AtlasBiForecastRisk.high;
    }).take(5)) {
      result.add(
        AtlasCopilotAlert(
          id:
              'alert_forecast_${item.farmName}_${item.indicatorId}',
          farmName: item.farmName,
          title:
              'Risco futuro — ${item.title}',
          description:
              'Chance atual da meta: ${item.targetProbabilityPercent.toStringAsFixed(0)}%.',
          category: item.category,
          severity:
              item.risk ==
                      AtlasBiForecastRisk.critical
                  ? AtlasCopilotSeverity.critical
                  : AtlasCopilotSeverity.high,
          source:
              AtlasCopilotAlertSource.forecast,
          recommendation:
              item.recommendation,
        ),
      );
    }

    if (benchmark.farms.length > 1) {
      final lastFarm = benchmark.farms.last;

      result.add(
        AtlasCopilotAlert(
          id:
              'alert_benchmark_${lastFarm.farmName}',
          farmName: lastFarm.farmName,
          title:
              'Maior distância no benchmarking',
          description:
              '${lastFarm.distanceFromLeader.toStringAsFixed(1)} pontos abaixo da líder.',
          category: AtlasBiCategory.management,
          severity: lastFarm.distanceFromLeader >= 25
              ? AtlasCopilotSeverity.high
              : AtlasCopilotSeverity.medium,
          source:
              AtlasCopilotAlertSource.benchmark,
          recommendation:
              'Comparar os indicadores com a fazenda líder e priorizar os maiores gaps.',
        ),
      );
    }

    for (final bottleneck
        in analytics.bottlenecks.take(3)) {
      result.add(
        AtlasCopilotAlert(
          id:
              'alert_analytics_${bottleneck.id}',
          farmName: bottleneck.farmName,
          title:
              'Gargalo econômico — ${bottleneck.indicatorTitle}',
          description:
              'Impacto estimado de R\$ ${bottleneck.financialImpactValue.toStringAsFixed(2)}.',
          category: bottleneck.category,
          severity:
              _severity(bottleneck.severity),
          source:
              AtlasCopilotAlertSource.analytics,
          recommendation:
              bottleneck.recommendation,
        ),
      );
    }

    result.sort((first, second) {
      return _severityWeight(second.severity)
          .compareTo(
        _severityWeight(first.severity),
      );
    });

    return result.take(12).toList();
  }

  List<AtlasCopilotRecommendation>
      _recommendations({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
  }) {
    final result =
        <AtlasCopilotRecommendation>[];

    for (final item
        in analytics.investments.take(5)) {
      result.add(
        AtlasCopilotRecommendation(
          id:
              'recommendation_investment_${item.id}',
          farmName: item.farmName,
          title: item.title,
          description:
              item.recommendation,
          category: item.category,
          priority:
              item.impactScore >= 75
                  ? AtlasCopilotPriorityLevel.high
                  : AtlasCopilotPriorityLevel.medium,
          confidencePercent:
              item.confidencePercent,
          expectedImpact:
              'ROI estimado de ${item.roiPercent.toStringAsFixed(1)}%.',
        ),
      );
    }

    for (final insight in bi.insights.take(5)) {
      result.add(
        AtlasCopilotRecommendation(
          id:
              'recommendation_bi_${insight.id}',
          farmName:
              insight.farmName ?? 'Operação',
          title: insight.title,
          description:
              insight.recommendation,
          category: insight.category,
          priority:
              _priorityFromBi(insight.priority),
          confidencePercent:
              insight.confidencePercent,
          expectedImpact:
              insight.description,
        ),
      );
    }

    if (benchmark.leadingFarmName != null) {
      result.add(
        AtlasCopilotRecommendation(
          id: 'recommendation_benchmark',
          farmName:
              benchmark.leadingFarmName!,
          title:
              'Replicar práticas da fazenda líder',
          description:
              'Documentar os processos responsáveis pelo melhor score e avaliar sua aplicação nas demais propriedades.',
          category: AtlasBiCategory.management,
          priority:
              AtlasCopilotPriorityLevel.medium,
          confidencePercent: 82,
          expectedImpact:
              'Reduzir a distância média entre fazendas.',
        ),
      );
    }

    if (forecast.negativeCount > 0) {
      result.add(
        AtlasCopilotRecommendation(
          id: 'recommendation_forecast',
          farmName: 'Operação',
          title:
              'Revisar tendências negativas',
          description:
              'Priorizar os indicadores com queda e risco alto nas próximas reuniões de gestão.',
          category: AtlasBiCategory.intelligence,
          priority:
              AtlasCopilotPriorityLevel.high,
          confidencePercent: 88,
          expectedImpact:
              'Reduzir o risco futuro dos indicadores.',
        ),
      );
    }

    return result.take(12).toList();
  }

  double _maturityScore({
    required AtlasBiData bi,
    required AtlasBiForecastDashboardData forecast,
    required AtlasBiBenchmarkData benchmark,
    required AtlasBiAnalyticsData analytics,
  }) {
    final dataScore = bi.score * 0.30;

    final forecastScore = forecast.forecasts.isEmpty
        ? 0.0
        : (100 -
                forecast.highRiskCount /
                    forecast.forecasts.length *
                    100) *
            0.20;

    final benchmarkScore =
        benchmark.averageScore * 0.20;

    final analyticsScore =
        analytics.score * 0.30;

    return (dataScore +
            forecastScore +
            benchmarkScore +
            analyticsScore)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasCopilotMaturityLevel _maturityLevel(
    double score,
  ) {
    if (score >= 90) {
      return AtlasCopilotMaturityLevel.excellent;
    }

    if (score >= 75) {
      return AtlasCopilotMaturityLevel.advanced;
    }

    if (score >= 60) {
      return AtlasCopilotMaturityLevel.structured;
    }

    if (score >= 40) {
      return AtlasCopilotMaturityLevel.developing;
    }

    return AtlasCopilotMaturityLevel.initial;
  }

  List<AtlasCopilotChecklistItem> _checklist({
    required AtlasCopilotIssue? mainProblem,
    required AtlasCopilotPriority? topPriority,
    required List<AtlasCopilotAlert> alerts,
  }) {
    final result =
        <AtlasCopilotChecklistItem>[];

    if (mainProblem != null) {
      result.add(
        AtlasCopilotChecklistItem(
          id: 'check_main_problem',
          title:
              'Validar o principal gargalo',
          description:
              'Confirmar em campo as causas de ${mainProblem.title}.',
          priority:
              AtlasCopilotPriorityLevel.critical,
          completed: false,
        ),
      );
    }

    if (topPriority != null) {
      result.add(
        AtlasCopilotChecklistItem(
          id: 'check_top_priority',
          title:
              'Definir responsável pela prioridade',
          description:
              'Nomear responsável e prazo para ${topPriority.title}.',
          priority: topPriority.priority,
          completed: false,
        ),
      );
    }

    if (alerts.isNotEmpty) {
      result.add(
        const AtlasCopilotChecklistItem(
          id: 'check_alerts',
          title:
              'Revisar alertas executivos',
          description:
              'Analisar os alertas críticos e registrar decisões.',
          priority:
              AtlasCopilotPriorityLevel.high,
          completed: false,
        ),
      );
    }

    result.add(
      const AtlasCopilotChecklistItem(
        id: 'check_meeting',
        title:
            'Realizar reunião de acompanhamento',
        description:
            'Revisar KPIs, metas, Forecast e plano de ação.',
        priority:
            AtlasCopilotPriorityLevel.medium,
        completed: false,
      ),
    );

    return result;
  }

  AtlasCopilotSeverity _severity(
    AtlasBiAnalyticsSeverity severity,
  ) {
    switch (severity) {
      case AtlasBiAnalyticsSeverity.low:
        return AtlasCopilotSeverity.low;

      case AtlasBiAnalyticsSeverity.medium:
        return AtlasCopilotSeverity.medium;

      case AtlasBiAnalyticsSeverity.high:
        return AtlasCopilotSeverity.high;

      case AtlasBiAnalyticsSeverity.critical:
        return AtlasCopilotSeverity.critical;
    }
  }

  AtlasCopilotPriorityLevel _priorityFromBi(
    AtlasBiPriority priority,
  ) {
    switch (priority) {
      case AtlasBiPriority.low:
        return AtlasCopilotPriorityLevel.low;

      case AtlasBiPriority.medium:
        return AtlasCopilotPriorityLevel.medium;

      case AtlasBiPriority.high:
        return AtlasCopilotPriorityLevel.high;

      case AtlasBiPriority.critical:
        return AtlasCopilotPriorityLevel.critical;
    }
  }

  int _severityWeight(
    AtlasCopilotSeverity severity,
  ) {
    switch (severity) {
      case AtlasCopilotSeverity.low:
        return 1;

      case AtlasCopilotSeverity.medium:
        return 2;

      case AtlasCopilotSeverity.high:
        return 3;

      case AtlasCopilotSeverity.critical:
        return 4;
    }
  }

  String _summary({
    required double maturityScore,
    required AtlasCopilotMaturityLevel maturityLevel,
    required AtlasCopilotIssue? mainProblem,
    required AtlasCopilotPriority? topPriority,
    required List<AtlasCopilotAlert> alerts,
  }) {
    final problemText = mainProblem == null
        ? 'nenhum gargalo crítico identificado'
        : 'principal gargalo em ${mainProblem.title}';

    final priorityText = topPriority == null
        ? 'sem prioridade executiva definida'
        : 'prioridade número 1: ${topPriority.title}';

    return 'A operação possui maturidade '
        '${atlasCopilotMaturityLevelLabel(maturityLevel).toLowerCase()} '
        'com score de ${maturityScore.toStringAsFixed(0)}/100, '
        '$problemText, $priorityText e '
        '${alerts.length} alertas executivos ativos.';
  }
}
