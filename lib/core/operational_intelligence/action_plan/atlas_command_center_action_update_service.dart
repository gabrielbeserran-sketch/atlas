import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasCommandCenterActionUpdateService {
  AtlasCommandCenterActionUpdateService._();

  static final AtlasCommandCenterActionUpdateService instance =
      AtlasCommandCenterActionUpdateService._();

  static const String _storageKey =
      'atlas_command_center_action_updates_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasCommandCenterActionUpdate>> loadForAction(
    String actionId,
  ) async {
    final all = await _loadAll();

    return all
        .where((update) => update.actionId == actionId)
        .toList()
      ..sort(
        (first, second) =>
            second.createdAt.compareTo(first.createdAt),
      );
  }

  Future<Map<String, DateTime>> loadLatestDates() async {
    final all = await _loadAll();
    final result = <String, DateTime>{};

    for (final update in all) {
      final current = result[update.actionId];

      if (current == null || update.createdAt.isAfter(current)) {
        result[update.actionId] = update.createdAt;
      }
    }

    return result;
  }

  Future<AtlasCommandCenterActionUpdate> add({
    required AtlasCommandCenterAction action,
    required String note,
    required int progressPercent,
    required String responsibleName,
  }) async {
    final now = DateTime.now();
    final update = AtlasCommandCenterActionUpdate(
      id: 'action_update_${now.microsecondsSinceEpoch}',
      actionId: action.id,
      createdAt: now,
      progressPercent: progressPercent.clamp(0, 100),
      responsibleName: responsibleName.trim(),
      note: note.trim(),
    );

    final all = await _loadAll();
    all.add(update);
    await _saveAll(all);

    await AtlasEventBus.instance.publish(
      AtlasEvent(
        id: 'action_follow_up_${update.id}',
        type: AtlasEventType.taskUpdated,
        sourceModule: 'command_center_action_plan',
        title: 'Acompanhamento registrado',
        description:
            'Foi registrado um novo acompanhamento para a ação '
            '"${action.title}".',
        occurredAt: now,
        priority: _eventPriority(action),
        farmName: action.farmName,
        entityId: action.id,
        entityType: 'command_center_action',
        payload: <String, dynamic>{
          'actionId': action.id,
          'updateId': update.id,
          'progressPercent': update.progressPercent,
          'responsibleName': update.responsibleName,
          'note': update.note,
        },
        tags: <String>[
          'command_center',
          'action_plan',
          'follow_up',
        ],
      ),
    );

    return update;
  }

  Future<void> deleteForAction(String actionId) async {
    final all = await _loadAll()
      ..removeWhere((update) => update.actionId == actionId);

    await _saveAll(all);
  }

  Future<List<AtlasCommandCenterActionUpdate>>
      _loadAll() async {
    final encoded =
        await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasCommandCenterActionUpdate>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) =>
                AtlasCommandCenterActionUpdate.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasCommandCenterActionUpdate>[];
    }
  }

  Future<void> _saveAll(
    List<AtlasCommandCenterActionUpdate> updates,
  ) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(
        updates.map((update) => update.toMap()).toList(),
      ),
    );
  }

  AtlasEventPriority _eventPriority(
    AtlasCommandCenterAction action,
  ) {
    switch (action.priority.name) {
      case 'critical':
        return AtlasEventPriority.critical;
      case 'high':
        return AtlasEventPriority.high;
      case 'low':
        return AtlasEventPriority.low;
      default:
        return AtlasEventPriority.normal;
    }
  }
}
