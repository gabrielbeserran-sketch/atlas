import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_sustainability_enterprise/data/services/atlas_sustainability_enterprise_storage_service.dart';
import 'package:projeto_atlas/features/atlas_sustainability_enterprise/domain/models/atlas_sustainability_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_sustainability_enterprise/domain/services/atlas_sustainability_enterprise_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasSustainabilityEnterpriseScreen extends StatefulWidget {
  const AtlasSustainabilityEnterpriseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasSustainabilityEnterpriseModule initialModule;

  @override
  State<AtlasSustainabilityEnterpriseScreen> createState() =>
      _AtlasSustainabilityEnterpriseScreenState();
}

class _AtlasSustainabilityEnterpriseScreenState
    extends State<AtlasSustainabilityEnterpriseScreen> {
  final AtlasSustainabilityEnterpriseStorageService storage =
      AtlasSustainabilityEnterpriseStorageService();
  final AtlasSustainabilityEnterpriseAnalyticsService analyticsService =
      const AtlasSustainabilityEnterpriseAnalyticsService();

  late AtlasSustainabilityEnterpriseModule selectedModule;
  List<AtlasSustainabilityEnterpriseRecord> records = [];
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
      (first, second) => parseAtlasSustainabilityDate(
        second.date,
      ).compareTo(parseAtlasSustainabilityDate(first.date)),
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

  List<AtlasSustainabilityEnterpriseRecord> get visibleRecords {
    return records
        .where((record) {
          final moduleMatches = record.module == selectedModule;
          final featureMatches =
              selectedFeature == 'Todos' || record.feature == selectedFeature;
          return moduleMatches && featureMatches;
        })
        .toList(growable: false);
  }

  Future<void> openForm([AtlasSustainabilityEnterpriseRecord? current]) async {
    final result = await showDialog<AtlasSustainabilityEnterpriseRecord>(
      context: context,
      builder: (context) =>
          _SustainabilityForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasSustainabilityEnterpriseRecord record) async {
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
                            '${selectedModule.packageLabel} • '
                            '${widget.farm.name} • '
                            '${widget.animal.displayName}',
                        icon: _moduleIcon(selectedModule),
                      ),
                      const SizedBox(height: 14),
                      Card(
                        color: const Color(0xFFFFF8E1),
                        child: const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Fase 29 — Sustentabilidade Enterprise'),
                          subtitle: Text(
                            'A entrega organiza indicadores, metas e evidências ESG. '
                            'Inventários, licenças e certificações reais exigem metodologia e validação profissional.',
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
                            title: 'Score ESG',
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
                            subtitle: 'Ativos ou conformes',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Prazos e não conformidades',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor atual',
                            value: analytics.totalCurrentValue.toStringAsFixed(
                              2,
                            ),
                            subtitle: 'Total consolidado',
                            icon: Icons.assessment_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Linha de base',
                            value: analytics.totalBaselineValue.toStringAsFixed(
                              2,
                            ),
                            subtitle: 'Referência consolidada',
                            icon: Icons.history_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Meta',
                            value: analytics.totalTargetValue.toStringAsFixed(
                              2,
                            ),
                            subtitle: 'Meta consolidada',
                            icon: Icons.flag_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Variação',
                            value:
                                '${analytics.consolidatedChangePercent.toStringAsFixed(1)}%',
                            subtitle: 'Atual versus linha de base',
                            icon: Icons.trending_up_outlined,
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
                            subtitle: 'Evolução das metas',
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
                        'Registros de sustentabilidade',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre o primeiro indicador, evidência ou meta.',
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

  final AtlasSustainabilityEnterpriseModule selected;
  final ValueChanged<AtlasSustainabilityEnterpriseModule> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AtlasSustainabilityEnterpriseModule.values
              .map((module) {
                final active = module == selected;

                return FilledButton.tonalIcon(
                  onPressed: () => onSelected(module),
                  style: FilledButton.styleFrom(
                    backgroundColor: active ? const Color(0xFF1B5E20) : null,
                    foregroundColor: active ? Colors.white : null,
                  ),
                  icon: Icon(_moduleIcon(module)),
                  label: Text(module.packageLabel),
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

  final AtlasSustainabilityEnterpriseModule module;
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

  final AtlasSustainabilityEnterpriseRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      'Crítico' || 'Bloqueado' || 'Não conforme' => Colors.red.shade800,
      'Atenção' => Colors.orange.shade800,
      'Ativo' ||
      'Validado' ||
      'Conforme' ||
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
          '${record.currentValue.toStringAsFixed(2)} ${record.unit}',
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

class _SustainabilityForm extends StatefulWidget {
  const _SustainabilityForm({required this.module, this.current});

  final AtlasSustainabilityEnterpriseModule module;
  final AtlasSustainabilityEnterpriseRecord? current;

  @override
  State<_SustainabilityForm> createState() => _SustainabilityFormState();
}

class _SustainabilityFormState extends State<_SustainabilityForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController companyName;
  late final TextEditingController farmName;
  late final TextEditingController scope;
  late final TextEditingController metricName;
  late final TextEditingController currentValue;
  late final TextEditingController baselineValue;
  late final TextEditingController targetValue;
  late final TextEditingController unit;
  late final TextEditingController qualityPercent;
  late final TextEditingController progressPercent;
  late final TextEditingController alertCount;
  late final TextEditingController dueDate;
  late final TextEditingController responsible;
  late final TextEditingController evidence;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final current = widget.current;

    feature = current?.feature ?? widget.module.features.first;
    status = current?.status ?? 'Planejado';

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ?? formatAtlasSustainabilityDate(DateTime.now()),
    );
    companyName = TextEditingController(text: current?.companyName ?? '');
    farmName = TextEditingController(text: current?.farmName ?? '');
    scope = TextEditingController(text: current?.scope ?? '');
    metricName = TextEditingController(text: current?.metricName ?? '');
    currentValue = TextEditingController(
      text: current == null || current.currentValue == 0
          ? ''
          : current.currentValue.toString(),
    );
    baselineValue = TextEditingController(
      text: current == null || current.baselineValue == 0
          ? ''
          : current.baselineValue.toString(),
    );
    targetValue = TextEditingController(
      text: current == null || current.targetValue == 0
          ? ''
          : current.targetValue.toString(),
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
    dueDate = TextEditingController(text: current?.dueDate ?? '');
    responsible = TextEditingController(text: current?.responsible ?? '');
    evidence = TextEditingController(text: current?.evidence ?? '');
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    companyName.dispose();
    farmName.dispose();
    scope.dispose();
    metricName.dispose();
    currentValue.dispose();
    baselineValue.dispose();
    targetValue.dispose();
    unit.dispose();
    qualityPercent.dispose();
    progressPercent.dispose();
    alertCount.dispose();
    dueDate.dispose();
    responsible.dispose();
    evidence.dispose();
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
    final parsed = parseAtlasSustainabilityDate(controller.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      controller.text = formatAtlasSustainabilityDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasSustainabilityEnterpriseRecord(
        id:
            current?.id ??
            'sustainability_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        companyName: companyName.text.trim(),
        farmName: farmName.text.trim(),
        scope: scope.text.trim(),
        metricName: metricName.text.trim(),
        currentValue: decimal(currentValue),
        baselineValue: decimal(baselineValue),
        targetValue: decimal(targetValue),
        unit: unit.text.trim(),
        qualityPercent: percent(qualityPercent),
        progressPercent: integer(progressPercent).clamp(0, 100),
        alertCount: nonNegative(alertCount),
        dueDate: dueDate.text.trim(),
        responsible: responsible.text.trim(),
        evidence: evidence.text.trim(),
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
                            'Conforme',
                            'Concluído',
                            'Atenção',
                            'Não conforme',
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
                  controller: companyName,
                  decoration: const InputDecoration(labelText: 'Empresa'),
                ),
                TextFormField(
                  controller: farmName,
                  decoration: const InputDecoration(labelText: 'Fazenda'),
                ),
                TextFormField(
                  controller: scope,
                  decoration: const InputDecoration(
                    labelText: 'Escopo, área ou atividade',
                  ),
                ),
                TextFormField(
                  controller: metricName,
                  decoration: const InputDecoration(
                    labelText: 'Nome do indicador',
                  ),
                ),
                TextFormField(
                  controller: currentValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Valor atual'),
                ),
                TextFormField(
                  controller: baselineValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Linha de base'),
                ),
                TextFormField(
                  controller: targetValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Meta'),
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
                  controller: dueDate,
                  readOnly: true,
                  onTap: () => chooseDate(dueDate),
                  decoration: const InputDecoration(
                    labelText: 'Prazo ou validade',
                    suffixIcon: Icon(Icons.event_busy_outlined),
                  ),
                ),
                TextFormField(
                  controller: responsible,
                  decoration: const InputDecoration(labelText: 'Responsável'),
                ),
                TextFormField(
                  controller: evidence,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Evidência ou referência',
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

IconData _moduleIcon(AtlasSustainabilityEnterpriseModule module) {
  return switch (module) {
    AtlasSustainabilityEnterpriseModule.carbonFootprint => Icons.cloud_outlined,
    AtlasSustainabilityEnterpriseModule.greenhouseGasInventory =>
      Icons.co2_outlined,
    AtlasSustainabilityEnterpriseModule.waterManagement =>
      Icons.water_drop_outlined,
    AtlasSustainabilityEnterpriseModule.energyEfficiency => Icons.bolt_outlined,
    AtlasSustainabilityEnterpriseModule.wasteManagement =>
      Icons.recycling_outlined,
    AtlasSustainabilityEnterpriseModule.biodiversity => Icons.eco_outlined,
    AtlasSustainabilityEnterpriseModule.environmentalCompliance =>
      Icons.rule_outlined,
    AtlasSustainabilityEnterpriseModule.sustainabilityCertifications =>
      Icons.workspace_premium_outlined,
    AtlasSustainabilityEnterpriseModule.sustainableTraceability =>
      Icons.route_outlined,
    AtlasSustainabilityEnterpriseModule.esgCenter => Icons.dashboard_outlined,
  };
}
