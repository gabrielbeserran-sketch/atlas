import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/models/atlas_workflow_data.dart';

class AtlasWorkflowEventService {
  const AtlasWorkflowEventService({
    this.eventFactory = const AtlasEventFactory(),
  });

  final AtlasEventFactory eventFactory;

  Future<void> publishWorkflowCreated({required AtlasWorkflow workflow}) async {
    final events = <AtlasEvent>[
      _workflowEvent(
        type: AtlasEventType.workflowCreated,
        title: 'Workflow criado',
        workflow: workflow,
      ),
      ...workflow.tasks.map(
        (task) => _taskEvent(
          type: AtlasEventType.taskCreated,
          title: 'Tarefa criada',
          workflow: workflow,
          task: task,
        ),
      ),
    ];

    await AtlasEventBus.instance.publishAll(events);
  }

  Future<void> publishWorkflowChanged({
    required AtlasWorkflow previousWorkflow,
    required AtlasWorkflow updatedWorkflow,
  }) async {
    final events = <AtlasEvent>[];

    final workflowType = _workflowEventType(
      previousWorkflow: previousWorkflow,
      updatedWorkflow: updatedWorkflow,
    );

    events.add(
      _workflowEvent(
        type: workflowType,
        title: _workflowTitle(workflowType),
        workflow: updatedWorkflow,
        extraPayload: <String, dynamic>{
          'previousStatus': previousWorkflow.status.name,
          'previousProgressPercent': previousWorkflow.progressPercent,
        },
      ),
    );

    for (final updatedTask in updatedWorkflow.tasks) {
      final previousTask = previousWorkflow.tasks
          .cast<AtlasWorkflowTask?>()
          .firstWhere((item) => item?.id == updatedTask.id, orElse: () => null);

      if (previousTask == null) {
        events.add(
          _taskEvent(
            type: AtlasEventType.taskCreated,
            title: 'Tarefa criada',
            workflow: updatedWorkflow,
            task: updatedTask,
          ),
        );
        continue;
      }

      if (!_taskChanged(previousTask, updatedTask)) {
        continue;
      }

      final taskType = _taskEventType(
        previousTask: previousTask,
        updatedTask: updatedTask,
      );

      events.add(
        _taskEvent(
          type: taskType,
          title: _taskTitle(taskType),
          workflow: updatedWorkflow,
          task: updatedTask,
          extraPayload: <String, dynamic>{
            'previousStatus': previousTask.status.name,
            'previousProgressPercent': previousTask.progressPercent,
            'previousResponsibleName': previousTask.responsibleName,
            'previousDeadline': previousTask.deadline.toIso8601String(),
          },
        ),
      );
    }

    await AtlasEventBus.instance.publishAll(events);
  }

  AtlasEventType _workflowEventType({
    required AtlasWorkflow previousWorkflow,
    required AtlasWorkflow updatedWorkflow,
  }) {
    if (updatedWorkflow.status == AtlasWorkflowStatus.completed &&
        previousWorkflow.status != AtlasWorkflowStatus.completed) {
      return AtlasEventType.workflowCompleted;
    }

    if (updatedWorkflow.status == AtlasWorkflowStatus.delayed &&
        previousWorkflow.status != AtlasWorkflowStatus.delayed) {
      return AtlasEventType.workflowDelayed;
    }

    return AtlasEventType.workflowUpdated;
  }

  AtlasEventType _taskEventType({
    required AtlasWorkflowTask previousTask,
    required AtlasWorkflowTask updatedTask,
  }) {
    if (updatedTask.status == AtlasWorkflowTaskStatus.completed &&
        previousTask.status != AtlasWorkflowTaskStatus.completed) {
      return AtlasEventType.taskCompleted;
    }

    if (updatedTask.status == AtlasWorkflowTaskStatus.delayed &&
        previousTask.status != AtlasWorkflowTaskStatus.delayed) {
      return AtlasEventType.taskDelayed;
    }

    return AtlasEventType.taskUpdated;
  }

