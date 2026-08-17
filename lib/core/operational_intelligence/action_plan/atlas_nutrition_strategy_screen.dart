import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_intelligence_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_strategy_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_strategy_service.dart';

class AtlasNutritionStrategyScreen extends StatefulWidget {
  const AtlasNutritionStrategyScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasNutritionStrategyScreen> createState() =>
      _AtlasNutritionStrategyScreenState();
}

class _AtlasNutritionStrategyScreenState
    extends State<AtlasNutritionStrategyScreen> {
  final service = AtlasNutritionStrategyService.instance;

  AtlasNutritionExecutiveSnapshot? snapshot;
  List<AtlasNutritionProjection> projections = [];
  List<AtlasNutritionAnnualPlan> plans = [];
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
    projections = await service.buildProjections(
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
        builder: (_) => AtlasNutritionIntelligenceScreen(
          actionController: widget.actionController,
        ),
      ),
    );
  }

  Future<void> _addPlan() async {
    final title = TextEditingController();
    final lot = TextEditingController();
    final gain = TextEditingController(text: '1.0');
    final conversion = TextEditingController(text: '8.0');
    final budget = TextEditingController();
    final responsible = TextEditingController();
    final notes = TextEditingController();
    final year = DateTime.now().year;

    final result = await showDialog<AtlasNutritionAnnualPlan>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Planejamento nutricional anual'),
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
                  controller: lot,
                  decoration: const InputDecoration(
                    labelText: 'Lote-alvo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                _number(gain, 'GMD-alvo (kg)'),
                const SizedBox(height: 10),
                _number(conversion, 'Conversão alimentar-alvo'),
                const SizedBox(height: 10),
                _number(budget, 'Orçamento'),
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
                AtlasNutritionAnnualPlan(
                  id:
                      'nutrition_plan_'
                      '${now.microsecondsSinceEpoch}',
                  title: title.text.trim(),
                  year: year,
                  targetLot: lot.text.trim(),
                  targetDailyGainKg: _double(gain.text),
                  targetFeedConversion: _double(conversion.text),
                  budget: _double(budget.text),
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
      lot,
      gain,
      conversion,
      budget,
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
          title: const Text('Estratégia nutricional'),
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
              Tab(text: 'Dietas'),
              Tab(text: 'Consumo'),
              Tab(text: 'Eficiência'),
              Tab(text: 'Previsões'),
              Tab(text: 'IA nutricional'),
              Tab(text: 'Custos e estoque'),
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
                    title: 'Formulação de dietas',
                    description:
                        'Abra o módulo operacional para cadastrar ingredientes, dietas e metas por lote.',
                    onOpen: _openOperational,
                  ),
                  _Bridge(
                    title: 'Consumo e leitura de cocho',
                    description:
                        'Registre oferta, sobras, consumo e desempenho dos lotes.',
                    onOpen: _openOperational,
                  ),
                  _Indicators(snapshot: current),
                  _Projections(projections: projections),
                  _Recommendations(recommendations: recommendations),
                  _Costs(snapshot: current),
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

  final AtlasNutritionExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem dados nutricionais.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _card('Dietas ativas', item.activeDiets.toDouble(), ''),
            _card('Animais', item.totalAnimals.toDouble(), ''),
            _card('GMD', item.averageDailyGainKg, 'kg'),
            _card('Conversão', item.averageFeedConversion, ''),
            _card('Consumo', item.averageConsumptionKg, 'kg'),
            _card('Desperdício', item.wastePercent, '%'),
            _card('Estoque baixo', item.lowStockIngredients.toDouble(), ''),
            _card('Score', item.nutritionScore, '/100'),
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

class _Indicators extends StatelessWidget {
  const _Indicators({required this.snapshot});

  final AtlasNutritionExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem indicadores.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('GMD médio', item.averageDailyGainKg, 'kg'),
        _metric('Conversão alimentar', item.averageFeedConversion, ''),
        _metric('Consumo médio', item.averageConsumptionKg, 'kg'),
        _metric('Desperdício', item.wastePercent, '%'),
        _metric('Score nutricional', item.nutritionScore, '/100'),
      ],
    );
  }
}

class _Projections extends StatelessWidget {
  const _Projections({required this.projections});

  final List<AtlasNutritionProjection> projections;

  @override
  Widget build(BuildContext context) {
    if (projections.isEmpty) {
      return const Center(child: Text('Nenhuma projeção disponível.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = projections[index];
        return Card(
          child: ExpansionTile(
            title: Text(item.lotName),
            subtitle: Text(
              'Risco ${item.riskLevel} • '
              '${item.stockCoverageDays.toStringAsFixed(1)} dias de estoque',
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              _metric(
                'Consumo em 30 dias',
                item.projectedConsumption30DaysKg,
                'kg',
              ),
              _metric('Custo em 30 dias', item.projectedCost30Days, 'R\$'),
              _metric(
                'Ganho projetado em 30 dias',
                item.projectedWeightGain30DaysKg,
                'kg',
              ),
            ],
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

class _Costs extends StatelessWidget {
  const _Costs({required this.snapshot});

  final AtlasNutritionExecutiveSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    if (item == null) {
      return const Center(child: Text('Sem custos.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('Custo diário', item.dailyFeedCost, 'R\$'),
        _metric('Custo mensal', item.monthlyFeedCost, 'R\$'),
        _metric(
          'Ingredientes com estoque baixo',
          item.lowStockIngredients.toDouble(),
          '',
        ),
      ],
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({required this.plans, required this.onAdd});

  final List<AtlasNutritionAnnualPlan> plans;
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
              ? const Center(child: Text('Nenhum planejamento nutricional.'))
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
                          '${item.targetLot} • '
                          'GMD ${item.targetDailyGainKg.toStringAsFixed(2)} kg • '
                          'CA ${item.targetFeedConversion.toStringAsFixed(2)}',
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
                  : unit == 'kg'
                  ? ' kg'
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
            : unit == 'kg'
            ? ' kg'
            : ''}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ),
  );
}
