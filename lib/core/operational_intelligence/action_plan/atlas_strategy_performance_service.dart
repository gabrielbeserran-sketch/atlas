import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_area_performance.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_farm_execution_score.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_goal_action_link.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_goal_performance_summary.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';

class AtlasStrategyPerformanceService {
  const AtlasStrategyPerformanceService();

  List<AtlasAreaPerformance> buildAreas({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasOperationalGoal> goals,
    required List<AtlasGoalActionLink> links,
  }) {
    final linksByAction = <String, AtlasGoalActionLink>{
      for (final link in links) link.actionId: link,
    };

    return AtlasOperationalArea.values.map((area) {
      final areaActions = actions.where((action) {
        final linkedArea = linksByAction[action.id]?.area;
        final inferredArea = _inferArea(action.sourceModule);

        return (linkedArea ?? inferredArea) == area;
      }).toList();

      final areaGoals =
          goals.where((goal) => goal.area == area).toList();

      final completed = areaActions
          .where((action) => action.isCompleted)
          .length;
      final open =
          areaActions.where((action) => action.isOpen).length;
      final overdue = areaActions
          .where((action) => action.isOverdue)
          .length;
      final averageProgress = areaActions.isEmpty
          ? 0.0
          : areaActions
                  .map((action) => action.progressPercent)
                  .reduce((first, second) => first + second) /
              areaActions.length;
      final expectedImpact = areaActions.fold<double>(
        0,
        (total, action) =>
            total + action.expectedFinancialImpact,
      );
      final activeGoals =
          areaGoals.where((goal) => goal.active).length;
      final completedGoals =
          areaGoals.where((goal) => goal.isCompleted).length;

      final completionRate = areaActions.isEmpty
          ? 0.0
          : completed / areaActions.length * 100;
      final deadlineHealth = areaActions.isEmpty
          ? 100.0
          : (1 - overdue / areaActions.length) * 100;
      final goalRate = areaGoals.isEmpty
          ? 0.0
          : completedGoals / areaGoals.length * 100;

      final score = (
        completionRate * 0.35 +
        averageProgress * 0.30 +
        deadlineHealth * 0.20 +
        goalRate * 0.15
      ).clamp(0.0, 100.0);

      return AtlasAreaPerformance(
        area: area,
        totalActions: areaActions.length,
        openActions: open,
        completedActions: completed,
        overdueActions: overdue,
        averageProgressPercent: averageProgress,
        expectedFinancialImpact: expectedImpact,
        activeGoals: activeGoals,
        completedGoals: completedGoals,
        performanceScore: score,
      );
    }).toList(growable: false);
  }

  List<AtlasGoalPerformanceSummary> buildGoals({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasOperationalGoal> goals,
    required List<AtlasGoalActionLink> links,
  }) {
    final actionsById = <String, AtlasCommandCenterAction>{
      for (final action in actions) action.id: action,
    };

    return goals.map((goal) {
      final goalLinks =
          links.where((link) => link.goalId == goal.id);
      final linkedActions = goalLinks
          .map((link) => actionsById[link.actionId])
          .whereType<AtlasCommandCenterAction>()
          .toList();

      final completed = linkedActions
          .where((action) => action.isCompleted)
          .length;
      final overdue = linkedActions
          .where((action) => action.isOverdue)
          .length;
      final averageProgress = linkedActions.isEmpty
          ? 0.0
          : linkedActions
                  .map((action) => action.progressPercent)
                  .reduce((first, second) => first + second) /
              linkedActions.length;
      final expectedImpact = linkedActions.fold<double>(
        0,
        (total, action) =>
            total + action.expectedFinancialImpact,
      );
      final completionRate = linkedActions.isEmpty
          ? 0.0
          : completed / linkedActions.length * 100;
      final deadlineHealth = linkedActions.isEmpty
          ? 100.0
          : (1 - overdue / linkedActions.length) * 100;

      final executionScore = (
        goal.progressPercent * 0.45 +
        averageProgress * 0.30 +
        completionRate * 0.15 +
        deadlineHealth * 0.10
      ).clamp(0.0, 100.0);

      return AtlasGoalPerformanceSummary(
        goal: goal,
        linkedActions: linkedActions.length,
        completedActions: completed,
        overdueActions: overdue,
        averageActionProgressPercent: averageProgress,
        expectedFinancialImpact: expectedImpact,
        plannedValue: goal.targetValue,
        realizedValue: goal.currentValue,
        variance: goal.currentValue - goal.targetValue,
        executionScore: executionScore,
      );
    }).toList(growable: false);
  }

  AtlasFarmExecutionScore buildFarmScore({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasOperationalGoal> goals,
  }) {
    final total = actions.length;
    final completed =
        actions.where((action) => action.isCompleted).length;
    final overdue =
        actions.where((action) => action.isOverdue).length;
    final withResponsible =
        actions.where((action) => action.hasResponsible).length;

    final completion = total == 0
        ? 0.0
        : completed / total * 100;
    final progress = total == 0
        ? 0.0
        : actions
                .map((action) => action.progressPercent)
                .fold<int>(0, (a, b) => a + b) /
            total;
    final deadline = total == 0
        ? 100.0
        : (1 - overdue / total) * 100;
    final responsibility = total == 0
        ? 0.0
        : withResponsible / total * 100;
    final goalComponent = goals.isEmpty
        ? 0.0
        : goals
                .map((goal) => goal.progressPercent)
                .fold<double>(0, (a, b) => a + b) /
            goals.length;

    final score = (
      completion * 0.30 +
      progress * 0.25 +
      deadline * 0.20 +
      responsibility * 0.10 +
      goalComponent * 0.15
    ).clamp(0.0, 100.0);

    return AtlasFarmExecutionScore(
      score: score,
      completionComponent: completion,
      progressComponent: progress,
      deadlineComponent: deadline,
      responsibilityComponent: responsibility,
      goalComponent: goalComponent,
      statusLabel: _status(score),
    );
  }

  AtlasOperationalArea _inferArea(
    String sourceModule,
  ) {
    final value = sourceModule.toLowerCase();

    if (value.contains('repro')) {
      return AtlasOperationalArea.reproduction;
    }
    if (value.contains('san') ||
        value.contains('health')) {
      return AtlasOperationalArea.health;
    }
    if (value.contains('nutri')) {
      return AtlasOperationalArea.nutrition;
    }
    if (value.contains('estoque') ||
        value.contains('stock')) {
      return AtlasOperationalArea.stock;
    }
    if (value.contains('financ')) {
      return AtlasOperationalArea.finance;
    }
    if (value.contains('rebanho') ||
        value.contains('herd') ||
        value.contains('animal')) {
      return AtlasOperationalArea.herd;
    }

    return AtlasOperationalArea.general;
  }

  String _status(double score) {
    if (score >= 85) {
      return 'Excelente';
    }
    if (score >= 70) {
      return 'Bom';
    }
    if (score >= 50) {
      return 'Atenção';
    }

    return 'Crítico';
  }
}
