import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_intelligence_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_intelligence_service.dart';

class AtlasEconomicIntelligenceScreen extends StatefulWidget {
  const AtlasEconomicIntelligenceScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasEconomicIntelligenceScreen> createState() =>
      _AtlasEconomicIntelligenceScreenState();
}

class _AtlasEconomicIntelligenceScreenState
    extends State<AtlasEconomicIntelligenceScreen> {
  final service = AtlasEconomicIntelligenceService.instance;

  List<AtlasEconomicProductionMetric> metrics = [];
  List<AtlasEconomicInvestmentScenario> scenarios = [];
  AtlasEconomicSnapshot? snapshot;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    metrics = await service.loadMetrics(
      farmName: widget.actionController.farmName,
    );
    scenarios = await service.loadScenarios(
      farmName: widget.actionController.farmName,
    );
    snapshot = await service.buildSnapshot(
      farmName: widget.actionController.farmName,
      metrics: metrics,
    );
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _addMetric() async {
    var activity = AtlasEconomicActivity.breeding;
    var start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    var end = DateTime.now();

    final hectares = TextEditingController();
    final animals = TextEditingController();
    final arrobas = TextEditingController();
    final liters = TextEditingController();
    final kilograms = TextEditingController();
    final revenue = TextEditingController();
    final variableCost = TextEditingController();
    final fixedCost = TextEditingController();
    final notes = TextEditingController();

    final result = await showDialog<AtlasEconomicProductionMetric>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo indicador econômico'),
              content: SizedBox(
                width: 680,
                height: 650,
                child: ListView(
                  children: [
                    DropdownButtonFormField<AtlasEconomicActivity>(
                      initialValue: activity,
                      decoration: const InputDecoration(
                        labelText: 'Atividade',
                        border: OutlineInputBorder(),
                      ),
                      items: AtlasEconomicActivity.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(atlasEconomicActivityLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => activity = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
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
                    _row(
                      _number(hectares, 'Hectares'),
                      _number(animals, 'Animais'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(arrobas, 'Arrobas produzidas'),
                      _number(liters, 'Litros produzidos'),
                    ),
                    const SizedBox(height: 10),
                    _number(kilograms, 'Quilogramas produzidos'),
                    const SizedBox(height: 10),
                    _row(
                      _number(revenue, 'Receita'),
                      _number(variableCost, 'Custos variáveis'),
                    ),
                    const SizedBox(height: 10),
                    _number(fixedCost, 'Custos fixos'),
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasEconomicProductionMetric(
                        id:
                            'economic_metric_'
                            '${now.microsecondsSinceEpoch}',
                        activity: activity,
                        periodStart: start,
                        periodEnd: end,
                        hectares: _double(hectares.text),
                        animalCount: int.tryParse(animals.text) ?? 0,
                        arrobasProduced: _double(arrobas.text),
                        litersProduced: _double(liters.text),
                        kilogramsProduced: _double(kilograms.text),
                        revenue: _double(revenue.text),
                        variableCost: _double(variableCost.text),
                        fixedCost: _double(fixedCost.text),
                        farmName: widget.actionController.farmName,
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
      hectares,
      animals,
      arrobas,
      liters,
      kilograms,
      revenue,
      variableCost,
      fixedCost,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveMetric(result);
      await _load();
    }
  }

  Future<void> _addScenario() async {
    var type = AtlasEconomicScenarioType.base;
    final title = TextEditingController();
    final investment = TextEditingController();
    final monthlyRevenue = TextEditingController();
    final monthlyCost = TextEditingController();
    final months = TextEditingController(text: '24');
    final discount = TextEditingController(text: '12');
    final notes = TextEditingController();

    final result = await showDialog<AtlasEconomicInvestmentScenario>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo cenário de investimento'),
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
                      DropdownButtonFormField<AtlasEconomicScenarioType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Cenário',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasEconomicScenarioType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  atlasEconomicScenarioTypeLabel(value),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => type = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _number(investment, 'Investimento inicial'),
                      const SizedBox(height: 10),
                      _row(
                        _number(monthlyRevenue, 'Receita mensal adicional'),
                        _number(monthlyCost, 'Custo mensal adicional'),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        _number(months, 'Horizonte em meses'),
                        _number(discount, 'Taxa anual de desconto (%)'),
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
                    if (title.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasEconomicInvestmentScenario(
                        id:
                            'economic_scenario_'
                            '${now.microsecondsSinceEpoch}',
                        title: title.text.trim(),
                        type: type,
                        initialInvestment: _double(investment.text),
                        monthlyRevenueIncrease: _double(monthlyRevenue.text),
                        monthlyCostIncrease: _double(monthlyCost.text),
                        horizonMonths: int.tryParse(months.text) ?? 0,
                        discountRatePercent: _double(discount.text),
                        farmName: widget.actionController.farmName,
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
      investment,
      monthlyRevenue,
      monthlyCost,
      months,
      discount,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveScenario(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = snapshot;
    final recommendations = current == null
        ? <String>[]
        : service.buildRecommendations(snapshot: current, metrics: metrics);
    final profitability = service.profitabilityByActivity(metrics);

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inteligência econômica'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'DRE'),
              Tab(text: 'Fluxo de caixa'),
              Tab(text: 'Custos'),
              Tab(text: 'Indicadores'),
              Tab(text: 'Simulador'),
              Tab(text: 'Atividades'),
              Tab(text: 'Projeções'),
              Tab(text: 'IA econômica'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addMetric,
          icon: const Icon(Icons.add),
          label: const Text('Novo período'),
        ),
        body: loading && current == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _DreTab(snapshot: current),
                  _CashFlowTab(snapshot: current),
                  _CostsTab(metrics: metrics),
                  _EconomicIndicatorsTab(snapshot: current),
                  _ScenariosTab(scenarios: scenarios, onAdd: _addScenario),
                  _ActivitiesTab(values: profitability),
                  _ProjectionsTab(snapshot: current),
                  _EconomicAiTab(
                    snapshot: current,
                    recommendations: recommendations,
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
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _DreTab extends StatelessWidget {
  const _DreTab({required this.snapshot});

  final AtlasEconomicSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados econômicos.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line('Receita total', item.revenue),
        _line('Custos variáveis', -item.variableCosts),
        _line('Custos fixos', -item.fixedCosts),
        const Divider(),
        _line('EBITDA', item.ebitda, strong: true),
        _line('Resultado líquido', item.netResult, strong: true),
      ],
    );
  }

  Widget _line(String label, double value, {bool strong = false}) {
    return Card(
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(fontWeight: strong ? FontWeight.w900 : null),
        ),
        trailing: Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: strong ? FontWeight.w900 : null),
        ),
      ),
    );
  }
}

class _CashFlowTab extends StatelessWidget {
  const _CashFlowTab({required this.snapshot});

  final AtlasEconomicSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem projeções.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('30 dias', item.projectedBalance30Days, 'R\$'),
        _metric('90 dias', item.projectedBalance90Days, 'R\$'),
        _metric('365 dias', item.projectedBalance365Days, 'R\$'),
      ],
    );
  }
}

class _CostsTab extends StatelessWidget {
  const _CostsTab({required this.metrics});

  final List<AtlasEconomicProductionMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const Center(child: Text('Nenhum período econômico cadastrado.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: metrics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Card(
          child: ExpansionTile(
            title: Text(atlasEconomicActivityLabel(item.activity)),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy').format(item.periodStart)} a '
              '${DateFormat('dd/MM/yyyy').format(item.periodEnd)}',
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      'R\$ ${item.costPerHectare.toStringAsFixed(2)}/ha',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'R\$ ${item.costPerAnimal.toStringAsFixed(2)}/cabeça',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'R\$ ${item.costPerArroba.toStringAsFixed(2)}/@',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'R\$ ${item.costPerLiter.toStringAsFixed(2)}/L',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EconomicIndicatorsTab extends StatelessWidget {
  const _EconomicIndicatorsTab({required this.snapshot});

  final AtlasEconomicSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem indicadores.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('Margem operacional', item.operatingMarginPercent, '%'),
        _metric('ROI', item.roiPercent, '%'),
        _metric('Liquidez', item.liquidity, ''),
        _metric('Score financeiro', item.financialScore, '/100'),
      ],
    );
  }
}

class _ScenariosTab extends StatelessWidget {
  const _ScenariosTab({required this.scenarios, required this.onAdd});

  final List<AtlasEconomicInvestmentScenario> scenarios;
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
              label: const Text('Novo cenário'),
            ),
          ),
        ),
        Expanded(
          child: scenarios.isEmpty
              ? const Center(child: Text('Nenhum cenário de investimento.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: scenarios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = scenarios[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.title),
                        subtitle: Text(
                          '${atlasEconomicScenarioTypeLabel(item.type)} • '
                          'ROI ${item.roiPercent.toStringAsFixed(1)}%',
                        ),
                        trailing: Text(
                          item.paybackMonths == null
                              ? 'Sem payback'
                              : '${item.paybackMonths!.toStringAsFixed(1)} meses',
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

class _ActivitiesTab extends StatelessWidget {
  const _ActivitiesTab({required this.values});

  final Map<AtlasEconomicActivity, double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text('Sem atividades para comparar.'));
    }
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          child: ListTile(
            title: Text(atlasEconomicActivityLabel(entry.key)),
            trailing: Text(
              'R\$ ${entry.value.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectionsTab extends StatelessWidget {
  const _ProjectionsTab({required this.snapshot});

  final AtlasEconomicSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem projeções.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Projeções de caixa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        _metric('Curto prazo', item.projectedBalance30Days, 'R\$'),
        _metric('Médio prazo', item.projectedBalance90Days, 'R\$'),
        _metric('Longo prazo', item.projectedBalance365Days, 'R\$'),
      ],
    );
  }
}

class _EconomicAiTab extends StatelessWidget {
  const _EconomicAiTab({required this.snapshot, required this.recommendations});

  final AtlasEconomicSnapshot? snapshot;
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (snapshot != null)
          _metric('Score econômico', snapshot!.financialScore, '/100'),
        const SizedBox(height: 12),
        ...recommendations.map(
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
