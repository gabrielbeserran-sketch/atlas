import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_predictive_ai_suite/data/services/atlas_predictive_ai_storage_service.dart';
import 'package:projeto_atlas/features/atlas_predictive_ai_suite/domain/models/atlas_predictive_ai_record.dart';
import 'package:projeto_atlas/features/atlas_predictive_ai_suite/domain/services/atlas_predictive_ai_engine.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasPredictiveAiScreen extends StatefulWidget {
  const AtlasPredictiveAiScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasPredictiveAiModule initialModule;

  @override
  State<AtlasPredictiveAiScreen> createState() =>
      _AtlasPredictiveAiScreenState();
}

class _AtlasPredictiveAiScreenState extends State<AtlasPredictiveAiScreen> {
  final AtlasPredictiveAiStorageService storage =
      AtlasPredictiveAiStorageService();
  final AtlasPredictiveAiEngine engine = const AtlasPredictiveAiEngine();

  late AtlasPredictiveAiModule selectedModule;
  List<AtlasPredictiveAiRecord> records = [];
  bool loading = true;
  String selectedFeature = 'Todos';

  @override
  void initState() {
    super.initState();
    selectedModule = widget.initialModule;
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final loaded = await storage.load(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
    );

    loaded.sort(
      (first, second) => parseAtlasPredictiveDate(
        second.date,
      ).compareTo(parseAtlasPredictiveDate(first.date)),
    );

    if (!mounted) return;

    setState(() {
      records = loaded;
      loading = false;
    });
  }

  Future<void> persist() {
    return storage.save(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
      records: records,
    );
  }

  List<AtlasPredictiveAiRecord> get visibleRecords {
    return records
        .where((record) {
          final moduleMatches = record.module == selectedModule;
          final featureMatches =
              selectedFeature == 'Todos' || record.feature == selectedFeature;
          return moduleMatches && featureMatches;
        })
        .toList(growable: false);
  }

  Future<void> openForm([AtlasPredictiveAiRecord? current]) async {
    final result = await showDialog<AtlasPredictiveAiRecord>(
      context: context,
      builder: (context) =>
          _PredictiveAiRecordForm(module: selectedModule, current: current),
    );

    if (result == null || !mounted) return;

    final index = records.indexWhere((record) => record.id == result.id);

    setState(() {
      if (index < 0) {
        records.add(result);
      } else {
        records[index] = result;
      }
    });

    await persist();
    await load();
  }

  Future<void> deleteRecord(AtlasPredictiveAiRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir simulação'),
        content: Text('Deseja excluir "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      records.removeWhere((item) => item.id == record.id);
    });

