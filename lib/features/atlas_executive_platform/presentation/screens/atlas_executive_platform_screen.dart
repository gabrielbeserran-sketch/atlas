import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_executive_platform/data/services/atlas_executive_platform_storage_service.dart';
import 'package:projeto_atlas/features/atlas_executive_platform/domain/models/atlas_executive_platform_record.dart';
import 'package:projeto_atlas/features/atlas_executive_platform/domain/services/atlas_executive_platform_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasExecutivePlatformScreen extends StatefulWidget {
  const AtlasExecutivePlatformScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasExecutivePlatformModule initialModule;

  @override
  State<AtlasExecutivePlatformScreen> createState() =>
      _AtlasExecutivePlatformScreenState();
}

class _AtlasExecutivePlatformScreenState
    extends State<AtlasExecutivePlatformScreen> {
  final storage = AtlasExecutivePlatformStorageService();
  final analyticsService =
      const AtlasExecutivePlatformAnalyticsService();

  late AtlasExecutivePlatformModule selectedModule;
  List<AtlasExecutivePlatformRecord> records = [];
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
      (a, b) => parseAtlasExecutiveDate(b.date)
          .compareTo(parseAtlasExecutiveDate(a.date)),
    );

    if (!mounted) return;

    setState(() {
      records = loaded;
      loading = false;
    });
  }

  Future<void> persist() => storage.save(
        farmName: widget.farm.name,
        animalId: widget.animal.id,
        records: records,
      );

  List<AtlasExecutivePlatformRecord> get visibleRecords =>
      records.where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' ||
                record.feature == selectedFeature);
      }).toList(growable: false);

  Future<void> openForm([
    AtlasExecutivePlatformRecord? current,
  ]) async {
    final result =
        await showDialog<AtlasExecutivePlatformRecord>(
      context: context,
      builder: (_) => _ExecutivePlatformForm(
        module: selectedModule,
        current: current,
      ),
    );

    if (result == null || !mounted) return;

    final index = records.indexWhere((item) => item.id == result.id);

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

  Future<void> deleteRecord(
    AtlasExecutivePlatformRecord record,
  ) async {
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
                          title: Text(
                            'Fase 35 — Plataforma Executiva e Produto Comercial',
                          ),
                          subtitle: Text(
                            'A entrega consolida indicadores, metas, alertas, relatórios e gestão da plataforma. '
                            'Cobrança, exportações e administração reais exigem backend, provedores e políticas.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasExecutivePlatformModule.values
                            .map(
                              (module) => ChoiceChip(
                                label: Text(module.packageLabel),
                                selected: selectedModule == module,
                                onSelected: (_) {
                                  setState(() {
                                    selectedModule = module;
                                    selectedFeature = 'Todos';
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
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
                            title: 'Score executivo',
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
                            subtitle: 'Ativos ou publicados',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Vencidos',
                            value: '${analytics.overdueCount}',
                            subtitle: 'Prazos ultrapassados',
                            icon: Icons.event_busy_outlined,
                            warning: analytics.overdueCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Riscos e pendências',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor atual médio',
                            value:
                                analytics.averageCurrent.toStringAsFixed(2),
                            subtitle: 'Indicador atual',
                            icon: Icons.assessment_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Meta média',
                            value:
                                analytics.averageTarget.toStringAsFixed(2),
                            subtitle: 'Meta consolidada',
                            icon: Icons.flag_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Gap médio',
                            value:
                                analytics.averageGap.toStringAsFixed(2),
                            subtitle: 'Atual menos meta',
                            icon: Icons.compare_arrows_outlined,
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
                            title: 'Progresso médio',
                            value:
                                '${analytics.averageProgress.toStringAsFixed(0)}%',
                            subtitle: 'Evolução consolidada',
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Todos', ...selectedModule.features]
                            .map(
                              (feature) => ChoiceChip(
                                label: Text(feature),
                                selected: selectedFeature == feature,
                                onSelected: (_) {
                                  setState(() {
                                    selectedFeature = feature;
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 18),
                      const EnterpriseSectionTitle(
                        'Registros da plataforma executiva',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text(
                              'Nenhum registro encontrado.',
                            ),
                            subtitle: const Text(
                              'Cadastre o primeiro indicador, meta, alerta ou relatório.',
                            ),
                          ),
                        )
                      else
                        ...visibleRecords.map(
                          (record) => Card(
                            child: ListTile(
                              leading: Icon(_moduleIcon(record.module)),
                              title: Text(record.title),
                              subtitle: Text(
                                '${record.feature}\n'
                                '${record.date} • ${record.status} • '
                                '${record.priority} • '
                                '${record.progressPercent}%\n'
                                '${record.metricName.isEmpty ? 'Sem indicador vinculado' : record.metricName}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    openForm(record);
                                  } else if (value == 'delete') {
                                    deleteRecord(record);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
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
}

class _ExecutivePlatformForm extends StatefulWidget {
  const _ExecutivePlatformForm({
    required this.module,
    this.current,
  });

  final AtlasExecutivePlatformModule module;
  final AtlasExecutivePlatformRecord? current;

  @override
  State<_ExecutivePlatformForm> createState() =>
      _ExecutivePlatformFormState();
}

class _ExecutivePlatformFormState
    extends State<_ExecutivePlatformForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController dueDate;
  late final TextEditingController farmName;
  late final TextEditingController companyName;
  late final TextEditingController ownerName;
  late final TextEditingController metricName;
  late final TextEditingController currentValue;
  late final TextEditingController targetValue;
  late final TextEditingController referenceValue;
  late final TextEditingController unit;
  late final TextEditingController progressPercent;
  late final TextEditingController confidencePercent;
  late final TextEditingController riskPercent;
  late final TextEditingController alertCount;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final current = widget.current;

    feature = current?.feature ?? widget.module.features.first;
    status = current?.status ?? 'Planejado';
    priority = current?.priority ?? 'Média';

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ??
          formatAtlasExecutiveDate(DateTime.now()),
    );
    dueDate = TextEditingController(text: current?.dueDate ?? '');
    farmName = TextEditingController(text: current?.farmName ?? '');
    companyName =
        TextEditingController(text: current?.companyName ?? '');
    ownerName = TextEditingController(text: current?.ownerName ?? '');
    metricName =
        TextEditingController(text: current?.metricName ?? '');
    currentValue = TextEditingController(
      text: current == null || current.currentValue == 0
          ? ''
          : current.currentValue.toString(),
    );
    targetValue = TextEditingController(
      text: current == null || current.targetValue == 0
          ? ''
          : current.targetValue.toString(),
    );
    referenceValue = TextEditingController(
      text: current == null || current.referenceValue == 0
          ? ''
          : current.referenceValue.toString(),
    );
    unit = TextEditingController(text: current?.unit ?? '');
    progressPercent = TextEditingController(
      text: current == null
          ? ''
          : current.progressPercent.toString(),
    );
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
    alertCount = TextEditingController(
      text: current == null || current.alertCount == 0
          ? ''
          : current.alertCount.toString(),
    );
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      title,
      date,
      dueDate,
      farmName,
      companyName,
      ownerName,
      metricName,
      currentValue,
      targetValue,
      referenceValue,
      unit,
      progressPercent,
      confidencePercent,
      riskPercent,
      alertCount,
      notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double decimal(TextEditingController controller) =>
      double.tryParse(
        controller.text.trim().replaceAll(',', '.'),
      ) ??
      0;

  int integer(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  Future<void> chooseDate(
    TextEditingController controller,
  ) async {
    final parsed = parseAtlasExecutiveDate(controller.text);
    final selected = await showDatePicker(
      context: context,
      initialDate:
          parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (selected == null) return;

    setState(() {
      controller.text = formatAtlasExecutiveDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final current = widget.current;
    final now = DateTime.now().toIso8601String();

    Navigator.pop(
      context,
      AtlasExecutivePlatformRecord(
        id: current?.id ??
            'executive_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        dueDate: dueDate.text.trim(),
        status: status,
        priority: priority,
        farmName: farmName.text.trim(),
        companyName: companyName.text.trim(),
        ownerName: ownerName.text.trim(),
        metricName: metricName.text.trim(),
        currentValue: decimal(currentValue),
        targetValue: decimal(targetValue),
        referenceValue: decimal(referenceValue),
        unit: unit.text.trim(),
        progressPercent:
            integer(progressPercent).clamp(0, 100),
        confidencePercent:
            decimal(confidencePercent).clamp(0, 100),
        riskPercent:
            decimal(riskPercent).clamp(0, 100),
        alertCount:
            integer(alertCount) < 0 ? 0 : integer(alertCount),
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
            ? 'Novo registro'
            : 'Editar registro',
      ),
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
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
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
                  decoration: const InputDecoration(
                    labelText: 'Título',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Informe o título.'
                          : null,
                ),
                TextFormField(
                  controller: date,
                  readOnly: true,
                  onTap: () => chooseDate(date),
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    suffixIcon: Icon(
                      Icons.calendar_month_outlined,
                    ),
                  ),
                ),
                TextFormField(
                  controller: dueDate,
                  readOnly: true,
                  onTap: () => chooseDate(dueDate),
                  decoration: const InputDecoration(
                    labelText: 'Prazo',
                    suffixIcon: Icon(
                      Icons.event_busy_outlined,
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Situação',
                  ),
                  items: const [
                    'Planejado',
                    'Ativo',
                    'Validado',
                    'Concluído',
                    'Publicado',
                    'Atenção',
                    'Atrasado',
                    'Crítico',
                    'Bloqueado',
                    'Cancelado',
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
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade',
                  ),
                  items: const [
                    'Baixa',
                    'Média',
                    'Alta',
                    'Urgente',
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
                      setState(() => priority = value);
                    }
                  },
                ),
                ...[
                  (farmName, 'Fazenda'),
                  (companyName, 'Empresa'),
                  (ownerName, 'Responsável'),
                  (metricName, 'Indicador ou referência'),
                  (unit, 'Unidade'),
                ].map(
                  (item) => TextFormField(
                    controller: item.$1,
                    decoration: InputDecoration(
                      labelText: item.$2,
                    ),
                  ),
                ),
                ...[
                  (currentValue, 'Valor atual'),
                  (targetValue, 'Meta'),
                  (referenceValue, 'Valor de referência'),
                  (confidencePercent, 'Confiança (0 a 100%)'),
                  (riskPercent, 'Risco (0 a 100%)'),
                ].map(
                  (item) => TextFormField(
                    controller: item.$1,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: item.$2,
                    ),
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
                  controller: notes,
                  minLines: 3,
                  maxLines: 6,
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

IconData _moduleIcon(
  AtlasExecutivePlatformModule module,
) {
  return switch (module) {
    AtlasExecutivePlatformModule.globalExecutiveDashboard =>
      Icons.dashboard_outlined,
    AtlasExecutivePlatformModule.farmBenchmarking =>
      Icons.compare_arrows_outlined,
    AtlasExecutivePlatformModule.corporateGoals =>
      Icons.flag_outlined,
    AtlasExecutivePlatformModule.unifiedAlerts =>
      Icons.notifications_active_outlined,
    AtlasExecutivePlatformModule.intelligentTasks =>
      Icons.task_alt_outlined,
    AtlasExecutivePlatformModule.professionalReports =>
      Icons.description_outlined,
    AtlasExecutivePlatformModule.exportAndSharing =>
      Icons.ios_share_outlined,
    AtlasExecutivePlatformModule.plansAndSubscriptions =>
      Icons.workspace_premium_outlined,
    AtlasExecutivePlatformModule.platformAdminPanel =>
      Icons.admin_panel_settings_outlined,
    AtlasExecutivePlatformModule.enterpriseCommandCenter =>
      Icons.hub_outlined,
  };
}
