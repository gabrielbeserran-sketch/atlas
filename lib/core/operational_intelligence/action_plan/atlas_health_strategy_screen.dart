import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_strategy_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_strategy_service.dart';

class AtlasHealthStrategyScreen extends StatefulWidget {
  const AtlasHealthStrategyScreen({required this.actionController, super.key});

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasHealthStrategyScreen> createState() =>
      _AtlasHealthStrategyScreenState();
}

class _AtlasHealthStrategyScreenState extends State<AtlasHealthStrategyScreen> {
  final service = AtlasHealthStrategyService.instance;

  AtlasHealthExecutiveSnapshot? snapshot;
  List<AtlasEpidemiologicalCluster> clusters = [];
  List<AtlasHealthAnnualPlan> plans = [];
  List<String> recommendations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    snapshot = await service.buildSnapshot(
      farmName: widget.actionController.farmName,
    );
    clusters = await service.buildClusters(
      farmName: widget.actionController.farmName,
    );
    plans = await service.loadPlans(farmName: widget.actionController.farmName);
    recommendations = await service.buildRecommendations(
      farmName: widget.actionController.farmName,
      snapshot: snapshot!,
    );
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _openOperational() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasHealthIntelligenceScreen(
          actionController: widget.actionController,
        ),
      ),
    );
  }

  Future<void> _addPlan() async {
    final title = TextEditingController();
    final target = TextEditingController();
    final budget = TextEditingController();
    final coverage = TextEditingController(text: '95');
    final responsible = TextEditingController();
    final notes = TextEditingController();
    final year = DateTime.now().year;

    final result = await showDialog<AtlasHealthAnnualPlan>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Planejamento sanitário anual'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: target,
                  decoration: const InputDecoration(
                    labelText: 'Grupo-alvo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                _number(budget, 'Orçamento'),
                const SizedBox(height: 10),
                _number(coverage, 'Meta de cobertura (%)'),
                const SizedBox(height: 10),
                TextField(
                  controller: responsible,
                  decoration: const InputDecoration(
                    labelText: 'Responsável',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final now = DateTime.now();
              Navigator.of(dialogContext).pop(
                AtlasHealthAnnualPlan(
                  id:
                      'health_plan_'
                      '${now.microsecondsSinceEpoch}',
                  title: title.text.trim(),
                  year: year,
                  targetGroup: target.text.trim(),
                  budget: _double(budget.text),
                  targetCoveragePercent: _double(coverage.text),
                  responsibleName: responsible.text.trim(),
                  farmName: widget.actionController.farmName,
                  notes: notes.text.trim(),
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    for (final controller in [
      title,
      target,
      budget,
      coverage,
      responsible,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.savePlan(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = snapshot;

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estratégia sanitária'),
          actions: [
            IconButton(
              tooltip: 'Abrir módulo operacional',
              onPressed: _openOperational,
              icon: const Icon(Icons.open_in_new),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Painel'),
              Tab(text: 'Calendário'),
              Tab(text: 'Vacinação'),
              Tab(text: 'Medicamentos'),
              Tab(text: 'Epidemiologia'),
              Tab(text: 'IA sanitária'),
              Tab(text: 'Indicadores'),
              Tab(text: 'Planejamento'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addPlan,
          icon: const Icon(Icons.add),
          label: const Text('Novo plano'),
        ),
        body: loading && current == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _Dashboard(snapshot: current),
                  _Bridge(
                    title: 'Calendário sanitário e protocolos',
                    description:
                        'Abra o módulo operacional para cadastrar protocolos, datas e grupos-alvo.',
                    onOpen: _openOperational,
                  ),
                  _Bridge(
                    title: 'Vacinação e antiparasitários',
                    description:
                        'Registre vacinações, vermifugações, doses e responsáveis.',
                    onOpen: _openOperational,
                  ),
                  _Bridge(
                    title: 'Medicamentos e tratamentos',
                    description:
                        'Controle lotes, validade, carência, tratamentos e custos.',
                    onOpen: _openOperational,
                  ),
                  _Clusters(clusters: clusters),
                  _Recommendations(recommendations: recommendations),
                  _Indicators(snapshot: current),
                  _Plans(plans: plans, onAdd: _addPlan),
                ],
              ),
      ),
    );
  }

  static Widget _number(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.snapshot});

  final AtlasHealthExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados sanitários.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _card('Eventos', item.totalEvents.toDouble(), ''),
            _card('Vacinações', item.vaccinations.toDouble(), ''),
            _card('Vermifugações', item.dewormings.toDouble(), ''),
            _card('Tratamentos', item.treatments.toDouble(), ''),
            _card('Morbidade', item.morbidityRatePercent, '%'),
            _card('Mortalidade', item.mortalityRatePercent, '%'),
            _card('Cobertura', item.protocolCoveragePercent, '%'),
            _card('Score', item.healthScore, '/100'),
          ],
        ),
      ],
    );
  }
}

class _Bridge extends StatelessWidget {
  const _Bridge({
    required this.title,
    required this.description,
    required this.onOpen,
  });

  final String title;
  final String description;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(description),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir módulo operacional'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Clusters extends StatelessWidget {
  const _Clusters({required this.clusters});

  final List<AtlasEpidemiologicalCluster> clusters;

  @override
  Widget build(BuildContext context) {
    if (clusters.isEmpty) {
      return const Center(child: Text('Sem agrupamentos epidemiológicos.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clusters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = clusters[index];
        return Card(
          child: ListTile(
            title: Text(item.label),
            subtitle: Text(
              '${item.caseCount} caso(s) • '
              '${item.mortalityCount} morte(s)',
            ),
            trailing: Text(
              'Risco ${item.riskScore.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );
      },
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({required this.recommendations});

  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: Text(recommendations[index]),
        ),
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.snapshot});

  final AtlasHealthExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem indicadores.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('Custo sanitário', item.totalCost, 'R\$'),
        _metric('Morbidade', item.morbidityRatePercent, '%'),
        _metric('Mortalidade', item.mortalityRatePercent, '%'),
        _metric('Cobertura de protocolos', item.protocolCoveragePercent, '%'),
        _metric('Score sanitário', item.healthScore, '/100'),
      ],
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({required this.plans, required this.onAdd});

  final List<AtlasHealthAnnualPlan> plans;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo planejamento'),
            ),
          ),
        ),
        Expanded(
          child: plans.isEmpty
              ? const Center(child: Text('Nenhum planejamento sanitário.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = plans[index];
                    return Card(
                      child: ListTile(
                        title: Text('${item.title} — ${item.year}'),
                        subtitle: Text(
                          '${item.targetGroup} • '
                          'meta ${item.targetCoveragePercent.toStringAsFixed(1)}%',
                        ),
                        trailing: Text('R\$ ${item.budget.toStringAsFixed(2)}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Widget _card(String title, double value, String unit) {
  return SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
              '${unit == '%'
                  ? '%'
                  : unit == '/100'
                  ? '/100'
                  : ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _metric(String title, double value, String unit) {
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        '${unit == 'R\$' ? 'R\$ ' : ''}'
        '${value.toStringAsFixed(2)}'
        '${unit == '%'
            ? '%'
            : unit == '/100'
            ? '/100'
            : ''}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ),
  );
}
