import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_attention.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';

class AtlasActionAttentionService {
  const AtlasActionAttentionService();

  List<AtlasActionAttention> build({
    required List<AtlasCommandCenterAction> actions,
    required Map<String, DateTime> latestUpdateDates,
  }) {
    final now = DateTime.now();
    final attentions = <AtlasActionAttention>[];

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      if (action.isOverdue) {
        attentions.add(
          AtlasActionAttention(
            id: '${action.id}_overdue',
            action: action,
            type: AtlasActionAttentionType.overdue,
            severity: AtlasActionAttentionSeverity.critical,
            title: 'Ação atrasada',
            description:
                'O prazo da ação "${action.title}" já foi ultrapassado.',
            recommendedAction:
                'Revise o prazo, registre o andamento e defina o próximo passo.',
            detectedAt: now,
          ),
        );
      } else {
        final remaining = action.remainingTime;

        if (remaining != null &&
            !remaining.isNegative &&
            remaining.inHours <= 24) {
          attentions.add(
            AtlasActionAttention(
              id: '${action.id}_due_soon',
              action: action,
              type: AtlasActionAttentionType.dueSoon,
              severity: AtlasActionAttentionSeverity.warning,
              title: 'Prazo próximo',
              description:
                  'A ação "${action.title}" vence em menos de 24 horas.',
              recommendedAction:
                  'Confirme o responsável e verifique se a execução está em dia.',
              detectedAt: now,
            ),
          );
        }
      }

      if (!action.hasResponsible) {
        attentions.add(
          AtlasActionAttention(
            id: '${action.id}_without_responsible',
            action: action,
            type: AtlasActionAttentionType.withoutResponsible,
            severity: AtlasActionAttentionSeverity.warning,
            title: 'Ação sem responsável',
            description:
                'A ação "${action.title}" ainda não possui responsável definido.',
            recommendedAction:
                'Defina uma pessoa responsável pela execução e pelo acompanhamento.',
            detectedAt: now,
          ),
        );
      }

      final lastUpdate =
          latestUpdateDates[action.id] ?? action.updatedAt;

      if (now.difference(lastUpdate).inDays >= 7) {
        attentions.add(
          AtlasActionAttention(
            id: '${action.id}_without_follow_up',
            action: action,
            type: AtlasActionAttentionType.withoutFollowUp,
            severity: AtlasActionAttentionSeverity.warning,
            title: 'Sem acompanhamento recente',
            description:
                'A ação "${action.title}" está há sete dias ou mais sem atualização.',
            recommendedAction:
                'Registre o andamento, impedimentos e o próximo passo.',
            detectedAt: now,
          ),
        );
      }

      if (action.status == AtlasCanonicalStatus.blocked) {
        attentions.add(
          AtlasActionAttention(
            id: '${action.id}_blocked',
            action: action,
            type: AtlasActionAttentionType.blocked,
            severity: AtlasActionAttentionSeverity.critical,
            title: 'Execução bloqueada',
            description:
                'A ação "${action.title}" está marcada como bloqueada.',
            recommendedAction:
                'Identifique o impedimento e defina uma ação para desbloqueio.',
            detectedAt: now,
          ),
        );
      }
    }

    attentions.sort((first, second) {
      final severityComparison = _severityWeight(
        second.severity,
      ).compareTo(
        _severityWeight(first.severity),
      );

      if (severityComparison != 0) {
        return severityComparison;
      }

      return first.action.title.compareTo(
        second.action.title,
      );
    });

    return List<AtlasActionAttention>.unmodifiable(attentions);
  }

  int _severityWeight(
    AtlasActionAttentionSeverity severity,
  ) {
    switch (severity) {
      case AtlasActionAttentionSeverity.information:
        return 1;
      case AtlasActionAttentionSeverity.warning:
        return 2;
      case AtlasActionAttentionSeverity.critical:
        return 3;
    }
  }
}
