import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';

class AtlasExecutiveGoalService {
  const AtlasExecutiveGoalService();

  AtlasExecutiveGoal createFromKpi({
    required AtlasExecutiveKpi kpi,
    required double targetValue,
    required DateTime deadline,
    String responsibleName = '',
    String notes = '',
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    return AtlasExecutiveGoal(
      id: '${kpi.id}_${currentTime.microsecondsSinceEpoch}',
      farmName: kpi.farmName,
      kpiId: kpi.id,
      kpiTitle: kpi.title,
      category: kpi.category,
      currentValue: kpi.value,
      targetValue: targetValue,
      startValue: kpi.value,
      unit: kpi.unit,
      direction: kpi.direction,
      createdAt: currentTime,
      deadline: deadline,
      updatedAt: currentTime,
      status: AtlasExecutiveGoalStatus.active,
      priority: _priorityFromKpi(kpi),
      responsibleName: responsibleName.trim(),
      notes: notes.trim(),
    );
  }

  List<AtlasExecutiveGoal> synchronizeWithKpis({
    required List<AtlasExecutiveGoal> goals,
    required List<AtlasExecutiveKpi> kpis,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final kpisById = {for (final kpi in kpis) kpi.id: kpi};

    return goals.map((goal) {
      final kpi = kpisById[goal.kpiId];

      if (kpi == null || goal.status == AtlasExecutiveGoalStatus.cancelled) {
        return goal;
      }

      final updated = goal.copyWith(
        currentValue: kpi.value,
        updatedAt: currentTime,
      );

      return _evaluateGoal(updated, now: currentTime);
    }).toList();
  }

  AtlasExecutiveGoal updateGoal({
    required AtlasExecutiveGoal goal,
    double? targetValue,
    DateTime? deadline,
    String? responsibleName,
    String? notes,
    AtlasExecutiveGoalStatus? status,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    var updated = goal.copyWith(
      targetValue: targetValue,
      deadline: deadline,
      responsibleName: responsibleName,
      notes: notes,
      status: status,
      updatedAt: currentTime,
      completedAt: status == AtlasExecutiveGoalStatus.completed
          ? currentTime
          : null,
      clearCompletedAt: status != AtlasExecutiveGoalStatus.completed,
    );

    if (status == null) {
      updated = _evaluateGoal(updated, now: currentTime);
    }

    return updated;
  }

  AtlasExecutiveGoalDashboardData buildDashboard({
    required List<AtlasExecutiveGoal> goals,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final evaluated = goals.map((goal) {
      return _evaluateGoal(goal, now: currentTime);
    }).toList()..sort(_compareGoals);

    final progress = _calculateProgress(evaluated);

    final farms = _buildFarmSummaries(evaluated);

    final priorityGoals = evaluated
        .where((goal) {
          return goal.status != AtlasExecutiveGoalStatus.completed &&
              goal.status != AtlasExecutiveGoalStatus.cancelled;
        })
        .take(10)
        .toList();

    return AtlasExecutiveGoalDashboardData(
      generatedAt: currentTime,
      summary: _buildSummary(progress: progress, priorityGoals: priorityGoals),
      progress: progress,
      goals: evaluated,
      priorityGoals: priorityGoals,
      farms: farms,
    );
  }

  AtlasExecutiveGoal _evaluateGoal(
    AtlasExecutiveGoal goal, {
    required DateTime now,
  }) {
    if (goal.status == AtlasExecutiveGoalStatus.cancelled ||
        goal.status == AtlasExecutiveGoalStatus.completed) {
      return goal;
    }

    if (goal.targetReached) {
      return goal.copyWith(
        status: AtlasExecutiveGoalStatus.completed,
        updatedAt: now,
        completedAt: now,
      );
    }

    if (goal.deadline.isBefore(now)) {
      return goal.copyWith(
        status: AtlasExecutiveGoalStatus.overdue,
        updatedAt: now,
      );
    }

    final totalDays = goal.deadline.difference(goal.createdAt).inDays;

    final elapsedDays = now.difference(goal.createdAt).inDays;

    final expectedProgress = totalDays <= 0
        ? 100.0
        : elapsedDays / totalDays * 100;

    final isAtRisk =
        goal.progressPercent + 15 < expectedProgress.clamp(0.0, 100.0);

    return goal.copyWith(
      status: isAtRisk
          ? AtlasExecutiveGoalStatus.atRisk
          : AtlasExecutiveGoalStatus.active,
      updatedAt: now,
    );
  }

  AtlasExecutiveGoalProgress _calculateProgress(
    List<AtlasExecutiveGoal> goals,
  ) {
    final active = goals.where((goal) {
      return goal.status == AtlasExecutiveGoalStatus.active;
    }).length;

    final atRisk = goals.where((goal) {
      return goal.status == AtlasExecutiveGoalStatus.atRisk;
    }).length;

    final overdue = goals.where((goal) {
      return goal.status == AtlasExecutiveGoalStatus.overdue;
    }).length;

    final completed = goals.where((goal) {
      return goal.status == AtlasExecutiveGoalStatus.completed;
    }).length;

    final valid = goals.where((goal) {
      return goal.status != AtlasExecutiveGoalStatus.cancelled;
    }).toList();

    final averageProgress = valid.isEmpty
        ? 0.0
        : valid.fold<double>(0, (sum, goal) => sum + goal.progressPercent) /
              valid.length;

    final completionPercent = valid.isEmpty
        ? 0.0
        : completed / valid.length * 100;

    return AtlasExecutiveGoalProgress(
      total: goals.length,
      active: active,
      atRisk: atRisk,
      overdue: overdue,
      completed: completed,
      averageProgressPercent: averageProgress.clamp(0.0, 100.0).toDouble(),
      completionPercent: completionPercent.clamp(0.0, 100.0).toDouble(),
    );
  }

  List<AtlasExecutiveFarmGoalSummary> _buildFarmSummaries(
    List<AtlasExecutiveGoal> goals,
  ) {
    final grouped = <String, List<AtlasExecutiveGoal>>{};

    for (final goal in goals) {
      grouped.putIfAbsent(goal.farmName, () => []);

      grouped[goal.farmName]!.add(goal);
    }

    final result = <AtlasExecutiveFarmGoalSummary>[];

    for (final entry in grouped.entries) {
      final items = entry.value..sort(_compareGoals);

      final active = items.where((goal) {
        return goal.status == AtlasExecutiveGoalStatus.active;
      }).length;

      final atRisk = items.where((goal) {
        return goal.status == AtlasExecutiveGoalStatus.atRisk;
      }).length;

      final overdue = items.where((goal) {
        return goal.status == AtlasExecutiveGoalStatus.overdue;
      }).length;

      final completed = items.where((goal) {
        return goal.status == AtlasExecutiveGoalStatus.completed;
      }).length;

      final average = items.isEmpty
          ? 0.0
          : items.fold<double>(0, (sum, goal) => sum + goal.progressPercent) /
                items.length;

      result.add(
        AtlasExecutiveFarmGoalSummary(
          farmName: entry.key,
          total: items.length,
          active: active,
          atRisk: atRisk,
          overdue: overdue,
          completed: completed,
          averageProgressPercent: average.clamp(0.0, 100.0).toDouble(),
          mainGoalTitle: items.isEmpty ? null : items.first.kpiTitle,
        ),
      );
    }

    result.sort((first, second) {
      if (first.overdue != second.overdue) {
        return second.overdue.compareTo(first.overdue);
      }

      if (first.atRisk != second.atRisk) {
        return second.atRisk.compareTo(first.atRisk);
      }

      return first.averageProgressPercent.compareTo(
        second.averageProgressPercent,
      );
    });

    return result;
  }

  AtlasExecutiveGoalPriority _priorityFromKpi(AtlasExecutiveKpi kpi) {
    switch (kpi.status) {
      case AtlasExecutiveKpiStatus.critical:
        return AtlasExecutiveGoalPriority.critical;

      case AtlasExecutiveKpiStatus.attention:
        return AtlasExecutiveGoalPriority.high;

      case AtlasExecutiveKpiStatus.adequate:
        return AtlasExecutiveGoalPriority.medium;

      case AtlasExecutiveKpiStatus.excellent:
        return AtlasExecutiveGoalPriority.low;
    }
  }

  int _compareGoals(AtlasExecutiveGoal first, AtlasExecutiveGoal second) {
    final firstWeight = _statusWeight(first.status);

    final secondWeight = _statusWeight(second.status);

    if (firstWeight != secondWeight) {
      return secondWeight.compareTo(firstWeight);
    }

    final firstPriority = _priorityWeight(first.priority);

    final secondPriority = _priorityWeight(second.priority);

    if (firstPriority != secondPriority) {
      return secondPriority.compareTo(firstPriority);
    }

    return first.deadline.compareTo(second.deadline);
  }

  int _statusWeight(AtlasExecutiveGoalStatus status) {
    switch (status) {
      case AtlasExecutiveGoalStatus.overdue:
        return 5;

      case AtlasExecutiveGoalStatus.atRisk:
        return 4;

      case AtlasExecutiveGoalStatus.active:
        return 3;

      case AtlasExecutiveGoalStatus.completed:
        return 2;

      case AtlasExecutiveGoalStatus.cancelled:
        return 1;
    }
  }

  int _priorityWeight(AtlasExecutiveGoalPriority priority) {
    switch (priority) {
      case AtlasExecutiveGoalPriority.critical:
        return 4;

      case AtlasExecutiveGoalPriority.high:
        return 3;

      case AtlasExecutiveGoalPriority.medium:
        return 2;

      case AtlasExecutiveGoalPriority.low:
        return 1;
    }
  }

  String _buildSummary({
    required AtlasExecutiveGoalProgress progress,
    required List<AtlasExecutiveGoal> priorityGoals,
  }) {
    if (!progress.hasGoals) {
      return 'Ainda não existem metas executivas cadastradas.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A operação possui ${progress.total} '
      '${progress.total == 1 ? 'meta' : 'metas'}, '
      'com progresso médio de '
      '${progress.averageProgressPercent.toStringAsFixed(0)}%. ',
    );

    buffer.write(
      '${progress.completed} concluídas, '
      '${progress.active} no prazo, '
      '${progress.atRisk} em risco e '
      '${progress.overdue} atrasadas. ',
    );

    if (priorityGoals.isNotEmpty) {
      buffer.write(
        'A meta prioritária é '
        '"${priorityGoals.first.kpiTitle}" '
        'na ${priorityGoals.first.farmName}.',
      );
    }

    return buffer.toString().trim();
  }
}
