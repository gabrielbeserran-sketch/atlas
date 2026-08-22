import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_action_bar.dart';
import 'package:projeto_atlas/core/widgets/atlas_feedback.dart';
import 'package:projeto_atlas/core/widgets/atlas_empty_state.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_feedback.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/nutrition/data/services/nutrition_storage_service.dart';
import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';
import 'package:projeto_atlas/features/nutrition/domain/services/nutrition_inventory_service.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class NutritionOverviewScreen extends StatefulWidget {
  const NutritionOverviewScreen({
    this.farm,
    this.autoOpenCreate = false,
    this.embedded = false,
    super.key,
  });

  final FarmData? farm;
  final bool autoOpenCreate;
  final bool embedded;

  @override
  State<NutritionOverviewScreen> createState() =>
      _NutritionOverviewScreenState();
}

class _NutritionOverviewScreenState extends State<NutritionOverviewScreen> {
  final farmStorage = FarmStorageService();
  final storage = NutritionStorageService();
  final inventoryIntegration = NutritionInventoryService();
  final searchController = TextEditingController();

  List<FarmData> farms = [];
  List<NutritionPlanData> plans = [];
  bool isLoading = true;
  String? loadError;
  String search = '';
  String farmFilter = 'Todas';

  bool get isFarmScoped => widget.farm != null;

  double get totalDailyKg =>
      plans.fold(0, (sum, item) => sum + item.totalDailyKg);
  double get totalMonthlyCost =>
      plans.fold(0, (sum, item) => sum + item.monthlyCost);
  int get coveredAnimals =>
      plans.fold(0, (sum, item) => sum + item.animalCount);
  double get averageGmd {
    final valid = plans.where((item) => item.observedDailyGainKg > 0).toList();
    if (valid.isEmpty) {
      return 0;
    }
    return valid.fold<double>(
          0,
          (sum, item) => sum + item.observedDailyGainKg,
        ) /
        valid.length;
  }

