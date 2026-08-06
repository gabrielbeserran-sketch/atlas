
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/automation_strategy/data/atlas_automation_repository.dart';

class AtlasAutomationStrategyScreen extends StatefulWidget {
  const AtlasAutomationStrategyScreen({super.key});

  @override
  State<AtlasAutomationStrategyScreen> createState() =>
      _AtlasAutomationStrategyScreenState();
}

class _AtlasAutomationStrategyScreenState
    extends State<AtlasAutomationStrategyScreen> {
  final repository = AtlasAutomationRepository();
  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> rules = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> objectives = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final values = await Future.wait([
        repository.dashboard(),
        repository.rules(),
        repository.calendar(),
        repository.objectives(),
      ]);
      if (!mounted) return;
      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        rules = values[1] as List<Map<String, dynamic>>;
        events = values[2] as List<Map<String, dynamic>>;
        objectives = values[3] as List<Map<String, dynamic>>;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automação e Estratégia'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _Metric('Regras ativas',
                            '${dashboard['active_rules'] ?? 0}'),
                        _Metric('Workflows',
                            '${dashboard['running_workflows'] ?? 0}'),
                        _Metric('Objetivos ativos',
                            '${dashboard['active_objectives'] ?? 0}'),
                        _Metric('Progresso médio',
                            '${dashboard['average_objective_progress'] ?? 0}%'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Regras', style: Theme.of(context).textTheme.titleLarge),
                    ...rules.take(6).map(
                          (item) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.auto_awesome_motion),
                              title: Text(item['name']?.toString() ?? ''),
                              subtitle: Text(item['event_type']?.toString() ?? ''),
                              trailing: Text('${item['priority'] ?? 0}'),
                            ),
                          ),
                        ),
                    const SizedBox(height: 18),
                    Text('Agenda', style: Theme.of(context).textTheme.titleLarge),
                    ...events.take(6).map(
                          (item) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_month),
                              title: Text(item['title']?.toString() ?? ''),
                              subtitle: Text(item['category']?.toString() ?? ''),
                            ),
                          ),
                        ),
                    const SizedBox(height: 18),
                    Text('Objetivos',
                        style: Theme.of(context).textTheme.titleLarge),
                    ...objectives.take(6).map(
                          (item) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.flag_outlined),
                              title: Text(item['title']?.toString() ?? ''),
                              subtitle: LinearProgressIndicator(
                                value: ((item['progress_percent'] ?? 0) as num)
                                        .toDouble() /
                                    100,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
