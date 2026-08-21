import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_geospatial_platform/data/services/atlas_geospatial_storage_service.dart';
import 'package:projeto_atlas/features/atlas_geospatial_platform/domain/models/atlas_geospatial_record.dart';
import 'package:projeto_atlas/features/atlas_geospatial_platform/domain/services/atlas_geospatial_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasGeospatialScreen extends StatefulWidget {
  const AtlasGeospatialScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasGeospatialModule initialModule;

  @override
  State<AtlasGeospatialScreen> createState() => _AtlasGeospatialScreenState();
}

class _AtlasGeospatialScreenState extends State<AtlasGeospatialScreen> {
  final AtlasGeospatialStorageService storage = AtlasGeospatialStorageService();
  final AtlasGeospatialAnalyticsService analyticsService =
      const AtlasGeospatialAnalyticsService();

  late AtlasGeospatialModule selectedModule;
  List<AtlasGeospatialRecord> records = [];
  bool loading = true;
  String selectedFeature = 'Todos';

  @override
  void initState() {
    super.initState();
    selectedModule = widget.initialModule;
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);

    final loaded = await storage.load(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
    );

    loaded.sort(
      (first, second) => parseAtlasGeospatialDate(
        second.date,
      ).compareTo(parseAtlasGeospatialDate(first.date)),
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

  List<AtlasGeospatialRecord> get visibleRecords {
    return records
        .where((record) {
          final moduleMatches = record.module == selectedModule;
          final featureMatches =
              selectedFeature == 'Todos' || record.feature == selectedFeature;
          return moduleMatches && featureMatches;
        })
        .toList(growable: false);
  }

  Future<void> openForm([AtlasGeospatialRecord? current]) async {
    final result = await showDialog<AtlasGeospatialRecord>(
      context: context,
      builder: (context) =>
          _GeospatialForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasGeospatialRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro'),
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
    final analytics = analyticsService.analyze(
      module: selectedModule,
      records: records,
    );

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
        label: const Text('Novo registro'),
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
                          title: Text('Geoprocessamento'),
                          subtitle: Text(
                            'A entrega organiza dados territoriais, métricas e planejamento. '
                            'Mapas e análises reais exigem fontes geográficas, imagens e validação de campo.',
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
                            title: 'Cobertura',
                            value:
                                '${analytics.coveragePercent.toStringAsFixed(0)}%',
                            subtitle: 'Funcionalidades registradas',
                            icon: Icons.grid_view_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Score territorial',
                            value: '${analytics.score}/100',
                            subtitle: analytics.score >= 70
                                ? 'Estrutura consistente'
                                : 'Requer revisão',
                            icon: Icons.analytics_outlined,
                            warning: analytics.score < 50,
                          ),
                          EnterpriseMetricCard(
                            title: 'Registros',
                            value: '${analytics.recordCount}',
                            subtitle: 'Histórico do módulo',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Operacionais',
                            value: '${analytics.operationalCount}',
                            subtitle: 'Ativos ou validados',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Inconsistências e riscos',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Área total',
                            value:
                                '${analytics.totalAreaHectares.toStringAsFixed(2)} ha',
                            subtitle: 'Área consolidada',
                            icon: Icons.square_foot_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Métrica média',
                            value: analytics.averageMetric.toStringAsFixed(2),
                            subtitle: 'Leitura consolidada',
                            icon: Icons.show_chart_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Qualidade média',
                            value:
                                '${analytics.averageQuality.toStringAsFixed(1)}%',
                            subtitle: 'Qualidade informada',
                            icon: Icons.verified_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Progresso médio',
                            value:
                                '${analytics.averageProgress.toStringAsFixed(0)}%',
                            subtitle: 'Evolução do planejamento',
                            icon: Icons.trending_up_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      EnterpriseInsightCard(
                        title: 'Recomendações Atlas',
                        items: analytics.recommendations,
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
                        'Registros geoespaciais',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre a primeira área, análise ou métrica.',
                            ),
                          ),
                        )
                      else
                        ...visibleRecords.map(
                          (record) => _RecordCard(
                            record: record,
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

  final AtlasGeospatialModule selected;
  final ValueChanged<AtlasGeospatialModule> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AtlasGeospatialModule.values
              .map((module) {
                final active = module == selected;

                return FilledButton.tonalIcon(
                  onPressed: () => onSelected(module),
                  style: FilledButton.styleFrom(
                    backgroundColor: active ? const Color(0xFF1B5E20) : null,
                    foregroundColor: active ? Colors.white : null,
                  ),
                  icon: Icon(_moduleIcon(module)),
                  label: Text(module.title),
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

  final AtlasGeospatialModule module;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Todos', ...module.features]
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final AtlasGeospatialRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      'Crítico' || 'Bloqueado' || 'Inconsistente' => Colors.red.shade800,
      'Atenção' => Colors.orange.shade800,
      'Ativo' ||
      'Validado' ||
      'Monitorado' ||
      'Concluído' => Colors.green.shade800,
      _ => Colors.blueGrey,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_moduleIcon(record.module), color: color),
        ),
        title: Text(record.title),
        subtitle: Text(
          '${record.feature}\n'
          '${record.date} • ${AtlasUiText.status(record.status)} • '
          '${record.areaHectares.toStringAsFixed(2)} ha\n'
          '${record.metricName}: '
          '${record.metricValue.toStringAsFixed(2)} ${record.unit}',
        ),
        isThreeLine: true,
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
      ),
    );
  }
}

class _GeospatialForm extends StatefulWidget {
  const _GeospatialForm({required this.module, this.current});

  final AtlasGeospatialModule module;
  final AtlasGeospatialRecord? current;

  @override
  State<_GeospatialForm> createState() => _GeospatialFormState();
}

class _GeospatialFormState extends State<_GeospatialForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController areaName;
  late final TextEditingController areaHectares;
  late final TextEditingController latitude;
  late final TextEditingController longitude;
  late final TextEditingController metricName;
  late final TextEditingController metricValue;
  late final TextEditingController unit;
  late final TextEditingController qualityPercent;
  late final TextEditingController progressPercent;
  late final TextEditingController alertCount;
  late final TextEditingController referenceDate;
  late final TextEditingController source;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final current = widget.current;

    feature = current?.feature ?? widget.module.features.first;
    status = current?.status ?? 'Planejado';

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ?? formatAtlasGeospatialDate(DateTime.now()),
    );
    areaName = TextEditingController(text: current?.areaName ?? '');
    areaHectares = TextEditingController(
      text: current == null || current.areaHectares == 0
          ? ''
          : current.areaHectares.toString(),
    );
    latitude = TextEditingController(
      text: current == null || current.latitude == 0
          ? ''
          : current.latitude.toString(),
    );
    longitude = TextEditingController(
      text: current == null || current.longitude == 0
          ? ''
          : current.longitude.toString(),
    );
    metricName = TextEditingController(text: current?.metricName ?? '');
    metricValue = TextEditingController(
      text: current == null || current.metricValue == 0
          ? ''
          : current.metricValue.toString(),
    );
    unit = TextEditingController(text: current?.unit ?? '');
    qualityPercent = TextEditingController(
      text: current == null || current.qualityPercent == 0
          ? ''
          : current.qualityPercent.toString(),
    );
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
    );
    alertCount = TextEditingController(
      text: current == null || current.alertCount == 0
          ? ''
          : current.alertCount.toString(),
    );
    referenceDate = TextEditingController(text: current?.referenceDate ?? '');
    source = TextEditingController(text: current?.source ?? '');
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    areaName.dispose();
    areaHectares.dispose();
    latitude.dispose();
    longitude.dispose();
    metricName.dispose();
    metricValue.dispose();
    unit.dispose();
    qualityPercent.dispose();
    progressPercent.dispose();
    alertCount.dispose();
    referenceDate.dispose();
    source.dispose();
    notes.dispose();
    super.dispose();
  }

  double decimal(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0.0;
  }

  int integer(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  double percent(TextEditingController controller) {
    return decimal(controller).clamp(0.0, 100.0);
  }

  int nonNegative(TextEditingController controller) {
    final value = integer(controller);
    return value < 0 ? 0 : value;
  }

  Future<void> chooseDate(TextEditingController controller) async {
    final parsed = parseAtlasGeospatialDate(controller.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      controller.text = formatAtlasGeospatialDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasGeospatialRecord(
        id: current?.id ?? 'geo_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        areaName: areaName.text.trim(),
        areaHectares: decimal(areaHectares),
        latitude: decimal(latitude),
        longitude: decimal(longitude),
        metricName: metricName.text.trim(),
        metricValue: decimal(metricValue),
        unit: unit.text.trim(),
        qualityPercent: percent(qualityPercent),
        progressPercent: integer(progressPercent).clamp(0, 100),
        alertCount: nonNegative(alertCount),
        referenceDate: referenceDate.text.trim(),
        source: source.text.trim(),
        notes: notes.text.trim(),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.current == null ? 'Novo registro' : 'Editar registro'),
      content: SizedBox(
        width: 760,
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
                  onTap: () => chooseDate(date),
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
                            'Em análise',
                            'Ativo',
                            'Validado',
                            'Monitorado',
                            'Concluído',
                            'Atenção',
                            'Inconsistente',
                            'Crítico',
                            'Bloqueado',
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
                  controller: areaName,
                  decoration: const InputDecoration(
                    labelText: 'Área, piquete ou zona',
                  ),
                ),
                TextFormField(
                  controller: areaHectares,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Área (ha)'),
                ),
                TextFormField(
                  controller: latitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                ),
                TextFormField(
                  controller: longitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                ),
                TextFormField(
                  controller: metricName,
                  decoration: const InputDecoration(
                    labelText: 'Nome da métrica',
                  ),
                ),
                TextFormField(
                  controller: metricValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor da métrica',
                  ),
                ),
                TextFormField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                ),
                TextFormField(
                  controller: qualityPercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Qualidade do dado (0 a 100%)',
                  ),
                ),
                TextFormField(
                  controller: progressPercent,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Progresso (0 a 100%)',
                  ),
                ),
                TextFormField(
                  controller: alertCount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de alertas',
                  ),
                ),
                TextFormField(
                  controller: referenceDate,
                  readOnly: true,
                  onTap: () => chooseDate(referenceDate),
                  decoration: const InputDecoration(
                    labelText: 'Data de referência',
                    suffixIcon: Icon(Icons.event_outlined),
                  ),
                ),
                TextFormField(
                  controller: source,
                  decoration: const InputDecoration(
                    labelText: 'Fonte ou referência',
                  ),
                ),
                TextFormField(
                  controller: notes,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Observações'),
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
        FilledButton(onPressed: save, child: const Text('Salvar')),
      ],
    );
  }
}

IconData _moduleIcon(AtlasGeospatialModule module) {
  return switch (module) {
    AtlasGeospatialModule.gisMaps => Icons.map_outlined,
    AtlasGeospatialModule.smartPaddocks => Icons.grid_on_outlined,
    AtlasGeospatialModule.automaticRotation => Icons.sync_alt_outlined,
    AtlasGeospatialModule.pasturePlanning => Icons.grass_outlined,
    AtlasGeospatialModule.ndvi => Icons.eco_outlined,
    AtlasGeospatialModule.biomass => Icons.stacked_line_chart_outlined,
    AtlasGeospatialModule.soil => Icons.landscape_outlined,
    AtlasGeospatialModule.slope => Icons.terrain_outlined,
    AtlasGeospatialModule.irrigation => Icons.water_outlined,
    AtlasGeospatialModule.territorialPlanning => Icons.account_tree_outlined,
  };
}
