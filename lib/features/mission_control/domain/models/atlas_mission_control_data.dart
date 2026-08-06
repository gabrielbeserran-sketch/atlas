import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasMissionControlData {
  const AtlasMissionControlData({
    required this.generatedAt,
    required this.greeting,
    required this.summary,
    required this.globalScore,
    required this.executionProbabilityPercent,
    required this.goalProbabilityPercent,
    required this.estimatedMonthlyImpact,
    required this.status,
    required this.priorities,
    required this.alerts,
    required this.workflows,
    required this.decisions,
    required this.dailyPlan,
  });

  final DateTime generatedAt;

  final String greeting;
  final String summary;

  final double globalScore;
  final double executionProbabilityPercent;
  final double goalProbabilityPercent;
  final double estimatedMonthlyImpact;

  final AtlasMissionControlStatus status;

  final List<AtlasMissionPriority> priorities;
  final List<AtlasMissionAlert> alerts;
  final List<AtlasMissionWorkflowSummary> workflows;
  final List<AtlasMissionDecisionSummary> decisions;
  final List<AtlasMissionDailyAction> dailyPlan;

  bool get hasData {
    return priorities.isNotEmpty ||
        alerts.isNotEmpty ||
        workflows.isNotEmpty ||
        decisions.isNotEmpty ||
        dailyPlan.isNotEmpty;
  }

  AtlasMissionPriority? get topPriority {
    if (priorities.isEmpty) {
      return null;
    }

    return priorities.first;
  }
}

class AtlasMissionPriority {
  const AtlasMissionPriority({
    required this.position,
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.urgency,
    required this.impactScore,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineDays,
    required this.source,
    required this.recommendation,
  });

  final int position;
  final String id;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;

  final AtlasMissionPriorityLevel priority;
  final AtlasMissionUrgency urgency;

  final double impactScore;
  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineDays;

  final AtlasMissionSource source;

  final String recommendation;
}

class AtlasMissionAlert {
  const AtlasMissionAlert({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.probabilityPercent,
    required this.expectedFinancialImpact,
    required this.source,
    required this.recommendation,
  });

  final String id;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasMissionSeverity severity;

  final double probabilityPercent;
  final double expectedFinancialImpact;

  final AtlasMissionSource source;

  final String recommendation;
}

class AtlasMissionWorkflowSummary {
  const AtlasMissionWorkflowSummary({
    required this.id,
    required this.farmName,
    required this.title,
    required this.status,
    required this.progressPercent,
    required this.totalTasks,
    required this.completedTasks,
    required this.delayedTasks,
    required this.deadline,
  });

  final String id;
  final String farmName;
  final String title;

  final AtlasMissionWorkflowStatus status;

  final double progressPercent;

  final int totalTasks;
  final int completedTasks;
  final int delayedTasks;

  final DateTime deadline;
}

class AtlasMissionDecisionSummary {
  const AtlasMissionDecisionSummary({
    required this.position,
    required this.id,
    required this.farmName,
    required this.title,
    required this.priority,
    required this.urgency,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineDays,
  });

  final int position;
  final String id;

  final String farmName;
  final String title;

  final AtlasMissionPriorityLevel priority;
  final AtlasMissionUrgency urgency;

  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineDays;
}

class AtlasMissionDailyAction {
  const AtlasMissionDailyAction({
    required this.position,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.deadlineHours,
    required this.expectedImpact,
    required this.completed,
  });

  final int position;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasMissionPriorityLevel priority;

  final int deadlineHours;

  final String expectedImpact;

  final bool completed;

  AtlasMissionDailyAction copyWith({
    bool? completed,
  }) {
    return AtlasMissionDailyAction(
      position: position,
      farmName: farmName,
      title: title,
      description: description,
      category: category,
      priority: priority,
      deadlineHours: deadlineHours,
      expectedImpact: expectedImpact,
      completed: completed ?? this.completed,
    );
  }
}

enum AtlasMissionControlStatus {
  stable,
  attention,
  highRisk,
  critical,
}

enum AtlasMissionPriorityLevel {
  low,
  medium,
  high,
  critical,
}

enum AtlasMissionUrgency {
  low,
  medium,
  high,
  immediate,
}

enum AtlasMissionSeverity {
  low,
  medium,
  high,
  critical,
}

enum AtlasMissionSource {
  decisionEngine,
  predictiveAnalytics,
  workflow,
  intelligence,
  advisor,
  benchmark,
  atlasBi,
}

enum AtlasMissionWorkflowStatus {
  planned,
  inProgress,
  delayed,
  completed,
  cancelled,
}

String atlasMissionControlStatusLabel(
  AtlasMissionControlStatus status,
) {
  switch (status) {
    case AtlasMissionControlStatus.stable:
      return 'Estável';

    case AtlasMissionControlStatus.attention:
      return 'Atenção';

    case AtlasMissionControlStatus.highRisk:
      return 'Risco alto';

    case AtlasMissionControlStatus.critical:
      return 'Crítico';
  }
}

String atlasMissionPriorityLabel(
  AtlasMissionPriorityLevel priority,
) {
  switch (priority) {
    case AtlasMissionPriorityLevel.low:
      return 'Baixa';

    case AtlasMissionPriorityLevel.medium:
      return 'Média';

    case AtlasMissionPriorityLevel.high:
      return 'Alta';

    case AtlasMissionPriorityLevel.critical:
      return 'Crítica';
  }
}

String atlasMissionUrgencyLabel(
  AtlasMissionUrgency urgency,
) {
  switch (urgency) {
    case AtlasMissionUrgency.low:
      return 'Baixa';

    case AtlasMissionUrgency.medium:
      return 'Média';

    case AtlasMissionUrgency.high:
      return 'Alta';

    case AtlasMissionUrgency.immediate:
      return 'Imediata';
  }
}

String atlasMissionSeverityLabel(
  AtlasMissionSeverity severity,
) {
  switch (severity) {
    case AtlasMissionSeverity.low:
      return 'Baixa';

    case AtlasMissionSeverity.medium:
      return 'Média';

    case AtlasMissionSeverity.high:
      return 'Alta';

    case AtlasMissionSeverity.critical:
      return 'Crítica';
  }
}

String atlasMissionSourceLabel(
  AtlasMissionSource source,
) {
  switch (source) {
    case AtlasMissionSource.decisionEngine:
      return 'Decision Engine';

    case AtlasMissionSource.predictiveAnalytics:
      return 'Predictive Analytics';

    case AtlasMissionSource.workflow:
      return 'Workflow';

    case AtlasMissionSource.intelligence:
      return 'Inteligência Executiva';

    case AtlasMissionSource.advisor:
      return 'AI Advisor';

    case AtlasMissionSource.benchmark:
      return 'Benchmarking';

    case AtlasMissionSource.atlasBi:
      return 'Atlas BI';
  }
}

String atlasMissionWorkflowStatusLabel(
  AtlasMissionWorkflowStatus status,
) {
  switch (status) {
    case AtlasMissionWorkflowStatus.planned:
      return 'Planejado';

    case AtlasMissionWorkflowStatus.inProgress:
      return 'Em andamento';

    case AtlasMissionWorkflowStatus.delayed:
      return 'Atrasado';

    case AtlasMissionWorkflowStatus.completed:
      return 'Concluído';

    case AtlasMissionWorkflowStatus.cancelled:
      return 'Cancelado';
  }
}
