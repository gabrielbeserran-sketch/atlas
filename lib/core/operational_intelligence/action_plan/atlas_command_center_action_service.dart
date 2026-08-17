import 'dart:convert';

import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_audit_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasCommandCenterActionService {
  AtlasCommandCenterActionService._();

  static final AtlasCommandCenterActionService instance =
      AtlasCommandCenterActionService._();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasExecutionAuditService _auditService =
      AtlasExecutionAuditService.instance;

  static const String _storageKey = 'atlas_command_center_actions_v1';

  Future<List<AtlasCommandCenterAction>> loadActions({String? farmName}) async {
    final encoded = await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasCommandCenterAction>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final actions = decoded
          .map(
            (item) => AtlasCommandCenterAction.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((action) => _matchesFarm(action.farmName, farmName))
          .toList();

      actions.sort(_compareActions);
      return actions;
    } catch (_) {
      return <AtlasCommandCenterAction>[];
    }
  }

  Future<AtlasCommandCenterAction> createFromPriority({
    required AtlasOperationalPriority priority,
    DateTime? dueAt,
  }) async {
    final now = DateTime.now();
    final action = AtlasCommandCenterAction(
      id: 'action_${priority.id}_${now.microsecondsSinceEpoch}',
      title: priority.title,
      description: priority.description,
      recommendedAction: priority.recommendedAction,
      priority: priority.priority,
      status: AtlasCanonicalStatus.pending,
      farmName: priority.farmName,
      sourceModule: priority.sourceModule,
      sourceEventId: priority.event.eventId,
      createdAt: now,
      updatedAt: now,
      dueAt: dueAt ?? _defaultDueAt(priority.priority, now),
      completedAt: null,
      notes: '',
      responsibleName: '',
      progressPercent: 0,
      expectedFinancialImpact: 0,
    );

    final all = await _loadAllActions();

    final duplicate = all.any(
      (existing) =>
          existing.sourceEventId == action.sourceEventId &&
          existing.status != AtlasCanonicalStatus.completed &&
          existing.status != AtlasCanonicalStatus.cancelled,
    );

    if (duplicate) {
      return all.firstWhere(
        (existing) =>
            existing.sourceEventId == action.sourceEventId &&
            existing.status != AtlasCanonicalStatus.completed &&
            existing.status != AtlasCanonicalStatus.cancelled,
      );
    }

    all.add(action);
    await _saveAllActions(all);
    await _publishActionEvent(
      action: action,
      type: AtlasEventType.taskCreated,
      title: 'Ação criada no Command Center',
      description:
          'A prioridade "${action.title}" foi adicionada ao plano de ação.',
    );
    return action;
  }

  Future<void> saveAction(
    AtlasCommandCenterAction action, {
    String source = 'plano de ação',
  }) async {
    final all = await _loadAllActions();
    final index = all.indexWhere((item) => item.id == action.id);
    final previous = index == -1 ? null : all[index];

    final updated = action.copyWith(
      updatedAt: DateTime.now(),
      completedAt: action.status == AtlasCanonicalStatus.completed
          ? action.completedAt ?? DateTime.now()
          : action.completedAt,
      clearCompletedAt: action.status != AtlasCanonicalStatus.completed,
      progressPercent: action.status == AtlasCanonicalStatus.completed
          ? 100
          : action.progressPercent,
    );

    if (index == -1) {
      all.add(updated);
    } else {
      all[index] = updated;
    }

    await _saveAllActions(all);

    if (previous != null) {
      await _auditActionChanges(
        previous: previous,
        current: updated,
        source: source,
      );
    }

    final eventType = updated.status == AtlasCanonicalStatus.completed
        ? AtlasEventType.taskCompleted
        : updated.isOverdue
        ? AtlasEventType.taskDelayed
        : AtlasEventType.taskUpdated;

    await _publishActionEvent(
      action: updated,
      type: eventType,
      title: updated.status == AtlasCanonicalStatus.completed
          ? 'Ação concluída'
          : updated.isOverdue
          ? 'Ação atrasada'
          : 'Ação atualizada',
      description:
          'A ação "${updated.title}" agora está com status '
          '"${atlasCanonicalStatusLabel(updated.status)}".',
    );
  }

  Future<void> _auditActionChanges({
    required AtlasCommandCenterAction previous,
    required AtlasCommandCenterAction current,
    required String source,
  }) async {
    final changes = <String, List<Object?>>{
      'Título': [previous.title, current.title],
      'Descrição': [previous.description, current.description],
      'Recomendação': [previous.recommendedAction, current.recommendedAction],
      'Responsável': [previous.responsibleName, current.responsibleName],
      'Identificador do responsável': [
        previous.responsibleId,
        current.responsibleId,
      ],
      'Prazo': [previous.dueAt, current.dueAt],
      'Status': [previous.status.name, current.status.name],
      'Progresso': [previous.progressPercent, current.progressPercent],
      'Observações': [previous.notes, current.notes],
    };

    for (final change in changes.entries) {
      await _auditService.record(
        entityType: 'action',
        entityId: current.id,
        entityTitle: current.title,
        fieldName: change.key,
        oldValue: change.value.first,
        newValue: change.value.last,
        source: source,
        farmName: current.farmName,
      );
    }
  }

  Future<void> deleteAction(String id) async {
    final all = await _loadAllActions();
    final action = all.cast<AtlasCommandCenterAction?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );

    all.removeWhere((item) => item.id == id);
    await _saveAllActions(all);

    if (action != null) {
      await _publishActionEvent(
        action: action,
        type: AtlasEventType.taskUpdated,
        title: 'Ação removida do plano',
        description: 'A ação "${action.title}" foi removida do plano de ação.',
      );
    }
  }

  Future<List<AtlasCommandCenterAction>> _loadAllActions() async {
    final encoded = await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasCommandCenterAction>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasCommandCenterAction.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasCommandCenterAction>[];
    }
  }

  Future<void> _saveAllActions(List<AtlasCommandCenterAction> actions) async {
    final encoded = jsonEncode(
      actions.map((action) => action.toMap()).toList(),
    );

    await _preferences.setString(_storageKey, encoded);
  }

  bool _matchesFarm(String? actionFarm, String? requestedFarm) {
    final normalizedRequested = requestedFarm?.trim().toLowerCase();

    if (normalizedRequested == null || normalizedRequested.isEmpty) {
      return true;
    }

    return actionFarm?.trim().toLowerCase() == normalizedRequested;
  }

  int _compareActions(
    AtlasCommandCenterAction first,
    AtlasCommandCenterAction second,
  ) {
    final statusComparison = _statusWeight(
      first.status,
    ).compareTo(_statusWeight(second.status));

    if (statusComparison != 0) {
      return statusComparison;
    }

    final priorityComparison = _priorityWeight(
      second.priority,
    ).compareTo(_priorityWeight(first.priority));

    if (priorityComparison != 0) {
      return priorityComparison;
    }

    final firstDue = first.dueAt ?? DateTime(9999);
    final secondDue = second.dueAt ?? DateTime(9999);

    return firstDue.compareTo(secondDue);
  }

  int _statusWeight(AtlasCanonicalStatus status) {
    switch (status) {
      case AtlasCanonicalStatus.pending:
        return 1;
      case AtlasCanonicalStatus.inProgress:
        return 2;
      case AtlasCanonicalStatus.blocked:
        return 3;
      case AtlasCanonicalStatus.completed:
        return 4;
      case AtlasCanonicalStatus.cancelled:
        return 5;
    }
  }

  int _priorityWeight(AtlasCanonicalPriority priority) {
    switch (priority) {
      case AtlasCanonicalPriority.low:
        return 1;
      case AtlasCanonicalPriority.medium:
        return 2;
      case AtlasCanonicalPriority.high:
        return 3;
      case AtlasCanonicalPriority.critical:
        return 4;
    }
  }

  Future<void> _publishActionEvent({
    required AtlasCommandCenterAction action,
    required AtlasEventType type,
    required String title,
    required String description,
  }) async {
    final now = DateTime.now();

    await AtlasEventBus.instance.publish(
      AtlasEvent(
        id: 'command_center_action_${action.id}_${now.microsecondsSinceEpoch}',
        type: type,
        sourceModule: 'command_center_action_plan',
        title: title,
        description: description,
        occurredAt: now,
        priority: _eventPriority(action.priority),
        farmName: action.farmName,
        entityId: action.id,
        entityType: 'command_center_action',
        payload: <String, dynamic>{
          'actionId': action.id,
          'status': action.status.name,
          'priority': action.priority.name,
          'dueAt': action.dueAt?.toIso8601String(),
          'sourceModule': action.sourceModule,
          'sourceEventId': action.sourceEventId,
          'notes': action.notes,
        },
        tags: <String>[
          'command_center',
          'action_plan',
          action.status.name,
          action.priority.name,
        ],
      ),
    );
  }

  AtlasEventPriority _eventPriority(AtlasCanonicalPriority priority) {
    switch (priority) {
      case AtlasCanonicalPriority.low:
        return AtlasEventPriority.low;
      case AtlasCanonicalPriority.medium:
        return AtlasEventPriority.normal;
      case AtlasCanonicalPriority.high:
        return AtlasEventPriority.high;
      case AtlasCanonicalPriority.critical:
        return AtlasEventPriority.critical;
    }
  }

  DateTime _defaultDueAt(AtlasCanonicalPriority priority, DateTime now) {
    switch (priority) {
      case AtlasCanonicalPriority.critical:
        return now.add(const Duration(hours: 4));
      case AtlasCanonicalPriority.high:
        return now.add(const Duration(days: 1));
      case AtlasCanonicalPriority.medium:
        return now.add(const Duration(days: 7));
      case AtlasCanonicalPriority.low:
        return now.add(const Duration(days: 30));
    }
  }
}
