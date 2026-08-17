import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_intelligence_reports_experience/data/services/atlas_intelligence_reports_storage_service.dart';
import 'package:projeto_atlas/features/atlas_intelligence_reports_experience/domain/models/atlas_intelligence_reports_record.dart';
import 'package:projeto_atlas/features/atlas_intelligence_reports_experience/domain/services/atlas_intelligence_reports_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasIntelligenceReportsScreen extends StatefulWidget {
  const AtlasIntelligenceReportsScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasIntelligenceReportsModule initialModule;

  @override
  State<AtlasIntelligenceReportsScreen> createState() =>
      _AtlasIntelligenceReportsScreenState();
}

class _AtlasIntelligenceReportsScreenState
    extends State<AtlasIntelligenceReportsScreen> {
  final storage = AtlasIntelligenceReportsStorageService();
  final analyticsService = const AtlasIntelligenceReportsAnalyticsService();

  late AtlasIntelligenceReportsModule selectedModule;
  List<AtlasIntelligenceReportsRecord> records = [];
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
      (a, b) => parseAtlasIntelligenceReportsDate(
        b.date,
      ).compareTo(parseAtlasIntelligenceReportsDate(a.date)),
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

  List<AtlasIntelligenceReportsRecord> get visibleRecords => records
      .where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' || record.feature == selectedFeature);
      })
      .toList(growable: false);

  Future<void> openForm([AtlasIntelligenceReportsRecord? current]) async {
    final result = await showDialog<AtlasIntelligenceReportsRecord>(
      context: context,
      builder: (_) =>
          _IntelligenceReportsForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasIntelligenceReportsRecord record) async {
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
                      const Card(
                        color: Color(0xFFFFF8E1),
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text(
                            'Fase 39 — Inteligência, Relatórios e Experiência Profissional',
                          ),
                          subtitle: Text(
                            'A entrega organiza indicadores, recomendações, relatórios, exportações e navegação. '
                            'Geração real de PDF, planilhas, benchmarking e compartilhamento exigem serviços e dados integrados.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasIntelligenceReportsModule.values
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
                            title: 'Score profissional',
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
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Falhas e riscos',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor atual médio',
                            value: analytics.averageCurrentValue
                                .toStringAsFixed(2),
                            subtitle: 'Indicadores atuais',
                            icon: Icons.assessment_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Meta média',
                            value: analytics.averageTargetValue.toStringAsFixed(
                              2,
                            ),
                            subtitle: 'Indicadores-alvo',
                            icon: Icons.flag_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Gap médio',
                            value: analytics.averageGap.toStringAsFixed(2),
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
                        'Registros de inteligência e relatórios',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre o primeiro indicador, relatório, exportação ou melhoria de navegação.',
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
                                '${record.indicatorName.isEmpty ? 'Sem indicador vinculado' : record.indicatorName}',
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

class _IntelligenceReportsForm extends StatefulWidget {
  const _IntelligenceReportsForm({required this.module, this.current});

  final AtlasIntelligenceReportsModule module;
  final AtlasIntelligenceReportsRecord? current;

  @override
  State<_IntelligenceReportsForm> createState() =>
      _IntelligenceReportsFormState();
}

class _IntelligenceReportsFormState extends State<_IntelligenceReportsForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController farmName;
  late final TextEditingController indicatorName;
  late final TextEditingController dataSource;
  late final TextEditingController periodLabel;
  late final TextEditingController responsible;
  late final TextEditingController currentValue;
  late final TextEditingController targetValue;
  late final TextEditingController confidencePercent;
  late final TextEditingController riskPercent;
  late final TextEditingController progressPercent;
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
      text: current?.date ?? formatAtlasIntelligenceReportsDate(DateTime.now()),
    );
    farmName = TextEditingController(text: current?.farmName ?? '');
    indicatorName = TextEditingController(text: current?.indicatorName ?? '');
    dataSource = TextEditingController(text: current?.dataSource ?? '');
    periodLabel = TextEditingController(text: current?.periodLabel ?? '');
    responsible = TextEditingController(text: current?.responsible ?? '');
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
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
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
      farmName,
      indicatorName,
      dataSource,
      periodLabel,
      responsible,
      currentValue,
      targetValue,
      confidencePercent,
      riskPercent,
      progressPercent,
      alertCount,
      notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double decimal(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

  int integer(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  void save() {
    if (!formKey.currentState!.validate()) return;

    final current = widget.current;
    final now = DateTime.now().toIso8601String();

    Navigator.pop(
      context,
      AtlasIntelligenceReportsRecord(
        id:
            current?.id ??
            'intelligence_reports_'
                '${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        priority: priority,
        farmName: farmName.text.trim(),
        indicatorName: indicatorName.text.trim(),
        dataSource: dataSource.text.trim(),
        periodLabel: periodLabel.text.trim(),
        responsible: responsible.text.trim(),
        currentValue: decimal(currentValue),
        targetValue: decimal(targetValue),
        confidencePercent: decimal(confidencePercent).clamp(0, 100),
        riskPercent: decimal(riskPercent).clamp(0, 100),
        progressPercent: integer(progressPercent).clamp(0, 100),
        alertCount: integer(alertCount) < 0 ? 0 : integer(alertCount),
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
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o título.'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Situação'),
                  items:
                      const [
                            'Planejado',
                            'Ativo',
                            'Validado',
                            'Publicado',
                            'Concluído',
                            'Atenção',
                            'Falha',
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
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Prioridade'),
                  items: const ['Baixa', 'Média', 'Alta', 'Urgente']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => priority = value);
                    }
                  },
                ),
                ...[
                  (date, 'Data'),
                  (farmName, 'Fazenda'),
                  (indicatorName, 'Indicador ou relatório'),
                  (dataSource, 'Fonte de dados'),
                  (periodLabel, 'Período'),
                  (responsible, 'Responsável'),
                  (currentValue, 'Valor atual'),
                  (targetValue, 'Meta'),
                  (confidencePercent, 'Confiança (0 a 100%)'),
                  (riskPercent, 'Risco (0 a 100%)'),
                  (progressPercent, 'Progresso (0 a 100%)'),
                  (alertCount, 'Alertas'),
                ].map(
                  (item) => TextFormField(
                    controller: item.$1,
                    decoration: InputDecoration(labelText: item.$2),
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

IconData _moduleIcon(AtlasIntelligenceReportsModule module) {
  return switch (module) {
    AtlasIntelligenceReportsModule.consolidatedIndicatorEngine =>
      Icons.calculate_outlined,
    AtlasIntelligenceReportsModule.realDataExecutiveDashboard =>
      Icons.dashboard_outlined,
    AtlasIntelligenceReportsModule.realFarmBenchmarking =>
      Icons.compare_arrows_outlined,
    AtlasIntelligenceReportsModule.traceableRecommendationEngine =>
      Icons.psychology_outlined,
    AtlasIntelligenceReportsModule.validatedPredictiveDiagnostics =>
      Icons.auto_graph_outlined,
    AtlasIntelligenceReportsModule.technicalPdfReports =>
      Icons.picture_as_pdf_outlined,
    AtlasIntelligenceReportsModule.financialExecutiveReports =>
      Icons.request_quote_outlined,
    AtlasIntelligenceReportsModule.spreadsheetCsvExport =>
      Icons.table_view_outlined,
    AtlasIntelligenceReportsModule.secureSharing => Icons.share_outlined,
    AtlasIntelligenceReportsModule.professionalNavigationExperience =>
      Icons.menu_open_outlined,
  };
}
