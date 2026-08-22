import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_livestock_integration/data/services/atlas_livestock_integration_storage_service.dart';
import 'package:projeto_atlas/features/atlas_livestock_integration/domain/models/atlas_livestock_integration_record.dart';
import 'package:projeto_atlas/features/atlas_livestock_integration/domain/services/atlas_livestock_integration_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasLivestockIntegrationScreen extends StatefulWidget {
  const AtlasLivestockIntegrationScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasLivestockIntegrationModule initialModule;

  @override
  State<AtlasLivestockIntegrationScreen> createState() =>
      _AtlasLivestockIntegrationScreenState();
}

class _AtlasLivestockIntegrationScreenState
    extends State<AtlasLivestockIntegrationScreen> {
  final storage = AtlasLivestockIntegrationStorageService();
  final analyticsService = const AtlasLivestockIntegrationAnalyticsService();

  late AtlasLivestockIntegrationModule selectedModule;
  List<AtlasLivestockIntegrationRecord> records = [];
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
      (a, b) => parseAtlasLivestockIntegrationDate(
        b.date,
      ).compareTo(parseAtlasLivestockIntegrationDate(a.date)),
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

  List<AtlasLivestockIntegrationRecord> get visibleRecords => records
      .where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' || record.feature == selectedFeature);
      })
      .toList(growable: false);

  Future<void> openForm([AtlasLivestockIntegrationRecord? current]) async {
    final result = await showDialog<AtlasLivestockIntegrationRecord>(
      context: context,
      builder: (_) =>
          _LivestockIntegrationForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasLivestockIntegrationRecord record) async {
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
                          title: Text('Integração dos Módulos Pecuários'),
                          subtitle: Text(
                            'Esta entrega organiza a migração e integração dos módulos. '
                            'Integração efetiva com API e banco real exige backend, endpoints e sincronização configurados.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasLivestockIntegrationModule.values
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
                            title: 'Score de integração',
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
                            subtitle: 'Ativos ou integrados',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Pendências',
                            value: '${analytics.pendingCount}',
                            subtitle: 'Operações aguardando',
                            icon: Icons.pending_actions_outlined,
                            warning: analytics.pendingCount > 0,
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
                        'Registros de integração pecuária',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre a primeira migração, integração, alerta ou tarefa.',
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
                                '${record.sourceModule.isEmpty ? 'Sem origem vinculada' : record.sourceModule}',
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

class _LivestockIntegrationForm extends StatefulWidget {
  const _LivestockIntegrationForm({required this.module, this.current});

  final AtlasLivestockIntegrationModule module;
  final AtlasLivestockIntegrationRecord? current;

  @override
  State<_LivestockIntegrationForm> createState() =>
      _LivestockIntegrationFormState();
}

class _LivestockIntegrationFormState extends State<_LivestockIntegrationForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController farmName;
  late final TextEditingController animalOrLot;
  late final TextEditingController sourceModule;
  late final TextEditingController destinationModule;
  late final TextEditingController eventType;
  late final TextEditingController responsible;
  late final TextEditingController progressPercent;
  late final TextEditingController successRatePercent;
  late final TextEditingController riskPercent;
  late final TextEditingController pendingCount;
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
      text:
          current?.date ?? formatAtlasLivestockIntegrationDate(DateTime.now()),
    );
    farmName = TextEditingController(text: current?.farmName ?? '');
    animalOrLot = TextEditingController(text: current?.animalOrLot ?? '');
    sourceModule = TextEditingController(text: current?.sourceModule ?? '');
    destinationModule = TextEditingController(
      text: current?.destinationModule ?? '',
    );
    eventType = TextEditingController(text: current?.eventType ?? '');
    responsible = TextEditingController(text: current?.responsible ?? '');
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
      animalOrLot,
      sourceModule,
      destinationModule,
      eventType,
      responsible,
      progressPercent,
      successRatePercent,
      riskPercent,
      pendingCount,
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
      AtlasLivestockIntegrationRecord(
        id:
            current?.id ??
            'livestock_integration_'
                '${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        priority: priority,
        farmName: farmName.text.trim(),
        animalOrLot: animalOrLot.text.trim(),
        sourceModule: sourceModule.text.trim(),
        destinationModule: destinationModule.text.trim(),
        eventType: eventType.text.trim(),
        responsible: responsible.text.trim(),
        progressPercent: integer(progressPercent).clamp(0, 100),
        successRatePercent: decimal(successRatePercent).clamp(0, 100),
        riskPercent: decimal(riskPercent).clamp(0, 100),
        pendingCount: integer(pendingCount) < 0 ? 0 : integer(pendingCount),
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
                            'Integrado',
                            'Validado',
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
                  (animalOrLot, 'Animal ou lote'),
                  (sourceModule, 'Módulo de origem'),
                  (destinationModule, 'Módulo de destino'),
                  (eventType, 'Tipo de evento'),
                  (responsible, 'Responsável'),
                  (progressPercent, 'Progresso (0 a 100%)'),
                  (successRatePercent, 'Taxa de sucesso (0 a 100%)'),
                  (riskPercent, 'Risco (0 a 100%)'),
                  (pendingCount, 'Operações pendentes'),
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

IconData _moduleIcon(AtlasLivestockIntegrationModule module) {
  return switch (module) {
    AtlasLivestockIntegrationModule.herdMigration => AtlasLivestockIcons.cow,
    AtlasLivestockIntegrationModule.reproductionMigration =>
      Icons.favorite_outline,
    AtlasLivestockIntegrationModule.healthMigration => Icons.vaccines_outlined,
    AtlasLivestockIntegrationModule.nutritionMigration =>
      Icons.restaurant_outlined,
    AtlasLivestockIntegrationModule.financeMigration =>
      Icons.account_balance_wallet_outlined,
    AtlasLivestockIntegrationModule.stockMigration =>
      Icons.inventory_2_outlined,
    AtlasLivestockIntegrationModule.eventIntegration => Icons.hub_outlined,
    AtlasLivestockIntegrationModule.unifiedTimeline => Icons.timeline_outlined,
    AtlasLivestockIntegrationModule.integratedAlerts =>
      Icons.notifications_active_outlined,
    AtlasLivestockIntegrationModule.integratedTasks => Icons.task_alt_outlined,
  };
}
