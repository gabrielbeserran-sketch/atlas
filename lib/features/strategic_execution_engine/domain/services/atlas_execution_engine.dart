import '../models/atlas_execution_analysis.dart';
import '../models/atlas_execution_plan.dart';

class AtlasExecutionEngine {
  const AtlasExecutionEngine();

  AtlasExecutionAnalysis analyze(AtlasExecutionPlan plan, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final tasks = plan.tasks;
    if (tasks.isEmpty) {
      return const AtlasExecutionAnalysis(
        progress: 0,
        spi: 1,
        cpi: 1,
        plannedCost: 0,
        actualCost: 0,
        completed: 0,
        delayed: 0,
        blocked: 0,
        criticalPath: [],
        alerts: [],
      );
    }
    final planned = tasks.fold<double>(
      0,
      (sum, item) => sum + item.plannedCost,
    );
    final actual = tasks.fold<double>(0, (sum, item) => sum + item.actualCost);
    final progress =
        tasks.fold<double>(0, (sum, item) => sum + item.progress) /
        tasks.length;
    final elapsedProgress =
        tasks
            .map((task) {
              final total = task.dueDate
                  .difference(task.startDate)
                  .inDays
                  .clamp(1, 99999);
              final elapsed = today
                  .difference(task.startDate)
                  .inDays
                  .clamp(0, total);
              return elapsed / total * 100;
            })
            .fold<double>(0, (sum, item) => sum + item) /
        tasks.length;
    final spi = elapsedProgress <= 0 ? 1.0 : progress / elapsedProgress;
    final earnedValue = planned * progress / 100;
    final cpi = actual <= 0 ? 1.0 : earnedValue / actual;
    final delayedTasks = tasks
        .where(
          (t) =>
              (t.dueDate.isBefore(today) && t.progress < 100) ||
              t.status == AtlasExecutionTaskStatus.delayed,
        )
        .toList();
    final blockedTasks = tasks
        .where((t) => t.status == AtlasExecutionTaskStatus.blocked)
        .toList();
    final alerts = <AtlasExecutionAlert>[];
    if (spi < .9) {
      alerts.add(
        const AtlasExecutionAlert(
          title: 'Risco de atraso',
          message:
              'O avanço físico está abaixo do avanço planejado. Repriorize tarefas críticas.',
          severity: AtlasExecutionPriority.high,
        ),
      );
    }
    if (cpi < .9) {
      alerts.add(
        const AtlasExecutionAlert(
          title: 'Desvio de custos',
          message: 'O custo real está acima do valor agregado pela execução.',
          severity: AtlasExecutionPriority.high,
        ),
      );
    }
    for (final task in delayedTasks.take(3)) {
      alerts.add(
        AtlasExecutionAlert(
          title: 'Atividade atrasada',
          message: '${task.title} precisa de replanejamento imediato.',
          severity: task.priority,
        ),
      );
    }
    for (final task in blockedTasks.take(3)) {
      alerts.add(
        AtlasExecutionAlert(
          title: 'Dependência bloqueada',
          message:
              '${task.title} está bloqueada. Verifique recursos e predecessoras.',
          severity: AtlasExecutionPriority.critical,
        ),
      );
    }
    final critical = [...tasks]
      ..sort((a, b) {
        final aScore =
            a.priority.index * 1000 +
            (100 - a.progress).round() +
            a.dependencyIds.length * 20;
        final bScore =
            b.priority.index * 1000 +
            (100 - b.progress).round() +
            b.dependencyIds.length * 20;
        return bScore.compareTo(aScore);
      });
    return AtlasExecutionAnalysis(
      progress: progress,
      spi: spi,
      cpi: cpi,
      plannedCost: planned,
      actualCost: actual,
      completed: tasks
          .where(
            (t) =>
                t.progress >= 100 ||
                t.status == AtlasExecutionTaskStatus.completed,
          )
          .length,
      delayed: delayedTasks.length,
      blocked: blockedTasks.length,
      criticalPath: critical.take(5).toList(),
      alerts: alerts,
    );
  }
}
