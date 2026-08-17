import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/consultancy_workflow/data/services/atlas_consultancy_workflow_repository.dart';
import 'package:projeto_atlas/features/consultancy_workflow/domain/models/atlas_consultancy_case.dart';
import 'package:projeto_atlas/features/consultancy_workflow/domain/services/atlas_consultancy_workflow_engine.dart';

class AtlasConsultancyWorkflowScreen extends StatefulWidget {
  const AtlasConsultancyWorkflowScreen({super.key});

  @override
  State<AtlasConsultancyWorkflowScreen> createState() =>
      _AtlasConsultancyWorkflowScreenState();
}

class _AtlasConsultancyWorkflowScreenState
    extends State<AtlasConsultancyWorkflowScreen> {
  final AtlasConsultancyWorkflowRepository _repository =
      AtlasConsultancyWorkflowRepository();
  final AtlasConsultancyWorkflowEngine _engine =
      const AtlasConsultancyWorkflowEngine();

  List<AtlasConsultancyCase> _cases = <AtlasConsultancyCase>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<AtlasConsultancyCase> cases = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _cases = cases;
      _loading = false;
    });
  }

  Future<void> _save() => _repository.save(_cases);

  Future<void> _createCase() async {
    final TextEditingController client = TextEditingController();
    final TextEditingController farm = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Novo caso de consultoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: client,
                decoration: const InputDecoration(labelText: 'Cliente'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: farm,
                decoration: const InputDecoration(labelText: 'Propriedade'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true ||
        client.text.trim().isEmpty ||
        farm.text.trim().isEmpty) {
      return;
    }
    final DateTime now = DateTime.now();
    setState(() {
      _cases = <AtlasConsultancyCase>[
        AtlasConsultancyCase(
          id: 'case_${now.microsecondsSinceEpoch}',
          clientName: client.text.trim(),
          farmName: farm.text.trim(),
          stage: AtlasConsultancyStage.initialContact,
          createdAt: now,
          visits: const <AtlasConsultancyVisit>[],
          actions: const <AtlasConsultancyAction>[],
          notes: '',
        ),
        ..._cases,
      ];
    });
    await _save();
  }

  Future<void> _advance(AtlasConsultancyCase item) async {
    final int index = AtlasConsultancyStage.values.indexOf(item.stage);
    if (index >= AtlasConsultancyStage.values.length - 1) {
      return;
    }
    setState(() {
      _cases = _cases
          .map(
            (current) => current.id == item.id
                ? current.copyWith(
                    stage: AtlasConsultancyStage.values[index + 1],
                  )
                : current,
          )
          .toList();
    });
    await _save();
  }

  Future<void> _toggleAction(
    AtlasConsultancyCase caseItem,
    AtlasConsultancyAction action,
  ) async {
    final List<AtlasConsultancyAction> updatedActions = caseItem.actions
        .map(
          (item) => item.id == action.id
              ? item.copyWith(completed: !item.completed)
              : item,
        )
        .toList();
    setState(() {
      _cases = _cases
          .map(
            (item) => item.id == caseItem.id
                ? item.copyWith(actions: updatedActions)
                : item,
          )
          .toList();
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fluxo de Consultoria Veterinária')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCase,
        icon: const Icon(Icons.add),
        label: const Text('Novo caso'),
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
                    'Casos de consultoria',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_cases.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhum caso cadastrado.'),
                      ),
                    ),
                  ..._cases.map(_buildCaseCard),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    final AtlasConsultancyWorkflowSummary summary = _engine.summarize(_cases);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Visão geral da consultoria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _metric('Ativos', summary.activeCases.toString()),
                _metric('Concluídos', summary.completedCases.toString()),
                _metric('Ações pendentes', summary.pendingActions.toString()),
                _metric('Atrasadas', summary.overdueActions.toString()),
                _metric('Próximas visitas', summary.upcomingVisits.toString()),
                _metric(
                  'Execução',
                  '${(summary.executionRate * 100).round()}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 145,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(AtlasConsultancyCase item) {
    final int completed = item.actions
        .where((action) => action.completed)
        .length;
    final double progress = item.actions.isEmpty
        ? 0
        : completed / item.actions.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(
            '${AtlasConsultancyStage.values.indexOf(item.stage) + 1}',
          ),
        ),
        title: Text(item.farmName),
        subtitle: Text('${item.clientName} • ${item.stage.label}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Plano executado: ${(progress * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          if (item.actions.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Nenhuma ação cadastrada neste caso.'),
            ),
          ...item.actions.map(
            (action) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: action.completed,
              onChanged: (_) => _toggleAction(item, action),
              title: Text(action.title),
              subtitle: Text(
                '${action.responsible} • ${DateFormat('dd/MM/yyyy').format(action.deadline)}',
              ),
            ),
          ),
          if (item.visits.isNotEmpty) ...<Widget>[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Visitas: ${item.visits.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: item.stage == AtlasConsultancyStage.completed
                  ? null
                  : () => _advance(item),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                item.stage == AtlasConsultancyStage.completed
                    ? 'Consultoria concluída'
                    : 'Avançar etapa',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