  AtlasEvent _workflowEvent({
    required AtlasEventType type,
    required String title,
    required AtlasWorkflow workflow,
    Map<String, dynamic> extraPayload = const <String, dynamic>{},
  }) {
    return eventFactory.create(
      type: type,
      sourceModule: 'workflow_engine',
      title: title,
      description:
          '${workflow.title}: '
          '${workflow.progressPercent.toStringAsFixed(0)}% concluído.',
      priority: _workflowPriority(workflow),
      farmId: workflow.farmName,
      farmName: workflow.farmName,
      entityId: workflow.id,
      entityType: 'atlas_workflow',
      payload: <String, dynamic>{
        'executionId': workflow.executionId,
        'title': workflow.title,
        'description': workflow.description,
        'category': workflow.category.name,
        'startedAt': workflow.startedAt.toIso8601String(),
        'deadline': workflow.deadline.toIso8601String(),
        'status': workflow.status.name,
        'progressPercent': workflow.progressPercent,
        'taskCount': workflow.tasks.length,
        'bottleneckCount': workflow.bottlenecks.length,
        ...extraPayload,
      },
      tags: <String>['workflow', workflow.status.name, workflow.category.name],
    );
  }

  AtlasEvent _taskEvent({
    required AtlasEventType type,
    required String title,
    required AtlasWorkflow workflow,
    required AtlasWorkflowTask task,
    Map<String, dynamic> extraPayload = const <String, dynamic>{},
  }) {
    return eventFactory.create(
      type: type,
      sourceModule: 'workflow_engine',
      title: title,
      description:
          '${task.title}: '
          '${task.progressPercent.toStringAsFixed(0)}% concluído.',
      priority: _taskPriority(task),
      farmId: workflow.farmName,
      farmName: workflow.farmName,
      entityId: task.id,
      entityType: 'atlas_workflow_task',
      payload: <String, dynamic>{
        'workflowId': workflow.id,
        'workflowTitle': workflow.title,
        'position': task.position,
        'title': task.title,
        'description': task.description,
        'responsibleName': task.responsibleName,
        'startDate': task.startDate.toIso8601String(),
        'deadline': task.deadline.toIso8601String(),
        'status': task.status.name,
        'progressPercent': task.progressPercent,
        'dependencies': task.dependencies,
        'expectedResult': task.expectedResult,
        'notes': task.notes,
        ...extraPayload,
      },
      tags: <String>['workflow', 'task', task.status.name],
    );
  }

  bool _taskChanged(AtlasWorkflowTask previous, AtlasWorkflowTask updated) {
    return previous.status != updated.status ||
        previous.progressPercent != updated.progressPercent ||
        previous.responsibleName != updated.responsibleName ||
        previous.deadline != updated.deadline ||
        previous.startDate != updated.startDate ||
        previous.notes != updated.notes;
  }

  AtlasEventPriority _workflowPriority(AtlasWorkflow workflow) {
    if (workflow.status == AtlasWorkflowStatus.delayed) {
      return AtlasEventPriority.high;
    }

    if (workflow.bottlenecks.any(
      (item) => item.severity == AtlasWorkflowBottleneckSeverity.critical,
    )) {
      return AtlasEventPriority.critical;
    }

    return AtlasEventPriority.normal;
  }

  AtlasEventPriority _taskPriority(AtlasWorkflowTask task) {
    if (task.status == AtlasWorkflowTaskStatus.delayed) {
      return AtlasEventPriority.high;
    }

    if (task.status == AtlasWorkflowTaskStatus.blocked) {
      return AtlasEventPriority.high;
    }

    return AtlasEventPriority.normal;
  }

  String _workflowTitle(AtlasEventType type) {
    switch (type) {
      case AtlasEventType.workflowCompleted:
        return 'Workflow concluído';

      case AtlasEventType.workflowDelayed:
        return 'Workflow atrasado';

      default:
        return 'Workflow atualizado';
    }
  }

  String _taskTitle(AtlasEventType type) {
    switch (type) {
      case AtlasEventType.taskCompleted:
        return 'Tarefa concluída';

      case AtlasEventType.taskDelayed:
        return 'Tarefa atrasada';

      default:
        return 'Tarefa atualizada';
    }
  }
}
