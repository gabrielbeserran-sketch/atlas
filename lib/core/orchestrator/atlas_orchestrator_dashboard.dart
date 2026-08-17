import 'package:flutter/material.dart';

import 'atlas_orchestrator_engine.dart';
import 'atlas_orchestrator_models.dart';
import 'atlas_orchestrator_repository.dart';

class AtlasOrchestratorDashboard extends StatefulWidget {
  const AtlasOrchestratorDashboard({super.key});

  @override
  State<AtlasOrchestratorDashboard> createState() =>
      _AtlasOrchestratorDashboardState();
}

class _AtlasOrchestratorDashboardState
    extends State<AtlasOrchestratorDashboard> {
  final AtlasOrchestratorRepository _repository = AtlasOrchestratorRepository();
  final AtlasOrchestratorEngine _engine = AtlasOrchestratorEngine();
  List<AtlasOrchestratorTask> _tasks = <AtlasOrchestratorTask>[];
  List<AtlasOrchestratorRun> _runs = <AtlasOrchestratorRun>[];
  bool _loading = true;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<AtlasOrchestratorTask> tasks = await _repository.loadTasks();
    final List<AtlasOrchestratorRun> runs = await _repository.loadRuns();
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = tasks;
      _runs = runs;
      _loading = false;
    });
  }

  Future<void> _execute() async {
    if (_running) {
      return;
    }
    setState(() => _running = true);
    final AtlasOrchestratorExecution execution = await _engine.execute(_tasks, (
      List<AtlasOrchestratorTask> tasks,
    ) {
      if (mounted) {
        setState(() => _tasks = tasks);
      }
    });
    _runs.insert(0, execution.run);
    await _repository.saveTasks(execution.tasks);
    await _repository.saveRuns(_runs);
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = execution.tasks;
      _running = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pipeline concluído com sucesso.')),
    );
  }

  Future<void> _toggleTask(int index, bool value) async {
    setState(() => _tasks[index] = _tasks[index].copyWith(enabled: value));
    await _repository.saveTasks(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atlas Orchestrator Engine')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _running ? null : _execute,
        icon: _running
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(_running ? 'Executando' : 'Executar pipeline'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: <Widget>[
                  _buildSummary(),
                  const SizedBox(height: 20),
                  const Text(
                    'Pipeline de execução',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...List<Widget>.generate(_tasks.length, _buildTask),
                  const SizedBox(height: 20),
                  const Text(
                    'Histórico recente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_runs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Nenhuma execução registrada.'),
                      ),
                    )
                  else
                    ..._runs.take(8).map(_buildRun),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    final int enabled = _tasks
        .where((AtlasOrchestratorTask task) => task.enabled)
        .length;
    final int successful = _tasks
        .where(
          (AtlasOrchestratorTask task) =>
              task.status == AtlasPipelineStatus.success,
        )
        .length;
    final int average = _tasks.isEmpty
        ? 0
        : _tasks.fold<int>(
                0,
                (int total, AtlasOrchestratorTask task) =>
                    total + task.durationMs,
              ) ~/
              _tasks.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Orquestração central',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coordena a coleta, análise, decisão, automação e auditoria dos principais motores do Atlas.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _metric(
                  'Etapas ativas',
                  '$enabled',
                  Icons.account_tree_outlined,
                ),
                _metric(
                  'Concluídas',
                  '$successful',
                  Icons.check_circle_outline,
                ),
                _metric('Execuções', '${_runs.length}', Icons.history_rounded),
                _metric('Tempo médio', '$average ms', Icons.speed_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) => Container(
    width: 150,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    ),
  );

  Widget _buildTask(int index) {
    final AtlasOrchestratorTask task = _tasks[index];
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${task.order}')),
        title: Text(
          task.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${task.module} • ${_statusLabel(task.status)}${task.durationMs > 0 ? ' • ${task.durationMs} ms' : ''}',
        ),
        trailing: Switch(
          value: task.enabled,
          onChanged: _running
              ? null
              : (bool value) => _toggleTask(index, value),
        ),
      ),
    );
  }

  Widget _buildRun(AtlasOrchestratorRun run) {
    final String date =
        '${run.finishedAt.day.toString().padLeft(2, '0')}/${run.finishedAt.month.toString().padLeft(2, '0')} ${run.finishedAt.hour.toString().padLeft(2, '0')}:${run.finishedAt.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.route_outlined),
        title: Text(
          '${run.successfulTasks}/${run.totalTasks} etapas concluídas',
        ),
        subtitle: Text('$date • ${run.durationMs} ms'),
        trailing: const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
      ),
    );
  }

  String _statusLabel(AtlasPipelineStatus status) {
    switch (status) {
      case AtlasPipelineStatus.idle:
        return 'Aguardando';
      case AtlasPipelineStatus.running:
        return 'Executando';
      case AtlasPipelineStatus.success:
        return 'Concluído';
      case AtlasPipelineStatus.warning:
        return 'Atenção';
      case AtlasPipelineStatus.failed:
        return 'Falha';
    }
  }
}
