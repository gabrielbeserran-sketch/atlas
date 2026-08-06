import 'package:projeto_atlas/features/command_center/domain/models/atlas_command_center_data.dart';

class AtlasCommandEngine {
  AtlasDailyBrief buildBrief(AtlasCommandCenterState state) {
    final int criticalCount = state.items
        .where(
          (AtlasCommandItem item) =>
              item.isOpen && item.priority == AtlasCommandPriority.critical,
        )
        .length;
    final int openCount =
        state.items.where((AtlasCommandItem item) => item.isOpen).length;
    final int overdueCount =
        state.items.where((AtlasCommandItem item) => item.isOverdue).length;
    final int completedCount = state.items
        .where(
          (AtlasCommandItem item) =>
              item.status == AtlasCommandItemStatus.completed,
        )
        .length;

    final int rawScore = 100 -
        (criticalCount * 24) -
        (overdueCount * 16) -
        ((openCount - criticalCount) * 5);
    final int attentionScore = rawScore.clamp(0, 100).toInt();

    final String message;
    if (openCount == 0) {
      message =
          'Tudo está sob controle. Não existem prioridades abertas no momento.';
    } else {
      message =
          'Hoje existem $criticalCount prioridades críticas, $overdueCount tarefas vencidas e $openCount itens abertos. Concentre-se primeiro nos pontos de maior impacto.';
    }

    return AtlasDailyBrief(
      message: message,
      criticalCount: criticalCount,
      openCount: openCount,
      overdueCount: overdueCount,
      completedCount: completedCount,
      attentionScore: attentionScore,
    );
  }

  List<AtlasCommandItem> orderedItems(AtlasCommandCenterState state) {
    final List<AtlasCommandItem> result =
        List<AtlasCommandItem>.from(state.items);
    result.sort((AtlasCommandItem first, AtlasCommandItem second) {
      if (first.isOpen != second.isOpen) {
        return first.isOpen ? -1 : 1;
      }
      if (first.isOverdue != second.isOverdue) {
        return first.isOverdue ? -1 : 1;
      }
      final int priorityComparison =
          first.priority.index.compareTo(second.priority.index);
      if (priorityComparison != 0) {
        return priorityComparison;
      }
      return second.createdAt.compareTo(first.createdAt);
    });
    return result;
  }
}
