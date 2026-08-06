import 'dart:math' as math;

import 'package:projeto_atlas/features/decision_tracking/domain/models/atlas_decision_tracking_data.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/models/atlas_workflow_data.dart';

class AtlasWorkflowService {
  const AtlasWorkflowService();

  AtlasWorkflow createWorkflow({
    required AtlasDecisionExecution execution,
  }) {
    final start =
        execution.startedAt ?? execution.approvedAt;

    final workflowId =
        'workflow_${execution.id}';

    final tasks =
        <AtlasWorkflowTask>[];

    for (final step in execution.steps) {
      final taskId =
          '${workflowId}_task_${step.position}';

      final dependencies = step.position <= 1
          ? <String>[]
          : <String>[
              '${workflowId}_task_${step.position - 1}',
            ];

      final taskStart = start.add(
        Duration(
          days: math.max(
            0,
            step.position == 1
                ? 0
                : execution.steps[
                            step.position - 2]
                        .deadlineDays,
          ),
        ),
      );

      final deadline = start.add(
        Duration(days: step.deadlineDays),
      );

      tasks.add(
        AtlasWorkflowTask(
          id: taskId,
          workflowId: workflowId,
          position: step.position,
          title: step.title,
          description: step.description,
          responsibleName:
              step.responsibleName,
          startDate: taskStart,
          deadline: deadline,
          status: step.completed
              ? AtlasWorkflowTaskStatus.completed
              : dependencies.isEmpty
                  ? AtlasWorkflowTaskStatus.pending
                  : AtlasWorkflowTaskStatus.blocked,
          progressPercent:
              step.completed ? 100 : 0,
          dependencies: dependencies,
          expectedResult:
              step.expectedResult,
          notes: '',
        ),
      );
    }

    return _normalizeWorkflow(
      AtlasWorkflow(
        id: workflowId,
        executionId: execution.id,
        farmName: execution.farmName,
        title: execution.title,
        description: execution.description,
        category: execution.category,
        startedAt: start,
        deadline: execution.deadline,
        status:
            AtlasWorkflowStatus.planned,
        progressPercent: 0,
        tasks: tasks,
        bottlenecks: const [],
        replanningSuggestions: const [],
      ),
    );
  }

