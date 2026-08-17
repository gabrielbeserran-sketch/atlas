import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_service.dart';

class AtlasNutritionIntelligenceScreen extends StatefulWidget {
  const AtlasNutritionIntelligenceScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasNutritionIntelligenceScreen> createState() =>
      _AtlasNutritionIntelligenceScreenState();
}

class _AtlasNutritionIntelligenceScreenState
    extends State<AtlasNutritionIntelligenceScreen> {
  final service = AtlasNutritionService.instance;
  List<AtlasFeedIngredient> ingredients = [];
  List<AtlasDietPlan> diets = [];
  List<AtlasFeedConsumptionRecord> records = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    ingredients = await service.loadIngredients(
      farmName: widget.actionController.farmName,
    );
    diets = await service.loadDiets(farmName: widget.actionController.farmName);
    records = await service.loadConsumption(
      farmName: widget.actionController.farmName,
    );
    if (mounted) setState(() => loading = false);
  }

  Future<void> _addIngredient() async {
    final name = TextEditingController();
    final cost = TextEditingController();
    final stock = TextEditingController();
    final minimum = TextEditingController();
    var category = AtlasFeedCategory.roughage;

    final result = await showDialog<AtlasFeedIngredient>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo ingrediente'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<AtlasFeedCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: AtlasFeedCategory.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(atlasFeedCategoryLabel(e)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Custo por kg',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stock,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Estoque em kg',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minimum,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Estoque mínimo em kg',
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
                  AtlasFeedIngredient(
                    id: 'ingredient_${now.microsecondsSinceEpoch}',
                    name: name.text.trim(),
                    category: category,
                    dryMatterPercent: 0,
                    crudeProteinPercent: 0,
                    ndfPercent: 0,
                    energyMcalKg: 0,
                    costPerKg: double.tryParse(cost.text) ?? 0,
                    stockKg: double.tryParse(stock.text) ?? 0,
                    minimumStockKg: double.tryParse(minimum.text) ?? 0,
                    farmName: widget.actionController.farmName,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    cost.dispose();
    stock.dispose();
    minimum.dispose();

    if (result != null) {
      await service.saveIngredient(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = service.alerts(ingredients, records);
    final totalDailyCost = diets.fold<double>(
      0,
      (sum, diet) =>
          sum + service.dietCost(diet, ingredients) * diet.animalCount,
    );
    final avgGain = records.isEmpty
        ? 0.0
        : records.map((e) => e.averageDailyGainKg).reduce((a, b) => a + b) /
              records.length;
    final validConversions = records
        .where((e) => e.feedConversion > 0)
        .toList();
    final avgConversion = validConversions.isEmpty
        ? 0.0
        : validConversions
                  .map((e) => e.feedConversion)
                  .reduce((a, b) => a + b) /
              validConversions.length;

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inteligência nutricional'),
          actions: [
            IconButton(
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Dietas'),
              Tab(text: 'Custos'),
              Tab(text: 'Consumo'),
              Tab(text: 'Eficiência'),
              Tab(text: 'Estoque'),
              Tab(text: 'Planejamento'),
              Tab(text: 'Simulações'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addIngredient,
          icon: const Icon(Icons.add),
          label: const Text('Ingrediente'),
        ),
        body: loading && ingredients.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _list(
                    diets.map(
                      (e) => ListTile(
                        title: Text(e.name),
                        subtitle: Text(
                          '${e.lotName} • ${e.animalCount} animais • '
                          'GMD alvo ${e.targetDailyGainKg.toStringAsFixed(2)} kg',
                        ),
                        trailing: Text(
                          'R\$ ${service.dietCost(e, ingredients).toStringAsFixed(2)}/cab/dia',
                        ),
                      ),
                    ),
                    'Nenhuma dieta cadastrada.',
                  ),
                  _metrics([
                    ('Custo diário', totalDailyCost, 'R\$'),
                    ('Custo mensal', totalDailyCost * 30, 'R\$'),
                    (
                      'Dietas ativas',
                      diets.where((e) => e.active).length.toDouble(),
                      '',
                    ),
                  ]),
                  _list(
                    records.map(
                      (e) => ListTile(
                        title: Text(e.lotName),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(e.recordedAt)} • '
                          '${e.consumptionPerAnimalKg.toStringAsFixed(2)} kg/cab',
                        ),
                        trailing: Text(
                          'CA ${e.feedConversion.toStringAsFixed(2)}',
                        ),
                      ),
                    ),
                    'Nenhum consumo registrado.',
                  ),
                  _metrics([
                    ('GMD', avgGain, 'kg'),
                    ('Conversão', avgConversion, ''),
                    (
                      'Eficiência',
                      avgConversion <= 0 ? 0 : 100 / avgConversion,
                      '%',
                    ),
                  ]),
                  _list([
                    ...ingredients.map(
                      (e) => ListTile(
                        title: Text(e.name),
                        subtitle: Text(atlasFeedCategoryLabel(e.category)),
                        trailing: Text('${e.stockKg.toStringAsFixed(1)} kg'),
                      ),
                    ),
                    ...alerts.map(
                      (e) => ListTile(
                        leading: const Icon(Icons.warning_amber),
                        title: Text(e),
                      ),
                    ),
                  ], 'Nenhum ingrediente cadastrado.'),
                  _list(
                    diets.map(
                      (e) => ListTile(
                        title: Text(e.name),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(e.startAt)} a '
                          '${DateFormat('dd/MM/yyyy').format(e.endAt)}',
                        ),
                      ),
                    ),
                    'Nenhum planejamento ativo.',
                  ),
                  _list([
                    const ListTile(
                      leading: Icon(Icons.science_outlined),
                      title: Text('Reduzir custo da dieta em 5%'),
                      subtitle: Text(
                        'Negociar ingredientes de maior participação.',
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.science_outlined),
                      title: Text('Elevar GMD em 10%'),
                      subtitle: Text('Rebalancear energia e proteína.'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.science_outlined),
                      title: Text('Reduzir sobras de cocho'),
                      subtitle: Text(
                        'Ajustar a oferta diária ao consumo real.',
                      ),
                    ),
                  ], ''),
                ],
              ),
      ),
    );
  }

  Widget _list(Iterable<Widget> children, String empty) {
    final list = children.toList();
    if (list.isEmpty) return Center(child: Text(empty));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => Card(child: list[index]),
    );
  }

  Widget _metrics(List<(String, double, String)> values) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: values
          .map(
            (e) => Card(
              child: ListTile(
                title: Text(e.$1),
                trailing: Text(
                  '${e.$3 == 'R\$' ? 'R\$ ' : ''}'
                  '${e.$2.toStringAsFixed(2)}'
                  '${e.$3 == '%'
                      ? '%'
                      : e.$3 == 'kg'
                      ? ' kg'
                      : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
