import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_monitoring_item.dart';

class AtlasMeetingDecisionMonitoringService {
  const AtlasMeetingDecisionMonitoringService();

  List<AtlasMeetingDecisionMonitoringItem> build({
    required List<AtlasExecutionMeeting> meetings,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final items = <AtlasMeetingDecisionMonitoringItem>[];

    for (final meeting in meetings) {
      for (final decision in meeting.decisions) {
        final statuses = <AtlasMeetingDecisionMonitoringStatus>[];

        if (decision.completed) {
          statuses.add(AtlasMeetingDecisionMonitoringStatus.completed);
        } else {
          statuses.add(AtlasMeetingDecisionMonitoringStatus.pending);
        }

        int? daysUntilDue;
        final dueAt = decision.dueAt;

        if (!decision.completed && dueAt != null) {
          final difference = dueAt.difference(reference);
          daysUntilDue = difference.inDays;

          if (difference.isNegative) {
            statuses.add(AtlasMeetingDecisionMonitoringStatus.overdue);
          } else if (difference.inHours <= 48) {
            statuses.add(AtlasMeetingDecisionMonitoringStatus.dueSoon);
          }
        }

        if (decision.responsibleName.trim().isEmpty) {
          statuses.add(AtlasMeetingDecisionMonitoringStatus.withoutResponsible);
        }

        if (decision.linkedActionId?.trim().isEmpty != false) {
          statuses.add(
            AtlasMeetingDecisionMonitoringStatus.withoutLinkedAction,
          );
        }

        items.add(
          AtlasMeetingDecisionMonitoringItem(
            id: '${meeting.id}_${decision.id}',
            meeting: meeting,
            decision: decision,
            statuses: List<AtlasMeetingDecisionMonitoringStatus>.unmodifiable(
              statuses,
            ),
            daysUntilDue: daysUntilDue,
          ),
        );
      }
    }

    items.sort((first, second) {
      final firstWeight = _weight(first);
      final secondWeight = _weight(second);

      if (firstWeight != secondWeight) {
        return secondWeight.compareTo(firstWeight);
      }

      final firstDue = first.decision.dueAt ?? DateTime(9999);
      final secondDue = second.decision.dueAt ?? DateTime(9999);

      return firstDue.compareTo(secondDue);
    });

    return List<AtlasMeetingDecisionMonitoringItem>.unmodifiable(items);
  }

  int _weight(AtlasMeetingDecisionMonitoringItem item) {
    if (item.isOverdue) {
      return 5;
    }

    if (item.isDueSoon) {
      return 4;
    }

    if (!item.hasResponsible) {
      return 3;
    }

    if (!item.hasLinkedAction) {
      return 2;
    }

    if (!item.isCompleted) {
      return 1;
    }

    return 0;
  }
}