  AtlasWorkflow startTask({
    required AtlasWorkflow workflow,
    required String taskId,
    DateTime? startedAt,
  }) {
    final currentTime = startedAt ?? DateTime.now();

    final tasks = workflow.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      if (!_dependenciesCompleted(
        task: task,
        tasks: workflow.tasks,
      )) {
        return task.copyWith(
          status:
              AtlasWorkflowTaskStatus.blocked,
        );
      }

      return task.copyWith(
        status:
            AtlasWorkflowTaskStatus.inProgress,
        startDate: currentTime,
        progressPercent:
            math.max(task.progressPercent, 1),
      );
    }).toList();

    return _normalizeWorkflow(
      workflow.copyWith(tasks: tasks),
      now: currentTime,
    );
  }

  AtlasWorkflow updateTaskProgress({
    required AtlasWorkflow workflow,
    required String taskId,
    required double progressPercent,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final safeProgress =
        progressPercent
            .clamp(0.0, 100.0)
            .toDouble();

    final tasks = workflow.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      if (!_dependenciesCompleted(
        task: task,
        tasks: workflow.tasks,
      )) {
        return task.copyWith(
          status:
              AtlasWorkflowTaskStatus.blocked,
        );
      }

      return task.copyWith(
        progressPercent: safeProgress,
        status: safeProgress >= 100
            ? AtlasWorkflowTaskStatus.completed
            : AtlasWorkflowTaskStatus.inProgress,
      );
    }).toList();

    return _normalizeWorkflow(
      workflow.copyWith(tasks: tasks),
      now: currentTime,
    );
  }

  AtlasWorkflow assignResponsible({
    required AtlasWorkflow workflow,
    required String taskId,
    required String responsibleName,
  }) {
    final tasks = workflow.tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      return task.copyWith(
        responsibleName:
            responsibleName.trim(),
      );
    }).toList();

    return _normalizeWorkflow(
      workflow.copyWith(tasks: tasks),
    );
  }

  AtlasWorkflow replan({
    required AtlasWorkflow workflow,
    required int additionalDays,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final safeDays =
        math.max(additionalDays, 1);

    final tasks = workflow.tasks.map((task) {
      if (task.status ==
              AtlasWorkflowTaskStatus.completed ||
          task.status ==
              AtlasWorkflowTaskStatus.cancelled) {
        return task;
      }

      return task.copyWith(
        deadline: task.deadline.add(
          Duration(days: safeDays),
        ),
      );
    }).toList();

    return _normalizeWorkflow(
      workflow.copyWith(
        tasks: tasks,
        replanningSuggestions: const [],
      ),
      now: currentTime,
    );
  }

  AtlasWorkflowData buildDashboard({
    required List<AtlasWorkflow> workflows,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final normalized = workflows.map((item) {
      return _normalizeWorkflow(
        item,
        now: currentTime,
      );
    }).toList();

    final allTasks = normalized
        .expand((workflow) => workflow.tasks)
        .toList();

    final completed = allTasks.where((task) {
      return task.status ==
          AtlasWorkflowTaskStatus.completed;
    }).length;

    final delayed = allTasks.where((task) {
      return task.status ==
          AtlasWorkflowTaskStatus.delayed;
    }).length;

    final progress = allTasks.isEmpty
        ? 0.0
        : allTasks.fold<double>(
              0,
              (sum, task) =>
                  sum + task.progressPercent,
            ) /
            allTasks.length;

    final executionScore =
        (progress -
                delayed * 5 +
                completed * 1.5)
            .clamp(0.0, 100.0)
            .toDouble();

    return AtlasWorkflowData(
      generatedAt: currentTime,
      summary:
          'O Workflow Engine acompanha '
          '${normalized.length} planos, '
          '${allTasks.length} tarefas, '
          '$completed concluídas, '
          '$delayed atrasadas e '
          '${progress.toStringAsFixed(0)}% de progresso global.',
      workflows: normalized,
      totalTasks: allTasks.length,
      completedTasks: completed,
      delayedTasks: delayed,
      progressPercent: progress,
      executionScore: executionScore,
    );
  }

  AtlasWorkflow _normalizeWorkflow(
    AtlasWorkflow workflow, {
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    var tasks = workflow.tasks.map((task) {
      if (task.status ==
              AtlasWorkflowTaskStatus.completed ||
          task.status ==
              AtlasWorkflowTaskStatus.cancelled) {
        return task;
      }

      final dependenciesCompleted =
          _dependenciesCompleted(
        task: task,
        tasks: workflow.tasks,
      );

      if (!dependenciesCompleted) {
        return task.copyWith(
          status:
              AtlasWorkflowTaskStatus.blocked,
        );
      }

      if (currentTime.isAfter(task.deadline)) {
        return task.copyWith(
          status:
              AtlasWorkflowTaskStatus.delayed,
        );
      }

      if (task.status ==
          AtlasWorkflowTaskStatus.blocked) {
        return task.copyWith(
          status:
              AtlasWorkflowTaskStatus.pending,
        );
      }

      return task;
    }).toList();

    final completedCount = tasks.where((task) {
      return task.status ==
          AtlasWorkflowTaskStatus.completed;
    }).length;

    final progress = tasks.isEmpty
        ? 0.0
        : tasks.fold<double>(
              0,
              (sum, task) =>
                  sum + task.progressPercent,
            ) /
            tasks.length;

    final allCompleted =
        tasks.isNotEmpty &&
            completedCount == tasks.length;

    final hasDelayed = tasks.any((task) {
      return task.status ==
          AtlasWorkflowTaskStatus.delayed;
    });

    final hasInProgress = tasks.any((task) {
      return task.status ==
          AtlasWorkflowTaskStatus.inProgress;
    });

    final status = allCompleted
        ? AtlasWorkflowStatus.completed
        : hasDelayed
            ? AtlasWorkflowStatus.delayed
            : hasInProgress
                ? AtlasWorkflowStatus.inProgress
                : AtlasWorkflowStatus.planned;

    final bottlenecks =
        _buildBottlenecks(
      workflowId: workflow.id,
      tasks: tasks,
      now: currentTime,
    );

    final replanning =
        _buildReplanningSuggestions(
      workflow: workflow,
      bottlenecks: bottlenecks,
      now: currentTime,
    );

    return workflow.copyWith(
      tasks: tasks,
      progressPercent:
          progress.clamp(0.0, 100.0).toDouble(),
      status: status,
      bottlenecks: bottlenecks,
      replanningSuggestions: replanning,
    );
  }

  bool _dependenciesCompleted({
    required AtlasWorkflowTask task,
    required List<AtlasWorkflowTask> tasks,
  }) {
    if (task.dependencies.isEmpty) {
      return true;
    }

    for (final dependencyId
        in task.dependencies) {
      final dependency = tasks
          .cast<AtlasWorkflowTask?>()
          .firstWhere(
            (item) => item?.id == dependencyId,
            orElse: () => null,
          );

      if (dependency == null ||
          dependency.status !=
              AtlasWorkflowTaskStatus
                  .completed) {
        return false;
      }
    }

    return true;
  }

  List<AtlasWorkflowBottleneck>
      _buildBottlenecks({
    required String workflowId,
    required List<AtlasWorkflowTask> tasks,
    required DateTime now,
  }) {
    final result =
        <AtlasWorkflowBottleneck>[];

    for (final task in tasks) {
      if (task.status !=
          AtlasWorkflowTaskStatus.delayed) {
        continue;
      }

      final delayDays =
          now.difference(task.deadline).inDays;

      result.add(
        AtlasWorkflowBottleneck(
          id:
              'bottleneck_${workflowId}_${task.id}',
          workflowId: workflowId,
          taskId: task.id,
          title:
              'Atraso em ${task.title}',
          description:
              'A tarefa ultrapassou o prazo planejado.',
          severity:
              delayDays >= 15
                  ? AtlasWorkflowBottleneckSeverity
                      .critical
                  : delayDays >= 7
                      ? AtlasWorkflowBottleneckSeverity
                          .high
                      : delayDays >= 3
                          ? AtlasWorkflowBottleneckSeverity
                              .medium
                          : AtlasWorkflowBottleneckSeverity
                              .low,
          delayDays: math.max(delayDays, 1),
          recommendation:
              'Revisar responsável, recursos e dependências antes de replanejar.',
        ),
      );
    }

    return result;
  }

  List<AtlasWorkflowReplanningSuggestion>
      _buildReplanningSuggestions({
    required AtlasWorkflow workflow,
    required List<AtlasWorkflowBottleneck>
        bottlenecks,
    required DateTime now,
  }) {
    if (bottlenecks.isEmpty) {
      return const [];
    }

    final maxDelay = bottlenecks.fold<int>(
      0,
      (current, item) =>
          math.max(current, item.delayDays),
    );

    return [
      AtlasWorkflowReplanningSuggestion(
        id:
            'replan_${workflow.id}_${now.millisecondsSinceEpoch}',
        workflowId: workflow.id,
        title:
            'Replanejar cronograma',
        description:
            'Adicionar $maxDelay dias aos prazos pendentes e redistribuir recursos.',
        newDeadline:
            workflow.deadline.add(
          Duration(days: maxDelay),
        ),
        priority: maxDelay >= 15
            ? AtlasWorkflowReplanningPriority
                .critical
            : maxDelay >= 7
                ? AtlasWorkflowReplanningPriority
                    .high
                : AtlasWorkflowReplanningPriority
                    .medium,
      ),
    ];
  }
}
