import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_analytics_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_weekly_review.dart';

class AtlasExecutionWeeklyReviewBuilder {
  const AtlasExecutionWeeklyReviewBuilder({
    AtlasCommandCenterActionAnalyticsService analyticsService =
        const AtlasCommandCenterActionAnalyticsService(),
  }) : _analyticsService = analyticsService;

  final AtlasCommandCenterActionAnalyticsService _analyticsService;

  AtlasExecutionWeeklyReview build({
    required List<AtlasCommandCenterAction> actions,
    required Map<String, DateTime> latestUpdateDates,
    String? farmName,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final periodEnd = generatedAt;
    final periodStart = generatedAt.subtract(const Duration(days: 7));
    final analytics = _analyticsService.build(actions);

    final completedInPeriod = actions.where((action) {
      final completedAt = action.completedAt;

      return completedAt != null &&
          !completedAt.isBefore(periodStart) &&
          !completedAt.isAfter(periodEnd);
    }).length;

    final blockedActions = actions
        .where((action) => action.status == AtlasCanonicalStatus.blocked)
        .length;

    final withoutResponsible = actions
        .where((action) => action.isOpen && !action.hasResponsible)
        .length;

    final withoutFollowUp = actions.where((action) {
      if (!action.isOpen) {
        return false;
      }

      final reference = latestUpdateDates[action.id] ?? action.updatedAt;

      return generatedAt.difference(reference).inDays >= 7;
    }).length;

    final achievements = _buildAchievements(
      actions: actions,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    final bottlenecks = _buildBottlenecks(
      actions: actions,
      withoutResponsible: withoutResponsible,
      withoutFollowUp: withoutFollowUp,
    );
    final focusActions = _buildFocusActions(actions);

    return AtlasExecutionWeeklyReview(
      id: 'weekly_review_${generatedAt.microsecondsSinceEpoch}',
      farmName: farmName,
      generatedAt: generatedAt,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalActions: analytics.total,
      openActions: analytics.open,
      completedInPeriod: completedInPeriod,
      overdueActions: analytics.overdue,
      blockedActions: blockedActions,
      actionsWithoutResponsible: withoutResponsible,
      actionsWithoutRecentFollowUp: withoutFollowUp,
      averageProgressPercent: analytics.averageProgressPercent,
      executionHealthPercent: analytics.executionHealthPercent,
      expectedFinancialImpact: analytics.expectedFinancialImpact,
      achievements: achievements,
      bottlenecks: bottlenecks,
      focusActions: focusActions,
    );
  }

  List<String> _buildAchievements({
    required List<AtlasCommandCenterAction> actions,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final completed =
        actions.where((action) {
          final completedAt = action.completedAt;

          return completedAt != null &&
              !completedAt.isBefore(periodStart) &&
              !completedAt.isAfter(periodEnd);
        }).toList()..sort(
          (first, second) => second.completedAt!.compareTo(first.completedAt!),
        );

    if (completed.isEmpty) {
      return const <String>[
        'Nenhuma ação foi concluída nos últimos sete dias.',
      ];
    }

    return completed
        .take(5)
        .map((action) => 'Concluída: ${action.title}')
        .toList(growable: false);
  }

  List<String> _buildBottlenecks({
    required List<AtlasCommandCenterAction> actions,
    required int withoutResponsible,
    required int withoutFollowUp,
  }) {
    final result = <String>[];
    final overdue = actions.where((action) => action.isOverdue).length;
    final blocked = actions
        .where((action) => action.status == AtlasCanonicalStatus.blocked)
        .length;

    if (overdue > 0) {
      result.add('$overdue ação(ões) está(ão) atrasada(s).');
    }

    if (blocked > 0) {
      result.add('$blocked ação(ões) está(ão) bloqueada(s).');
    }

    if (withoutResponsible > 0) {
      result.add(
        '$withoutResponsible ação(ões) aberta(s) não possui(em) responsável.',
      );
    }

    if (withoutFollowUp > 0) {
      result.add(
        '$withoutFollowUp ação(ões) está(ão) sem acompanhamento recente.',
      );
    }

    if (result.isEmpty) {
      result.add('Nenhum gargalo crítico foi identificado no período.');
    }

    return result;
  }

  List<String> _buildFocusActions(List<AtlasCommandCenterAction> actions) {
    final candidates = actions.where((action) => action.isOpen).toList()
      ..sort((first, second) {
        if (first.isOverdue != second.isOverdue) {
          return first.isOverdue ? -1 : 1;
        }

        final priorityComparison = _priorityWeight(
          second.priority,
        ).compareTo(_priorityWeight(first.priority));

        if (priorityComparison != 0) {
          return priorityComparison;
        }

        final firstDue = first.dueAt ?? DateTime(9999);
        final secondDue = second.dueAt ?? DateTime(9999);

        return firstDue.compareTo(secondDue);
      });

    if (candidates.isEmpty) {
      return const <String>[
        'Manter o acompanhamento das ações concluídas e preparar o próximo ciclo.',
      ];
    }

    return candidates
        .take(5)
        .map((action) => '${action.title}: ${action.recommendedAction}')
        .toList(growable: false);
  }

  int _priorityWeight(AtlasCanonicalPriority priority) {
    switch (priority) {
      case AtlasCanonicalPriority.low:
        return 1;
      case AtlasCanonicalPriority.medium:
        return 2;
      case AtlasCanonicalPriority.high:
        return 3;
      case AtlasCanonicalPriority.critical:
        return 4;
    }
  }
}
