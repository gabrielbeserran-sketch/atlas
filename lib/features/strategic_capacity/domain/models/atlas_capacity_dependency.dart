import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';

class AtlasCapacityAssessment {
  const AtlasCapacityAssessment({
    required this.generatedAt,
    required this.items,
    required this.dependencies,
    required this.conflicts,
    required this.totalCapacityDemand,
    required this.availableCapacity,
  });

  final DateTime generatedAt;
  final List<AtlasCapacityItem> items;
  final List<AtlasStrategyDependency> dependencies;
  final List<AtlasCapacityConflict> conflicts;
  final double totalCapacityDemand;
  final double availableCapacity;

  double get utilizationPercent {
    if (availableCapacity <= 0) {
      return totalCapacityDemand > 0 ? 100 : 0;
    }

    return (totalCapacityDemand / availableCapacity * 100)
        .clamp(0.0, 300.0)
        .toDouble();
  }

  int get overloadedStrategies {
    return items.where((item) => item.overloaded).length;
  }

  int get criticalConflicts {
    return conflicts
        .where(
          (item) =>
              item.severity ==
              AtlasCapacityConflictSeverity.critical,
        )
        .length;
  }

  int get blockedDependencies {
    return dependencies
        .where(
          (item) =>
              item.status ==
              AtlasStrategyDependencyStatus.blocked,
        )
        .length;
  }
}

class AtlasCapacityItem {
  const AtlasCapacityItem({
    required this.plan,
    required this.requiredHours,
    required this.teamLoadPercent,
    required this.remainingMilestones,
    required this.remainingDays,
    required this.overloaded,
    required this.recommendation,
  });

  final AtlasStrategyExecutionPlan plan;
  final double requiredHours;
  final double teamLoadPercent;
  final int remainingMilestones;
  final int remainingDays;
  final bool overloaded;
  final String recommendation;
}

class AtlasStrategyDependency {
  const AtlasStrategyDependency({
    required this.id,
    required this.predecessorPlanId,
    required this.predecessorTitle,
    required this.successorPlanId,
    required this.successorTitle,
    required this.reason,
    required this.status,
  });

  final String id;
  final String predecessorPlanId;
  final String predecessorTitle;
  final String successorPlanId;
  final String successorTitle;
  final String reason;
  final AtlasStrategyDependencyStatus status;
}

class AtlasCapacityConflict {
  const AtlasCapacityConflict({
    required this.id,
    required this.title,
    required this.description,
    required this.planIds,
    required this.severity,
    required this.recommendation,
  });

  final String id;
  final String title;
  final String description;
  final List<String> planIds;
  final AtlasCapacityConflictSeverity severity;
  final String recommendation;
}

enum AtlasStrategyDependencyStatus {
  satisfied,
  pending,
  blocked,
}

enum AtlasCapacityConflictSeverity {
  low,
  moderate,
  high,
  critical,
}

String atlasDependencyStatusLabel(
  AtlasStrategyDependencyStatus status,
) {
  switch (status) {
    case AtlasStrategyDependencyStatus.satisfied:
      return 'Atendida';
    case AtlasStrategyDependencyStatus.pending:
      return 'Pendente';
    case AtlasStrategyDependencyStatus.blocked:
      return 'Bloqueada';
  }
}

String atlasCapacityConflictSeverityLabel(
  AtlasCapacityConflictSeverity severity,
) {
  switch (severity) {
    case AtlasCapacityConflictSeverity.low:
      return 'Baixa';
    case AtlasCapacityConflictSeverity.moderate:
      return 'Moderada';
    case AtlasCapacityConflictSeverity.high:
      return 'Alta';
    case AtlasCapacityConflictSeverity.critical:
      return 'Crítica';
  }
}
