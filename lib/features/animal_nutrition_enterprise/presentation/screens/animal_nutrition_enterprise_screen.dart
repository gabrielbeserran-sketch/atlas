import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/animal_nutrition_enterprise/data/services/animal_nutrition_storage_service.dart';
import 'package:projeto_atlas/features/animal_nutrition_enterprise/domain/models/animal_nutrition_plan.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalNutritionEnterpriseScreen extends StatefulWidget {
  const AnimalNutritionEnterpriseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalNutritionEnterpriseScreen> createState() =>
      _AnimalNutritionEnterpriseScreenState();
}

class _AnimalNutritionEnterpriseScreenState
    extends State<AnimalNutritionEnterpriseScreen> {
  final AnimalNutritionStorageService storage =
      AnimalNutritionStorageService();

  List<AnimalNutritionPlan> plans = <AnimalNutritionPlan>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final loaded = await storage.load(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
    );

    loaded.sort(
      (first, second) => parseEnterpriseDate(
        second.date,
      ).compareTo(parseEnterpriseDate(first.date)),
    );

    if (!mounted) return;

    setState(() {
      plans = loaded;
      loading = false;
    });
  }

  AnimalNutritionPlan? get active {
    for (final plan in plans) {
      if (plan.status == 'Ativa') return plan;
    }

    return plans.isEmpty ? null : plans.first;
  }

  Future<void> openForm([AnimalNutritionPlan? plan]) async {
    final result = await showDialog<AnimalNutritionPlan>(
      context: context,
      builder: (context) => _NutritionForm(plan: plan),
    );

    if (result == null || !mounted) return;

    final index = plans.indexWhere(
      (current) => current.id == result.id,
    );

    setState(() {
      if (index < 0) {
        plans.add(result);
      } else {
        plans[index] = result;
      }
    });

    await _save();
    await load();
  }

  Future<void> deletePlan(AnimalNutritionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir dieta'),
        content: Text(
          'Deseja excluir o plano "${plan.dietName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      plans.removeWhere((current) => current.id == plan.id);
    });

    await _save();
    await load();
  }

  Future<void> _save() async {
    await storage.save(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      plans: plans,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = active;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrição Enterprise'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : () => openForm(),
        icon: const Icon(Icons.restaurant_outlined),
        label: const Text('Nova dieta'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EnterpriseModuleHeader(
                        title:
                            'Nutrição de ${widget.animal.displayName}',
                        subtitle:
                            'Dieta, consumo, matéria seca, custo e meta de ganho.',
                        icon: Icons.restaurant_outlined,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Dieta ativa',
                            value:
                                current?.dietName ?? 'Não cadastrada',
                            subtitle:
                                current?.status ?? 'Cadastre um plano',
                            icon: Icons.menu_book_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Consumo diário',
                            value: current == null
                                ? '—'
                                : '${_decimal(current.dailyIntakeKg, 1)} kg',
                            subtitle: 'Matéria natural',
                            icon: Icons.scale_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Matéria seca',
                            value: current == null
                                ? '—'
                                : '${_decimal(current.dryMatterKg, 1)} kg',
                            subtitle: current == null
                                ? 'Sem plano'
                                : '${_decimal(current.dryMatterPercent, 1)}% da dieta',
                            icon: Icons.grass_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Custo diário',
                            value: current == null
                                ? '—'
                                : _money(current.dailyCost),
                            subtitle: current == null
                                ? 'Sem plano'
                                : '${_money(current.dailyCost * 30)} em 30 dias',
                            icon: Icons.payments_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Meta de GMD',
                            value: current == null
                                ? '—'
                                : '${_decimal(current.targetGainKg, 3)} kg/dia',
                            subtitle: 'Objetivo nutricional',
                            icon: Icons.trending_up_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Planos',
                            value: '${plans.length}',
                            subtitle: 'Histórico nutricional',
                            icon: Icons.history_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      EnterpriseInsightCard(
                        title: 'Inteligência nutricional',
                        items: [
                          if (current == null)
                            'Cadastre uma dieta para calcular consumo, matéria seca, custo e meta de ganho.',
                          if (current != null &&
                              current.dryMatterKg <= 0)
                            'Revise o consumo e o percentual de matéria seca.',
                          if (current != null &&
                              current.dailyCost > 0)
                            'O custo projetado em 90 dias é ${_money(current.dailyCost * 90)}.',
                          if (current != null &&
                              current.targetGainKg <= 0)
                            'Defina uma meta de ganho diário para medir eficiência.',
                          if (current != null)
                            'Compare a meta de ${_decimal(current.targetGainKg, 3)} kg/dia com o GMD real das pesagens.',
                        ],
                      ),
                      const SizedBox(height: 22),
                      const EnterpriseSectionTitle(
                        'Planos nutricionais',
                        'Histórico e situação das dietas.',
                      ),
                      const SizedBox(height: 12),
                      if (plans.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text(
                              'Nenhuma dieta cadastrada.',
                            ),
                          ),
                        )
                      else
                        ...plans.map(
                          (plan) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(
                                  Icons.restaurant_outlined,
                                ),
                              ),
                              title: Text(plan.dietName),
                              subtitle: Text(
                                '${plan.date} • '
                                '${_decimal(plan.dailyIntakeKg, 1)} kg/dia • '
                                '${_money(plan.dailyCost)}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    openForm(plan);
                                  } else if (value == 'delete') {
                                    deletePlan(plan);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 90),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _decimal(double value, int decimals) {
    return value
        .toStringAsFixed(decimals)
        .replaceAll('.', ',');
  }

  String _money(double value) {
    return 'R\$ ${_decimal(value, 2)}';
  }
}

class _NutritionForm extends StatefulWidget {
  const _NutritionForm({
    this.plan,
  });

  final AnimalNutritionPlan? plan;

  @override
  State<_NutritionForm> createState() => _NutritionFormState();
}

class _NutritionFormState extends State<_NutritionForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController dateController;
  late final TextEditingController dietController;
  late final TextEditingController intakeController;
  late final TextEditingController dryMatterController;
  late final TextEditingController costController;
  late final TextEditingController targetController;
  late final TextEditingController notesController;

  String status = 'Ativa';

  @override
  void initState() {
    super.initState();

    final plan = widget.plan;

    dateController = TextEditingController(
      text: plan?.date ?? enterpriseDate(DateTime.now()),
    );
    dietController = TextEditingController(
      text: plan?.dietName ?? '',
    );
    intakeController = TextEditingController(
      text: plan?.dailyIntakeKg.toString() ?? '',
    );
    dryMatterController = TextEditingController(
      text: plan?.dryMatterPercent.toString() ?? '',
    );
    costController = TextEditingController(
      text: plan?.dailyCost.toString() ?? '',
    );
    targetController = TextEditingController(
      text: plan?.targetGainKg.toString() ?? '',
    );
    notesController = TextEditingController(
      text: plan?.notes ?? '',
    );
    status = plan?.status ?? 'Ativa';
  }

  @override
  void dispose() {
    dateController.dispose();
    dietController.dispose();
    intakeController.dispose();
    dryMatterController.dispose();
    costController.dispose();
    targetController.dispose();
    notesController.dispose();
    super.dispose();
  }

  double number(TextEditingController controller) {
    return double.tryParse(
          controller.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      AnimalNutritionPlan(
        id: widget.plan?.id ??
            'nutrition_${DateTime.now().microsecondsSinceEpoch}',
        date: dateController.text.trim(),
        dietName: dietController.text.trim(),
        dailyIntakeKg: number(intakeController),
        dryMatterPercent: number(dryMatterController),
        dailyCost: number(costController),
        targetGainKg: number(targetController),
        status: status,
        notes: notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.plan == null ? 'Nova dieta' : 'Editar dieta',
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: dietController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da dieta',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Obrigatório';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                  ),
                ),
                TextFormField(
                  controller: intakeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Consumo diário (kg)',
                  ),
                ),
                TextFormField(
                  controller: dryMatterController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Matéria seca (%)',
                  ),
                ),
                TextFormField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Custo diário (R\$)',
                  ),
                ),
                TextFormField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Meta GMD (kg/dia)',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Ativa',
                      child: Text('Ativa'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Encerrada',
                      child: Text('Encerrada'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => status = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Situação',
                  ),
                ),
                TextFormField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
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
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
