import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_quality_release/data/services/atlas_quality_release_storage_service.dart';
import 'package:projeto_atlas/features/atlas_quality_release/domain/models/atlas_quality_release_record.dart';
import 'package:projeto_atlas/features/atlas_quality_release/domain/services/atlas_quality_release_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasQualityReleaseScreen extends StatefulWidget {
  const AtlasQualityReleaseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasQualityReleaseModule initialModule;

  @override
  State<AtlasQualityReleaseScreen> createState() =>
      _AtlasQualityReleaseScreenState();
}

class _AtlasQualityReleaseScreenState extends State<AtlasQualityReleaseScreen> {
  final storage = AtlasQualityReleaseStorageService();
  final analyticsService = const AtlasQualityReleaseAnalyticsService();

  late AtlasQualityReleaseModule selectedModule;
  List<AtlasQualityReleaseRecord> records = [];
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
      (a, b) => parseAtlasQualityReleaseDate(
        b.date,
      ).compareTo(parseAtlasQualityReleaseDate(a.date)),
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

  List<AtlasQualityReleaseRecord> get visibleRecords => records
      .where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' || record.feature == selectedFeature);
      })
      .toList(growable: false);

  Future<void> openForm([AtlasQualityReleaseRecord? current]) async {
    final result = await showDialog<AtlasQualityReleaseRecord>(
      context: context,
      builder: (_) =>
          _QualityReleaseForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasQualityReleaseRecord record) async {
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
                      const Card(
                        color: Color(0xFFFFF8E1),
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text(
                            'Qualidade, Publicação e Operação Comercial',
                          ),
                          subtitle: Text(
                            'A entrega organiza revisão, testes, homologação, piloto e lançamento. '
                            'Os testes e a publicação efetivos precisam ser executados no ambiente Flutter, backend e infraestrutura reais.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasQualityReleaseModule.values
                            .map(
                              (module) => ChoiceChip(
                                label: Text(module.title),
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
                            title: 'Cobertura do pacote',
                            value:
                                '${analytics.moduleCoveragePercent.toStringAsFixed(0)}%',
                            subtitle: 'Itens registrados',
                            icon: Icons.grid_view_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Score de lançamento',
                            value: '${analytics.score}/100',
                            subtitle: analytics.score >= 70
                                ? 'Estrutura consistente'
                                : 'Requer revisão',
                            icon: Icons.rocket_launch_outlined,
                            warning: analytics.score < 50,
                          ),
                          EnterpriseMetricCard(
                            title: 'Registros',
                            value: '${analytics.recordCount}',
                            subtitle: 'Histórico',
                            icon: Icons.fact_check_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Operacionais',
                            value: '${analytics.operationalCount}',
                            subtitle: 'Aprovados ou concluídos',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Falhas',
                            value: '${analytics.failureCount}',
                            subtitle: 'Falhas registradas',
                            icon: Icons.bug_report_outlined,
                            warning: analytics.failureCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Riscos de qualidade',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Taxa de aprovação',
                            value:
                                '${analytics.averagePassRate.toStringAsFixed(1)}%',
                            subtitle: 'Média informada',
                            icon: Icons.verified_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Cobertura de testes',
                            value:
                                '${analytics.averageTestCoverage.toStringAsFixed(1)}%',
                            subtitle: 'Média informada',
                            icon: Icons.rule_folder_outlined,
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
                        'Registros de qualidade e lançamento',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre a primeira revisão, execução de teste, publicação ou atividade do piloto.',
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
                                '${record.scope.isEmpty ? 'Sem escopo informado' : record.scope}',
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

class _QualityReleaseForm extends StatefulWidget {
  const _QualityReleaseForm({required this.module, this.current});

  final AtlasQualityReleaseModule module;
  final AtlasQualityReleaseRecord? current;

  @override
  State<_QualityReleaseForm> createState() => _QualityReleaseFormState();
}

class _QualityReleaseFormState extends State<_QualityReleaseForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController environment;
  late final TextEditingController responsible;
  late final TextEditingController scope;
  late final TextEditingController evidence;
  late final TextEditingController progressPercent;
  late final TextEditingController passRatePercent;
  late final TextEditingController coveragePercent;
  late final TextEditingController riskPercent;
  late final TextEditingController failureCount;
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
      text: current?.date ?? formatAtlasQualityReleaseDate(DateTime.now()),
    );
    environment = TextEditingController(text: current?.environment ?? '');
    responsible = TextEditingController(text: current?.responsible ?? '');
    scope = TextEditingController(text: current?.scope ?? '');
    evidence = TextEditingController(text: current?.evidence ?? '');
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
    );
    passRatePercent = TextEditingController(
      text: current == null || current.passRatePercent == 0
          ? ''
          : current.passRatePercent.toString(),
    );
    coveragePercent = TextEditingController(
      text: current == null || current.coveragePercent == 0
          ? ''
          : current.coveragePercent.toString(),
    );
    riskPercent = TextEditingController(
      text: current == null || current.riskPercent == 0
          ? ''
          : current.riskPercent.toString(),
    );
    failureCount = TextEditingController(
      text: current == null || current.failureCount == 0
          ? ''
          : current.failureCount.toString(),
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
      environment,
      responsible,
      scope,
      evidence,
      progressPercent,
      passRatePercent,
      coveragePercent,
      riskPercent,
      failureCount,
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
      AtlasQualityReleaseRecord(
        id:
            current?.id ??
            'quality_release_'
                '${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        priority: priority,
        environment: environment.text.trim(),
        responsible: responsible.text.trim(),
        scope: scope.text.trim(),
        evidence: evidence.text.trim(),
        progressPercent: integer(progressPercent).clamp(0, 100),
        passRatePercent: decimal(passRatePercent).clamp(0, 100),
        coveragePercent: decimal(coveragePercent).clamp(0, 100),
        riskPercent: decimal(riskPercent).clamp(0, 100),
        failureCount: integer(failureCount) < 0 ? 0 : integer(failureCount),
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
                            'Aprovado',
                            'Concluído',
                            'Atenção',
                            'Reprovado',
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
                  (environment, 'Ambiente'),
                  (responsible, 'Responsável'),
                  (scope, 'Escopo'),
                  (evidence, 'Evidência ou referência'),
                  (progressPercent, 'Progresso (0 a 100%)'),
                  (passRatePercent, 'Taxa de aprovação (0 a 100%)'),
                  (coveragePercent, 'Cobertura de testes (0 a 100%)'),
                  (riskPercent, 'Risco (0 a 100%)'),
                  (failureCount, 'Quantidade de falhas'),
                  (alertCount, 'Quantidade de alertas'),
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

IconData _moduleIcon(AtlasQualityReleaseModule module) {
  return switch (module) {
    AtlasQualityReleaseModule.architecturalReview =>
      Icons.architecture_outlined,
    AtlasQualityReleaseModule.comprehensiveUnitTests => Icons.science_outlined,
    AtlasQualityReleaseModule.integrationTests => Icons.hub_outlined,
    AtlasQualityReleaseModule.interfaceTests => Icons.devices_outlined,
    AtlasQualityReleaseModule.securityTests => Icons.security_outlined,
    AtlasQualityReleaseModule.performanceTests => Icons.speed_outlined,
    AtlasQualityReleaseModule.monitoringAndFailureHandling =>
      Icons.monitor_heart_outlined,
    AtlasQualityReleaseModule.stagingPublication => Icons.cloud_upload_outlined,
    AtlasQualityReleaseModule.farmPilotProgram => Icons.agriculture_outlined,
    AtlasQualityReleaseModule.atlasVersionOne => Icons.rocket_launch_outlined,
  };
}
