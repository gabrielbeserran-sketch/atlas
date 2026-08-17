import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal_history.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';
import 'package:projeto_atlas/features/strategy_center/domain/models/atlas_strategy_data.dart';

class AtlasStrategyLoaderService {
  const AtlasStrategyLoaderService();

  AtlasStrategyInput buildInput({
    required AtlasExecutiveKpiDashboardData kpis,
    required AtlasExecutiveGoalDashboardData goals,
    required AtlasExecutiveGoalHistorySummary goalHistory,
  }) {
    return AtlasStrategyInput(
      title: 'Estratégia Consolidada Atlas',
      mission:
          'Transformar dados da fazenda em decisões, execução e resultado sustentável.',
      objectives: _buildObjectives(goals.goals),
      priorities: _buildPriorities(goals.priorityGoals),
      initiatives: _buildInitiatives(goals.goals),
      risks: _buildRisks(kpis: kpis, history: goalHistory),
      opportunities: _buildOpportunities(kpis),
    );
  }

  List<AtlasStrategyObjective> _buildObjectives(
    List<AtlasExecutiveGoal> goals,
  ) {
    return goals
        .where((goal) {
          return goal.status != AtlasExecutiveGoalStatus.cancelled;
        })
        .map((goal) {
          return AtlasStrategyObjective(
            id: 'objective_${goal.id}',
            farmName: goal.farmName,
            title: goal.kpiTitle,
            description: goal.notes.isEmpty
                ? 'Alcançar o valor-alvo definido para o indicador.'
                : goal.notes,
            category: _categoryFromKpi(goal.category),
            progressPercent: goal.progressPercent,
            deadline: goal.deadline,
            status: _statusFromGoal(goal.status),
            priority: _priorityFromGoal(goal.priority),
            responsibleName: goal.responsibleName,
          );
        })
        .toList();
  }

  List<AtlasStrategyPriority> _buildPriorities(List<AtlasExecutiveGoal> goals) {
    return goals
        .where((goal) {
          return goal.status != AtlasExecutiveGoalStatus.completed &&
              goal.status != AtlasExecutiveGoalStatus.cancelled;
        })
        .take(12)
        .map((goal) {
          return AtlasStrategyPriority(
            id: 'priority_${goal.id}',
            farmName: goal.farmName,
            title: goal.kpiTitle,
            description:
                'Prioridade estratégica derivada de uma meta executiva '
                '${atlasExecutiveGoalStatusLabel(goal.status).toLowerCase()}.',
            category: _categoryFromKpi(goal.category),
            priority: _priorityFromGoal(goal.priority),
            status: _statusFromGoal(goal.status),
            deadline: goal.deadline,
            progressPercent: goal.progressPercent,
          );
        })
        .toList();
  }

  List<AtlasStrategyInitiative> _buildInitiatives(
    List<AtlasExecutiveGoal> goals,
  ) {
    return goals
        .where((goal) {
          return goal.status == AtlasExecutiveGoalStatus.active ||
              goal.status == AtlasExecutiveGoalStatus.atRisk ||
              goal.status == AtlasExecutiveGoalStatus.overdue;
        })
        .map((goal) {
          return AtlasStrategyInitiative(
            id: 'initiative_${goal.id}',
            farmName: goal.farmName,
            title: 'Plano de execução — ${goal.kpiTitle}',
            description:
                'Executar ações para evoluir de '
                '${_value(goal.startValue, goal.unit)} '
                'para '
                '${_value(goal.targetValue, goal.unit)}.',
            category: _categoryFromKpi(goal.category),
            status: _statusFromGoal(goal.status),
            progressPercent: goal.progressPercent,
            deadline: goal.deadline,
            expectedImpact:
                'Atingir ${_value(goal.targetValue, goal.unit)} '
                'até ${_date(goal.deadline)}.',
          );
        })
        .toList();
  }

