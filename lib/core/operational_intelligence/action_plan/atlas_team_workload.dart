import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_team_member.dart';

class AtlasTeamWorkload {
  const AtlasTeamWorkload({
    required this.member,
    required this.actions,
    required this.openActions,
    required this.overdueActions,
    required this.criticalActions,
    required this.dueSoonActions,
    required this.blockedActions,
    required this.averageProgressPercent,
    required this.workloadScore,
  });

  final AtlasTeamMember member;
  final List<AtlasCommandCenterAction> actions;
  final int openActions;
  final int overdueActions;
  final int criticalActions;
  final int dueSoonActions;
  final int blockedActions;
  final double averageProgressPercent;
  final double workloadScore;
}
