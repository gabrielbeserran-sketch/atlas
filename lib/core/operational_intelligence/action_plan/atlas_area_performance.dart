import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';

class AtlasAreaPerformance {
  const AtlasAreaPerformance({
    required this.area,
    required this.totalActions,
    required this.openActions,
    required this.completedActions,
    required this.overdueActions,
    required this.averageProgressPercent,
    required this.expectedFinancialImpact,
    required this.activeGoals,
    required this.completedGoals,
    required this.performanceScore,
  });

  final AtlasOperationalArea area;
  final int totalActions;
  final int openActions;
  final int completedActions;
  final int overdueActions;
  final double averageProgressPercent;
  final double expectedFinancialImpact;
  final int activeGoals;
  final int completedGoals;
  final double performanceScore;
}
