import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_audit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutionMeetingService {
  AtlasExecutionMeetingService._();

  static final AtlasExecutionMeetingService instance =
      AtlasExecutionMeetingService._();

  static const String _storageKey = 'atlas_execution_meetings_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasExecutionAuditService _auditService =
      AtlasExecutionAuditService.instance;

  Future<List<AtlasExecutionMeeting>> load({String? farmName}) async {
    final all = await _loadAll();
    final normalizedFarm = farmName?.trim().toLowerCase();

    final filtered =
        all.where((meeting) {
          if (normalizedFarm == null || normalizedFarm.isEmpty) {
            return true;
          }

          return meeting.farmName?.trim().toLowerCase() == normalizedFarm;
        }).toList()..sort(
          (first, second) => second.meetingAt.compareTo(first.meetingAt),
        );

    return filtered;
  }

  Future<void> save(
    AtlasExecutionMeeting meeting, {
    String source = 'reunião de execução',
  }) async {
    final all = await _loadAll();
    final index = all.indexWhere((item) => item.id == meeting.id);
    final previous = index == -1 ? null : all[index];

    if (index == -1) {
      all.add(meeting);
    } else {
      all[index] = meeting;
    }

    await _saveAll(all);

    if (previous != null) {
      await _auditMeetingChanges(
        previous: previous,
        current: meeting,
        source: source,
      );
    }

    await AtlasEventBus.instance.publish(
      AtlasEvent(
        id:
            'execution_meeting_${meeting.id}_'
            '${DateTime.now().microsecondsSinceEpoch}',
        type: AtlasEventType.systemUpdated,
        sourceModule: 'command_center_action_plan',
        title: meeting.closed
            ? 'Reunião de execução encerrada'
            : 'Reunião de execução atualizada',
        description:
            'A reunião "${meeting.title}" possui '
            '${meeting.decisions.length} decisão(ões) registrada(s).',
        occurredAt: DateTime.now(),
        priority: meeting.pendingDecisionCount > 0
            ? AtlasEventPriority.high
            : AtlasEventPriority.normal,
        farmName: meeting.farmName,
        entityId: meeting.id,
        entityType: 'execution_meeting',
        payload: <String, dynamic>{
          'meetingAt': meeting.meetingAt.toIso8601String(),
          'participants': meeting.participants,
          'decisionCount': meeting.decisions.length,
          'pendingDecisionCount': meeting.pendingDecisionCount,
          'closed': meeting.closed,
        },
        tags: const <String>[
          'command_center',
          'action_plan',
          'execution_meeting',
        ],
      ),
    );
  }

  Future<void> _auditMeetingChanges({
    required AtlasExecutionMeeting previous,
    required AtlasExecutionMeeting current,
    required String source,
  }) async {
    final previousById = {
      for (final decision in previous.decisions) decision.id: decision,
    };

    for (final decision in current.decisions) {
      final old = previousById[decision.id];

      if (old == null) {
        await _auditService.record(
          entityType: 'decision',
          entityId: decision.id,
          entityTitle: decision.title,
          fieldName: 'Criação',
          oldValue: null,
          newValue: 'Decisão criada',
          source: source,
          farmName: current.farmName,
        );
        continue;
      }

      final changes = <String, List<Object?>>{
        'Título': [old.title, decision.title],
        'Descrição': [old.description, decision.description],
        'Responsável': [old.responsibleName, decision.responsibleName],
        'Prazo': [old.dueAt, decision.dueAt],
        'Conclusão': [old.completed, decision.completed],
        'Ação vinculada': [old.linkedActionId, decision.linkedActionId],
      };

      for (final change in changes.entries) {
        await _auditService.record(
          entityType: 'decision',
          entityId: decision.id,
          entityTitle: decision.title,
          fieldName: change.key,
          oldValue: change.value.first,
          newValue: change.value.last,
          source: source,
          farmName: current.farmName,
        );
      }
    }
  }

  Future<void> delete(String id) async {
    final all = await _loadAll()
      ..removeWhere((item) => item.id == id);

    await _saveAll(all);
  }

  Future<List<AtlasExecutionMeeting>> _loadAll() async {
    final encoded = await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasExecutionMeeting>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasExecutionMeeting.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasExecutionMeeting>[];
    }
  }

  Future<void> _saveAll(List<AtlasExecutionMeeting> meetings) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(meetings.map((item) => item.toMap()).toList()),
    );
  }
}
