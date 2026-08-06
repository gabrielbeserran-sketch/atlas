import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_operations_enterprise/data/services/atlas_operations_enterprise_storage_service.dart';
import 'package:projeto_atlas/features/atlas_operations_enterprise/domain/models/atlas_operations_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_operations_enterprise/domain/services/atlas_operations_enterprise_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasOperationsEnterpriseScreen extends StatefulWidget {
  const AtlasOperationsEnterpriseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasOperationsEnterpriseModule initialModule;

  @override
  State<AtlasOperationsEnterpriseScreen> createState() =>
      _AtlasOperationsEnterpriseScreenState();
}

class _AtlasOperationsEnterpriseScreenState
    extends State<AtlasOperationsEnterpriseScreen> {
  final storage = AtlasOperationsEnterpriseStorageService();
  final analyticsService =
      const AtlasOperationsEnterpriseAnalyticsService();

  late AtlasOperationsEnterpriseModule selectedModule;
  List<AtlasOperationsEnterpriseRecord> records = [];
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
      (a, b) => parseAtlasOperationsDate(b.date)
          .compareTo(parseAtlasOperationsDate(a.date)),
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

  List<AtlasOperationsEnterpriseRecord> get visibleRecords =>
      records.where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' ||
                record.feature == selectedFeature);
      }).toList(growable: false);

  Future<void> openForm([
    AtlasOperationsEnterpriseRecord? current,
  ]) async {
    final result =
        await showDialog<AtlasOperationsEnterpriseRecord>(
      context: context,
      builder: (_) => _OperationsForm(
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
    AtlasOperationsEnterpriseRecord record,
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
                            'Fase 31 — Gestão Operacional Inteligente',
                          ),
                          subtitle: Text(
                            'A entrega organiza planos, atividades, equipes, máquinas e manutenção. '
                            'Registros trabalhistas e técnicos reais exigem validação dos responsáveis.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasOperationsEnterpriseModule.values
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
                            title: 'Score operacional',
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
                            subtitle: 'Ativos ou concluídos',
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
                            subtitle: 'Riscos e bloqueios',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Horas planejadas',
                            value:
                                analytics.totalPlannedHours.toStringAsFixed(1),
                            subtitle: 'Total consolidado',
                            icon: Icons.schedule_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Horas realizadas',
                            value:
                                analytics.totalActualHours.toStringAsFixed(1),
                            subtitle:
                                'Desvio ${analytics.hourDeviation.toStringAsFixed(1)} h',
                            icon: Icons.timelapse_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Custo planejado',
                            value:
                                'R\$ ${analytics.totalPlannedCost.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Total consolidado',
                            icon: Icons.request_quote_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Custo realizado',
                            value:
                                'R\$ ${analytics.totalActualCost.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle:
                                'Desvio R\$ ${analytics.costDeviation.toStringAsFixed(2).replaceAll('.', ',')}',
                            icon: Icons.payments_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Progresso médio',
                            value:
                                '${analytics.averageProgress.toStringAsFixed(0)}%',
                            subtitle: 'Execução consolidada',
                            icon: Icons.timeline_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Qualidade média',
                            value:
                                '${analytics.averageQuality.toStringAsFixed(1)}%',
                            subtitle: 'Qualidade informada',
                            icon: Icons.verified_outlined,
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
                        'Registros operacionais',
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
                              'Cadastre o primeiro plano, tarefa, equipe ou equipamento.',
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
                                '${record.responsible.isEmpty ? 'Sem responsável' : record.responsible}',
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

class _OperationsForm extends StatefulWidget {
  const _OperationsForm({
    required this.module,
    this.current,
  });

  final AtlasOperationsEnterpriseModule module;
  final AtlasOperationsEnterpriseRecord? current;

  @override
  State<_OperationsForm> createState() => _OperationsFormState();
}

class _OperationsFormState extends State<_OperationsForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController dueDate;
  late final TextEditingController farmName;
  late final TextEditingController areaName;
  late final TextEditingController responsible;
  late final TextEditingController teamName;
  late final TextEditingController assetName;
  late final TextEditingController plannedHours;
  late final TextEditingController actualHours;
  late final TextEditingController plannedCost;
  late final TextEditingController actualCost;
  late final TextEditingController progressPercent;
  late final TextEditingController qualityPercent;
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
          formatAtlasOperationsDate(DateTime.now()),
    );
    dueDate = TextEditingController(text: current?.dueDate ?? '');
    farmName = TextEditingController(text: current?.farmName ?? '');
    areaName = TextEditingController(text: current?.areaName ?? '');
    responsible =
        TextEditingController(text: current?.responsible ?? '');
    teamName = TextEditingController(text: current?.teamName ?? '');
    assetName = TextEditingController(text: current?.assetName ?? '');
    plannedHours = TextEditingController(
      text: current == null || current.plannedHours == 0
          ? ''
          : current.plannedHours.toString(),
    );
    actualHours = TextEditingController(
      text: current == null || current.actualHours == 0
          ? ''
          : current.actualHours.toString(),
    );
    plannedCost = TextEditingController(
      text: current == null || current.plannedCost == 0
          ? ''
          : current.plannedCost.toString(),
    );
    actualCost = TextEditingController(
      text: current == null || current.actualCost == 0
          ? ''
          : current.actualCost.toString(),
    );
    progressPercent = TextEditingController(
      text: current == null
          ? ''
          : current.progressPercent.toString(),
    );
    qualityPercent = TextEditingController(
      text: current == null || current.qualityPercent == 0
          ? ''
          : current.qualityPercent.toString(),
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
      areaName,
      responsible,
      teamName,
      assetName,
      plannedHours,
      actualHours,
      plannedCost,
      actualCost,
      progressPercent,
      qualityPercent,
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
    final parsed = parseAtlasOperationsDate(controller.text);
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
      controller.text = formatAtlasOperationsDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final current = widget.current;
    final now = DateTime.now().toIso8601String();

    Navigator.pop(
      context,
      AtlasOperationsEnterpriseRecord(
        id: current?.id ??
            'operations_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        dueDate: dueDate.text.trim(),
        status: status,
        priority: priority,
        farmName: farmName.text.trim(),
        areaName: areaName.text.trim(),
        responsible: responsible.text.trim(),
        teamName: teamName.text.trim(),
        assetName: assetName.text.trim(),
        plannedHours: decimal(plannedHours),
        actualHours: decimal(actualHours),
        plannedCost: decimal(plannedCost),
        actualCost: decimal(actualCost),
        progressPercent: integer(progressPercent).clamp(0, 100),
        qualityPercent: decimal(qualityPercent).clamp(0, 100),
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
                    'Em execução',
                    'Concluído',
                    'Validado',
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
                TextFormField(
                  controller: farmName,
                  decoration: const InputDecoration(
                    labelText: 'Fazenda',
                  ),
                ),
                TextFormField(
                  controller: areaName,
                  decoration: const InputDecoration(
                    labelText: 'Área, setor ou local',
                  ),
                ),
                TextFormField(
                  controller: responsible,
                  decoration: const InputDecoration(
                    labelText: 'Responsável',
                  ),
                ),
                TextFormField(
                  controller: teamName,
                  decoration: const InputDecoration(
                    labelText: 'Equipe',
                  ),
                ),
                TextFormField(
                  controller: assetName,
                  decoration: const InputDecoration(
                    labelText: 'Máquina, veículo ou equipamento',
                  ),
                ),
                ...[
                  (plannedHours, 'Horas planejadas'),
                  (actualHours, 'Horas realizadas'),
                  (plannedCost, 'Custo planejado (R\$)'),
                  (actualCost, 'Custo realizado (R\$)'),
                  (qualityPercent, 'Qualidade (0 a 100%)'),
                ].map(
                  (item) => TextFormField(
                    controller: item.$1,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
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
  AtlasOperationsEnterpriseModule module,
) {
  return switch (module) {
    AtlasOperationsEnterpriseModule.farmOperationalPlanning =>
      Icons.event_note_outlined,
    AtlasOperationsEnterpriseModule.intelligentActivityAgenda =>
      Icons.calendar_month_outlined,
    AtlasOperationsEnterpriseModule.workOrders =>
      Icons.assignment_outlined,
    AtlasOperationsEnterpriseModule.teamManagement =>
      Icons.groups_outlined,
    AtlasOperationsEnterpriseModule.workdayControl =>
      Icons.punch_clock_outlined,
    AtlasOperationsEnterpriseModule.machineryManagement =>
      Icons.agriculture_outlined,
    AtlasOperationsEnterpriseModule.preventiveMaintenance =>
      Icons.build_circle_outlined,
    AtlasOperationsEnterpriseModule.correctiveMaintenance =>
      Icons.handyman_outlined,
    AtlasOperationsEnterpriseModule.operationalIndicators =>
      Icons.insights_outlined,
    AtlasOperationsEnterpriseModule.operationsCenter =>
      Icons.dashboard_outlined,
  };
}
