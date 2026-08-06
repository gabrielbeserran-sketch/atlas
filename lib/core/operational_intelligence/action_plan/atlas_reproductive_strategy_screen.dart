import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_strategy_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_strategy_service.dart';

class AtlasReproductiveStrategyScreen extends StatefulWidget {
  const AtlasReproductiveStrategyScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasReproductiveStrategyScreen> createState() =>
      _AtlasReproductiveStrategyScreenState();
}

class _AtlasReproductiveStrategyScreenState
    extends State<AtlasReproductiveStrategyScreen> {
  final service = AtlasReproductiveStrategyService.instance;

  List<AtlasReproductiveAnnualPlan> plans = [];
  List<AtlasReproductiveSimulation> simulations = [];
  AtlasReproductiveExecutiveSnapshot? snapshot;
  List<String> intelligence = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    plans = await service.loadPlans(
      farmName: widget.actionController.farmName,
    );
    simulations = await service.loadSimulations(
      farmName: widget.actionController.farmName,
    );
    snapshot = await service.buildSnapshot(
      farmName: widget.actionController.farmName,
    );
    intelligence = await service.buildIntelligence(
      farmName: widget.actionController.farmName,
      snapshot: snapshot!,
    );
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _openOperationalModule() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AtlasReproductiveIntelligenceScreen(
          actionController: widget.actionController,
        ),
      ),
    );
  }

  Future<void> _addPlan() async {
    final title = TextEditingController();
    final females = TextEditingController();
    final rate = TextEditingController(text: '55');
    final calves = TextEditingController();
    final budget = TextEditingController();
    final team = TextEditingController();
    final notes = TextEditingController();

    var year = DateTime.now().year;
    var start = DateTime(year, 1, 1);
    var end = DateTime(year, 12, 31);
    var status = AtlasReproductivePlanStatus.planned;

    final result =
        await showDialog<AtlasReproductiveAnnualPlan>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Planejamento reprodutivo anual'),
              content: SizedBox(
                width: 650,
                height: 650,
                child: ListView(
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(females, 'Fêmeas-alvo'),
                      _number(rate, 'Meta de prenhez (%)'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(calves, 'Bezerros-alvo'),
                      _number(budget, 'Orçamento'),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        title: const Text('Ano do planejamento'),
                        trailing: Text(
                          year.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<
                        AtlasReproductivePlanStatus>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Situação',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          AtlasReproductivePlanStatus.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    atlasReproductivePlanStatusLabel(
                                      value,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () => status = value,
                          );
                        }
                      },
                    ),
                    _dateTile(
                      context: dialogContext,
                      title: 'Início',
                      date: start,
                      onChanged: (value) {
                        setDialogState(() => start = value);
                      },
                    ),
                    _dateTile(
                      context: dialogContext,
                      title: 'Fim',
                      date: end,
                      onChanged: (value) {
                        setDialogState(() => end = value);
                      },
                    ),
                    TextField(
                      controller: team,
                      decoration: const InputDecoration(
                        labelText: 'Equipe',
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
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasReproductiveAnnualPlan(
                        id: 'reproductive_plan_'
                            '${now.microsecondsSinceEpoch}',
                        title: title.text.trim(),
                        year: year,
                        targetFemales:
                            int.tryParse(females.text) ?? 0,
                        targetPregnancyRatePercent:
                            _double(rate.text),
                        targetCalves:
                            int.tryParse(calves.text) ?? 0,
                        budget: _double(budget.text),
                        startAt: start,
                        endAt: end,
                        status: status,
                        team: team.text.trim(),
                        farmName:
                            widget.actionController.farmName,
                        notes: notes.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in [
      title,
      females,
      rate,
      calves,
      budget,
      team,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.savePlan(result);
      await _load();
    }
  }

  Future<void> _addSimulation() async {
    final title = TextEditingController();
    final females = TextEditingController();
    final pregnancyRate = TextEditingController(text: '55');
    final survivalRate = TextEditingController(text: '95');
    final cost = TextEditingController();
    final calfValue = TextEditingController();
    final notes = TextEditingController();

    final result =
        await showDialog<AtlasReproductiveSimulation>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Simulador reprodutivo'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _number(females, 'Fêmeas'),
                  const SizedBox(height: 10),
                  _row(
                    _number(
                      pregnancyRate,
                      'Prenhez esperada (%)',
                    ),
                    _number(
                      survivalRate,
                      'Sobrevivência de bezerros (%)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _row(
                    _number(
                      cost,
                      'Custo por fêmea',
                    ),
                    _number(
                      calfValue,
                      'Valor por bezerro',
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
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                Navigator.of(dialogContext).pop(
                  AtlasReproductiveSimulation(
                    id: 'reproductive_simulation_'
                        '${now.microsecondsSinceEpoch}',
                    title: title.text.trim(),
                    females:
                        int.tryParse(females.text) ?? 0,
                    expectedPregnancyRatePercent:
                        _double(pregnancyRate.text),
                    expectedCalfSurvivalPercent:
                        _double(survivalRate.text),
                    costPerFemale: _double(cost.text),
                    expectedCalfValue:
                        _double(calfValue.text),
                    farmName:
                        widget.actionController.farmName,
                    notes: notes.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    for (final controller in [
      title,
      females,
      pregnancyRate,
      survivalRate,
      cost,
      calfValue,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveSimulation(result);
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
          title: const Text('Estratégia reprodutiva'),
          actions: [
            IconButton(
              tooltip: 'Abrir módulo operacional',
              onPressed: _openOperationalModule,
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
              Tab(text: 'Agenda e protocolos'),
              Tab(text: 'Indicadores'),
              Tab(text: 'Genética'),
              Tab(text: 'IA reprodutiva'),
              Tab(text: 'Alertas'),
              Tab(text: 'Simulador'),
              Tab(text: 'Planejamento anual'),
            ],
          ),
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: _addPlan,
          icon: const Icon(Icons.add),
          label: const Text('Novo plano'),
        ),
        body: loading && current == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  _ReproductiveDashboardTab(snapshot: current),
                  _OperationalBridgeTab(
                    onOpen: _openOperationalModule,
                  ),
                  _ReproductiveIndicatorsTab(
                    snapshot: current,
                  ),
                  _GeneticsBridgeTab(
                    onOpen: _openOperationalModule,
                  ),
                  _ReproductiveAiTab(
                    snapshot: current,
                    intelligence: intelligence,
                  ),
                  _ReproductiveAlertsTab(
                    alerts: intelligence,
                  ),
                  _ReproductiveSimulationTab(
                    simulations: simulations,
                    onAdd: _addSimulation,
                  ),
                  _AnnualPlansTab(
                    plans: plans,
                    onAdd: _addPlan,
                  ),
                ],
              ),
      ),
    );
  }

  static Widget _row(Widget first, Widget second) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }

  static Widget _number(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static Widget _dateTile({
    required BuildContext context,
    required String title,
    required DateTime date,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _ReproductiveDashboardTab extends StatelessWidget {
  const _ReproductiveDashboardTab({
    required this.snapshot,
  });

  final AtlasReproductiveExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados reprodutivos.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _card('Eventos', item.totalEvents.toDouble(), ''),
            _card('Inseminações', item.inseminations.toDouble(), ''),
            _card('Prenhezes', item.positivePregnancies.toDouble(), ''),
            _card('Partos', item.births.toDouble(), ''),
            _card('Prenhez', item.pregnancyRatePercent, '%'),
            _card('Concepção', item.conceptionRatePercent, '%'),
            _card('Perdas', item.lossRatePercent, '%'),
            _card('Score', item.reproductiveScore, '/100'),
          ],
        ),
      ],
    );
  }
}

class _OperationalBridgeTab extends StatelessWidget {
  const _OperationalBridgeTab({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onOpen,
        icon: const Icon(Icons.open_in_new),
        label: const Text(
          'Abrir agenda, IATF, protocolos e diagnósticos',
        ),
      ),
    );
  }
}

class _ReproductiveIndicatorsTab extends StatelessWidget {
  const _ReproductiveIndicatorsTab({
    required this.snapshot,
  });

  final AtlasReproductiveExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem indicadores.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('Taxa de prenhez', item.pregnancyRatePercent, '%'),
        _metric('Taxa de concepção', item.conceptionRatePercent, '%'),
        _metric('Taxa de perdas', item.lossRatePercent, '%'),
        _metric('Partos projetados', item.projectedBirths.toDouble(), ''),
      ],
    );
  }
}

