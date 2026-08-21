import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_auth_sync_enterprise/data/services/atlas_auth_sync_storage_service.dart';
import 'package:projeto_atlas/features/atlas_auth_sync_enterprise/domain/models/atlas_auth_sync_record.dart';
import 'package:projeto_atlas/features/atlas_auth_sync_enterprise/domain/services/atlas_auth_sync_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasAuthSyncScreen extends StatefulWidget {
  const AtlasAuthSyncScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasAuthSyncModule initialModule;

  @override
  State<AtlasAuthSyncScreen> createState() => _AtlasAuthSyncScreenState();
}

class _AtlasAuthSyncScreenState extends State<AtlasAuthSyncScreen> {
  final storage = AtlasAuthSyncStorageService();
  final analyticsService = const AtlasAuthSyncAnalyticsService();

  late AtlasAuthSyncModule selectedModule;
  List<AtlasAuthSyncRecord> records = [];
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
      (a, b) => parseAtlasAuthSyncDate(
        b.date,
      ).compareTo(parseAtlasAuthSyncDate(a.date)),
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

  List<AtlasAuthSyncRecord> get visibleRecords => records
      .where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' || record.feature == selectedFeature);
      })
      .toList(growable: false);

  Future<void> openForm([AtlasAuthSyncRecord? current]) async {
    final result = await showDialog<AtlasAuthSyncRecord>(
      context: context,
      builder: (_) => _AuthSyncForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasAuthSyncRecord record) async {
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
                            'Autenticação, Segurança e Sincronização',
                          ),
                          subtitle: Text(
                            'A entrega organiza a camada funcional de segurança e sincronização. '
                            'Tokens, MFA, criptografia, banco offline e conflitos reais exigem backend, banco local estruturado e infraestrutura configurada.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasAuthSyncModule.values
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
                            subtitle: 'Ativos ou sincronizados',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Pendências',
                            value: '${analytics.totalPending}',
                            subtitle: 'Operações aguardando',
                            icon: Icons.pending_actions_outlined,
                            warning: analytics.totalPending > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Retentativas',
                            value: '${analytics.totalRetries}',
                            subtitle: 'Reprocessamentos',
                            icon: Icons.sync_problem_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Falhas e riscos',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Sucesso médio',
                            value:
                                '${analytics.averageSuccessRate.toStringAsFixed(1)}%',
                            subtitle: 'Taxa informada',
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
                        'Registros de autenticação e sincronização',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre o primeiro controle, fila, sessão ou conflito.',
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

class _AuthSyncForm extends StatefulWidget {
  const _AuthSyncForm({required this.module, this.current});

  final AtlasAuthSyncModule module;
  final AtlasAuthSyncRecord? current;

  @override
  State<_AuthSyncForm> createState() => _AuthSyncFormState();
}

class _AuthSyncFormState extends State<_AuthSyncForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController environment;
  late final TextEditingController userName;
  late final TextEditingController companyName;
  late final TextEditingController deviceName;
  late final TextEditingController resourceName;
  late final TextEditingController versionLabel;
  late final TextEditingController progressPercent;
  late final TextEditingController successRatePercent;
  late final TextEditingController riskPercent;
  late final TextEditingController pendingCount;
  late final TextEditingController retryCount;
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
      text: current?.date ?? formatAtlasAuthSyncDate(DateTime.now()),
    );
    environment = TextEditingController(text: current?.environment ?? '');
    userName = TextEditingController(text: current?.userName ?? '');
    companyName = TextEditingController(text: current?.companyName ?? '');
    deviceName = TextEditingController(text: current?.deviceName ?? '');
    resourceName = TextEditingController(text: current?.resourceName ?? '');
    versionLabel = TextEditingController(text: current?.versionLabel ?? '');
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
    );
    successRatePercent = TextEditingController(
      text: current == null || current.successRatePercent == 0
          ? ''
          : current.successRatePercent.toString(),
    );
    riskPercent = TextEditingController(
      text: current == null || current.riskPercent == 0
          ? ''
          : current.riskPercent.toString(),
    );
    pendingCount = TextEditingController(
      text: current == null || current.pendingCount == 0
          ? ''
          : current.pendingCount.toString(),
    );
    retryCount = TextEditingController(
      text: current == null || current.retryCount == 0
          ? ''
          : current.retryCount.toString(),
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
      userName,
      companyName,
      deviceName,
      resourceName,
      versionLabel,
      progressPercent,
      successRatePercent,
      riskPercent,
      pendingCount,
      retryCount,
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
      AtlasAuthSyncRecord(
        id: current?.id ?? 'auth_sync_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        priority: priority,
        environment: environment.text.trim(),
        userName: userName.text.trim(),
        companyName: companyName.text.trim(),
        deviceName: deviceName.text.trim(),
        resourceName: resourceName.text.trim(),
        versionLabel: versionLabel.text.trim(),
        progressPercent: integer(progressPercent).clamp(0, 100),
        successRatePercent: decimal(successRatePercent).clamp(0, 100),
        riskPercent: decimal(riskPercent).clamp(0, 100),
        pendingCount: integer(pendingCount) < 0 ? 0 : integer(pendingCount),
        retryCount: integer(retryCount) < 0 ? 0 : integer(retryCount),
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
                            'Sincronizado',
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
                  (environment, 'Ambiente'),
                  (userName, 'Usuário'),
                  (companyName, 'Empresa'),
                  (deviceName, 'Dispositivo'),
                  (resourceName, 'Recurso ou serviço'),
                  (versionLabel, 'Versão ou identificador'),
                  (progressPercent, 'Progresso (0 a 100%)'),
                  (successRatePercent, 'Taxa de sucesso (0 a 100%)'),
                  (riskPercent, 'Risco (0 a 100%)'),
                  (pendingCount, 'Operações pendentes'),
                  (retryCount, 'Retentativas'),
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

IconData _moduleIcon(AtlasAuthSyncModule module) {
  return switch (module) {
    AtlasAuthSyncModule.secureUserRegistration =>
      Icons.person_add_alt_1_outlined,
    AtlasAuthSyncModule.secureTokenLogin => Icons.key_outlined,
    AtlasAuthSyncModule.passwordRecovery => Icons.lock_reset_outlined,
    AtlasAuthSyncModule.multiFactorAuthentication =>
      Icons.phonelink_lock_outlined,
    AtlasAuthSyncModule.roleBasedAccessControl =>
      Icons.admin_panel_settings_outlined,
    AtlasAuthSyncModule.sensitiveDataProtection =>
      Icons.enhanced_encryption_outlined,
    AtlasAuthSyncModule.immutableAuditLogs => Icons.manage_search_outlined,
    AtlasAuthSyncModule.structuredOfflineDatabase => Icons.storage_outlined,
    AtlasAuthSyncModule.synchronizationEngine => Icons.sync_outlined,
    AtlasAuthSyncModule.realConflictResolution => Icons.merge_type_outlined,
  };
}
