import 'package:projeto_atlas/features/performance_intelligence/presentation/screens/atlas_performance_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/atlas_execution_repository.dart';
import '../../domain/models/atlas_execution_analysis.dart';
import '../../domain/models/atlas_execution_plan.dart';
import '../../domain/services/atlas_execution_engine.dart';

class AtlasExecutionEngineScreen extends StatefulWidget {
  const AtlasExecutionEngineScreen({super.key, this.farmId});
  final String? farmId;

  @override
  State<AtlasExecutionEngineScreen> createState() =>
      _AtlasExecutionEngineScreenState();
}

class _AtlasExecutionEngineScreenState
    extends State<AtlasExecutionEngineScreen> {
  final _engine = const AtlasExecutionEngine();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _date = DateFormat('dd/MM/yyyy');
  bool _loading = true;
  List<AtlasExecutionPlan> _plans = const [];
  AtlasExecutionPlan? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await AtlasExecutionRepository.instance.loadAll();
    final filtered = widget.farmId == null
        ? all
        : all
              .where((e) => e.farmId.isEmpty || e.farmId == widget.farmId)
              .toList();
    if (!mounted) return;
    setState(() {
      _plans = filtered;
      _selected = filtered.isEmpty ? null : filtered.first;
      _loading = false;
    });
  }

  Future<void> _createPlan() async {
    final result = await showDialog<AtlasExecutionPlan>(
      context: context,
      builder: (_) => _PlanDialog(farmId: widget.farmId ?? ''),
    );
    if (result == null) return;
    await AtlasExecutionRepository.instance.save(result);
    await _load();
  }

  Future<void> _addTask() async {
    final plan = _selected;
    if (plan == null) return;
    final task = await showDialog<AtlasExecutionTask>(
      context: context,
      builder: (_) => const _TaskDialog(),
    );
    if (task == null) return;
    final updated = plan.copyWith(tasks: [...plan.tasks, task]);
    await AtlasExecutionRepository.instance.save(updated);
    await _load();
    if (mounted) setState(() => _selected = updated);
  }

  Future<void> _updateTask(AtlasExecutionTask task) async {
    final plan = _selected;
    if (plan == null) return;
    final edited = await showDialog<AtlasExecutionTask>(
      context: context,
      builder: (_) => _TaskDialog(initial: task),
    );
    if (edited == null) return;
    final tasks = plan.tasks.map((e) => e.id == task.id ? edited : e).toList();
    final updated = plan.copyWith(tasks: tasks);
    await AtlasExecutionRepository.instance.save(updated);
    await _load();
    if (mounted) setState(() => _selected = updated);
  }

  Future<void> _deletePlan() async {
    final plan = _selected;
    if (plan == null) return;
    await AtlasExecutionRepository.instance.delete(plan.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _selected;
    final analysis = plan == null ? null : _engine.analyze(plan);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Strategic Execution Engine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AtlasPerformanceDashboardScreen(farmId: widget.farmId),
              ),
            ),
            tooltip: 'Indicadores de desempenho',
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            onPressed: _load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: plan == null ? _createPlan : _addTask,
        icon: const Icon(Icons.add),
        label: Text(plan == null ? 'Novo plano' : 'Nova atividade'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
                  children: [
                    _Hero(onNewPlan: _createPlan),
                    const SizedBox(height: 18),
                    if (_plans.isNotEmpty)
                      _PlanSelector(
                        plans: _plans,
                        selected: plan!,
                        onChanged: (value) => setState(() => _selected = value),
                        onDelete: _deletePlan,
                      ),
                    if (plan == null)
                      const _EmptyState()
                    else ...[
                      const SizedBox(height: 18),
                      _Metrics(analysis: analysis!, currency: _currency),
                      const SizedBox(height: 18),
                      _Alerts(alerts: analysis.alerts),
                      const SizedBox(height: 24),
                      const Text(
                        'Caminho crítico',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CriticalPath(tasks: analysis.criticalPath),
                      const SizedBox(height: 24),
                      const Text(
                        'Plano operacional',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...plan.tasks.map(
                        (task) => _TaskCard(
                          task: task,
                          date: _date,
                          currency: _currency,
                          onTap: () => _updateTask(task),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onNewPlan});
  final VoidCallback onNewPlan;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF123B36),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const SizedBox(
            width: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Da estratégia para a execução',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Transforme decisões e investimentos em atividades, responsáveis, recursos, prazos, custos e alertas inteligentes.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onNewPlan,
            icon: const Icon(Icons.add_task),
            label: const Text('Criar plano'),
          ),
        ],
      ),
    ),
  );
}

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({
    required this.plans,
    required this.selected,
    required this.onChanged,
    required this.onDelete,
  });
  final List<AtlasExecutionPlan> plans;
  final AtlasExecutionPlan selected;
  final ValueChanged<AtlasExecutionPlan> onChanged;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.route_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selected.id,
              decoration: const InputDecoration(
                labelText: 'Plano em análise',
                border: OutlineInputBorder(),
              ),
              items: plans
                  .map(
                    (e) => DropdownMenuItem(value: e.id, child: Text(e.title)),
                  )
                  .toList(),
              onChanged: (id) {
                final p = plans.where((e) => e.id == id).first;
                onChanged(p);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Excluir plano',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.analysis, required this.currency});
  final AtlasExecutionAnalysis analysis;
  final NumberFormat currency;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 760
          ? constraints.maxWidth
          : (constraints.maxWidth - 36) / 4;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Metric(
            width: width,
            label: 'Avanço físico',
            value: '${analysis.progress.toStringAsFixed(1)}%',
            icon: Icons.donut_large,
          ),
          _Metric(
            width: width,
            label: 'SPI • Prazo',
            value: analysis.spi.toStringAsFixed(2),
            icon: Icons.schedule,
          ),
          _Metric(
            width: width,
            label: 'CPI • Custo',
            value: analysis.cpi.toStringAsFixed(2),
            icon: Icons.payments_outlined,
          ),
          _Metric(
            width: width,
            label: 'Custo real',
            value: currency.format(analysis.actualCost),
            icon: Icons.account_balance_wallet_outlined,
          ),
          _Metric(
            width: width,
            label: 'Concluídas',
            value: '${analysis.completed}',
            icon: Icons.task_alt,
          ),
          _Metric(
            width: width,
            label: 'Atrasadas',
            value: '${analysis.delayed}',
            icon: Icons.warning_amber,
          ),
          _Metric(
            width: width,
            label: 'Bloqueadas',
            value: '${analysis.blocked}',
            icon: Icons.block,
          ),
          _Metric(
            width: width,
            label: 'Orçamento',
            value: currency.format(analysis.plannedCost),
            icon: Icons.request_quote_outlined,
          ),
        ],
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });
  final double width;
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF175F55)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Alerts extends StatelessWidget {
  const _Alerts({required this.alerts});
  final List<AtlasExecutionAlert> alerts;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alertas inteligentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (alerts.isEmpty)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.verified_outlined, color: Colors.green),
              title: Text('Execução dentro dos parâmetros'),
            )
          else
            ...alerts.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  a.severity == AtlasExecutionPriority.critical
                      ? Icons.error_outline
                      : Icons.warning_amber,
                  color: a.severity == AtlasExecutionPriority.critical
                      ? Colors.red
                      : Colors.orange,
                ),
                title: Text(
                  a.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(a.message),
              ),
            ),
        ],
      ),
    ),
  );
}

