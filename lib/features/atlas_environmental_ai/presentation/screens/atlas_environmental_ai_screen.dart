import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_environmental_ai/data/services/atlas_environmental_ai_storage_service.dart';
import 'package:projeto_atlas/features/atlas_environmental_ai/domain/models/atlas_environmental_ai_record.dart';
import 'package:projeto_atlas/features/atlas_environmental_ai/domain/services/atlas_environmental_ai_engine.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasEnvironmentalAiScreen extends StatefulWidget {
  const AtlasEnvironmentalAiScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasEnvironmentalAiModule initialModule;

  @override
  State<AtlasEnvironmentalAiScreen> createState() =>
      _AtlasEnvironmentalAiScreenState();
}

class _AtlasEnvironmentalAiScreenState
    extends State<AtlasEnvironmentalAiScreen> {
  final AtlasEnvironmentalAiStorageService storage =
      AtlasEnvironmentalAiStorageService();
  final AtlasEnvironmentalAiEngine engine = const AtlasEnvironmentalAiEngine();

  late AtlasEnvironmentalAiModule selectedModule;
  List<AtlasEnvironmentalAiRecord> records = [];
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
      (first, second) => parseAtlasEnvironmentalDate(
        second.date,
      ).compareTo(parseAtlasEnvironmentalDate(first.date)),
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

  List<AtlasEnvironmentalAiRecord> get visibleRecords {
    return records
        .where((record) {
          final moduleMatches = record.module == selectedModule;
          final featureMatches =
              selectedFeature == 'Todos' || record.feature == selectedFeature;
          return moduleMatches && featureMatches;
        })
        .toList(growable: false);
  }

  Future<void> openForm([AtlasEnvironmentalAiRecord? current]) async {
    final result = await showDialog<AtlasEnvironmentalAiRecord>(
      context: context,
      builder: (context) =>
          _EnvironmentalAiRecordForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasEnvironmentalAiRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir análise'),
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
        label: const Text('Nova análise'),
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
                          title: Text('Análises ambientais de apoio'),
                          subtitle: Text(
                            'As projeções dependem das premissas informadas. '
                            'Dados meteorológicos e imagens reais exigem integrações externas.',
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
                            title: 'Análises',
                            value: '${moduleRecords.length}',
                            subtitle: 'Histórico do módulo',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Score médio',
                            value: averageScore.toStringAsFixed(0),
                            subtitle: 'Condição analisada',
                            icon: Icons.analytics_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Risco alto',
                            value: '$riskyCount',
                            subtitle: 'Cenários prioritários',
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
                        'Resultados ambientais',
                        'Análises ordenadas da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhuma análise cadastrada.'),
                            subtitle: const Text(
                              'Cadastre o primeiro cenário para gerar projeções.',
                            ),
                          ),
                        )
                      else
                        ...visibleRecords.map(
                          (record) => _ResultCard(
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

  final AtlasEnvironmentalAiModule selected;
  final ValueChanged<AtlasEnvironmentalAiModule> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: AtlasEnvironmentalAiModule.values
              .map((module) {
                final active = module == selected;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: module == AtlasEnvironmentalAiModule.values.last
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

  final AtlasEnvironmentalAiModule module;
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.record,
    required this.result,
    required this.onEdit,
    required this.onDelete,
  });

  final AtlasEnvironmentalAiRecord record;
  final AtlasEnvironmentalAiResult result;
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

class _EnvironmentalAiRecordForm extends StatefulWidget {
  const _EnvironmentalAiRecordForm({required this.module, this.current});

  final AtlasEnvironmentalAiModule module;
  final AtlasEnvironmentalAiRecord? current;

  @override
  State<_EnvironmentalAiRecordForm> createState() =>
      _EnvironmentalAiRecordFormState();
}

class _EnvironmentalAiRecordFormState
    extends State<_EnvironmentalAiRecordForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController temperature;
  late final TextEditingController rainfall;
  late final TextEditingController humidity;
  late final TextEditingController primaryValue;
  late final TextEditingController secondaryValue;
  late final TextEditingController areaHectares;
  late final TextEditingController stockingRate;
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
      text: current?.date ?? formatAtlasEnvironmentalDate(DateTime.now()),
    );
    temperature = TextEditingController(
      text: current == null || current.temperatureCelsius == 0
          ? ''
          : current.temperatureCelsius.toString(),
    );
    rainfall = TextEditingController(
      text: current == null || current.rainfallMillimeters == 0
          ? ''
          : current.rainfallMillimeters.toString(),
    );
    humidity = TextEditingController(
      text: current == null || current.humidityPercent == 0
          ? ''
          : current.humidityPercent.toString(),
    );
    primaryValue = TextEditingController(
      text: current == null || current.primaryValue == 0
          ? ''
          : current.primaryValue.toString(),
    );
    secondaryValue = TextEditingController(
      text: current == null || current.secondaryValue == 0
          ? ''
          : current.secondaryValue.toString(),
    );
    areaHectares = TextEditingController(
      text: current == null || current.areaHectares == 0
          ? ''
          : current.areaHectares.toString(),
    );
    stockingRate = TextEditingController(
      text: current == null || current.stockingRateUaHa == 0
          ? ''
          : current.stockingRateUaHa.toString(),
    );
    referenceName = TextEditingController(text: current?.referenceName ?? '');
    unit = TextEditingController(text: current?.unit ?? '');
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    temperature.dispose();
    rainfall.dispose();
    humidity.dispose();
    primaryValue.dispose();
    secondaryValue.dispose();
    areaHectares.dispose();
    stockingRate.dispose();
    referenceName.dispose();
    unit.dispose();
    notes.dispose();
    super.dispose();
  }

  double decimal(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  Future<void> chooseDate() async {
    final parsed = parseAtlasEnvironmentalDate(date.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      date.text = formatAtlasEnvironmentalDate(selected);
    });
  }

  String get primaryLabel => switch (widget.module) {
    AtlasEnvironmentalAiModule.climate => 'Indicador climático principal',
    AtlasEnvironmentalAiModule.pasture => 'Índice de degradação (0 a 100)',
    AtlasEnvironmentalAiModule.satellite => 'NDVI (-1 a 1)',
  };

  String get secondaryLabel => switch (widget.module) {
    AtlasEnvironmentalAiModule.climate => 'Indicador climático secundário',
    AtlasEnvironmentalAiModule.pasture => 'Massa de forragem (kg MS/ha)',
    AtlasEnvironmentalAiModule.satellite => 'Umidade estimada (%)',
  };

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasEnvironmentalAiRecord(
        id:
            current?.id ??
            'environmental_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        temperatureCelsius: decimal(temperature),
        rainfallMillimeters: decimal(rainfall),
        humidityPercent: decimal(humidity),
        primaryValue: decimal(primaryValue),
        secondaryValue: decimal(secondaryValue),
        areaHectares: decimal(areaHectares),
        stockingRateUaHa: decimal(stockingRate),
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
        widget.current == null
            ? 'Nova análise ambiental'
            : 'Editar análise ambiental',
      ),
      content: SizedBox(
        width: 740,
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
                            'Monitorado',
                            'Ativo',
                            'Concluído',
                            'Atenção',
                            'Crítico',
                            'Seca',
                            'Alagado',
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
                  controller: temperature,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Temperatura (°C)',
                  ),
                ),
                TextFormField(
                  controller: rainfall,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precipitação (mm)',
                  ),
                ),
                TextFormField(
                  controller: humidity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Umidade relativa (%)',
                  ),
                ),
                TextFormField(
                  controller: primaryValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: primaryLabel),
                ),
                TextFormField(
                  controller: secondaryValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: secondaryLabel),
                ),
                TextFormField(
                  controller: areaHectares,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Área analisada (ha)',
                  ),
                ),
                TextFormField(
                  controller: stockingRate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Lotação atual (UA/ha)',
                  ),
                ),
                TextFormField(
                  controller: referenceName,
                  decoration: InputDecoration(
                    labelText:
                        widget.module == AtlasEnvironmentalAiModule.satellite
                        ? 'Imagem, órbita ou referência'
                        : 'Piquete, estação ou referência',
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
        FilledButton(onPressed: save, child: const Text('Analisar')),
      ],
    );
  }
}

IconData _moduleIcon(AtlasEnvironmentalAiModule module) {
  return switch (module) {
    AtlasEnvironmentalAiModule.climate => Icons.cloud_outlined,
    AtlasEnvironmentalAiModule.pasture => Icons.grass_outlined,
    AtlasEnvironmentalAiModule.satellite => Icons.satellite_alt_outlined,
  };
}
