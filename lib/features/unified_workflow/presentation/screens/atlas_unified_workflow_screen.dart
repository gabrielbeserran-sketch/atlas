import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/features/unified_workflow/domain/models/atlas_automation_execution.dart';
import 'package:projeto_atlas/features/unified_workflow/domain/models/atlas_automation_rule.dart';
import 'package:projeto_atlas/features/unified_workflow/domain/services/atlas_unified_workflow_engine.dart';

class AtlasUnifiedWorkflowScreen extends StatefulWidget {
  const AtlasUnifiedWorkflowScreen({super.key});

  @override
  State<AtlasUnifiedWorkflowScreen> createState() =>
      _AtlasUnifiedWorkflowScreenState();
}

class _AtlasUnifiedWorkflowScreenState
    extends State<AtlasUnifiedWorkflowScreen> {
  final AtlasUnifiedWorkflowEngine _engine =
      AtlasUnifiedWorkflowEngine.instance;
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _engine.start();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _testAutomation() async {
    await _engine.publishTestEvent(AtlasEventType.inventoryLowStock);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento de teste processado.')),
    );
  }

  Future<void> _openEditor([AtlasAutomationRule? existing]) async {
    final result = await showDialog<AtlasAutomationRule>(
      context: context,
      builder: (context) => _RuleEditorDialog(rule: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _engine.addRule(result);
    } else {
      await _engine.updateRule(result);
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteRule(AtlasAutomationRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir automação?'),
        content: Text('A regra “${rule.title}” será removida.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _engine.deleteRule(rule.id);
    if (mounted) setState(() {});
  }

  String _dateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final rules = _engine.rules;
    final executions = _engine.executions;
    final enabled = rules.where((item) => item.enabled).length;
    final success = executions.where((item) => item.success).length;
    final successRate = executions.isEmpty
        ? 100
        : ((success / executions.length) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Atlas Workflow Automation'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Testar automação',
            onPressed: _loading ? null : _testAutomation,
            icon: const Icon(Icons.science_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SegmentedButton<int>(
                    segments: const <ButtonSegment<int>>[
                      ButtonSegment<int>(
                        value: 0,
                        icon: Icon(Icons.dashboard_outlined),
                        label: Text('Painel'),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: Icon(Icons.rule_outlined),
                        label: Text('Regras'),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        icon: Icon(Icons.history_outlined),
                        label: Text('Histórico'),
                      ),
                    ],
                    selected: <int>{_tabIndex},
                    onSelectionChanged: (value) {
                      setState(() => _tabIndex = value.first);
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _engine.load();
                      if (mounted) setState(() {});
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: _buildTab(
                        rules,
                        executions,
                        enabled,
                        successRate,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _tabIndex == 1 && !_loading
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Nova automação'),
            )
          : null,
    );
  }

  List<Widget> _buildTab(
    List<AtlasAutomationRule> rules,
    List<AtlasAutomationExecution> executions,
    int enabled,
    int successRate,
  ) {
    if (_tabIndex == 1) {
      return <Widget>[
        const Text(
          'Regras de automação',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Crie regras no formato: quando um evento acontecer, execute uma ação.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        ...rules.map(_buildRuleCard),
        const SizedBox(height: 80),
      ];
    }
    if (_tabIndex == 2) {
      return <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Histórico de execuções',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: executions.isEmpty
                  ? null
                  : () async {
                      await _engine.clearExecutions();
                      if (mounted) setState(() {});
                    },
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Limpar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (executions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('Nenhuma automação executada ainda.')),
            ),
          )
        else
          ...executions.take(100).map(_buildExecutionCard),
      ];
    }
    return <Widget>[
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          _Metric('Regras', '${rules.length}', Icons.rule_outlined),
          _Metric('Ativas', '$enabled', Icons.toggle_on_outlined),
          _Metric('Execuções', '${executions.length}', Icons.bolt_outlined),
          _Metric('Taxa de sucesso', '$successRate%', Icons.verified_outlined),
        ],
      ),
      const SizedBox(height: 22),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Motor de automação',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _engine.isRunning
                    ? 'Ativo e observando os eventos do Atlas.'
                    : 'Parado. Abra novamente a tela para iniciar.',
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _testAutomation,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Executar teste de estoque baixo'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Automações ativas',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      ...rules.where((item) => item.enabled).take(6).map(_buildRuleCard),
      const SizedBox(height: 18),
      const Text(
        'Últimas execuções',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      if (executions.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Nenhuma execução registrada.'),
          ),
        )
      else
        ...executions.take(5).map(_buildExecutionCard),
      const SizedBox(height: 60),
    ];
  }

  Widget _buildRuleCard(AtlasAutomationRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Switch(
          value: rule.enabled,
          onChanged: (value) async {
            await _engine.setRuleEnabled(rule.id, value);
            if (mounted) setState(() {});
          },
        ),
        title: Text(
          rule.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${atlasEventTypeLabel(rule.triggerType)} → '
            '${atlasAutomationActionLabel(rule.actionType)}\n${rule.description}',
          ),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _openEditor(rule);
            if (value == 'delete') _deleteRule(rule);
          },
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
            PopupMenuItem<String>(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionCard(AtlasAutomationExecution execution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(execution.success ? Icons.check : Icons.error_outline),
        ),
        title: Text(execution.actionTitle),
        subtitle: Text(
          '${execution.ruleTitle}\n${execution.message}\n'
          '${_dateTime(execution.executedAt)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _RuleEditorDialog extends StatefulWidget {
  const _RuleEditorDialog({this.rule});

  final AtlasAutomationRule? rule;

  @override
  State<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<_RuleEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _actionTitle;
  late AtlasEventType _trigger;
  late AtlasAutomationActionType _action;
  late AtlasEventPriority _priority;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _title = TextEditingController(text: rule?.title ?? '');
    _description = TextEditingController(text: rule?.description ?? '');
    _actionTitle = TextEditingController(text: rule?.actionTitle ?? '');
    _trigger = rule?.triggerType ?? AtlasEventType.inventoryLowStock;
    _action = rule?.actionType ?? AtlasAutomationActionType.createNotification;
    _priority = rule?.priority ?? AtlasEventPriority.normal;
    _enabled = rule?.enabled ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _actionTitle.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty || _actionTitle.text.trim().isEmpty) {
      return;
    }
    Navigator.pop(
      context,
      AtlasAutomationRule(
        id: widget.rule?.id ?? 'rule_${DateTime.now().microsecondsSinceEpoch}',
        title: _title.text.trim(),
        description: _description.text.trim(),
        triggerType: _trigger,
        actionType: _action,
        actionTitle: _actionTitle.text.trim(),
        enabled: _enabled,
        priority: _priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? 'Nova automação' : 'Editar automação'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Nome da regra'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AtlasEventType>(
                initialValue: _trigger,
                decoration: const InputDecoration(labelText: 'Gatilho'),
                items: AtlasEventType.values
                    .map(
                      (item) => DropdownMenuItem<AtlasEventType>(
                        value: item,
                        child: Text(atlasEventTypeLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _trigger = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AtlasAutomationActionType>(
                initialValue: _action,
                decoration: const InputDecoration(labelText: 'Ação'),
                items: AtlasAutomationActionType.values
                    .map(
                      (item) => DropdownMenuItem<AtlasAutomationActionType>(
                        value: item,
                        child: Text(atlasAutomationActionLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _action = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _actionTitle,
                decoration: const InputDecoration(
                  labelText: 'Título da ação gerada',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AtlasEventPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: AtlasEventPriority.values
                    .map(
                      (item) => DropdownMenuItem<AtlasEventPriority>(
                        value: item,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Automação ativa'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
