import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal_history.dart';

class AtlasExecutiveGoalHistoryService {
  const AtlasExecutiveGoalHistoryService();

  AtlasExecutiveGoalHistoryEvent createEvent({
    required AtlasExecutiveGoal goal,
    required AtlasExecutiveGoalHistoryEventType type,
    required String description,
    DateTime? recordedAt,
  }) {
    final now = recordedAt ?? DateTime.now();

    return AtlasExecutiveGoalHistoryEvent(
      id: '${goal.id}_${now.microsecondsSinceEpoch}',
      goalId: goal.id,
      farmName: goal.farmName,
      kpiTitle: goal.kpiTitle,
      type: type,
      recordedAt: now,
      description: description,
      progressPercent: goal.progressPercent,
      currentValue: goal.currentValue,
      targetValue: goal.targetValue,
      status: goal.status,
    );
  }

  AtlasExecutiveGoalHistorySummary buildSummary({
    required List<AtlasExecutiveGoalHistoryEvent> events,
    required List<AtlasExecutiveGoal> goals,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final grouped = <String, List<AtlasExecutiveGoalHistoryEvent>>{};

    for (final event in events) {
      grouped.putIfAbsent(event.goalId, () => []);
      grouped[event.goalId]!.add(event);
    }

    final series = <AtlasExecutiveGoalHistorySeries>[];

    for (final goal in goals) {
      final goalEvents = grouped[goal.id] ?? [];
      goalEvents.sort(
        (a, b) => a.recordedAt.compareTo(b.recordedAt),
      );

      final average = _averageDailyProgress(
        goal,
        goalEvents,
        currentTime,
      );

      final projected = _projectedDate(
        goal,
        average,
        currentTime,
      );

      final risk = _risk(
        goal,
        projected,
        currentTime,
      );

      series.add(
        AtlasExecutiveGoalHistorySeries(
          goalId: goal.id,
          farmName: goal.farmName,
          kpiTitle: goal.kpiTitle,
          events: List.unmodifiable(goalEvents),
          currentStatus: goal.status,
          currentProgressPercent: goal.progressPercent,
          averageDailyProgress: average,
          projectedCompletionDate: projected,
          riskLevel: risk,
        ),
      );
    }

    series.sort(
      (a, b) => _riskWeight(b.riskLevel)
          .compareTo(_riskWeight(a.riskLevel)),
    );

    final onTrack = series
        .where(
          (item) =>
              item.riskLevel ==
              AtlasExecutiveGoalRiskLevel.onTrack,
        )
        .length;

    final atRisk = series
        .where(
          (item) =>
              item.riskLevel ==
              AtlasExecutiveGoalRiskLevel.attention,
        )
        .length;

    final highRisk = series
        .where(
          (item) =>
              item.riskLevel ==
              AtlasExecutiveGoalRiskLevel.high,
        )
        .length;

    final completed = series
        .where(
          (item) =>
              item.riskLevel ==
              AtlasExecutiveGoalRiskLevel.completed,
        )
        .length;

    return AtlasExecutiveGoalHistorySummary(
      generatedAt: currentTime,
      summary: series.isEmpty
          ? 'Ainda não existem metas com histórico registrado.'
          : 'O histórico acompanha ${series.length} metas: '
              '$onTrack no ritmo esperado, '
              '$atRisk em atenção, '
              '$highRisk em alto risco e '
              '$completed concluídas.',
      series: series,
      onTrack: onTrack,
      atRisk: atRisk,
      highRisk: highRisk,
      completed: completed,
    );
  }

  double _averageDailyProgress(
    AtlasExecutiveGoal goal,
    List<AtlasExecutiveGoalHistoryEvent> events,
    DateTime now,
  ) {
    if (events.length >= 2) {
      final first = events.first;
      final last = events.last;
      final days = last.recordedAt
          .difference(first.recordedAt)
          .inDays
          .clamp(1, 100000);

      return ((last.progressPercent -
                  first.progressPercent) /
              days)
          .toDouble();
    }

    final days = now
        .difference(goal.createdAt)
        .inDays
        .clamp(1, 100000);

    return (goal.progressPercent / days).toDouble();
  }

  DateTime? _projectedDate(
    AtlasExecutiveGoal goal,
    double average,
    DateTime now,
  ) {
    if (goal.isCompleted) {
      return goal.completedAt ?? now;
    }

    if (average <= 0) return null;

    final remainingDays =
        ((100 - goal.progressPercent) / average)
            .ceil()
            .clamp(0, 36500);

    return now.add(
      Duration(days: remainingDays),
    );
  }

  AtlasExecutiveGoalRiskLevel _risk(
    AtlasExecutiveGoal goal,
    DateTime? projected,
    DateTime now,
  ) {
    if (goal.isCompleted) {
      return AtlasExecutiveGoalRiskLevel.completed;
    }

    if (goal.deadline.isBefore(now) ||
        projected == null ||
        projected.isAfter(goal.deadline)) {
      return AtlasExecutiveGoalRiskLevel.high;
    }

    if (projected.isAfter(
      goal.deadline.subtract(
        const Duration(days: 7),
      ),
    )) {
      return AtlasExecutiveGoalRiskLevel.attention;
    }

    return AtlasExecutiveGoalRiskLevel.onTrack;
  }

  int _riskWeight(
    AtlasExecutiveGoalRiskLevel level,
  ) {
    switch (level) {
      case AtlasExecutiveGoalRiskLevel.high:
        return 4;
      case AtlasExecutiveGoalRiskLevel.attention:
        return 3;
      case AtlasExecutiveGoalRiskLevel.onTrack:
        return 2;
      case AtlasExecutiveGoalRiskLevel.completed:
        return 1;
    }
  }
}
