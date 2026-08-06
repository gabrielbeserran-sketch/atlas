import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/decision_engine/domain/models/atlas_decision_engine_data.dart';

class AtlasDecisionTrackingData {
  const AtlasDecisionTrackingData({
    required this.generatedAt,
    required this.summary,
    required this.executions,
    required this.totalExpectedImpact,
    required this.totalRealizedImpact,
    required this.executionRatePercent,
    required this.successRatePercent,
  });

  final DateTime generatedAt;
  final String summary;

  final List<AtlasDecisionExecution> executions;

  final double totalExpectedImpact;
  final double totalRealizedImpact;

  final double executionRatePercent;
  final double successRatePercent;

  bool get hasData {
    return executions.isNotEmpty;
  }

  List<AtlasDecisionExecution> get activeExecutions {
    return executions.where((item) {
      return item.status ==
              AtlasDecisionExecutionStatus.approved ||
          item.status ==
              AtlasDecisionExecutionStatus.inProgress ||
          item.status ==
              AtlasDecisionExecutionStatus.delayed;
    }).toList();
  }

  List<AtlasDecisionExecution> get completedExecutions {
    return executions.where((item) {
      return item.status ==
          AtlasDecisionExecutionStatus.completed;
    }).toList();
  }
}

class AtlasDecisionExecution {
  const AtlasDecisionExecution({
    required this.id,
    required this.decisionId,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.approvedAt,
    required this.startedAt,
    required this.deadline,
    required this.completedAt,
    required this.progressPercent,
    required this.expectedFinancialImpact,
    required this.realizedFinancialImpact,
    required this.expectedResult,
    required this.resultSummary,
    required this.steps,
    required this.measurements,
    required this.notes,
  });

  final String id;
  final String decisionId;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasDecisionPriority priority;
  final AtlasDecisionExecutionStatus status;

  final DateTime approvedAt;
  final DateTime? startedAt;
  final DateTime deadline;
  final DateTime? completedAt;

  final double progressPercent;

  final double expectedFinancialImpact;
  final double realizedFinancialImpact;

  final String expectedResult;
  final String resultSummary;

  final List<AtlasDecisionExecutionStepState> steps;
  final List<AtlasDecisionMeasurement> measurements;

  final String notes;

  bool get isOverdue {
    if (status ==
            AtlasDecisionExecutionStatus.completed ||
        status ==
            AtlasDecisionExecutionStatus.cancelled) {
      return false;
    }

    return DateTime.now().isAfter(deadline);
  }

  double get financialAchievementPercent {
    if (expectedFinancialImpact <= 0) {
      return 0;
    }

    return (realizedFinancialImpact /
            expectedFinancialImpact *
            100)
        .clamp(0.0, 200.0)
        .toDouble();
  }

  AtlasDecisionExecution copyWith({
    AtlasDecisionExecutionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    double? progressPercent,
    double? realizedFinancialImpact,
    String? resultSummary,
    List<AtlasDecisionExecutionStepState>? steps,
    List<AtlasDecisionMeasurement>? measurements,
    String? notes,
  }) {
    return AtlasDecisionExecution(
      id: id,
      decisionId: decisionId,
      farmName: farmName,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: status ?? this.status,
      approvedAt: approvedAt,
      startedAt: startedAt ?? this.startedAt,
      deadline: deadline,
      completedAt: completedAt ?? this.completedAt,
      progressPercent:
          progressPercent ?? this.progressPercent,
      expectedFinancialImpact:
          expectedFinancialImpact,
      realizedFinancialImpact:
          realizedFinancialImpact ??
              this.realizedFinancialImpact,
      expectedResult: expectedResult,
      resultSummary:
          resultSummary ?? this.resultSummary,
      steps: steps ?? this.steps,
      measurements:
          measurements ?? this.measurements,
      notes: notes ?? this.notes,
    );
  }
}

class AtlasDecisionExecutionStepState {
  const AtlasDecisionExecutionStepState({
    required this.position,
    required this.title,
    required this.description,
    required this.deadlineDays,
    required this.expectedResult,
    required this.completed,
    required this.completedAt,
    this.responsibleName = '',
  });

  final int position;

  final String title;
  final String description;

  final int deadlineDays;
  final String expectedResult;

  final bool completed;
  final DateTime? completedAt;

  final String responsibleName;

  AtlasDecisionExecutionStepState copyWith({
    bool? completed,
    DateTime? completedAt,
    String? responsibleName,
  }) {
    return AtlasDecisionExecutionStepState(
      position: position,
      title: title,
      description: description,
      deadlineDays: deadlineDays,
      expectedResult: expectedResult,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      responsibleName:
          responsibleName ?? this.responsibleName,
    );
  }
}

class AtlasDecisionMeasurement {
  const AtlasDecisionMeasurement({
    required this.id,
    required this.indicatorTitle,
    required this.recordedAt,
    required this.value,
    required this.targetValue,
    required this.unit,
    required this.notes,
  });

  final String id;
  final String indicatorTitle;

  final DateTime recordedAt;

  final double value;
  final double targetValue;

  final String unit;
  final String notes;
}

enum AtlasDecisionExecutionStatus {
  approved,
  inProgress,
  delayed,
  completed,
  cancelled,
}

String atlasDecisionExecutionStatusLabel(
  AtlasDecisionExecutionStatus status,
) {
  switch (status) {
    case AtlasDecisionExecutionStatus.approved:
      return 'Aprovada';

    case AtlasDecisionExecutionStatus.inProgress:
      return 'Em andamento';

    case AtlasDecisionExecutionStatus.delayed:
      return 'Atrasada';

    case AtlasDecisionExecutionStatus.completed:
      return 'Concluída';

    case AtlasDecisionExecutionStatus.cancelled:
      return 'Cancelada';
  }
}
