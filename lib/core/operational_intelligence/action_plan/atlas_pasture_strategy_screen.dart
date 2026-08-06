import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_management_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_strategy_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_strategy_service.dart';

class AtlasPastureStrategyScreen extends StatefulWidget {
  const AtlasPastureStrategyScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasPastureStrategyScreen> createState() =>
      _AtlasPastureStrategyScreenState();
}

class _AtlasPastureStrategyScreenState
    extends State<AtlasPastureStrategyScreen> {
  final strategy = AtlasPastureStrategyService.instance;
  final pasture = AtlasPastureService.instance;

  AtlasPastureExecutiveSnapshot? snapshot;
  List<AtlasPastureOccupationRecommendation> recommendations =
      [];
  List<AtlasPastureRecoveryPlan> recoveryPlans = [];
  List<AtlasPaddock> paddocks = [];
  List<String> intelligence = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    snapshot = await strategy.buildSnapshot(
      farmName: widget.actionController.farmName,
    );
    recommendations =
        await strategy.buildOccupationRecommendations(
      farmName: widget.actionController.farmName,
    );
    recoveryPlans = await strategy.loadRecoveryPlans(
      farmName: widget.actionController.farmName,
    );
    paddocks = await pasture.loadPaddocks(
      farmName: widget.actionController.farmName,
    );
    intelligence = await strategy.buildRecommendations(
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
        builder: (_) => AtlasPastureManagementScreen(
          actionController: widget.actionController,
        ),
      ),
    );
  }

  Future<void> _addRecoveryPlan() async {
    if (paddocks.isEmpty) {
      return;
    }

    var paddockId = paddocks.first.id;
    var start = DateTime.now();
    var end = DateTime.now().add(const Duration(days: 90));
    final title = TextEditingController();
    final cost = TextEditingController();
    final dryMatter = TextEditingController();
    final support = TextEditingController();
    final responsible = TextEditingController();
    final notes = TextEditingController();

    final result =
        await showDialog<AtlasPastureRecoveryPlan>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Plano de recuperação'),
              content: SizedBox(
                width: 620,
                height: 600,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: paddockId,
                      decoration: const InputDecoration(
                        labelText: 'Piquete',
                        border: OutlineInputBorder(),
                      ),
                      items: paddocks
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () => paddockId = value,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _number(cost, 'Custo estimado'),
                    const SizedBox(height: 10),
                    _number(
                      dryMatter,
                      'Ganho esperado de MS (kg/ha)',
                    ),
                    const SizedBox(height: 10),
                    _number(
                      support,
                      'Ganho esperado de suporte (UA/ha)',
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
                      AtlasPastureRecoveryPlan(
                        id: 'pasture_recovery_'
                            '${now.microsecondsSinceEpoch}',
                        paddockId: paddockId,
                        title: title.text.trim(),
                        startAt: start,
                        endAt: end,
                        estimatedCost: _double(cost.text),
                        expectedDryMatterGainKgHa:
                            _double(dryMatter.text),
                        expectedSupportGainAuHa:
                            _double(support.text),
                        responsibleName:
                            responsible.text.trim(),
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
      cost,
      dryMatter,
      support,
      responsible,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await strategy.saveRecoveryPlan(result);
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
          title: const Text('Estratégia de pastagens'),
          actions: [
            IconButton(
              tooltip: 'Abrir gestão operacional',
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
              Tab(text: 'Estado do pasto'),
              Tab(text: 'Oferta e lotação'),
              Tab(text: 'Rotação'),
              Tab(text: 'Ocupação inteligente'),
              Tab(text: 'Recuperação'),
              Tab(text: 'IA de pastagens'),
              Tab(text: 'Mapa e operações'),
            ],
          ),
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: _addRecoveryPlan,
          icon: const Icon(Icons.add),
          label: const Text('Plano de recuperação'),
        ),
        body: loading && current == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  _Dashboard(snapshot: current),
                  _PaddockState(paddocks: paddocks),
                  _Support(snapshot: current),
                  _Bridge(
                    title: 'Rotação de pastagens',
                    description:
                        'Cadastre entrada, saída, descanso e operações na gestão operacional.',
                    onOpen: _openOperational,
                  ),
                  _Occupation(
                    recommendations: recommendations,
                  ),
                  _Recovery(
                    plans: recoveryPlans,
                    paddocks: paddocks,
                    onAdd: _addRecoveryPlan,
                  ),
                  _Intelligence(values: intelligence),
                  _Bridge(
                    title: 'Mapa GIS e operações',
                    description:
                        'Acesse coordenadas, adubação, irrigação, roçada e reforma.',
                    onOpen: _openOperational,
                  ),
                ],
              ),
      ),
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

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.snapshot});

  final AtlasPastureExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados de pastagem.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricCard(
              'Piquetes',
              item.totalPaddocks.toDouble(),
              '',
            ),
            _metricCard(
              'Área',
              item.totalAreaHectares,
              'ha',
            ),
            _metricCard(
              'Disponíveis',
              item.availablePaddocks.toDouble(),
              '',
            ),
            _metricCard(
              'Altura média',
              item.averageHeightCm,
              'cm',
            ),
            _metricCard(
              'MS média',
              item.averageDryMatterKgHa,
              'kg/ha',
            ),
            _metricCard(
              'Suporte médio',
              item.averageSupportCapacityAuHa,
              'UA/ha',
            ),
            _metricCard(
              'Suporte total',
              item.totalSupportedAu,
              'UA',
            ),
            _metricCard(
              'Score',
              item.pastureScore,
              '/100',
            ),
          ],
        ),
      ],
    );
  }
}

