import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_decision.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_link.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_link_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_sync_result.dart';

class AtlasMeetingDecisionActionSyncService {
  AtlasMeetingDecisionActionSyncService._();

  static final AtlasMeetingDecisionActionSyncService instance =
      AtlasMeetingDecisionActionSyncService._();

  final AtlasMeetingDecisionActionLinkService _linkService =
      AtlasMeetingDecisionActionLinkService.instance;
  final AtlasExecutionMeetingService _meetingService =
      AtlasExecutionMeetingService.instance;
  final AtlasCommandCenterActionService _actionService =
      AtlasCommandCenterActionService.instance;
  final AtlasMeetingDecisionActionService _decisionActionService =
      AtlasMeetingDecisionActionService.instance;

  Future<AtlasMeetingDecisionActionSyncResult> synchronize({
    String? farmName,
    bool repairBrokenLinks = false,
  }) async {
    final links = await _linkService.loadAll();
    final meetings = await _meetingService.load(farmName: farmName);
    final actions = await _actionService.loadActions(farmName: farmName);

    final meetingsById = <String, AtlasExecutionMeeting>{
      for (final meeting in meetings) meeting.id: meeting,
    };
    final actionsById = <String, AtlasCommandCenterAction>{
      for (final action in actions) action.id: action,
    };

    var updatedDecisions = 0;
    var updatedActions = 0;
    var missingActions = 0;
    var repairedLinks = 0;

    for (final link in links) {
      var meeting = meetingsById[link.meetingId];
      var action = actionsById[link.actionId];

      if (meeting == null) {
        continue;
      }

      final decision = _findDecision(meeting, link);

      if (decision == null) {
        continue;
      }

      if (action == null) {
        missingActions += 1;

        if (repairBrokenLinks) {
          action = await _decisionActionService.createAction(
            meeting: meeting,
            decision: decision.copyWith(
              linkedActionId: null,
              clearLinkedActionId: true,
            ),
          );

          actionsById[action.id] = action;
          repairedLinks += 1;
        } else {
          continue;
        }
      }

      final actionIsCompleted = action.status == AtlasCanonicalStatus.completed;

      final syncedDecision = decision.copyWith(
        responsibleName: action.responsibleName,
        dueAt: action.dueAt,
        clearDueAt: action.dueAt == null,
        completed: actionIsCompleted,
        linkedActionId: action.id,
      );

      var syncedStatus = action.status;
      var syncedProgress = action.progressPercent;
      DateTime? syncedCompletedAt = action.completedAt;

      if (syncedDecision.completed) {
        syncedStatus = AtlasCanonicalStatus.completed;
        syncedProgress = 100;
        syncedCompletedAt ??= DateTime.now();
      }

      final syncedAction = action.copyWith(
        responsibleName: syncedDecision.responsibleName,
        dueAt: syncedDecision.dueAt,
        clearDueAt: syncedDecision.dueAt == null,
        status: syncedStatus,
        progressPercent: syncedProgress,
        completedAt: syncedCompletedAt,
        clearCompletedAt: syncedStatus != AtlasCanonicalStatus.completed,
        updatedAt: DateTime.now(),
      );

      if (!_sameDecision(decision, syncedDecision)) {
        meeting = meeting.copyWith(
          decisions: meeting.decisions
              .map((item) => item.id == decision.id ? syncedDecision : item)
              .toList(growable: false),
        );

        await _meetingService.save(meeting, source: 'sincronização automática');
        meetingsById[meeting.id] = meeting;
        updatedDecisions += 1;
      }

      if (!_sameAction(action, syncedAction)) {
        await _actionService.saveAction(
          syncedAction,
          source: 'sincronização automática',
        );
        actionsById[action.id] = syncedAction;
        updatedActions += 1;
      }
    }

    return AtlasMeetingDecisionActionSyncResult(
      checkedLinks: links.length,
      updatedDecisions: updatedDecisions,
      updatedActions: updatedActions,
      missingActions: missingActions,
      repairedLinks: repairedLinks,
      syncedAt: DateTime.now(),
    );
  }

  AtlasExecutionMeetingDecision? _findDecision(
    AtlasExecutionMeeting meeting,
    AtlasMeetingDecisionActionLink link,
  ) {
    for (final decision in meeting.decisions) {
      if (decision.id == link.decisionId) {
        return decision;
      }
    }

    return null;
  }

  bool _sameDecision(
    AtlasExecutionMeetingDecision first,
    AtlasExecutionMeetingDecision second,
  ) {
    return first.completed == second.completed &&
        first.responsibleName == second.responsibleName &&
        first.dueAt == second.dueAt &&
        first.linkedActionId == second.linkedActionId;
  }

  bool _sameAction(
    AtlasCommandCenterAction first,
    AtlasCommandCenterAction second,
  ) {
    return first.status == second.status &&
        first.progressPercent == second.progressPercent &&
        first.responsibleName == second.responsibleName &&
        first.dueAt == second.dueAt &&
        first.completedAt == second.completedAt;
  }
}
