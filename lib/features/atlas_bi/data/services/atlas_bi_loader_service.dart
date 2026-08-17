import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal_history.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi_history.dart';
import 'package:projeto_atlas/features/strategy_center/domain/models/atlas_strategy_data.dart';

class AtlasBiLoaderService {
  const AtlasBiLoaderService();

  AtlasBiInput buildInput({
    required AtlasExecutiveKpiDashboardData kpis,
    required AtlasExecutiveKpiHistorySummary kpiHistory,
    required AtlasExecutiveGoalDashboardData goals,
    required AtlasExecutiveGoalHistorySummary goalHistory,
    required AtlasStrategyData strategy,
  }) {
    return AtlasBiInput(
      indicators: _buildIndicators(kpis: kpis, history: kpiHistory),
      insights: _buildInsights(
        kpis: kpis,
        kpiHistory: kpiHistory,
        goals: goals,
        goalHistory: goalHistory,
        strategy: strategy,
      ),
    );
  }

  List<AtlasBiIndicatorInput> _buildIndicators({
    required AtlasExecutiveKpiDashboardData kpis,
    required AtlasExecutiveKpiHistorySummary history,
  }) {
    final historyByKey = <String, AtlasExecutiveKpiHistorySeries>{
      for (final series in history.series)
        '${series.farmName}::${series.kpiId}': series,
    };

    return kpis.kpis.map((kpi) {
      final series = historyByKey['${kpi.farmName}::${kpi.id}'];

      final points =
          series?.points.map((point) {
            return AtlasBiSeriesPoint(
              recordedAt: point.recordedAt,
              value: point.value,
            );
          }).toList() ??
          [AtlasBiSeriesPoint(recordedAt: kpi.generatedAt, value: kpi.value)];

      return AtlasBiIndicatorInput(
        id: kpi.id,
        farmName: kpi.farmName,
        title: kpi.title,
        description: kpi.description,
        category: _categoryFromKpi(kpi.category),
        unit: kpi.unit,
        currentValue: kpi.value,
        targetValue: kpi.targetValue,
        higherIsBetter:
            kpi.direction != AtlasExecutiveKpiDirection.lowerIsBetter,
        series: points,
      );
    }).toList();
  }