class _CriticalPath extends StatelessWidget {
  const _CriticalPath({required this.tasks});
  final List<AtlasExecutionTask> tasks;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tasks
            .map(
              (t) => Chip(
                avatar: const Icon(Icons.bolt, size: 18),
                label: Text(t.title),
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.date,
    required this.currency,
    required this.onTap,
  });
  final AtlasExecutionTask task;
  final DateFormat date;
  final NumberFormat currency;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(status: task.status),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              task.description,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (task.progress / 100).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('${task.progress.toStringAsFixed(0)}% concluído'),
                Text('Responsável: ${task.owner}'),
                Text(
                  '${date.format(task.startDate)} → ${date.format(task.dueDate)}',
                ),
                Text(
                  '${currency.format(task.actualCost)} / ${currency.format(task.plannedCost)}',
                ),
              ],
            ),
            if (task.resourceNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: task.resourceNames
                    .map(
                      (e) => Chip(
                        label: Text(e),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final AtlasExecutionTaskStatus status;
  @override
  Widget build(BuildContext context) {
    const labels = {
      AtlasExecutionTaskStatus.planned: 'Planejada',
      AtlasExecutionTaskStatus.inProgress: 'Em andamento',
      AtlasExecutionTaskStatus.blocked: 'Bloqueada',
      AtlasExecutionTaskStatus.completed: 'Concluída',
      AtlasExecutionTaskStatus.delayed: 'Atrasada',
    };
    return Chip(label: Text(labels[status]!));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text('Crie o primeiro plano de execução estratégica.'),
      ),
    ),
  );
}

