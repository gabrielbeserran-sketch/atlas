import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasWorkflowData {
  const AtlasWorkflowData({
    required this.generatedAt,
    required this.summary,
    required this.workflows,
    required this.totalTasks,
    required this.completedTasks,
    required this.delayedTasks,
    required this.progressPercent,
    required this.executionScore,
  });

  final DateTime generatedAt;
  final String summary;

  final List<AtlasWorkflow> workflows;

  final int totalTasks;
  final int completedTasks;
  final int delayedTasks;

  final double progressPercent;
  final double executionScore;

  bool get hasData {
    return workflows.isNotEmpty;
  }

  List<AtlasWorkflowTask> get allTasks {
    return workflows.expand((workflow) => workflow.tasks).toList();
  }

  List<AtlasWorkflowTask> get delayedTaskList {
    return allTasks.where((task) {
      return task.status == AtlasWorkflowTaskStatus.delayed;
    }).toList();
  }
}

class AtlasWorkflow {
  const AtlasWorkflow({
    required this.id,
    required this.executionId,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.startedAt,
    required this.deadline,
    required this.status,
    required this.progressPercent,
    required this.tasks,
    required this.bottlenecks,
    required this.replanningSuggestions,
  });

  final String id;
  final String executionId;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;

  final DateTime startedAt;
  final DateTime deadline;

  final AtlasWorkflowStatus status;
  final double progressPercent;

  final List<AtlasWorkflowTask> tasks;
  final List<AtlasWorkflowBottleneck> bottlenecks;
  final List<AtlasWorkflowReplanningSuggestion> replanningSuggestions;

  bool get isCompleted {
    return status == AtlasWorkflowStatus.completed;
  }

  AtlasWorkflow copyWith({
    AtlasWorkflowStatus? status,
    double? progressPercent,
    List<AtlasWorkflowTask>? tasks,
    List<AtlasWorkflowBottleneck>? bottlenecks,
    List<AtlasWorkflowReplanningSuggestion>? replanningSuggestions,
  }) {
    return AtlasWorkflow(
      id: id,
      executionId: executionId,
      farmName: farmName,
      title: title,
      description: description,
      category: category,
      startedAt: startedAt,
      deadline: deadline,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      tasks: tasks ?? this.tasks,
      bottlenecks: bottlenecks ?? this.bottlenecks,
      replanningSuggestions:
          replanningSuggestions ?? this.replanningSuggestions,
    );
  }
}

class AtlasWorkflowTask {
  const AtlasWorkflowTask({
    required this.id,
    required this.workflowId,
    required this.position,
    required this.title,
    required this.description,
    required this.responsibleName,
    required this.startDate,
    required this.deadline,
    required this.status,
    required this.progressPercent,
    required this.dependencies,
    required this.expectedResult,
    required this.notes,
  });

  final String id;
  final String workflowId;

  final int position;

  final String title;
  final String description;
  final String responsibleName;

  final DateTime startDate;
  final DateTime deadline;

  final AtlasWorkflowTaskStatus status;
  final double progressPercent;

  final List<String> dependencies;

  final String expectedResult;
  final String notes;

  bool get hasDependencies {
    return dependencies.isNotEmpty;
  }

  bool get isCompleted {
    return status == AtlasWorkflowTaskStatus.completed;
  }

  AtlasWorkflowTask copyWith({
    String? responsibleName,
    DateTime? startDate,
    DateTime? deadline,
    AtlasWorkflowTaskStatus? status,
    double? progressPercent,
    String? notes,
  }) {
    return AtlasWorkflowTask(
      id: id,
      workflowId: workflowId,
      position: position,
      title: title,
      description: description,
      responsibleName: responsibleName ?? this.responsibleName,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      dependencies: dependencies,
      expectedResult: expectedResult,
      notes: notes ?? this.notes,
    );
  }
}

class AtlasWorkflowBottleneck {
  const AtlasWorkflowBottleneck({
    required this.id,
    required this.workflowId,
    required this.taskId,
    required this.title,
    required this.description,
    required this.severity,
    required this.delayDays,
    required this.recommendation,
  });

  final String id;
  final String workflowId;
  final String taskId;

  final String title;
  final String description;

  final AtlasWorkflowBottleneckSeverity severity;

  final int delayDays;

  final String recommendation;
}

class AtlasWorkflowReplanningSuggestion {
  const AtlasWorkflowReplanningSuggestion({
    required this.id,
    required this.workflowId,
    required this.title,
    required this.description,
    required this.newDeadline,
    required this.priority,
  });

  final String id;
  final String workflowId;

  final String title;
  final String description;

  final DateTime newDeadline;

  final AtlasWorkflowReplanningPriority priority;
}

enum AtlasWorkflowStatus { planned, inProgress, delayed, completed, cancelled }

enum AtlasWorkflowTaskStatus {
  blocked,
  pending,
  inProgress,
  delayed,
  completed,
  cancelled,
}

enum AtlasWorkflowBottleneckSeverity { low, medium, high, critical }

enum AtlasWorkflowReplanningPriority { low, medium, high, critical }

String atlasWorkflowStatusLabel(AtlasWorkflowStatus status) {
  switch (status) {
    case AtlasWorkflowStatus.planned:
      return 'Planejado';

    case AtlasWorkflowStatus.inProgress:
      return 'Em andamento';

    case AtlasWorkflowStatus.delayed:
      return 'Atrasado';

    case AtlasWorkflowStatus.completed:
      return 'Concluído';

    case AtlasWorkflowStatus.cancelled:
      return 'Cancelado';
  }
}

String atlasWorkflowTaskStatusLabel(AtlasWorkflowTaskStatus status) {
  switch (status) {
    case AtlasWorkflowTaskStatus.blocked:
      return 'Bloqueada';

    case AtlasWorkflowTaskStatus.pending:
      return 'Pendente';

    case AtlasWorkflowTaskStatus.inProgress:
      return 'Em andamento';

    case AtlasWorkflowTaskStatus.delayed:
      return 'Atrasada';

    case AtlasWorkflowTaskStatus.completed:
      return 'Concluída';

    case AtlasWorkflowTaskStatus.cancelled:
      return 'Cancelada';
  }
}

String atlasWorkflowBottleneckSeverityLabel(
  AtlasWorkflowBottleneckSeverity severity,
) {
  switch (severity) {
    case AtlasWorkflowBottleneckSeverity.low:
      return 'Baixa';

    case AtlasWorkflowBottleneckSeverity.medium:
      return 'Média';

    case AtlasWorkflowBottleneckSeverity.high:
      return 'Alta';

    case AtlasWorkflowBottleneckSeverity.critical:
      return 'Crítica';
  }
}
