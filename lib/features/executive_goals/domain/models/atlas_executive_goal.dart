import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';

class AtlasExecutiveGoal {
  const AtlasExecutiveGoal({
    required this.id,
    required this.farmName,
    required this.kpiId,
    required this.kpiTitle,
    required this.category,
    required this.currentValue,
    required this.targetValue,
    required this.startValue,
    required this.unit,
    required this.direction,
    required this.createdAt,
    required this.deadline,
    required this.updatedAt,
    required this.status,
    required this.priority,
    this.completedAt,
    this.responsibleName = '',
    this.notes = '',
  });

  final String id;
  final String farmName;

  final String kpiId;
  final String kpiTitle;

  final AtlasExecutiveKpiCategory category;

  final double currentValue;
  final double targetValue;
  final double startValue;

  final String unit;

  final AtlasExecutiveKpiDirection direction;

  final DateTime createdAt;
  final DateTime deadline;
  final DateTime updatedAt;
  final DateTime? completedAt;

  final AtlasExecutiveGoalStatus status;
  final AtlasExecutiveGoalPriority priority;

  final String responsibleName;
  final String notes;

  double get progressPercent {
    if (status == AtlasExecutiveGoalStatus.completed) {
      return 100;
    }

    final totalDistance =
        (targetValue - startValue).abs();

    if (totalDistance == 0) {
      return currentValue == targetValue ? 100 : 0;
    }

    final travelledDistance =
        (currentValue - startValue).abs();

    final raw =
        travelledDistance / totalDistance * 100;

    return raw.clamp(0.0, 100.0).toDouble();
  }

  int get remainingDays {
    return deadline
        .difference(DateTime.now())
        .inDays;
  }

  bool get isCompleted {
    return status ==
        AtlasExecutiveGoalStatus.completed;
  }

  bool get isOverdue {
    return !isCompleted &&
        deadline.isBefore(DateTime.now());
  }

  bool get targetReached {
    switch (direction) {
      case AtlasExecutiveKpiDirection.higherIsBetter:
        return currentValue >= targetValue;

      case AtlasExecutiveKpiDirection.lowerIsBetter:
        return currentValue <= targetValue;

      case AtlasExecutiveKpiDirection.neutral:
        return (currentValue - targetValue).abs() <= 0.01;
    }
  }

  AtlasExecutiveGoal copyWith({
    String? id,
    String? farmName,
    String? kpiId,
    String? kpiTitle,
    AtlasExecutiveKpiCategory? category,
    double? currentValue,
    double? targetValue,
    double? startValue,
    String? unit,
    AtlasExecutiveKpiDirection? direction,
    DateTime? createdAt,
    DateTime? deadline,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    AtlasExecutiveGoalStatus? status,
    AtlasExecutiveGoalPriority? priority,
    String? responsibleName,
    String? notes,
  }) {
    return AtlasExecutiveGoal(
      id: id ?? this.id,
      farmName: farmName ?? this.farmName,
      kpiId: kpiId ?? this.kpiId,
      kpiTitle: kpiTitle ?? this.kpiTitle,
      category: category ?? this.category,
      currentValue:
          currentValue ?? this.currentValue,
      targetValue:
          targetValue ?? this.targetValue,
      startValue: startValue ?? this.startValue,
      unit: unit ?? this.unit,
      direction: direction ?? this.direction,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt
          ? null
          : completedAt ?? this.completedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      responsibleName:
          responsibleName ?? this.responsibleName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmName': farmName,
      'kpiId': kpiId,
      'kpiTitle': kpiTitle,
      'category': category.name,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'startValue': startValue,
      'unit': unit,
      'direction': direction.name,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt':
          completedAt?.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'responsibleName': responsibleName,
      'notes': notes,
    };
  }

