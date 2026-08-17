import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';

class AtlasGoalActionLink {
  const AtlasGoalActionLink({
    required this.id,
    required this.goalId,
    required this.actionId,
    required this.area,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  final String actionId;
  final AtlasOperationalArea area;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'goalId': goalId,
      'actionId': actionId,
      'area': area.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AtlasGoalActionLink.fromMap(Map<String, dynamic> map) {
    return AtlasGoalActionLink(
      id: map['id']?.toString() ?? '',
      goalId: map['goalId']?.toString() ?? '',
      actionId: map['actionId']?.toString() ?? '',
      area: AtlasOperationalArea.values.firstWhere(
        (value) => value.name == map['area']?.toString(),
        orElse: () => AtlasOperationalArea.general,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
