import 'package:flutter/material.dart';

import '../../data/services/atlas_quality_repository.dart';
import '../../domain/models/atlas_quality_data.dart';
import '../../domain/services/atlas_quality_engine.dart';

class AtlasQualityCenterScreen extends StatefulWidget {
  const AtlasQualityCenterScreen({super.key});

  @override
  State<AtlasQualityCenterScreen> createState() => _AtlasQualityCenterScreenState();
}

class _AtlasQualityCenterScreenState extends State<AtlasQualityCenterScreen> {
  final AtlasQualityRepository _repository = AtlasQualityRepository();
  final AtlasQualityEngine _engine = AtlasQualityEngine();
  AtlasQualityState? _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AtlasQualityState state = await _repository.load();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _save(AtlasQualityState state) async {
    await _repository.save(state);
    if (!mounted) return;
    setState(() => _state = state);
  }

  Future<void> _toggleCheck(AtlasQualityCheck check, bool completed) async {
    final AtlasQualityState current = _state!;
    final List<AtlasQualityCheck> updated = current.checks.map((AtlasQualityCheck item) {
      if (item.id != check.id) return item;
      return item.copyWith(
        completed: completed,
        completedAt: completed ? DateTime.now() : null,
      );
    }).toList();
    await _save(current.copyWith(checks: updated, lastReviewAt: DateTime.now()));
  }

  Future<void> _toggleIncident(AtlasQualityIncident incident) async {
    final AtlasQualityState current = _state!;
    final List<AtlasQualityIncident> updated = current.incidents.map((AtlasQualityIncident item) {
      if (item.id != incident.id) return item;
      final bool resolved = !item.resolved;
      return item.copyWith(resolved: resolved, resolvedAt: resolved ? DateTime.now() : null);
    }).toList();
    await _save(current.copyWith(incidents: updated, lastReviewAt: DateTime.now()));
  }

  Future<void> _addIncident() async {
    final TextEditingController title = TextEditingController();
    final TextEditingController module = TextEditingController();
    final TextEditingController description = TextEditingController();
    String severity = 'Média';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Registrar ocorrência'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(controller: title, decoration: const InputDecoration(labelText: 'Título')),
                    const SizedBox(height: 12),
                    TextField(controller: module, decoration: const InputDecoration(labelText: 'Módulo')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: severity,
                      decoration: const InputDecoration(labelText: 'Severidade'),
                      items: const <String>['Baixa', 'Média', 'Alta', 'Crítica']
                          .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) setDialogState(() => severity = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar')),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || title.text.trim().isEmpty || module.text.trim().isEmpty) return;
    final AtlasQualityState current = _state!;
    final AtlasQualityIncident incident = AtlasQualityIncident(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.text.trim(),
      description: description.text.trim(),
      module: module.text.trim(),
      severity: severity,
      createdAt: DateTime.now(),
      resolved: false,
    );
    await _save(current.copyWith(
      incidents: <AtlasQualityIncident>[incident, ...current.incidents],
      lastReviewAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Atlas Quality & Stability Center'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Visão geral'),
              Tab(text: 'Checklist'),
              Tab(text: 'Ocorrências'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : _addIncident,
          icon: const Icon(Icons.add_alert_outlined),
          label: const Text('Ocorrência'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: <Widget>[
                  _overview(),
                  _checklist(),
                  _incidents(),
                ],
              ),
      ),
    );
  }

  Widget _overview() {
    final AtlasQualityState state = _state!;
    final AtlasQualitySummary summary = _engine.summarize(state);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Índice de estabilidade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Text('${summary.score}%', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 18),
                    Expanded(child: LinearProgressIndicator(value: summary.score / 100, minHeight: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Última revisão: ${_formatDate(state.lastReviewAt)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _metric('Checklist concluído', '${summary.completedChecks}/${summary.totalChecks}', Icons.task_alt),
            _metric('Ocorrências abertas', '${summary.openIncidents}', Icons.report_problem_outlined),
            _metric('Críticos pendentes', '${summary.criticalPending}', Icons.priority_high),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Próximas prioridades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...state.checks.where((AtlasQualityCheck item) => !item.completed).take(4).map(
              (AtlasQualityCheck item) => Card(
                child: ListTile(
                  leading: Icon(item.critical ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                  title: Text(item.title),
                  subtitle: Text(item.description),
                  trailing: item.critical ? const Chip(label: Text('Crítico')) : null,
                ),
              ),
            ),
      ],
    );
  }

  Widget _metric(String title, String value, IconData icon) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(title),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checklist() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: _state!.checks.map((AtlasQualityCheck check) {
        return Card(
          child: CheckboxListTile(
            value: check.completed,
            onChanged: (bool? value) => _toggleCheck(check, value ?? false),
            title: Text(check.title),
            subtitle: Text('${check.category} • ${check.description}'),
            secondary: check.critical ? const Icon(Icons.priority_high) : const Icon(Icons.fact_check_outlined),
          ),
        );
      }).toList(),
    );
  }

  Widget _incidents() {
    final List<AtlasQualityIncident> incidents = _state!.incidents;
    if (incidents.isEmpty) return const Center(child: Text('Nenhuma ocorrência registrada.'));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: incidents.map((AtlasQualityIncident incident) {
        return Card(
          child: ListTile(
            leading: Icon(incident.resolved ? Icons.check_circle_outline : Icons.error_outline),
            title: Text(incident.title),
            subtitle: Text('${incident.module} • ${incident.severity}\n${incident.description}'),
            isThreeLine: true,
            trailing: TextButton(
              onPressed: () => _toggleIncident(incident),
              child: Text(incident.resolved ? 'Reabrir' : 'Resolver'),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} às $hour:$minute';
  }
}
