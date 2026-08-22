import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_governance_people_enterprise/data/services/atlas_governance_people_storage_service.dart';
import 'package:projeto_atlas/features/atlas_governance_people_enterprise/domain/models/atlas_governance_people_record.dart';
import 'package:projeto_atlas/features/atlas_governance_people_enterprise/domain/services/atlas_governance_people_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasGovernancePeopleScreen extends StatefulWidget {
  const AtlasGovernancePeopleScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasGovernancePeopleModule initialModule;

  @override
  State<AtlasGovernancePeopleScreen> createState() =>
      _AtlasGovernancePeopleScreenState();
}

class _AtlasGovernancePeopleScreenState
    extends State<AtlasGovernancePeopleScreen> {
  final storage = AtlasGovernancePeopleStorageService();
  final analyticsService = const AtlasGovernancePeopleAnalyticsService();

  late AtlasGovernancePeopleModule selectedModule;
  List<AtlasGovernancePeopleRecord> records = [];
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
      (a, b) => parseAtlasGovernancePeopleDate(
        b.date,
      ).compareTo(parseAtlasGovernancePeopleDate(a.date)),
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

  List<AtlasGovernancePeopleRecord> get visibleRecords => records
      .where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' || record.feature == selectedFeature);
      })
      .toList(growable: false);

  Future<void> openForm([AtlasGovernancePeopleRecord? current]) async {
    final result = await showDialog<AtlasGovernancePeopleRecord>(
      context: context,
      builder: (_) =>
          _GovernancePeopleForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasGovernancePeopleRecord record) async {
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
                          title: Text(
                            'Pessoas, Segurança e Governança',
                          ),
                          subtitle: Text(
                            'A entrega organiza pessoas, documentos, auditorias, riscos e acessos. '
                            'Registros legais e trabalhistas reais exigem validação profissional.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasGovernancePeopleModule.values
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
                            title: 'Cobertura',
                            value:
                                '${analytics.coveragePercent.toStringAsFixed(0)}%',
                            subtitle: 'Funcionalidades registradas',
                            icon: Icons.grid_view_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Score de governança',
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
                            title: 'Vencidos',
                            value: '${analytics.overdueCount}',
                            subtitle: 'Prazos ultrapassados',
                            icon: Icons.event_busy_outlined,
                            warning: analytics.overdueCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Riscos e não conformidades',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Probabilidade média',
                            value:
                                '${analytics.averageProbability.toStringAsFixed(1)}%',
                            subtitle: 'Probabilidade informada',
                            icon: Icons.percent_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Impacto médio',
                            value:
                                '${analytics.averageImpact.toStringAsFixed(1)}%',
                            subtitle: 'Impacto informado',
                            icon: Icons.trending_up_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Risco médio',
                            value:
                                '${analytics.averageRiskScore.toStringAsFixed(1)}%',
                            subtitle: 'Probabilidade × impacto',
                            icon: Icons.shield_outlined,
                            warning: analytics.averageRiskScore >= 60,
                          ),
                          EnterpriseMetricCard(
                            title: 'Conformidade média',
                            value:
                                '${analytics.averageCompliance.toStringAsFixed(1)}%',
                            subtitle: 'Conformidade informada',
                            icon: Icons.rule_outlined,
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
                        'Registros de pessoas e governança',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre a primeira pessoa, auditoria, permissão ou evidência.',
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
                                '${record.date} • ${AtlasUiText.status(record.status)} • '
                                '${record.priority} • '
                                '${record.progressPercent}%\n'
                                '${record.personName.isEmpty ? 'Sem pessoa vinculada' : record.personName}',
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

class _GovernancePeopleForm extends StatefulWidget {
  const _GovernancePeopleForm({required this.module, this.current});

  final AtlasGovernancePeopleModule module;
  final AtlasGovernancePeopleRecord? current;

  @override
  State<_GovernancePeopleForm> createState() => _GovernancePeopleFormState();
}

class _GovernancePeopleFormState extends State<_GovernancePeopleForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController dueDate;
  late final TextEditingController personName;
  late final TextEditingController roleName;
  late final TextEditingController departmentName;
  late final TextEditingController documentName;
  late final TextEditingController requirementName;
  late final TextEditingController riskName;
  late final TextEditingController responsible;
  late final TextEditingController probabilityPercent;
  late final TextEditingController impactPercent;
  late final TextEditingController progressPercent;
  late final TextEditingController compliancePercent;
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
      text: current?.date ?? formatAtlasGovernancePeopleDate(DateTime.now()),
    );
    dueDate = TextEditingController(text: current?.dueDate ?? '');
    personName = TextEditingController(text: current?.personName ?? '');
    roleName = TextEditingController(text: current?.roleName ?? '');
    departmentName = TextEditingController(text: current?.departmentName ?? '');
    documentName = TextEditingController(text: current?.documentName ?? '');
    requirementName = TextEditingController(
      text: current?.requirementName ?? '',
    );
    riskName = TextEditingController(text: current?.riskName ?? '');
    responsible = TextEditingController(text: current?.responsible ?? '');
    probabilityPercent = TextEditingController(
      text: current == null || current.probabilityPercent == 0
          ? ''
          : current.probabilityPercent.toString(),
    );
    impactPercent = TextEditingController(
      text: current == null || current.impactPercent == 0
          ? ''
          : current.impactPercent.toString(),
    );
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
    );
    compliancePercent = TextEditingController(
      text: current == null || current.compliancePercent == 0
          ? ''
          : current.compliancePercent.toString(),
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
      personName,
      roleName,
      departmentName,
      documentName,
      requirementName,
      riskName,
      responsible,
      probabilityPercent,
      impactPercent,
      progressPercent,
      compliancePercent,
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

  Future<void> chooseDate(TextEditingController controller) async {
    final parsed = parseAtlasGovernancePeopleDate(controller.text);
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      controller.text = formatAtlasGovernancePeopleDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final current = widget.current;
    final now = DateTime.now().toIso8601String();

    Navigator.pop(
      context,
      AtlasGovernancePeopleRecord(
        id:
            current?.id ??
            'governance_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        dueDate: dueDate.text.trim(),
        status: status,
        priority: priority,
        personName: personName.text.trim(),
        roleName: roleName.text.trim(),
        departmentName: departmentName.text.trim(),
        documentName: documentName.text.trim(),
        requirementName: requirementName.text.trim(),
        riskName: riskName.text.trim(),
        responsible: responsible.text.trim(),
        probabilityPercent: decimal(probabilityPercent).clamp(0, 100),
        impactPercent: decimal(impactPercent).clamp(0, 100),
        progressPercent: integer(progressPercent).clamp(0, 100),
        compliancePercent: decimal(compliancePercent).clamp(0, 100),
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
                TextFormField(
                  controller: date,
                  readOnly: true,
                  onTap: () => chooseDate(date),
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
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
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Situação'),
                  items:
                      const [
                            'Planejado',
                            'Ativo',
                            'Conforme',
                            'Validado',
                            'Concluído',
                            'Atenção',
                            'Não conforme',
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
                  (personName, 'Pessoa ou colaborador'),
                  (roleName, 'Cargo ou papel'),
                  (departmentName, 'Departamento ou setor'),
                  (documentName, 'Documento ou certificado'),
                  (requirementName, 'Requisito ou evidência'),
                  (riskName, 'Risco ou achado'),
                  (responsible, 'Responsável'),
                ].map(
                  (item) => TextFormField(
                    controller: item.$1,
                    decoration: InputDecoration(labelText: item.$2),
                  ),
                ),
                ...[
                  (probabilityPercent, 'Probabilidade (0 a 100%)'),
                  (impactPercent, 'Impacto (0 a 100%)'),
                  (compliancePercent, 'Conformidade (0 a 100%)'),
                ].map(
                  (item) => TextFormField(
                    controller: item.$1,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: item.$2),
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

IconData _moduleIcon(AtlasGovernancePeopleModule module) {
  return switch (module) {
    AtlasGovernancePeopleModule.peopleManagement => Icons.badge_outlined,
    AtlasGovernancePeopleModule.trainingAndQualification =>
      Icons.school_outlined,
    AtlasGovernancePeopleModule.occupationalHealthAndSafety =>
      Icons.health_and_safety_outlined,
    AtlasGovernancePeopleModule.personalProtectiveEquipment =>
      Icons.shield_outlined,
    AtlasGovernancePeopleModule.documentManagement =>
      Icons.folder_copy_outlined,
    AtlasGovernancePeopleModule.complianceControl => Icons.rule_outlined,
    AtlasGovernancePeopleModule.internalAudits => Icons.fact_check_outlined,
    AtlasGovernancePeopleModule.corporateRiskManagement =>
      Icons.warning_amber_outlined,
    AtlasGovernancePeopleModule.permissionMatrix =>
      Icons.admin_panel_settings_outlined,
    AtlasGovernancePeopleModule.governanceCenter => Icons.dashboard_outlined,
  };
}