  List<AtlasBiInsight> _buildInsights({
    required AtlasExecutiveKpiDashboardData kpis,
    required AtlasExecutiveKpiHistorySummary kpiHistory,
    required AtlasExecutiveGoalDashboardData goals,
    required AtlasExecutiveGoalHistorySummary goalHistory,
    required AtlasStrategyData strategy,
  }) {
    final insights = <AtlasBiInsight>[];

    for (final kpi in kpis.criticalKpis.take(10)) {
      insights.add(
        AtlasBiInsight(
          id: 'critical_${kpi.farmName}_${kpi.id}',
          title: 'Indicador crítico — ${kpi.title}',
          description:
              '${kpi.farmName}: o indicador atingiu '
              '${kpi.targetAchievementPercent.toStringAsFixed(0)}% da meta.',
          category: _categoryFromKpi(kpi.category),
          type: AtlasBiInsightType.risk,
          priority: AtlasBiPriority.critical,
          confidencePercent: 95,
          recommendation:
              'Revisar a causa, criar ou atualizar uma meta e definir uma ação corretiva com responsável e prazo.',
          farmName: kpi.farmName,
        ),
      );
    }

    for (final series in kpiHistory.worseningSeries.take(10)) {
      insights.add(
        AtlasBiInsight(
          id: 'trend_${series.farmName}_${series.kpiId}',
          title: 'Tendência de queda — ${series.title}',
          description:
              'O indicador variou '
              '${series.variationPercent.toStringAsFixed(1)}% em relação ao registro anterior.',
          category: _categoryFromKpi(series.category),
          type: AtlasBiInsightType.trend,
          priority: series.variationPercent <= -10
              ? AtlasBiPriority.critical
              : AtlasBiPriority.high,
          confidencePercent: series.hasHistory ? 88 : 60,
          recommendation:
              'Investigar o período da queda, comparar eventos operacionais e acompanhar o próximo registro.',
          farmName: series.farmName,
        ),
      );
    }

    for (final kpi in kpis.positiveHighlights.take(8)) {
      insights.add(
        AtlasBiInsight(
          id: 'opportunity_${kpi.farmName}_${kpi.id}',
          title: 'Oportunidade — ${kpi.title}',
          description:
              '${kpi.farmName}: desempenho de '
              '${kpi.targetAchievementPercent.toStringAsFixed(0)}% da meta.',
          category: _categoryFromKpi(kpi.category),
          type: AtlasBiInsightType.opportunity,
          priority: AtlasBiPriority.medium,
          confidencePercent: 86,
          recommendation:
              'Documentar a prática responsável pelo resultado e avaliar sua replicação em outras fazendas ou áreas.',
          farmName: kpi.farmName,
        ),
      );
    }

    for (final goal
        in goals.goals
            .where((goal) {
              return goal.status == AtlasExecutiveGoalStatus.overdue ||
                  goal.status == AtlasExecutiveGoalStatus.atRisk;
            })
            .take(8)) {
      insights.add(
        AtlasBiInsight(
          id: 'goal_${goal.id}',
          title:
              'Meta ${atlasExecutiveGoalStatusLabel(goal.status).toLowerCase()} — ${goal.kpiTitle}',
          description:
              '${goal.farmName}: progresso atual de '
              '${goal.progressPercent.toStringAsFixed(0)}%.',
          category: _categoryFromKpi(goal.category),
          type: AtlasBiInsightType.recommendation,
          priority: goal.status == AtlasExecutiveGoalStatus.overdue
              ? AtlasBiPriority.critical
              : AtlasBiPriority.high,
          confidencePercent: 92,
          recommendation:
              'Reavaliar prazo, recursos, responsável e próximos passos da meta.',
          farmName: goal.farmName,
        ),
      );
    }

    for (final series
        in goalHistory.series
            .where((item) {
              return item.riskLevel == AtlasExecutiveGoalRiskLevel.high;
            })
            .take(8)) {
      insights.add(
        AtlasBiInsight(
          id: 'goal_risk_${series.goalId}',
          title: 'Risco de não conclusão — ${series.kpiTitle}',
          description:
              '${series.farmName}: a velocidade atual não sustenta uma conclusão segura.',
          category: AtlasBiCategory.management,
          type: AtlasBiInsightType.risk,
          priority: AtlasBiPriority.high,
          confidencePercent: 90,
          recommendation:
              'Aumentar o ritmo de execução ou redefinir o plano antes do vencimento.',
          farmName: series.farmName,
        ),
      );
    }

    for (final risk in strategy.risks.take(8)) {
      insights.add(
        AtlasBiInsight(
          id: 'strategy_risk_${risk.id}',
          title: 'Risco estratégico — ${risk.title}',
          description: risk.description,
          category: _categoryFromStrategy(risk.category),
          type: AtlasBiInsightType.risk,
          priority: _priorityFromRisk(risk.impact),
          confidencePercent: 85,
          recommendation: risk.mitigation,
          farmName: risk.farmName,
        ),
      );
    }

    for (final opportunity in strategy.opportunities.take(8)) {
      insights.add(
        AtlasBiInsight(
          id: 'strategy_opportunity_${opportunity.id}',
          title: 'Oportunidade estratégica — ${opportunity.title}',
          description: opportunity.description,
          category: _categoryFromStrategy(opportunity.category),
          type: AtlasBiInsightType.opportunity,
          priority: AtlasBiPriority.medium,
          confidencePercent: opportunity.confidencePercent,
          recommendation: opportunity.recommendation,
          farmName: opportunity.farmName,
        ),
      );
    }

    final unique = <String, AtlasBiInsight>{};

    for (final insight in insights) {
      unique[insight.id] = insight;
    }

    return unique.values.toList();
  }

  AtlasBiCategory _categoryFromKpi(AtlasExecutiveKpiCategory category) {
    switch (category) {
      case AtlasExecutiveKpiCategory.production:
        return AtlasBiCategory.production;

      case AtlasExecutiveKpiCategory.reproduction:
        return AtlasBiCategory.reproduction;

      case AtlasExecutiveKpiCategory.health:
        return AtlasBiCategory.health;

      case AtlasExecutiveKpiCategory.finance:
        return AtlasBiCategory.finance;

      case AtlasExecutiveKpiCategory.management:
        return AtlasBiCategory.management;

      case AtlasExecutiveKpiCategory.intelligence:
        return AtlasBiCategory.intelligence;
    }
  }

  AtlasBiCategory _categoryFromStrategy(AtlasStrategyCategory category) {
    switch (category) {
      case AtlasStrategyCategory.production:
        return AtlasBiCategory.production;

      case AtlasStrategyCategory.reproduction:
        return AtlasBiCategory.reproduction;

      case AtlasStrategyCategory.health:
        return AtlasBiCategory.health;

      case AtlasStrategyCategory.finance:
        return AtlasBiCategory.finance;

      case AtlasStrategyCategory.management:
      case AtlasStrategyCategory.people:
        return AtlasBiCategory.management;

      case AtlasStrategyCategory.technology:
      case AtlasStrategyCategory.intelligence:
        return AtlasBiCategory.intelligence;

      case AtlasStrategyCategory.sustainability:
        return AtlasBiCategory.pasture;
    }
  }

  AtlasBiPriority _priorityFromRisk(AtlasStrategyRiskLevel level) {
    switch (level) {
      case AtlasStrategyRiskLevel.low:
        return AtlasBiPriority.low;

      case AtlasStrategyRiskLevel.medium:
        return AtlasBiPriority.medium;

      case AtlasStrategyRiskLevel.high:
        return AtlasBiPriority.high;

      case AtlasStrategyRiskLevel.critical:
        return AtlasBiPriority.critical;
    }
  }
}
