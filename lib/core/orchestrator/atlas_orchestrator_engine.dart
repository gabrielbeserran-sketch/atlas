import 'dart:math';

import 'atlas_orchestrator_models.dart';

class AtlasOrchestratorExecution {
  const AtlasOrchestratorExecution({required this.tasks, required this.run});
  final List<AtlasOrchestratorTask> tasks;
  final AtlasOrchestratorRun run;
}

class AtlasOrchestratorEngine {
  Future<AtlasOrchestratorExecution> execute(
    List<AtlasOrchestratorTask> source,
    void Function(List<AtlasOrchestratorTask>) onProgress,
  ) async {
    final DateTime startedAt = DateTime.now();
    final Random random = Random();
    List<AtlasOrchestratorTask> tasks = List<AtlasOrchestratorTask>.from(source)
      ..sort((AtlasOrchestratorTask a, AtlasOrchestratorTask b) => a.order.compareTo(b.order));

    for (int index = 0; index < tasks.length; index++) {
      if (!tasks[index].enabled) {
        continue;
      }
      tasks[index] = tasks[index].copyWith(status: AtlasPipelineStatus.running, message: 'Executando...');
      onProgress(List<AtlasOrchestratorTask>.from(tasks));
      await Future<void>.delayed(const Duration(milliseconds: 320));
      final int duration = 110 + random.nextInt(390);
      tasks[index] = tasks[index].copyWith(
        status: AtlasPipelineStatus.success,
        durationMs: duration,
        message: 'Etapa concluída com sucesso.',
      );
      onProgress(List<AtlasOrchestratorTask>.from(tasks));
    }

    final DateTime finishedAt = DateTime.now();
    final int enabled = tasks.where((AtlasOrchestratorTask task) => task.enabled).length;
    final int successful = tasks.where((AtlasOrchestratorTask task) => task.status == AtlasPipelineStatus.success).length;
    final AtlasOrchestratorRun run = AtlasOrchestratorRun(
      id: 'run_${finishedAt.millisecondsSinceEpoch}',
      startedAt: startedAt,
      finishedAt: finishedAt,
      status: successful == enabled ? AtlasPipelineStatus.success : AtlasPipelineStatus.warning,
      successfulTasks: successful,
      totalTasks: enabled,
      durationMs: finishedAt.difference(startedAt).inMilliseconds,
    );
    return AtlasOrchestratorExecution(tasks: tasks, run: run);
  }
}