  List<AtlasStrategyRisk> _buildRisks({
    required AtlasExecutiveKpiDashboardData kpis,
    required AtlasExecutiveGoalHistorySummary history,
  }) {
    final risks = <AtlasStrategyRisk>[];

    for (final kpi in kpis.criticalKpis.take(12)) {
      risks.add(
        AtlasStrategyRisk(
          id: 'risk_${kpi.id}',
          farmName: kpi.farmName,
          title: kpi.title,
          description: kpi.description,
          category: _categoryFromKpi(kpi.category),
          probability: AtlasStrategyRiskLevel.high,
          impact: kpi.targetAchievementPercent < 40
              ? AtlasStrategyRiskLevel.critical
              : AtlasStrategyRiskLevel.high,
          mitigation:
              'Criar ou atualizar uma meta, definir responsável e acompanhar o indicador semanalmente.',
        ),
      );
    }

    for (final series in history.series.where(
      (item) => item.riskLevel == AtlasExecutiveGoalRiskLevel.high,
    )) {
      risks.add(
        AtlasStrategyRisk(
          id: 'goal_risk_${series.goalId}',
          farmName: series.farmName,
          title: 'Risco de atraso — ${series.kpiTitle}',
          description:
              'A projeção atual indica risco elevado de a meta não ser concluída no prazo.',
          category: AtlasStrategyCategory.management,
          probability: AtlasStrategyRiskLevel.high,
          impact: AtlasStrategyRiskLevel.high,
          mitigation:
              'Revisar prazo, recursos, responsável e plano de execução.',
        ),
      );
    }

    return risks;
  }

  List<AtlasStrategyOpportunity> _buildOpportunities(
    AtlasExecutiveKpiDashboardData kpis,
  ) {
    return kpis.positiveHighlights.take(12).map((kpi) {
      final excess = kpi.targetAchievementPercent - 100;

      return AtlasStrategyOpportunity(
        id: 'opportunity_${kpi.id}',
        farmName: kpi.farmName,
        title: 'Potencial de expansão — ${kpi.title}',
        description:
            'O indicador superou a meta e pode servir como referência para outras áreas ou fazendas.',
        category: _categoryFromKpi(kpi.category),
        impactValue: excess.clamp(0.0, 100.0).toDouble(),
        impactUnit: '% acima da meta',
        confidencePercent: kpi.targetAchievementPercent
            .clamp(0.0, 100.0)
            .toDouble(),
        recommendation:
            'Documentar a prática, validar a consistência do resultado e replicar o padrão.',
      );
    }).toList();
  }

  AtlasStrategyCategory _categoryFromKpi(AtlasExecutiveKpiCategory category) {
    switch (category) {
      case AtlasExecutiveKpiCategory.production:
        return AtlasStrategyCategory.production;

      case AtlasExecutiveKpiCategory.reproduction:
        return AtlasStrategyCategory.reproduction;

      case AtlasExecutiveKpiCategory.health:
        return AtlasStrategyCategory.health;

      case AtlasExecutiveKpiCategory.finance:
        return AtlasStrategyCategory.finance;

      case AtlasExecutiveKpiCategory.management:
        return AtlasStrategyCategory.management;

      case AtlasExecutiveKpiCategory.intelligence:
        return AtlasStrategyCategory.intelligence;
    }
  }

  AtlasStrategyItemStatus _statusFromGoal(AtlasExecutiveGoalStatus status) {
    switch (status) {
      case AtlasExecutiveGoalStatus.active:
        return AtlasStrategyItemStatus.active;

      case AtlasExecutiveGoalStatus.atRisk:
        return AtlasStrategyItemStatus.atRisk;

      case AtlasExecutiveGoalStatus.overdue:
        return AtlasStrategyItemStatus.overdue;

      case AtlasExecutiveGoalStatus.completed:
        return AtlasStrategyItemStatus.completed;

      case AtlasExecutiveGoalStatus.cancelled:
        return AtlasStrategyItemStatus.cancelled;
    }
  }

  AtlasStrategyPriorityLevel _priorityFromGoal(
    AtlasExecutiveGoalPriority priority,
  ) {
    switch (priority) {
      case AtlasExecutiveGoalPriority.low:
        return AtlasStrategyPriorityLevel.low;

      case AtlasExecutiveGoalPriority.medium:
        return AtlasStrategyPriorityLevel.medium;

      case AtlasExecutiveGoalPriority.high:
        return AtlasStrategyPriorityLevel.high;

      case AtlasExecutiveGoalPriority.critical:
        return AtlasStrategyPriorityLevel.critical;
    }
  }

  String _value(double value, String unit) {
    final decimals = value == value.roundToDouble() ? 0 : 1;

    if (unit.isEmpty) {
      return value.toStringAsFixed(decimals);
    }

    return '${value.toStringAsFixed(decimals)} $unit';
  }

  String _date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