  factory AtlasExecutiveGoal.fromJson(
    Map<String, dynamic> json,
  ) {
    final categoryName =
        json['category']?.toString() ?? '';

    final directionName =
        json['direction']?.toString() ?? '';

    final statusName =
        json['status']?.toString() ?? '';

    final priorityName =
        json['priority']?.toString() ?? '';

    return AtlasExecutiveGoal(
      id: json['id']?.toString() ?? '',
      farmName:
          json['farmName']?.toString() ?? '',
      kpiId: json['kpiId']?.toString() ?? '',
      kpiTitle:
          json['kpiTitle']?.toString() ?? '',
      category:
          AtlasExecutiveKpiCategory.values.firstWhere(
        (item) => item.name == categoryName,
        orElse: () =>
            AtlasExecutiveKpiCategory.intelligence,
      ),
      currentValue:
          _readDouble(json['currentValue']),
      targetValue:
          _readDouble(json['targetValue']),
      startValue:
          _readDouble(json['startValue']),
      unit: json['unit']?.toString() ?? '',
      direction:
          AtlasExecutiveKpiDirection.values.firstWhere(
        (item) => item.name == directionName,
        orElse: () =>
            AtlasExecutiveKpiDirection
                .higherIsBetter,
      ),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      deadline: DateTime.tryParse(
            json['deadline']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
            json['updatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? '',
      ),
      status:
          AtlasExecutiveGoalStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () =>
            AtlasExecutiveGoalStatus.active,
      ),
      priority:
          AtlasExecutiveGoalPriority.values.firstWhere(
        (item) => item.name == priorityName,
        orElse: () =>
            AtlasExecutiveGoalPriority.medium,
      ),
      responsibleName:
          json['responsibleName']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  static double _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class AtlasExecutiveGoalProgress {
  const AtlasExecutiveGoalProgress({
    required this.total,
    required this.active,
    required this.atRisk,
    required this.overdue,
    required this.completed,
    required this.averageProgressPercent,
    required this.completionPercent,
  });

  final int total;
  final int active;
  final int atRisk;
  final int overdue;
  final int completed;

  final double averageProgressPercent;
  final double completionPercent;

  bool get hasGoals {
    return total > 0;
  }
}

class AtlasExecutiveGoalDashboardData {
  const AtlasExecutiveGoalDashboardData({
    required this.generatedAt,
    required this.summary,
    required this.progress,
    required this.goals,
    required this.priorityGoals,
    required this.farms,
  });

  final DateTime generatedAt;
  final String summary;

  final AtlasExecutiveGoalProgress progress;

  final List<AtlasExecutiveGoal> goals;
  final List<AtlasExecutiveGoal> priorityGoals;

  final List<AtlasExecutiveFarmGoalSummary> farms;

  bool get hasGoals {
    return goals.isNotEmpty;
  }
}

class AtlasExecutiveFarmGoalSummary {
  const AtlasExecutiveFarmGoalSummary({
    required this.farmName,
    required this.total,
    required this.active,
    required this.atRisk,
    required this.overdue,
    required this.completed,
    required this.averageProgressPercent,
    required this.mainGoalTitle,
  });

  final String farmName;

  final int total;
  final int active;
  final int atRisk;
  final int overdue;
  final int completed;

  final double averageProgressPercent;

  final String? mainGoalTitle;
}

enum AtlasExecutiveGoalStatus {
  active,
  atRisk,
  overdue,
  completed,
  cancelled,
}

enum AtlasExecutiveGoalPriority {
  low,
  medium,
  high,
  critical,
}

String atlasExecutiveGoalStatusLabel(
  AtlasExecutiveGoalStatus status,
) {
  switch (status) {
    case AtlasExecutiveGoalStatus.active:
      return 'No prazo';

    case AtlasExecutiveGoalStatus.atRisk:
      return 'Em risco';

    case AtlasExecutiveGoalStatus.overdue:
      return 'Atrasada';

    case AtlasExecutiveGoalStatus.completed:
      return 'Concluída';

    case AtlasExecutiveGoalStatus.cancelled:
      return 'Cancelada';
  }
}

String atlasExecutiveGoalPriorityLabel(
  AtlasExecutiveGoalPriority priority,
) {
  switch (priority) {
    case AtlasExecutiveGoalPriority.low:
      return 'Baixa';

    case AtlasExecutiveGoalPriority.medium:
      return 'Média';

    case AtlasExecutiveGoalPriority.high:
      return 'Alta';

    case AtlasExecutiveGoalPriority.critical:
      return 'Crítica';
  }
}
