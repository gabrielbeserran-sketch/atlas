import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_decision.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_link.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_link_service.dart';

class AtlasMeetingDecisionActionService {
  AtlasMeetingDecisionActionService._();

  static final AtlasMeetingDecisionActionService instance =
      AtlasMeetingDecisionActionService._();

  final AtlasCommandCenterActionService _actionService =
      AtlasCommandCenterActionService.instance;
  final AtlasMeetingDecisionActionLinkService _linkService =
      AtlasMeetingDecisionActionLinkService.instance;

  Future<AtlasCommandCenterAction> createAction({
    required AtlasExecutionMeeting meeting,
    required AtlasExecutionMeetingDecision decision,
  }) async {
    final existingLink = await _linkService.findByDecision(decision.id);

    if (existingLink != null) {
      final actions = await _actionService.loadActions(
        farmName: meeting.farmName,
      );

      for (final action in actions) {
        if (action.id == existingLink.actionId) {
          return action;
        }
      }
    }

    final now = DateTime.now();
    final action = AtlasCommandCenterAction(
      id: 'meeting_action_${decision.id}',
      title: decision.title,
      description: decision.description.isEmpty
          ? 'Decisão registrada na reunião "${meeting.title}".'
          : decision.description,
      recommendedAction: 'Executar a decisão definida na reunião.',
      priority: AtlasCanonicalPriority.high,
      status: decision.completed
          ? AtlasCanonicalStatus.completed
          : AtlasCanonicalStatus.pending,
      farmName: meeting.farmName,
      sourceModule: 'execution_meeting',
      sourceEventId: decision.id,
      createdAt: now,
      updatedAt: now,
      dueAt: decision.dueAt,
      completedAt: decision.completed ? now : null,
      notes: 'Origem: reunião ${meeting.title}.',
      responsibleName: decision.responsibleName,
      progressPercent: decision.completed ? 100 : 0,
      expectedFinancialImpact: 0,
    );

    await _actionService.saveAction(action);

    await _linkService.save(
      AtlasMeetingDecisionActionLink(
        meetingId: meeting.id,
        decisionId: decision.id,
        actionId: action.id,
        createdAt: now,
      ),
    );

    return action;
  }
}