class _PaddockState extends StatelessWidget {
  const _PaddockState({required this.paddocks});

  final List<AtlasPaddock> paddocks;

  @override
  Widget build(BuildContext context) {
    if (paddocks.isEmpty) {
      return const Center(child: Text('Nenhum piquete cadastrado.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: paddocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = paddocks[index];
        return Card(
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(
              '${atlasPaddockStatusLabel(item.status)} • '
              '${item.currentHeightCm.toStringAsFixed(1)} cm • '
              '${item.dryMatterKgHa.toStringAsFixed(0)} kg MS/ha',
            ),
            trailing: Text(
              item.belowTargetHeight ? 'Atenção' : 'Adequado',
            ),
          ),
        );
      },
    );
  }
}

class _Support extends StatelessWidget {
  const _Support({required this.snapshot});

  final AtlasPastureExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem indicadores.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _line(
          'Capacidade média',
          item.averageSupportCapacityAuHa,
          'UA/ha',
        ),
        _line(
          'Capacidade total',
          item.totalSupportedAu,
          'UA',
        ),
        _line(
          'Matéria seca média',
          item.averageDryMatterKgHa,
          'kg/ha',
        ),
        _line(
          'Piquetes ocupados',
          item.occupiedPaddocks.toDouble(),
          '',
        ),
        _line(
          'Piquetes em descanso',
          item.restingPaddocks.toDouble(),
          '',
        ),
      ],
    );
  }
}

class _Occupation extends StatelessWidget {
  const _Occupation({required this.recommendations});

  final List<AtlasPastureOccupationRecommendation>
      recommendations;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const Center(child: Text('Sem recomendações.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = recommendations[index];
        return Card(
          child: ExpansionTile(
            title: Text(item.paddockName),
            subtitle: Text(
              'Risco ${item.riskLevel} • '
              '${item.recommendedAnimalCount} animais',
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              _line(
                'Dias de ocupação',
                item.recommendedOccupationDays.toDouble(),
                '',
              ),
              _line(
                'Dias de descanso',
                item.recommendedRestDays.toDouble(),
                '',
              ),
              ListTile(
                title: const Text('Justificativa'),
                subtitle: Text(item.reason),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Recovery extends StatelessWidget {
  const _Recovery({
    required this.plans,
    required this.paddocks,
    required this.onAdd,
  });

  final List<AtlasPastureRecoveryPlan> plans;
  final List<AtlasPaddock> paddocks;
  final VoidCallback onAdd;

  String paddockName(String id) {
    for (final item in paddocks) {
      if (item.id == id) {
        return item.name;
      }
    }
    return 'Piquete';
  }

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
              label: const Text('Novo plano'),
            ),
          ),
        ),
        Expanded(
          child: plans.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum plano de recuperação.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = plans[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.title),
                        subtitle: Text(
                          '${paddockName(item.paddockId)} • '
                          '${DateFormat('dd/MM/yyyy').format(item.startAt)} a '
                          '${DateFormat('dd/MM/yyyy').format(item.endAt)}',
                        ),
                        trailing: Text(
                          'R\$ ${item.estimatedCost.toStringAsFixed(2)}',
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

class _Intelligence extends StatelessWidget {
  const _Intelligence({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: Text(values[index]),
        ),
      ),
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
                label: const Text('Abrir gestão operacional'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _metricCard(String title, double value, String unit) {
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
              '${unit.isEmpty || unit == '/100' ? unit : ' $unit'}',
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

Widget _line(String title, double value, String unit) {
  return Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(
        '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
        '${unit.isEmpty ? '' : ' $unit'}',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}