class _PlanDialog extends StatefulWidget {
  const _PlanDialog({required this.farmId});
  final String farmId;
  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  final title = TextEditingController();
  final objective = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    objective.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Novo plano de execução'),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: objective,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Objetivo estratégico',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (title.text.trim().isEmpty) return;
          Navigator.pop(
            context,
            AtlasExecutionPlan(
              id: 'plan_${DateTime.now().microsecondsSinceEpoch}',
              farmId: widget.farmId,
              title: title.text.trim(),
              objective: objective.text.trim(),
              createdAt: DateTime.now(),
              tasks: const [],
            ),
          );
        },
        child: const Text('Criar'),
      ),
    ],
  );
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({this.initial});
  final AtlasExecutionTask? initial;
  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController title;
  late final TextEditingController description;
  late final TextEditingController owner;
  late final TextEditingController planned;
  late final TextEditingController actual;
  late final TextEditingController progress;
  late AtlasExecutionPriority priority;
  late AtlasExecutionTaskStatus status;
  late DateTime start;
  late DateTime due;
  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    title = TextEditingController(text: i?.title ?? '');
    description = TextEditingController(text: i?.description ?? '');
    owner = TextEditingController(text: i?.owner ?? 'Equipe da fazenda');
    planned = TextEditingController(text: i?.plannedCost.toString() ?? '0');
    actual = TextEditingController(text: i?.actualCost.toString() ?? '0');
    progress = TextEditingController(text: i?.progress.toString() ?? '0');
    priority = i?.priority ?? AtlasExecutionPriority.medium;
    status = i?.status ?? AtlasExecutionTaskStatus.planned;
    start = i?.startDate ?? DateTime.now();
    due = i?.dueDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    owner.dispose();
    planned.dispose();
    actual.dispose();
    progress.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
    final value = await showDatePicker(
      context: context,
      initialDate: isStart ? start : due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (value != null) setState(() => isStart ? start = value : due = value);
  }

  double _number(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Nova atividade' : 'Editar atividade'),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Atividade'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: owner,
              decoration: const InputDecoration(labelText: 'Responsável'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: planned,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custo planejado (R\$)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: actual,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custo real (R\$)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: progress,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Progresso (%)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<AtlasExecutionPriority>(
                    initialValue: priority,
                    decoration: const InputDecoration(labelText: 'Prioridade'),
                    items: AtlasExecutionPriority.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => priority = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<AtlasExecutionTaskStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: AtlasExecutionTaskStatus.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => status = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Início: ${DateFormat('dd/MM/yyyy').format(start)}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(false),
                    icon: const Icon(Icons.event),
                    label: Text(
                      'Prazo: ${DateFormat('dd/MM/yyyy').format(due)}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (title.text.trim().isEmpty) return;
          final old = widget.initial;
          Navigator.pop(
            context,
            AtlasExecutionTask(
              id: old?.id ?? 'task_${DateTime.now().microsecondsSinceEpoch}',
              title: title.text.trim(),
              description: description.text.trim(),
              owner: owner.text.trim(),
              startDate: start,
              dueDate: due,
              plannedCost: _number(planned),
              actualCost: _number(actual),
              progress: _number(progress).clamp(0, 100),
              priority: priority,
              status: status,
              dependencyIds: old?.dependencyIds ?? const [],
              resourceNames: old?.resourceNames ?? const [],
            ),
          );
        },
        child: const Text('Salvar'),
      ),
    ],
  );
}
