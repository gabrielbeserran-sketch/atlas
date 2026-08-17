import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';

enum AtlasActionAttentionType {
  overdue,
  dueSoon,
  withoutResponsible,
  withoutFollowUp,
  blocked,
}

enum AtlasActionAttentionSeverity { information, warning, critical }

class AtlasActionAttention {
  const AtlasActionAttention({
    required this.id,
    required this.action,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.recommendedAction,
    required this.detectedAt,
  });

  final String id;
  final AtlasCommandCenterAction action;
  final AtlasActionAttentionType type;
  final AtlasActionAttentionSeverity severity;
  final String title;
  final String description;
  final String recommendedAction;
  final DateTime detectedAt;
}

String atlasActionAttentionTypeLabel(AtlasActionAttentionType type) {
  switch (type) {
    case AtlasActionAttentionType.overdue:
      return 'Atrasada';
    case AtlasActionAttentionType.dueSoon:
      return 'Prazo próximo';
    case AtlasActionAttentionType.withoutResponsible:
      return 'Sem responsável';
    case AtlasActionAttentionType.withoutFollowUp:
      return 'Sem acompanhamento';
    case AtlasActionAttentionType.blocked:
      return 'Bloqueada';
  }
}

String atlasActionAttentionSeverityLabel(
  AtlasActionAttentionSeverity severity,
) {
  switch (severity) {
    case AtlasActionAttentionSeverity.information:
      return 'Informação';
    case AtlasActionAttentionSeverity.warning:
      return 'Atenção';
    case AtlasActionAttentionSeverity.critical:
      return 'Crítica';
  }
}
