import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';

class AtlasGoalPerformanceSummary {
  const AtlasGoalPerformanceSummary({
    required this.goal,
    required this.linkedActions,
    required this.completedActions,
    required this.overdueActions,
    required this.averageActionProgressPercent,
    required this.expectedFinancialImpact,
    required this.plannedValue,
    required this.realizedValue,
    required this.variance,
    required this.executionScore,
  });

  final AtlasOperationalGoal goal;
  final int linkedActions;
  final int completedActions;
  final int overdueActions;
  final double averageActionProgressPercent;
  final double expectedFinancialImpact;
  final double plannedValue;
  final double realizedValue;
  final double variance;
  final double executionScore;
}
