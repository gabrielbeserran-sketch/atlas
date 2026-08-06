import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_analytics.dart';

class AtlasCommandCenterActionAnalyticsService {
  const AtlasCommandCenterActionAnalyticsService();

  AtlasCommandCenterActionAnalytics build(
    List<AtlasCommandCenterAction> actions,
  ) {
    final byPriority = <AtlasCanonicalPriority, int>{
      for (final value in AtlasCanonicalPriority.values) value: 0,
    };
    final byStatus = <AtlasCanonicalStatus, int>{
      for (final value in AtlasCanonicalStatus.values) value: 0,
    };
    final byModule = <String, int>{};

    var completed = 0;
    var cancelled = 0;
    var blocked = 0;
    var overdue = 0;
    var totalCompletionHours = 0.0;
    var completionSamples = 0;
    var withResponsible = 0;
    var progressTotal = 0;
    var expectedFinancialImpact = 0.0;

    for (final action in actions) {
      byPriority[action.priority] =
          (byPriority[action.priority] ?? 0) + 1;
      byStatus[action.status] =
          (byStatus[action.status] ?? 0) + 1;
      byModule[action.sourceModule] =
          (byModule[action.sourceModule] ?? 0) + 1;

      if (action.hasResponsible) withResponsible += 1;
      progressTotal += action.progressPercent;
      expectedFinancialImpact += action.expectedFinancialImpact;

      if (action.isCompleted) {
        completed += 1;

        final completedAt = action.completedAt;

        if (completedAt != null) {
          totalCompletionHours +=
              completedAt.difference(action.createdAt).inMinutes / 60;
          completionSamples += 1;
        }
      }

      if (action.isCancelled) {
        cancelled += 1;
      }

      if (action.status == AtlasCanonicalStatus.blocked) {
        blocked += 1;
      }

      if (action.isOverdue) {
        overdue += 1;
      }
    }

    final total = actions.length;
    final open = actions.where((action) => action.isOpen).length;
    final completionRate =
        total == 0 ? 0.0 : (completed / total) * 100;
    final averageCompletionHours = completionSamples == 0
        ? 0.0
        : totalCompletionHours / completionSamples;

    final averageProgressPercent =
        total == 0 ? 0.0 : progressTotal / total;
    final responsibleCoverage =
        total == 0 ? 0.0 : (withResponsible / total) * 100;
    final overduePenalty =
        total == 0 ? 0.0 : (overdue / total) * 100;
    final executionHealthPercent = (
      completionRate * 0.4 +
      averageProgressPercent * 0.3 +
      responsibleCoverage * 0.3 -
      overduePenalty * 0.35
    ).clamp(0.0, 100.0);

    return AtlasCommandCenterActionAnalytics(
      generatedAt: DateTime.now(),
      total: total,
      open: open,
      completed: completed,
      cancelled: cancelled,
      blocked: blocked,
      overdue: overdue,
      completionRatePercent: completionRate,
      averageCompletionHours: averageCompletionHours,
      byPriority:
          Map<AtlasCanonicalPriority, int>.unmodifiable(byPriority),
      byStatus:
          Map<AtlasCanonicalStatus, int>.unmodifiable(byStatus),
      byModule: Map<String, int>.unmodifiable(byModule),
      withResponsible: withResponsible,
      averageProgressPercent: averageProgressPercent,
      expectedFinancialImpact: expectedFinancialImpact,
      executionHealthPercent: executionHealthPercent,
    );
  }
}
