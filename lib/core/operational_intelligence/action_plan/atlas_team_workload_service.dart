import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_workload.dart';

class AtlasTeamWorkloadService {
  const AtlasTeamWorkloadService();

  List<AtlasTeamWorkload> build({
    required List<AtlasTeamMember> members,
    required List<AtlasCommandCenterAction> actions,
  }) {
    final workloads = members.map((member) {
      final memberActions = actions.where((action) {
        if (action.responsibleId != null) {
          return action.responsibleId == member.id;
        }

        return action.responsibleName
                .trim()
                .toLowerCase() ==
            member.name.trim().toLowerCase();
      }).toList();

      final open = memberActions
          .where((action) => action.isOpen)
          .length;
      final overdue = memberActions
          .where((action) => action.isOverdue)
          .length;
      final critical = memberActions
          .where(
            (action) =>
                action.priority ==
                AtlasCanonicalPriority.critical,
          )
          .length;
      final dueSoon = memberActions.where((action) {
        final remaining = action.remainingTime;

        return remaining != null &&
            !remaining.isNegative &&
            remaining.inHours <= 48;
      }).length;
      final blocked = memberActions
          .where(
            (action) =>
                action.status ==
                AtlasCanonicalStatus.blocked,
          )
          .length;

      final averageProgress = memberActions.isEmpty
          ? 0.0
          : memberActions
                  .map((action) => action.progressPercent)
                  .reduce((first, second) => first + second) /
              memberActions.length;

      final score = (
        open * 10 +
        overdue * 25 +
        critical * 20 +
        dueSoon * 12 +
        blocked * 18
      ).toDouble();

      return AtlasTeamWorkload(
        member: member,
        actions: List<AtlasCommandCenterAction>.unmodifiable(
          memberActions,
        ),
        openActions: open,
        overdueActions: overdue,
        criticalActions: critical,
        dueSoonActions: dueSoon,
        blockedActions: blocked,
        averageProgressPercent: averageProgress,
        workloadScore: score,
      );
    }).toList()
      ..sort(
        (first, second) =>
            second.workloadScore.compareTo(
          first.workloadScore,
        ),
      );

    return List<AtlasTeamWorkload>.unmodifiable(
      workloads,
    );
  }
}