    await persist();
  }

  @override
  Widget build(BuildContext context) {
    final moduleRecords = records
        .where((record) => record.module == selectedModule)
        .toList(growable: false);

    final riskyCount = moduleRecords.where((record) {
      return engine.evaluate(record).riskLevel == 'Alto';
    }).length;

    final averageScore = moduleRecords.isEmpty
        ? 0
        : moduleRecords
                  .map((record) => engine.evaluate(record).score)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedModule.title),
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
        icon: const Icon(Icons.add),
        label: const Text('Nova simulação'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EnterpriseModuleHeader(
                        title: selectedModule.title,
                        subtitle:
                            '${selectedModule.title} • '
                            '${widget.farm.name} • '
                            '${widget.animal.displayName}',
                        icon: _moduleIcon(selectedModule),
                      ),
                      const SizedBox(height: 14),
                      Card(
                        color: const Color(0xFFFFF8E1),
                        child: const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Simulações de apoio à decisão'),
                          subtitle: Text(
                            'Os resultados dependem das premissas informadas '
                            'e devem ser confirmados com dados reais e avaliação profissional.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ModuleSelector(
                        selected: selectedModule,
                        onSelected: (module) {
                          setState(() {
                            selectedModule = module;
                            selectedFeature = 'Todos';
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          EnterpriseMetricCard(
                            title: 'Simulações',
                            value: '${moduleRecords.length}',
                            subtitle: 'Histórico do módulo',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Score médio',
                            value: averageScore.toStringAsFixed(0),
                            subtitle: 'Qualidade dos cenários',
                            icon: Icons.analytics_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Risco alto',
                            value: '$riskyCount',
                            subtitle: 'Cenários que exigem revisão',
                            icon: Icons.warning_amber_outlined,
                            warning: riskyCount > 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _FeatureFilter(
                        module: selectedModule,
                        selected: selectedFeature,
                        onSelected: (value) {
                          setState(() => selectedFeature = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      const EnterpriseSectionTitle(
                        'Resultados preditivos',
                        'Simulações ordenadas da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhuma simulação cadastrada.'),
                            subtitle: const Text(
                              'Cadastre o primeiro cenário para gerar projeções.',
                            ),
                          ),
                        )
                      else
                        ...visibleRecords.map(
                          (record) => _PredictionCard(
                            record: record,
                            result: engine.evaluate(record),
                            onEdit: () => openForm(record),
                            onDelete: () => deleteRecord(record),
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
}

class _ModuleSelector extends StatelessWidget {
  const _ModuleSelector({required this.selected, required this.onSelected});

  final AtlasPredictiveAiModule selected;
  final ValueChanged<AtlasPredictiveAiModule> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: AtlasPredictiveAiModule.values
              .map((module) {
                final active = module == selected;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: module == AtlasPredictiveAiModule.values.last
                          ? 0
                          : 8,
                    ),
                    child: FilledButton.tonalIcon(
                      onPressed: () => onSelected(module),
                      style: FilledButton.styleFrom(
                        backgroundColor: active
                            ? const Color(0xFF1B5E20)
                            : null,
                        foregroundColor: active ? Colors.white : null,
                      ),
                      icon: Icon(_moduleIcon(module)),
                      label: Text(module.title),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _FeatureFilter extends StatelessWidget {
  const _FeatureFilter({
    required this.module,
    required this.selected,
    required this.onSelected,
  });

  final AtlasPredictiveAiModule module;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = ['Todos', ...module.features];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((feature) {
            return ChoiceChip(
              label: Text(feature),
              selected: selected == feature,
              onSelected: (_) => onSelected(feature),
            );
          })
          .toList(growable: false),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
    required this.record,
    required this.result,
    required this.onEdit,
    required this.onDelete,
  });

  final AtlasPredictiveAiRecord record;
  final AtlasPredictiveAiResult result;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.riskLevel) {
      'Alto' => Colors.red.shade800,
      'Moderado' => Colors.orange.shade800,
      _ => Colors.green.shade800,
    };

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_moduleIcon(record.module), color: color),
        ),
        title: Text(record.title),
        subtitle: Text(
          '${record.date} • risco ${result.riskLevel} • '
          'score ${result.score}/100 • '
          'confiança ${result.confidencePercent}%',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              EnterpriseMetricCard(
                title: result.primaryLabel,
                value: result.primaryProjection
                    .toStringAsFixed(2)
                    .replaceAll('.', ','),
                subtitle: 'Projeção principal',
                icon: Icons.trending_up_outlined,
              ),
              EnterpriseMetricCard(
                title: result.secondaryLabel,
                value: result.secondaryProjection
                    .toStringAsFixed(2)
                    .replaceAll('.', ','),
                subtitle: 'Projeção complementar',
                icon: Icons.calculate_outlined,
              ),
            ],
          ),
          if (result.explanations.isNotEmpty) ...[
            const SizedBox(height: 14),
            EnterpriseInsightCard(
              title: 'Explicação do resultado',
              icon: Icons.lightbulb_outline,
              items: result.explanations,
            ),
          ],
          const SizedBox(height: 14),
          EnterpriseInsightCard(
            title: 'Recomendações',
            icon: Icons.assignment_outlined,
            items: result.recommendations,
          ),
        ],
      ),
    );
  }
}

class _PredictiveAiRecordForm extends StatefulWidget {
  const _PredictiveAiRecordForm({required this.module, this.current});

  final AtlasPredictiveAiModule module;
  final AtlasPredictiveAiRecord? current;

  @override
  State<_PredictiveAiRecordForm> createState() =>
      _PredictiveAiRecordFormState();
}

class _PredictiveAiRecordFormState extends State<_PredictiveAiRecordForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController primaryInput;
  late final TextEditingController secondaryInput;
  late final TextEditingController tertiaryInput;
  late final TextEditingController costValue;
  late final TextEditingController revenueValue;
  late final TextEditingController periodDays;
  late final TextEditingController referenceName;
  late final TextEditingController unit;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();

    final current = widget.current;

    feature = current?.feature ?? widget.module.features.first;
    status = current?.status ?? 'Planejado';

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ?? formatAtlasPredictiveDate(DateTime.now()),
    );
    primaryInput = TextEditingController(
      text: current == null ? '' : current.primaryInput.toString(),
    );
    secondaryInput = TextEditingController(
      text: current == null ? '' : current.secondaryInput.toString(),
    );
    tertiaryInput = TextEditingController(
      text: current == null ? '' : current.tertiaryInput.toString(),
    );
    costValue = TextEditingController(
      text: current == null ? '' : current.costValue.toString(),
    );
    revenueValue = TextEditingController(
      text: current == null ? '' : current.revenueValue.toString(),
    );
    periodDays = TextEditingController(
      text: current == null || current.periodDays == 0
          ? ''
          : current.periodDays.toString(),
    );
    referenceName = TextEditingController(text: current?.referenceName ?? '');
    unit = TextEditingController(text: current?.unit ?? '');
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    primaryInput.dispose();
    secondaryInput.dispose();
    tertiaryInput.dispose();
    costValue.dispose();
    revenueValue.dispose();
    periodDays.dispose();
    referenceName.dispose();
    unit.dispose();
    notes.dispose();
    super.dispose();
  }

  double decimal(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  int integer(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> chooseDate() async {
    final parsed = parseAtlasPredictiveDate(date.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      date.text = formatAtlasPredictiveDate(selected);
    });
  }

  String get primaryLabel => switch (widget.module) {
    AtlasPredictiveAiModule.nutrition => 'Peso vivo (kg)',
    AtlasPredictiveAiModule.economics => 'Investimento inicial (R\$)',
    AtlasPredictiveAiModule.commercialization => 'Peso vivo (kg)',
  };

  String get secondaryLabel => switch (widget.module) {
    AtlasPredictiveAiModule.nutrition => 'Meta de GMD (kg/dia)',
    AtlasPredictiveAiModule.economics => 'Indicador complementar',
    AtlasPredictiveAiModule.commercialization => 'Rendimento de carcaça (%)',
  };

  String get tertiaryLabel => switch (widget.module) {
    AtlasPredictiveAiModule.nutrition => 'Consumo informado (kg/dia)',
    AtlasPredictiveAiModule.economics => 'Indicador adicional',
    AtlasPredictiveAiModule.commercialization =>
      'Preço esperado da arroba (R\$)',
  };

  String get costLabel => switch (widget.module) {
    AtlasPredictiveAiModule.nutrition => 'Custo diário da dieta (R\$)',
    AtlasPredictiveAiModule.economics => 'Custo mensal (R\$)',
    AtlasPredictiveAiModule.commercialization => 'Custos da negociação (R\$)',
  };

  String get revenueLabel => switch (widget.module) {
    AtlasPredictiveAiModule.nutrition => 'Receita estimada (opcional)',
    AtlasPredictiveAiModule.economics => 'Receita mensal (R\$)',
    AtlasPredictiveAiModule.commercialization => 'Receita adicional (opcional)',
  };

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasPredictiveAiRecord(
        id:
            current?.id ??
            'predictive_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        primaryInput: decimal(primaryInput),
        secondaryInput: decimal(secondaryInput),
        tertiaryInput: decimal(tertiaryInput),
        costValue: decimal(costValue),
        revenueValue: decimal(revenueValue),
        periodDays: integer(periodDays),
        referenceName: referenceName.text.trim(),
        unit: unit.text.trim(),
        notes: notes.text.trim(),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.current == null ? 'Nova simulação' : 'Editar simulação',
      ),
      content: SizedBox(
        width: 720,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: feature,
                  decoration: const InputDecoration(
                    labelText: 'Funcionalidade',
                  ),
                  items: widget.module.features
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => feature = value);
                    }
                  },
                ),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o título.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: date,
                  readOnly: true,
                  onTap: chooseDate,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Situação'),
                  items:
                      const [
                            'Planejado',
                            'Em avaliação',
                            'Ativo',
                            'Concluído',
                            'Atenção',
                            'Crítico',
                          ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => status = value);
                    }
                  },
                ),
                TextFormField(
                  controller: primaryInput,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: primaryLabel),
                ),
                TextFormField(
                  controller: secondaryInput,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: secondaryLabel),
                ),
                TextFormField(
                  controller: tertiaryInput,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: tertiaryLabel),
                ),
                TextFormField(
                  controller: costValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: costLabel),
                ),
                TextFormField(
                  controller: revenueValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: revenueLabel),
                ),
                TextFormField(
                  controller: periodDays,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Período da projeção (dias)',
                  ),
                ),
                TextFormField(
                  controller: referenceName,
                  decoration: InputDecoration(
                    labelText:
                        widget.module ==
                            AtlasPredictiveAiModule.commercialization
                        ? 'Comprador ou frigorífico'
                        : 'Referência ou cenário',
                  ),
                ),
                TextFormField(
                  controller: unit,
                  decoration: const InputDecoration(
                    labelText: 'Unidade complementar',
                  ),
                ),
                TextFormField(
                  controller: notes,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Observações e premissas',
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
        FilledButton(onPressed: save, child: const Text('Calcular')),
      ],
    );
  }
}

IconData _moduleIcon(AtlasPredictiveAiModule module) {
  return switch (module) {
    AtlasPredictiveAiModule.nutrition => Icons.restaurant_outlined,
    AtlasPredictiveAiModule.economics => Icons.account_balance_wallet_outlined,
    AtlasPredictiveAiModule.commercialization => Icons.sell_outlined,
  };
}
