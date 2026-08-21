import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_precision_livestock/data/services/atlas_precision_livestock_storage_service.dart';
import 'package:projeto_atlas/features/atlas_precision_livestock/domain/models/atlas_precision_livestock_record.dart';
import 'package:projeto_atlas/features/atlas_precision_livestock/domain/services/atlas_precision_livestock_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasPrecisionLivestockScreen extends StatefulWidget {
  const AtlasPrecisionLivestockScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasPrecisionLivestockModule initialModule;

  @override
  State<AtlasPrecisionLivestockScreen> createState() =>
      _AtlasPrecisionLivestockScreenState();
}

class _AtlasPrecisionLivestockScreenState
    extends State<AtlasPrecisionLivestockScreen> {
  final AtlasPrecisionLivestockStorageService storage =
      AtlasPrecisionLivestockStorageService();
  final AtlasPrecisionLivestockAnalyticsService analyticsService =
      const AtlasPrecisionLivestockAnalyticsService();

  late AtlasPrecisionLivestockModule selectedModule;
  List<AtlasPrecisionLivestockRecord> records = [];
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
      (first, second) => parseAtlasPrecisionLivestockDate(
        second.date,
      ).compareTo(parseAtlasPrecisionLivestockDate(first.date)),
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

  List<AtlasPrecisionLivestockRecord> get visibleRecords {
    return records
        .where((record) {
          final moduleMatches = record.module == selectedModule;
          final featureMatches =
              selectedFeature == 'Todos' || record.feature == selectedFeature;
          return moduleMatches && featureMatches;
        })
        .toList(growable: false);
  }

  Future<void> openForm([AtlasPrecisionLivestockRecord? current]) async {
    final result = await showDialog<AtlasPrecisionLivestockRecord>(
      context: context,
      builder: (context) =>
          _PrecisionLivestockForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasPrecisionLivestockRecord record) async {
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
                          title: Text('Pecuária de Precisão'),
                          subtitle: Text(
                            'A entrega organiza previsões, riscos e eficiência. '
                            'Modelos reais exigem dados históricos, sensores, calibração e validação profissional.',
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
                            title: 'Score de precisão',
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
                            subtitle: 'Riscos e desvios',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Confiança média',
                            value:
                                '${analytics.averageConfidence.toStringAsFixed(1)}%',
                            subtitle: 'Confiabilidade informada',
                            icon: Icons.verified_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Risco médio',
                            value:
                                '${analytics.averageRisk.toStringAsFixed(1)}%',
                            subtitle: 'Risco informado',
                            icon: Icons.shield_outlined,
                            warning: analytics.averageRisk >= 60,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor atual médio',
                            value: analytics.averageCurrent.toStringAsFixed(2),
                            subtitle: 'Métrica atual',
                            icon: Icons.assessment_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor projetado médio',
                            value: analytics.averageProjected.toStringAsFixed(
                              2,
                            ),
                            subtitle: 'Métrica projetada',
                            icon: Icons.auto_graph_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Impacto financeiro',
                            value:
                                'R\$ ${analytics.totalFinancialImpact.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Impacto consolidado',
                            icon: Icons.payments_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Progresso médio',
                            value:
                                '${analytics.averageProgress.toStringAsFixed(0)}%',
                            subtitle: 'Evolução das análises',
                            icon: Icons.timeline_outlined,
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
                        'Registros de pecuária de precisão',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre a primeira previsão, análise ou alerta.',
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

  final AtlasPrecisionLivestockModule selected;
  final ValueChanged<AtlasPrecisionLivestockModule> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AtlasPrecisionLivestockModule.values
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

  final AtlasPrecisionLivestockModule module;
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

  final AtlasPrecisionLivestockRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      'Crítico' || 'Bloqueado' || 'Alto risco' => Colors.red.shade800,
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
          '${record.date} • ${record.status} • '
          '${record.progressPercent}%\n'
          '${record.metricName}: '
          '${record.currentValue.toStringAsFixed(2)} → '
          '${record.projectedValue.toStringAsFixed(2)} '
          '${record.unit}',
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

class _PrecisionLivestockForm extends StatefulWidget {
  const _PrecisionLivestockForm({required this.module, this.current});

  final AtlasPrecisionLivestockModule module;
  final AtlasPrecisionLivestockRecord? current;

  @override
  State<_PrecisionLivestockForm> createState() =>
      _PrecisionLivestockFormState();
}

class _PrecisionLivestockFormState extends State<_PrecisionLivestockForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController animalReference;
  late final TextEditingController groupReference;
  late final TextEditingController metricName;
  late final TextEditingController currentValue;
  late final TextEditingController projectedValue;
  late final TextEditingController targetValue;
  late final TextEditingController unit;
  late final TextEditingController confidencePercent;
  late final TextEditingController riskPercent;
  late final TextEditingController financialImpact;
  late final TextEditingController progressPercent;
  late final TextEditingController alertCount;
  late final TextEditingController horizonDays;
  late final TextEditingController responsible;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final current = widget.current;

    feature = current?.feature ?? widget.module.features.first;
    status = current?.status ?? 'Planejado';

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ?? formatAtlasPrecisionLivestockDate(DateTime.now()),
    );
    animalReference = TextEditingController(
      text: current?.animalReference ?? '',
    );
    groupReference = TextEditingController(text: current?.groupReference ?? '');
    metricName = TextEditingController(text: current?.metricName ?? '');
    currentValue = TextEditingController(
      text: current == null || current.currentValue == 0
          ? ''
          : current.currentValue.toString(),
    );
    projectedValue = TextEditingController(
      text: current == null || current.projectedValue == 0
          ? ''
          : current.projectedValue.toString(),
    );
    targetValue = TextEditingController(
      text: current == null || current.targetValue == 0
          ? ''
          : current.targetValue.toString(),
    );
    unit = TextEditingController(text: current?.unit ?? '');
    confidencePercent = TextEditingController(
      text: current == null || current.confidencePercent == 0
          ? ''
          : current.confidencePercent.toString(),
    );
    riskPercent = TextEditingController(
      text: current == null || current.riskPercent == 0
          ? ''
          : current.riskPercent.toString(),
    );
    financialImpact = TextEditingController(
      text: current == null || current.financialImpact == 0
          ? ''
          : current.financialImpact.toString(),
    );
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
    );
    alertCount = TextEditingController(
      text: current == null || current.alertCount == 0
          ? ''
          : current.alertCount.toString(),
    );
    horizonDays = TextEditingController(
      text: current == null || current.horizonDays == 0
          ? ''
          : current.horizonDays.toString(),
    );
    responsible = TextEditingController(text: current?.responsible ?? '');
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    animalReference.dispose();
    groupReference.dispose();
    metricName.dispose();
    currentValue.dispose();
    projectedValue.dispose();
    targetValue.dispose();
    unit.dispose();
    confidencePercent.dispose();
    riskPercent.dispose();
    financialImpact.dispose();
    progressPercent.dispose();
    alertCount.dispose();
    horizonDays.dispose();
    responsible.dispose();
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

  Future<void> chooseDate() async {
    final parsed = parseAtlasPrecisionLivestockDate(date.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      date.text = formatAtlasPrecisionLivestockDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasPrecisionLivestockRecord(
        id: current?.id ?? 'precision_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        animalReference: animalReference.text.trim(),
        groupReference: groupReference.text.trim(),
        metricName: metricName.text.trim(),
        currentValue: decimal(currentValue),
        projectedValue: decimal(projectedValue),
        targetValue: decimal(targetValue),
        unit: unit.text.trim(),
        confidencePercent: percent(confidencePercent),
        riskPercent: percent(riskPercent),
        financialImpact: decimal(financialImpact),
        progressPercent: integer(progressPercent).clamp(0, 100),
        alertCount: nonNegative(alertCount),
        horizonDays: nonNegative(horizonDays),
        responsible: responsible.text.trim(),
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
                            'Em análise',
                            'Ativo',
                            'Validado',
                            'Monitorado',
                            'Concluído',
                            'Atenção',
                            'Alto risco',
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
                  controller: animalReference,
                  decoration: const InputDecoration(
                    labelText: 'Animal ou identificação',
                  ),
                ),
                TextFormField(
                  controller: groupReference,
                  decoration: const InputDecoration(
                    labelText: 'Lote, categoria ou grupo',
                  ),
                ),
                TextFormField(
                  controller: metricName,
                  decoration: const InputDecoration(
                    labelText: 'Nome da métrica',
                  ),
                ),
                TextFormField(
                  controller: currentValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Valor atual'),
                ),
                TextFormField(
                  controller: projectedValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor projetado',
                  ),
                ),
                TextFormField(
                  controller: targetValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Meta'),
                ),
                TextFormField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                ),
                TextFormField(
                  controller: confidencePercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Confiança (0 a 100%)',
                  ),
                ),
                TextFormField(
                  controller: riskPercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Risco (0 a 100%)',
                  ),
                ),
                TextFormField(
                  controller: financialImpact,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Impacto financeiro (R\$)',
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
                  controller: horizonDays,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Horizonte da projeção (dias)',
                  ),
                ),
                TextFormField(
                  controller: responsible,
                  decoration: const InputDecoration(
                    labelText: 'Responsável pela validação',
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

IconData _moduleIcon(AtlasPrecisionLivestockModule module) {
  return switch (module) {
    AtlasPrecisionLivestockModule.weightPrediction =>
      Icons.monitor_weight_outlined,
    AtlasPrecisionLivestockModule.dailyGainPrediction =>
      Icons.trending_up_outlined,
    AtlasPrecisionLivestockModule.estimatedIntake => Icons.restaurant_outlined,
    AtlasPrecisionLivestockModule.feedEfficiency => Icons.speed_outlined,
    AtlasPrecisionLivestockModule.feedConversion =>
      Icons.compare_arrows_outlined,
    AtlasPrecisionLivestockModule.animalWelfare => AtlasLivestockIcons.cow,
    AtlasPrecisionLivestockModule.earlyDiseaseDetection =>
      Icons.health_and_safety_outlined,
    AtlasPrecisionLivestockModule.heatStress =>
      Icons.device_thermostat_outlined,
    AtlasPrecisionLivestockModule.mortalityRisk => Icons.warning_amber_outlined,
    AtlasPrecisionLivestockModule.generalEfficiencyIndex =>
      Icons.dashboard_outlined,
  };
}