class _GeneticsBridgeTab extends StatelessWidget {
  const _GeneticsBridgeTab({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.account_tree_outlined),
            title: Text('Genealogia e ranking genético'),
            subtitle: Text(
              'Use o módulo operacional para cadastrar pai, mãe, índice genético, fertilidade e mérito maternal.',
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Abrir inteligência genética'),
        ),
      ],
    );
  }
}

class _ReproductiveAiTab extends StatelessWidget {
  const _ReproductiveAiTab({
    required this.snapshot,
    required this.intelligence,
  });

  final AtlasReproductiveExecutiveSnapshot? snapshot;
  final List<String> intelligence;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (snapshot != null)
          _metric(
            'Score reprodutivo',
            snapshot!.reproductiveScore,
            '/100',
          ),
        const SizedBox(height: 10),
        ...intelligence.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReproductiveAlertsTab extends StatelessWidget {
  const _ReproductiveAlertsTab({
    required this.alerts,
  });

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text(alerts[index]),
        ),
      ),
    );
  }
}

class _ReproductiveSimulationTab extends StatelessWidget {
  const _ReproductiveSimulationTab({
    required this.simulations,
    required this.onAdd,
  });

  final List<AtlasReproductiveSimulation> simulations;
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
              label: const Text('Nova simulação'),
            ),
          ),
        ),
        Expanded(
          child: simulations.isEmpty
              ? const Center(
                  child: Text('Nenhuma simulação cadastrada.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: simulations.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = simulations[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.expectedCalves} bezerros • '
                          'ROI ${item.roiPercent.toStringAsFixed(1)}%',
                        ),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          _metric(
                            'Receita esperada',
                            item.expectedRevenue,
                            'R\$',
                          ),
                          _metric(
                            'Custo total',
                            item.totalCost,
                            'R\$',
                          ),
                          _metric(
                            'Resultado esperado',
                            item.expectedResult,
                            'R\$',
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AnnualPlansTab extends StatelessWidget {
  const _AnnualPlansTab({
    required this.plans,
    required this.onAdd,
  });

  final List<AtlasReproductiveAnnualPlan> plans;
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
              ? const Center(
                  child: Text('Nenhum plano anual cadastrado.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = plans[index];
                    return Card(
                      child: ListTile(
                        title: Text('${item.title} — ${item.year}'),
                        subtitle: Text(
                          '${item.targetFemales} fêmeas • '
                          '${item.projectedPregnancies} prenhezes projetadas • '
                          '${atlasReproductivePlanStatusLabel(item.status)}',
                        ),
                        trailing: Text(
                          'R\$ ${item.budget.toStringAsFixed(2)}',
                        ),
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
              '${unit == '%' ? '%' : unit == '/100' ? '/100' : ''}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
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
        '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
        '${unit == '%' ? '%' : unit == '/100' ? '/100' : ''}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}
