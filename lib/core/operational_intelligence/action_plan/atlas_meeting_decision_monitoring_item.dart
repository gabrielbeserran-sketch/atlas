import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_decision.dart';

enum AtlasMeetingDecisionMonitoringStatus {
  pending,
  dueSoon,
  overdue,
  completed,
  withoutResponsible,
  withoutLinkedAction,
}

class AtlasMeetingDecisionMonitoringItem {
  const AtlasMeetingDecisionMonitoringItem({
    required this.id,
    required this.meeting,
    required this.decision,
    required this.statuses,
    required this.daysUntilDue,
  });

  final String id;
  final AtlasExecutionMeeting meeting;
  final AtlasExecutionMeetingDecision decision;
  final List<AtlasMeetingDecisionMonitoringStatus> statuses;
  final int? daysUntilDue;

  bool get isCompleted => decision.completed;

  bool get isOverdue => statuses.contains(
        AtlasMeetingDecisionMonitoringStatus.overdue,
      );

  bool get isDueSoon => statuses.contains(
        AtlasMeetingDecisionMonitoringStatus.dueSoon,
      );

  bool get hasResponsible =>
      decision.responsibleName.trim().isNotEmpty;

  bool get hasLinkedAction =>
      decision.linkedActionId?.trim().isNotEmpty == true;
}

String atlasMeetingDecisionMonitoringStatusLabel(
  AtlasMeetingDecisionMonitoringStatus status,
) {
  switch (status) {
    case AtlasMeetingDecisionMonitoringStatus.pending:
      return 'Pendente';
    case AtlasMeetingDecisionMonitoringStatus.dueSoon:
      return 'Prazo próximo';
    case AtlasMeetingDecisionMonitoringStatus.overdue:
      return 'Atrasada';
    case AtlasMeetingDecisionMonitoringStatus.completed:
      return 'Concluída';
    case AtlasMeetingDecisionMonitoringStatus.withoutResponsible:
      return 'Sem responsável';
    case AtlasMeetingDecisionMonitoringStatus.withoutLinkedAction:
      return 'Sem ação vinculada';
  }
}
