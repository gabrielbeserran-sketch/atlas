import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_cloud_security_enterprise/data/services/atlas_cloud_security_storage_service.dart';
import 'package:projeto_atlas/features/atlas_cloud_security_enterprise/domain/models/atlas_cloud_security_record.dart';
import 'package:projeto_atlas/features/atlas_cloud_security_enterprise/domain/services/atlas_cloud_security_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasCloudSecurityScreen extends StatefulWidget {
  const AtlasCloudSecurityScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasCloudSecurityModule initialModule;

  @override
  State<AtlasCloudSecurityScreen> createState() =>
      _AtlasCloudSecurityScreenState();
}

class _AtlasCloudSecurityScreenState extends State<AtlasCloudSecurityScreen> {
  final storage = AtlasCloudSecurityStorageService();
  final analyticsService = const AtlasCloudSecurityAnalyticsService();

  late AtlasCloudSecurityModule selectedModule;
  List<AtlasCloudSecurityRecord> records = [];
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
      (a, b) => parseAtlasCloudSecurityDate(
        b.date,
      ).compareTo(parseAtlasCloudSecurityDate(a.date)),
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

  List<AtlasCloudSecurityRecord> get visibleRecords => records
      .where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' || record.feature == selectedFeature);
      })
      .toList(growable: false);

  Future<void> openForm([AtlasCloudSecurityRecord? current]) async {
    final result = await showDialog<AtlasCloudSecurityRecord>(
      context: context,
      builder: (_) =>
          _CloudSecurityForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasCloudSecurityRecord record) async {
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
                            'Integração, Nuvem e Segurança',
                          ),
                          subtitle: Text(
                            'Esta entrega organiza a camada de gestão e monitoramento. '
                            'Autenticação, nuvem, criptografia, backup e sincronização reais exigem backend seguro e provedores configurados.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasCloudSecurityModule.values
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
                            title: 'Score de segurança',
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
                            subtitle: 'Ativos ou seguros',
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
                            subtitle: 'Riscos e incidentes',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Disponibilidade média',
                            value:
                                '${analytics.averageAvailability.toStringAsFixed(1)}%',
                            subtitle: 'Disponibilidade informada',
                            icon: Icons.cloud_done_outlined,
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
                            title: 'Retentativas',
                            value: '${analytics.totalRetries}',
                            subtitle: 'Falhas e reprocessamentos',
                            icon: Icons.sync_problem_outlined,
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
                        'Registros de nuvem e segurança',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre o primeiro controle, integração, backup ou incidente.',
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
                                '${record.resourceName.isEmpty ? 'Sem recurso vinculado' : record.resourceName}',
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

class _CloudSecurityForm extends StatefulWidget {
  const _CloudSecurityForm({required this.module, this.current});

  final AtlasCloudSecurityModule module;
  final AtlasCloudSecurityRecord? current;

  @override
  State<_CloudSecurityForm> createState() => _CloudSecurityFormState();
}

class _CloudSecurityFormState extends State<_CloudSecurityForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController dueDate;
  late final TextEditingController environment;
  late final TextEditingController resourceName;
  late final TextEditingController userName;
  late final TextEditingController companyName;
  late final TextEditingController providerName;
  late final TextEditingController versionLabel;
  late final TextEditingController progressPercent;
  late final TextEditingController availabilityPercent;
  late final TextEditingController riskPercent;
  late final TextEditingController alertCount;
  late final TextEditingController retryCount;
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
      text: current?.date ?? formatAtlasCloudSecurityDate(DateTime.now()),
    );
    dueDate = TextEditingController(text: current?.dueDate ?? '');
    environment = TextEditingController(text: current?.environment ?? '');
    resourceName = TextEditingController(text: current?.resourceName ?? '');
    userName = TextEditingController(text: current?.userName ?? '');
    companyName = TextEditingController(text: current?.companyName ?? '');
    providerName = TextEditingController(text: current?.providerName ?? '');
    versionLabel = TextEditingController(text: current?.versionLabel ?? '');
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
    );
    availabilityPercent = TextEditingController(
      text: current == null || current.availabilityPercent == 0
          ? ''
          : current.availabilityPercent.toString(),
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
    retryCount = TextEditingController(
      text: current == null || current.retryCount == 0
          ? ''
          : current.retryCount.toString(),
    );
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      title,
      date,
      dueDate,
      environment,
      resourceName,
      userName,
      companyName,
      providerName,
      versionLabel,
      progressPercent,
      availabilityPercent,
      riskPercent,
      alertCount,
      retryCount,
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
    final parsed = parseAtlasCloudSecurityDate(controller.text);
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      controller.text = formatAtlasCloudSecurityDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final current = widget.current;
    final now = DateTime.now().toIso8601String();

    Navigator.pop(
      context,
      AtlasCloudSecurityRecord(
        id:
            current?.id ??
            'cloud_security_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        dueDate: dueDate.text.trim(),
        status: status,
        priority: priority,
        environment: environment.text.trim(),
        resourceName: resourceName.text.trim(),
        userName: userName.text.trim(),
        companyName: companyName.text.trim(),
        providerName: providerName.text.trim(),
        versionLabel: versionLabel.text.trim(),
        progressPercent: integer(progressPercent).clamp(0, 100),
        availabilityPercent: decimal(availabilityPercent).clamp(0, 100),
        riskPercent: decimal(riskPercent).clamp(0, 100),
        alertCount: integer(alertCount) < 0 ? 0 : integer(alertCount),
        retryCount: integer(retryCount) < 0 ? 0 : integer(retryCount),
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
                            'Seguro',
                            'Sincronizado',
                            'Concluído',
                            'Atenção',
                            'Incidente',
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
                  (environment, 'Ambiente'),
                  (resourceName, 'Recurso, serviço ou integração'),
                  (userName, 'Usuário'),
                  (companyName, 'Empresa'),
                  (providerName, 'Provedor'),
                  (versionLabel, 'Versão ou identificador'),
                ].map(
                  (item) => TextFormField(
                    controller: item.$1,
                    decoration: InputDecoration(labelText: item.$2),
                  ),
                ),
                ...[
                  (availabilityPercent, 'Disponibilidade (0 a 100%)'),
                  (riskPercent, 'Risco (0 a 100%)'),
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
                  controller: retryCount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de retentativas',
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

IconData _moduleIcon(AtlasCloudSecurityModule module) {
  return switch (module) {
    AtlasCloudSecurityModule.professionalAuthentication => Icons.login_outlined,
    AtlasCloudSecurityModule.usersAndCompanies => Icons.business_outlined,
    AtlasCloudSecurityModule.cloudDatabase => Icons.cloud_outlined,
    AtlasCloudSecurityModule.offlineSynchronization => Icons.sync_outlined,
    AtlasCloudSecurityModule.conflictResolution => Icons.merge_type_outlined,
    AtlasCloudSecurityModule.automatedBackup => Icons.backup_outlined,
    AtlasCloudSecurityModule.dataEncryption => Icons.lock_outlined,
    AtlasCloudSecurityModule.userAuditLogs => Icons.manage_search_outlined,
    AtlasCloudSecurityModule.integrationCenter => Icons.hub_outlined,
    AtlasCloudSecurityModule.securityCenter => Icons.security_outlined,
  };
}
