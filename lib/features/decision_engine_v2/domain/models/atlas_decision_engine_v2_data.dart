import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasDecisionEngineV2Data {
  const AtlasDecisionEngineV2Data({
    required this.generatedAt,
    required this.summary,
    required this.score,
    required this.confidencePercent,
    required this.status,
    required this.bestActionToday,
    required this.dailyPlan,
    required this.weeklyPlan,
    required this.monthlyPlan,
    required this.rankedActions,
    required this.simulations,
  });

  final DateTime generatedAt;
  final String summary;

  final double score;
  final double confidencePercent;

  final AtlasDecisionEngineV2Status status;

  final AtlasDecisionV2Action? bestActionToday;

  final List<AtlasDecisionV2Action> dailyPlan;
  final List<AtlasDecisionV2Action> weeklyPlan;
  final List<AtlasDecisionV2Action> monthlyPlan;
  final List<AtlasDecisionV2Action> rankedActions;

  final List<AtlasDecisionV2Simulation> simulations;

  bool get hasData {
    return rankedActions.isNotEmpty;
  }
}

class AtlasDecisionV2Action {
  const AtlasDecisionV2Action({
    required this.position,
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.horizon,
    required this.priority,
    required this.urgency,
    required this.risk,
    required this.effort,
    required this.confidencePercent,
    required this.impactScore,
    required this.decisionScore,
    required this.expectedFinancialImpact,
    required this.investmentValue,
    required this.expectedReturnValue,
    required this.roiPercent,
    required this.deadlineDays,
    required this.canBePostponed,
    required this.maximumPostponementDays,
    required this.expectedResult,
    required this.reasoning,
    required this.dependencies,
  });

  final int position;
  final String id;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;

  final AtlasDecisionV2Horizon horizon;
  final AtlasDecisionV2Priority priority;
  final AtlasDecisionV2Urgency urgency;
  final AtlasDecisionV2Risk risk;
  final AtlasDecisionV2Effort effort;

  final double confidencePercent;
  final double impactScore;
  final double decisionScore;

  final double expectedFinancialImpact;
  final double investmentValue;
  final double expectedReturnValue;
  final double roiPercent;

  final int deadlineDays;

  final bool canBePostponed;
  final int maximumPostponementDays;

  final String expectedResult;
  final String reasoning;

  final List<String> dependencies;
}

class AtlasDecisionV2Simulation {
  const AtlasDecisionV2Simulation({
    required this.id,
    required this.actionId,
    required this.farmName,
    required this.title,
    required this.type,
    required this.delayDays,
    required this.investmentValue,
    required this.projectedFinancialImpact,
    required this.projectedRiskPercent,
    required this.projectedConfidencePercent,
    required this.recommendation,
  });

  final String id;
  final String actionId;

  final String farmName;
  final String title;

  final AtlasDecisionV2SimulationType type;

  final int delayDays;

  final double investmentValue;
  final double projectedFinancialImpact;
  final double projectedRiskPercent;
  final double projectedConfidencePercent;

  final String recommendation;
}

enum AtlasDecisionEngineV2Status {
  excellent,
  adequate,
  attention,
  critical,
}

enum AtlasDecisionV2Horizon {
  today,
  week,
  month,
}

enum AtlasDecisionV2Priority {
  low,
  medium,
  high,
  critical,
}

enum AtlasDecisionV2Urgency {
  low,
  medium,
  high,
  immediate,
}

enum AtlasDecisionV2Risk {
  low,
  medium,
  high,
  critical,
}

enum AtlasDecisionV2Effort {
  low,
  medium,
  high,
}

enum AtlasDecisionV2SimulationType {
  executeNow,
  waitSevenDays,
  increaseInvestment,
  reduceInvestment,
}

String atlasDecisionEngineV2StatusLabel(
  AtlasDecisionEngineV2Status status,
) {
  switch (status) {
    case AtlasDecisionEngineV2Status.excellent:
      return 'Excelente';

    case AtlasDecisionEngineV2Status.adequate:
      return 'Adequado';

    case AtlasDecisionEngineV2Status.attention:
      return 'Atenção';

    case AtlasDecisionEngineV2Status.critical:
      return 'Crítico';
  }
}

String atlasDecisionV2HorizonLabel(
  AtlasDecisionV2Horizon horizon,
) {
  switch (horizon) {
    case AtlasDecisionV2Horizon.today:
      return 'Hoje';

    case AtlasDecisionV2Horizon.week:
      return 'Esta semana';

    case AtlasDecisionV2Horizon.month:
      return 'Este mês';
  }
}

String atlasDecisionV2PriorityLabel(
  AtlasDecisionV2Priority priority,
) {
  switch (priority) {
    case AtlasDecisionV2Priority.low:
      return 'Baixa';

    case AtlasDecisionV2Priority.medium:
      return 'Média';

    case AtlasDecisionV2Priority.high:
      return 'Alta';

    case AtlasDecisionV2Priority.critical:
      return 'Crítica';
  }
}

String atlasDecisionV2UrgencyLabel(
  AtlasDecisionV2Urgency urgency,
) {
  switch (urgency) {
    case AtlasDecisionV2Urgency.low:
      return 'Baixa';

    case AtlasDecisionV2Urgency.medium:
      return 'Média';

    case AtlasDecisionV2Urgency.high:
      return 'Alta';

    case AtlasDecisionV2Urgency.immediate:
      return 'Imediata';
  }
}

String atlasDecisionV2RiskLabel(
  AtlasDecisionV2Risk risk,
) {
  switch (risk) {
    case AtlasDecisionV2Risk.low:
      return 'Baixo';

    case AtlasDecisionV2Risk.medium:
      return 'Médio';

    case AtlasDecisionV2Risk.high:
      return 'Alto';

    case AtlasDecisionV2Risk.critical:
      return 'Crítico';
  }
}

String atlasDecisionV2EffortLabel(
  AtlasDecisionV2Effort effort,
) {
  switch (effort) {
    case AtlasDecisionV2Effort.low:
      return 'Baixo';

    case AtlasDecisionV2Effort.medium:
      return 'Médio';

    case AtlasDecisionV2Effort.high:
      return 'Alto';
  }
}

String atlasDecisionV2SimulationTypeLabel(
  AtlasDecisionV2SimulationType type,
) {
  switch (type) {
    case AtlasDecisionV2SimulationType.executeNow:
      return 'Executar agora';

    case AtlasDecisionV2SimulationType.waitSevenDays:
      return 'Esperar 7 dias';

    case AtlasDecisionV2SimulationType.increaseInvestment:
      return 'Aumentar investimento';

    case AtlasDecisionV2SimulationType.reduceInvestment:
      return 'Reduzir investimento';
  }
}