  List<NutritionPlanData> get visiblePlans {
    final query = AtlasUiText.clean(search).toLowerCase();
    return plans.where((plan) {
      final farmOk = farmFilter == 'Todas' || plan.farmName == farmFilter;
      final text = AtlasUiText.clean(
        '${plan.dietName} ${plan.groupName} ${plan.farmName} '
        '${plan.category} ${plan.pastureType} ${plan.silageType} '
        '${plan.concentrateType} ${plan.mineralSupplement} '
        '${plan.ingredients.map((e) => e.name).join(' ')}',
      ).toLowerCase();
      return farmOk && (query.isEmpty || text.contains(query));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await loadData();
    if (widget.autoOpenCreate && mounted) {
      await openForm();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }
    try {
      final loadedFarms = widget.farm == null
          ? await farmStorage.loadFarms()
          : <FarmData>[widget.farm!];
      final loadedPlans = await storage.loadPlans(
        farmId: widget.farm?.id ?? '',
        farmName: widget.farm?.name ?? '',
      );
      loadedPlans.sort((a, b) => a.farmName.compareTo(b.farmName));
      if (!mounted) {
        return;
      }
      setState(() {
        farms = loadedFarms;
        plans = loadedPlans;
        farmFilter = widget.farm == null ? 'Todas' : widget.farm!.name;
      });
    } catch (error) {
      if (mounted) {
        setState(() => loadError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openForm({NutritionPlanData? plan}) async {
    if (farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma fazenda primeiro.')),
      );
      return;
    }
    final result = await showDialog<NutritionPlanData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NutritionPlanDialog(
        farms: farms,
        plan: plan,
        lockedFarmName: widget.farm?.name,
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    final isNew = plans.every((item) => item.id != result.id);
    final farmId = widget.farm?.id ?? '';
    var savedPlan = result;
    String? integrationMessage;

    try {
      if (farmId.isNotEmpty) {
        // Primeiro persiste a dieta. Assim nunca baixamos estoque de uma dieta
        // que falhou ao ser criada no backend.
        savedPlan = await storage.savePlan(
          farmId: farmId,
          plan: savedPlan,
          isNew: isNew,
        );

        if (savedPlan.stockIntegrationEnabled &&
            !savedPlan.inventoryDeducted &&
            savedPlan.ingredients.isNotEmpty) {
          final integration = await inventoryIntegration.deductDailyConsumption(
            savedPlan,
            farmId: farmId,
          );
          savedPlan = integration.plan;
          integrationMessage = integration.message;
          if (integration.success && savedPlan.inventoryDeducted) {
            // Persiste também o estado da integração após a baixa oficial.
            savedPlan = await storage.savePlan(
              farmId: farmId,
              plan: savedPlan,
              isNew: false,
            );
          }
        }
      } else {
        final index = plans.indexWhere((item) => item.id == savedPlan.id);
        if (index < 0) {
          plans.add(savedPlan);
        } else {
          plans[index] = savedPlan;
        }
        await storage.savePlans(plans);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        final index = plans.indexWhere(
          (item) => item.id == savedPlan.id || item.id == result.id,
        );
        if (index < 0) {
          plans.add(savedPlan);
        } else {
          plans[index] = savedPlan;
        }
        plans.sort((a, b) => a.farmName.compareTo(b.farmName));
      });

      if (integrationMessage != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(integrationMessage)));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dieta salva e confirmada no servidor.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar a dieta: $error')),
        );
      }
    }
  }

  Future<void> deletePlan(NutritionPlanData plan) async {
    final confirmed = await AtlasFeedback.confirmDelete(
      context,
      title: 'Excluir dieta',
      message:
          'Deseja excluir “${AtlasUiText.clean(plan.dietName)}”? Essa ação não pode ser desfeita.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    final farmId = widget.farm?.id ?? '';
    if (farmId.isNotEmpty) {
      await storage.deletePlan(farmId: farmId, plan: plan);
    }
    if (!mounted) {
      return;
    }
    setState(() => plans.removeWhere((item) => item.id == plan.id));
    if (farmId.isEmpty) {
      await storage.savePlans(plans);
    }
  }

  String number(double value, {int decimals = 1}) =>
      value.toStringAsFixed(decimals).replaceAll('.', ',');
  String money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(
                widget.farm == null
                    ? 'Central de Nutrição'
                    : 'Nutrição — ${widget.farm!.name}',
              ),
              actions: [
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: isLoading ? null : loadData,
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ],
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null && plans.isEmpty
          ? AtlasLoadErrorState(
              message: 'Verifique sua conexão e tente novamente.',
              onRetry: loadData,
            )
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  const Text(
                    'Nutrição profissional',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Formule dietas, acompanhe composição bromatológica, consumo, desempenho e custos.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  AtlasOperationalActionBar(
                    primaryLabel: 'Nova dieta',
                    onPrimary: () => openForm(),
                    onRefresh: loadData,
                    busy: isLoading,
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final width = constraints.maxWidth >= 1000
                          ? (constraints.maxWidth - 48) / 5
                          : constraints.maxWidth >= 560
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(
                            width: width,
                            icon: Icons.menu_book_outlined,
                            label: 'Dietas',
                            value: '${plans.length}',
                          ),
                          _MetricCard(
                            width: width,
                            icon: AtlasLivestockIcons.cow,
                            label: 'Animais',
                            value: '$coveredAnimals',
                          ),
                          _MetricCard(
                            width: width,
                            icon: Icons.scale_outlined,
                            label: 'Consumo/dia',
                            value: '${number(totalDailyKg)} kg',
                          ),
                          _MetricCard(
                            width: width,
                            icon: Icons.trending_up,
                            label: 'GMD médio',
                            value: '${number(averageGmd, decimals: 2)} kg',
                          ),
                          _MetricCard(
                            width: width,
                            icon: Icons.payments_outlined,
                            label: 'Custo/mês',
                            value: money(totalMonthlyCost),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 440,
                            child: TextField(
                              controller: searchController,
                              onChanged: (value) =>
                                  setState(() => search = value),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                labelText:
                                    'Buscar dieta, lote, ingrediente ou alimento',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 270,
                            child: DropdownButtonFormField<String>(
                              initialValue: farmFilter,
                              decoration: const InputDecoration(
                                labelText: 'Fazenda',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'Todas',
                                  child: Text('Todas as fazendas'),
                                ),
                                ...farms.map(
                                  (farm) => DropdownMenuItem(
                                    value: farm.name,
                                    child: Text(farm.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => farmFilter = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visiblePlans.isEmpty)
                    AtlasEmptyState(
                      icon: Icons.grass_outlined,
                      title: search.trim().isNotEmpty || farmFilter != 'Todas'
                          ? 'Nenhuma dieta encontrada'
                          : 'Nenhuma dieta cadastrada',
                      message: search.trim().isNotEmpty || farmFilter != 'Todas'
                          ? 'Os filtros atuais não encontraram dietas. Limpe os filtros para voltar à lista completa.'
                          : 'Cadastre a primeira dieta para iniciar o controle nutricional da fazenda.',
                      actionLabel:
                          search.trim().isNotEmpty || farmFilter != 'Todas'
                          ? 'Limpar filtros'
                          : 'Nova dieta',
                      onAction: () {
                        if (search.trim().isNotEmpty || farmFilter != 'Todas') {
                          searchController.clear();
                          setState(() {
                            search = '';
                            farmFilter = 'Todas';
                          });
                        } else {
                          openForm();
                        }
                      },
                    )
                  else
                    ...visiblePlans.map(
                      (plan) => _PlanCard(
                        plan: plan,
                        number: number,
                        money: money,
                        onEdit: () => openForm(plan: plan),
                        onDelete: () => deletePlan(plan),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.number,
    required this.money,
    required this.onEdit,
    required this.onDelete,
  });
  final NutritionPlanData plan;
  final String Function(double, {int decimals}) number;
  final String Function(double) money;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ingredients = plan.ingredients.isEmpty
        ? 'Sem formulação por ingredientes'
        : plan.ingredients
              .map(
                (e) =>
                    '${AtlasUiText.clean(e.name)} ${number(e.inclusionKg)} kg',
              )
              .join(' • ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.grass_outlined, color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AtlasUiText.clean(plan.dietName),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${AtlasUiText.clean(plan.farmName)} • ${AtlasUiText.clean(plan.groupName)} • ${AtlasUiText.category(plan.category)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        value == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _Info(
                    label: 'Fornecimento',
                    value: '${number(plan.dailyAmountKg)} kg/animal/dia',
                  ),
                  _Info(
                    label: 'CMS',
                    value:
                        '${number(plan.dryMatterIntakeKg)} kg (${number(plan.dryMatterIntakePercentBodyWeight, decimals: 2)}% PV)',
                  ),
                  _Info(
                    label: 'GMD observado',
                    value:
                        '${number(plan.observedDailyGainKg, decimals: 2)} kg',
                  ),
                  _Info(
                    label: 'Conversão',
                    value: plan.calculatedFeedConversion <= 0
                        ? 'Não informada'
                        : number(plan.calculatedFeedConversion, decimals: 2),
                  ),
                  _Info(label: 'Custo mensal', value: money(plan.monthlyCost)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Composição: MS ${number(plan.dryMatterPercent)}% • PB ${number(plan.crudeProteinPercent)}% • FDN ${number(plan.ndfPercent)}% • FDA ${number(plan.adfPercent)}% • NDT ${number(plan.tdnPercent)}%',
              ),
              const SizedBox(height: 8),
              Text(
                'Ingredientes: $ingredients',
                style: const TextStyle(color: Colors.black54),
              ),
              if (plan.stockIntegrationEnabled) ...[
                const SizedBox(height: 8),
                const Text(
                  'Integração com estoque habilitada',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });
  final double width;
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              child: Icon(icon, color: const Color(0xFF1B5E20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class NutritionPlanDialog extends StatefulWidget {
  const NutritionPlanDialog({
    required this.farms,
    this.plan,
    this.lockedFarmName,
    super.key,
  });

  final List<FarmData> farms;
  final NutritionPlanData? plan;
  final String? lockedFarmName;

  @override
  State<NutritionPlanDialog> createState() => _NutritionPlanDialogState();
}

class _NutritionPlanDialogState extends State<NutritionPlanDialog> {
  final formKey = GlobalKey<FormState>();
  late String farmName;
  late String category;
  late bool stockIntegrationEnabled;
  late List<NutritionIngredientData> ingredients;
  final controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    farmName = widget.lockedFarmName ?? p?.farmName ?? widget.farms.first.name;
    category = p?.category ?? 'Manutenção';
    stockIntegrationEnabled = p?.stockIntegrationEnabled ?? false;
    ingredients = List.of(p?.ingredients ?? const []);
    void add(String key, Object? value) =>
        controllers[key] = TextEditingController(
          text: value?.toString().replaceAll('.', ',') ?? '',
        );
    add('group', p?.groupName ?? '');
    add('diet', p?.dietName ?? '');
    add('amount', p?.dailyAmountKg);
    add('count', p?.animalCount);
    add('cost', p?.costPerKg);
    add('date', p?.startDate ?? _today());
    add('weight', p?.averageBodyWeightKg);
    add('targetGmd', p?.targetDailyGainKg);
    add('observedGmd', p?.observedDailyGainKg);
    add('conversion', p?.feedConversion);
    add('pasture', p?.pastureType ?? '');
    add('silage', p?.silageType ?? '');
    add('concentrate', p?.concentrateType ?? '');
    add('mineral', p?.mineralSupplement ?? '');
    add('ms', p?.dryMatterPercent);
    add('pb', p?.crudeProteinPercent);
    add('fdn', p?.ndfPercent);
    add('fda', p?.adfPercent);
    add('ndt', p?.tdnPercent);
    add('notes', p?.notes ?? '');
  }

  String _today() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}';
  }

  double parse(String key) =>
      double.tryParse(
        controllers[key]!.text.trim().replaceAll('.', '').replaceAll(',', '.'),
      ) ??
      0;
  String? positive(String? value) {
    final n = double.tryParse(
      (value ?? '').replaceAll('.', '').replaceAll(',', '.'),
    );
    return n == null || n <= 0 ? 'Informe um valor válido.' : null;
  }

  Future<void> addIngredient() async {
    final result = await showDialog<NutritionIngredientData>(
      context: context,
      builder: (_) => const _IngredientDialog(),
    );
    if (result != null) {
      setState(() => ingredients.add(result));
    }
  }

  void save() {
    if (!formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      NutritionPlanData(
        id: widget.plan?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        farmName: farmName,
        groupName: controllers['group']!.text.trim(),
        dietName: controllers['diet']!.text.trim(),
        category: category,
        dailyAmountKg: parse('amount'),
        animalCount: int.tryParse(controllers['count']!.text.trim()) ?? 0,
        costPerKg: parse('cost'),
        startDate: controllers['date']!.text.trim(),
        notes: controllers['notes']!.text.trim(),
        averageBodyWeightKg: parse('weight'),
        targetDailyGainKg: parse('targetGmd'),
        observedDailyGainKg: parse('observedGmd'),
        feedConversion: parse('conversion'),
        pastureType: controllers['pasture']!.text.trim(),
        silageType: controllers['silage']!.text.trim(),
        concentrateType: controllers['concentrate']!.text.trim(),
        mineralSupplement: controllers['mineral']!.text.trim(),
        dryMatterPercent: parse('ms'),
        crudeProteinPercent: parse('pb'),
        ndfPercent: parse('fdn'),
        adfPercent: parse('fda'),
        tdnPercent: parse('ndt'),
        stockIntegrationEnabled: stockIntegrationEnabled,
        inventoryDeducted: widget.plan?.inventoryDeducted ?? false,
        inventoryDeductionCost: widget.plan?.inventoryDeductionCost ?? 0,
        ingredients: ingredients,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(
    String key,
    String label, {
    String? Function(String?)? validator,
    int maxLines = 1,
  }) => TextFormField(
    controller: controllers[key],
    maxLines: maxLines,
    keyboardType: maxLines == 1
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.multiline,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.plan == null
            ? 'Nova dieta profissional'
            : 'Editar dieta profissional',
      ),
      content: SizedBox(
        width: 760,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: farmName,
                  decoration: const InputDecoration(labelText: 'Fazenda'),
                  items: widget.farms
                      .map(
                        (farm) => DropdownMenuItem(
                          value: farm.name,
                          child: Text(farm.name),
                        ),
                      )
                      .toList(),
                  onChanged: widget.lockedFarmName != null
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => farmName = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: field(
                        'group',
                        'Lote ou grupo',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Informe o grupo.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: field(
                        'diet',
                        'Nome da dieta',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Informe a dieta.'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria/objetivo',
                  ),
                  items:
                      const [
                            'Manutenção',
                            'Cria',
                            'Recria',
                            'Engorda',
                            'Lactação',
                            'Pré-parto',
                            'Confinamento',
                            'Outro',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => category = v);
                    }
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Fornecimento e desempenho',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: field(
                        'amount',
                        'kg/animal/dia',
                        validator: positive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: field(
                        'count',
                        'Número de animais',
                        validator: positive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: field('weight', 'Peso médio (kg)')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: field('targetGmd', 'GMD meta (kg)')),
                    const SizedBox(width: 12),
                    Expanded(child: field('observedGmd', 'GMD observado (kg)')),
                    const SizedBox(width: 12),
                    Expanded(child: field('conversion', 'Conversão alimentar')),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Composição bromatológica (%)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: field('ms', 'MS')),
                    const SizedBox(width: 8),
                    Expanded(child: field('pb', 'PB')),
                    const SizedBox(width: 8),
                    Expanded(child: field('fdn', 'FDN')),
                    const SizedBox(width: 8),
                    Expanded(child: field('fda', 'FDA')),
                    const SizedBox(width: 8),
                    Expanded(child: field('ndt', 'NDT')),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Alimentos principais',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controllers['pasture'],
                        decoration: const InputDecoration(
                          labelText: 'Pastagem',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controllers['silage'],
                        decoration: const InputDecoration(labelText: 'Silagem'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controllers['concentrate'],
                        decoration: const InputDecoration(
                          labelText: 'Concentrado',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controllers['mineral'],
                        decoration: const InputDecoration(
                          labelText: 'Suplemento mineral',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Formulação por ingredientes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: addIngredient,
                      icon: const Icon(Icons.add),
                      label: const Text('Ingrediente'),
                    ),
                  ],
                ),
                if (ingredients.isEmpty)
                  const Text(
                    'Nenhum ingrediente adicionado.',
                    style: TextStyle(color: Colors.black54),
                  )
                else
                  ...ingredients.asMap().entries.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.value.name),
                      subtitle: Text(
                        '${entry.value.type} • ${entry.value.inclusionKg.toStringAsFixed(2).replaceAll('.', ',')} kg • R\$ ${entry.value.costPerKg.toStringAsFixed(2).replaceAll('.', ',')}/kg',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => ingredients.removeAt(entry.key)),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: field(
                        'cost',
                        'Custo médio por kg (R\$)',
                        validator: (v) =>
                            double.tryParse(
                                  (v ?? '')
                                      .replaceAll('.', '')
                                      .replaceAll(',', '.'),
                                ) ==
                                null
                            ? 'Informe o custo.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controllers['date'],
                        decoration: const InputDecoration(
                          labelText: 'Início da dieta',
                        ),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: stockIntegrationEnabled,
                  onChanged: (v) => setState(() => stockIntegrationEnabled = v),
                  title: const Text('Habilitar integração com estoque'),
                  subtitle: const Text(
                    'Ao salvar uma nova dieta, baixa do estoque o consumo total de um dia. Os nomes dos ingredientes devem ser iguais aos produtos cadastrados no estoque.',
                  ),
                ),
                TextFormField(
                  controller: controllers['notes'],
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações técnicas',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _IngredientDialog extends StatefulWidget {
  const _IngredientDialog();
  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  final key = GlobalKey<FormState>();
  final c = List.generate(8, (_) => TextEditingController());
  String type = 'Concentrado';
  double value(int i) =>
      double.tryParse(c[i].text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  @override
  void dispose() {
    for (final item in c) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adicionar ingrediente'),
    content: SizedBox(
      width: 560,
      child: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: c[0],
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items:
                    const [
                          'Volumoso',
                          'Silagem',
                          'Concentrado',
                          'Mineral',
                          'Aditivo',
                          'Outro',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => type = v);
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: c[1],
                      decoration: const InputDecoration(
                        labelText: 'Inclusão kg/animal/dia',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: c[7],
                      decoration: const InputDecoration(
                        labelText: 'Custo R\$/kg',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: c[2],
                      decoration: const InputDecoration(labelText: 'MS %'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: c[3],
                      decoration: const InputDecoration(labelText: 'PB %'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: c[4],
                      decoration: const InputDecoration(labelText: 'FDN %'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: c[5],
                      decoration: const InputDecoration(labelText: 'FDA %'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: c[6],
                      decoration: const InputDecoration(labelText: 'NDT %'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!key.currentState!.validate()) {
            return;
          }
          Navigator.pop(
            context,
            NutritionIngredientData(
              name: c[0].text.trim(),
              type: type,
              inclusionKg: value(1),
              dryMatterPercent: value(2),
              crudeProteinPercent: value(3),
              ndfPercent: value(4),
              adfPercent: value(5),
              tdnPercent: value(6),
              costPerKg: value(7),
            ),
          );
        },
        child: const Text('Adicionar'),
      ),
    ],
  );
}
