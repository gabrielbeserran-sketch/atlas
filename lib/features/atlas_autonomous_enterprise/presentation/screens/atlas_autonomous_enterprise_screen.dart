import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_autonomous_enterprise/data/services/atlas_autonomous_enterprise_storage_service.dart';
import 'package:projeto_atlas/features/atlas_autonomous_enterprise/domain/models/atlas_autonomous_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_autonomous_enterprise/domain/services/atlas_autonomous_enterprise_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasAutonomousEnterpriseScreen extends StatefulWidget {
  const AtlasAutonomousEnterpriseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasAutonomousEnterpriseModule initialModule;

  @override
  State<AtlasAutonomousEnterpriseScreen> createState() =>
      _AtlasAutonomousEnterpriseScreenState();
}

class _AtlasAutonomousEnterpriseScreenState
    extends State<AtlasAutonomousEnterpriseScreen> {
  final AtlasAutonomousEnterpriseStorageService storage =
      AtlasAutonomousEnterpriseStorageService();
  final AtlasAutonomousEnterpriseAnalyticsService
      analyticsService =
      const AtlasAutonomousEnterpriseAnalyticsService();

  late AtlasAutonomousEnterpriseModule selectedModule;
  List<AtlasAutonomousEnterpriseRecord> records = [];
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
      (first, second) => parseAtlasAutonomousDate(
        second.date,
      ).compareTo(parseAtlasAutonomousDate(first.date)),
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

  List<AtlasAutonomousEnterpriseRecord> get visibleRecords {
    return records.where((record) {
      final moduleMatches = record.module == selectedModule;
      final featureMatches = selectedFeature == 'Todos' ||
          record.feature == selectedFeature;
      return moduleMatches && featureMatches;
    }).toList(growable: false);
  }

  Future<void> openForm([
    AtlasAutonomousEnterpriseRecord? current,
  ]) async {
    final result =
        await showDialog<AtlasAutonomousEnterpriseRecord>(
      context: context,
      builder: (context) => _AutonomousEnterpriseForm(
        module: selectedModule,
        current: current,
      ),
    );

    if (result == null || !mounted) return;

    final index = records.indexWhere(
      (record) => record.id == result.id,
    );

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
    AtlasAutonomousEnterpriseRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro'),
        content: Text('Deseja excluir "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
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
                            'Camada final de autonomia e produção',
                          ),
                          subtitle: Text(
                            'Decisões automáticas de alto impacto exigem aprovação humana. '
                            'Publicações reais dependem de infraestrutura, segurança e testes completos.',
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
                            title: 'Score final',
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
                            subtitle: 'Aprovados ou concluídos',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Pendentes',
                            value: '${analytics.pendingCount}',
                            subtitle: 'Aguardando andamento',
                            icon: Icons.pending_actions_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Falhas, riscos ou bloqueios',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Confiança média',
                            value:
                                '${analytics.averageConfidence.toStringAsFixed(1)}%',
                            subtitle: 'Confiança informada',
                            icon: Icons.psychology_alt_outlined,
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
                            title: 'Impacto financeiro',
                            value:
                                'R\$ ${analytics.financialImpact.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Impacto consolidado',
                            icon:
                                Icons.account_balance_wallet_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Progresso médio',
                            value:
                                '${analytics.averageProgress.toStringAsFixed(0)}%',
                            subtitle: 'Evolução dos processos',
                            icon: Icons.trending_up_outlined,
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
                        'Registros finais',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(
                              _moduleIcon(selectedModule),
                            ),
                            title: const Text(
                              'Nenhum registro encontrado.',
                            ),
                            subtitle: const Text(
                              'Cadastre a primeira decisão ou validação.',
                            ),
                          ),
                        )
                      else
                        ...visibleRecords.map(
                          (record) => _RecordCard(
                            record: record,
                            onEdit: () => openForm(record),
                            onDelete: () =>
                                deleteRecord(record),
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
  const _ModuleSelector({
    required this.selected,
    required this.onSelected,
  });

  final AtlasAutonomousEnterpriseModule selected;
  final ValueChanged<AtlasAutonomousEnterpriseModule>
      onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AtlasAutonomousEnterpriseModule.values.map(
            (module) {
              final active = module == selected;

              return FilledButton.tonalIcon(
                onPressed: () => onSelected(module),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      active ? const Color(0xFF1B5E20) : null,
                  foregroundColor: active ? Colors.white : null,
                ),
                icon: Icon(_moduleIcon(module)),
                label: Text(module.packageLabel),
              );
            },
          ).toList(growable: false),
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

  final AtlasAutonomousEnterpriseModule module;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Todos', ...module.features].map((feature) {
        return ChoiceChip(
          label: Text(feature),
          selected: selected == feature,
          onSelected: (_) => onSelected(feature),
        );
      }).toList(growable: false),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final AtlasAutonomousEnterpriseRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      'Bloqueado' || 'Falhou' || 'Crítico' ||
      'Rollback' =>
        Colors.red.shade800,
      'Atenção' => Colors.orange.shade800,
      'Aprovado' || 'Em execução' || 'Publicado' ||
      'Concluído' || 'Monitorado' =>
        Colors.green.shade800,
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
          'Confiança ${record.confidencePercent.toStringAsFixed(0)}% • '
          'Risco ${record.riskPercent.toStringAsFixed(0)}%',
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

class _AutonomousEnterpriseForm extends StatefulWidget {
  const _AutonomousEnterpriseForm({
    required this.module,
    this.current,
  });

  final AtlasAutonomousEnterpriseModule module;
  final AtlasAutonomousEnterpriseRecord? current;

  @override
  State<_AutonomousEnterpriseForm> createState() =>
      _AutonomousEnterpriseFormState();
}

class _AutonomousEnterpriseFormState
    extends State<_AutonomousEnterpriseForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController owner;
  late final TextEditingController externalId;
  late final TextEditingController priority;
  late final TextEditingController confidencePercent;
  late final TextEditingController riskPercent;
  late final TextEditingController financialImpact;
  late final TextEditingController quantity;
  late final TextEditingController progressPercent;
  late final TextEditingController alertCount;
  late final TextEditingController dueDate;
  late final TextEditingController reference;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final current = widget.current;

    feature = current?.feature ?? widget.module.features.first;
    status = current?.status ?? 'Planejado';

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ??
          formatAtlasAutonomousDate(DateTime.now()),
    );
    owner = TextEditingController(text: current?.owner ?? '');
    externalId =
        TextEditingController(text: current?.externalId ?? '');
    priority = TextEditingController(
      text: current == null || current.priority == 0
          ? ''
          : current.priority.toString(),
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
    financialImpact = TextEditingController(
      text: current == null || current.financialImpact == 0
          ? ''
          : current.financialImpact.toString(),
    );
    quantity = TextEditingController(
      text: current == null || current.quantity == 0
          ? ''
          : current.quantity.toString(),
    );
    progressPercent = TextEditingController(
      text: current == null
          ? ''
          : current.progressPercent.toString(),
    );
    alertCount = TextEditingController(
      text: current == null || current.alertCount == 0
          ? ''
          : current.alertCount.toString(),
    );
    dueDate = TextEditingController(text: current?.dueDate ?? '');
    reference =
        TextEditingController(text: current?.reference ?? '');
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    owner.dispose();
    externalId.dispose();
    priority.dispose();
    confidencePercent.dispose();
    riskPercent.dispose();
    financialImpact.dispose();
    quantity.dispose();
    progressPercent.dispose();
    alertCount.dispose();
    dueDate.dispose();
    reference.dispose();
    notes.dispose();
    super.dispose();
  }

  double decimal(TextEditingController controller) {
    return double.tryParse(
          controller.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;
  }

  int integer(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  int _maxZero(int value) => value < 0 ? 0 : value;

  double _percent(TextEditingController controller) {
    return decimal(controller).clamp(0.0, 100.0);
  }

  Future<void> chooseDate(
    TextEditingController controller,
  ) async {
    final parsed = parseAtlasAutonomousDate(controller.text);

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
      controller.text = formatAtlasAutonomousDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasAutonomousEnterpriseRecord(
        id: current?.id ??
            'autonomous_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        owner: owner.text.trim(),
        externalId: externalId.text.trim(),
        priority: integer(priority).clamp(0, 5),
        confidencePercent: _percent(confidencePercent),
        riskPercent: _percent(riskPercent),
        financialImpact: decimal(financialImpact),
        quantity: _maxZero(integer(quantity)),
        progressPercent:
            integer(progressPercent).clamp(0, 100),
        alertCount: _maxZero(integer(alertCount)),
        dueDate: dueDate.text.trim(),
        reference: reference.text.trim(),
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
        width: 740,
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
                  decoration:
                      const InputDecoration(labelText: 'Título'),
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
                    suffixIcon:
                        Icon(Icons.calendar_month_outlined),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration:
                      const InputDecoration(labelText: 'Situação'),
                  items: const [
                    'Planejado',
                    'Em análise',
                    'Aguardando aprovação',
                    'Aprovado',
                    'Em execução',
                    'Monitorado',
                    'Publicado',
                    'Concluído',
                    'Atenção',
                    'Crítico',
                    'Bloqueado',
                    'Falhou',
                    'Rollback',
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
                  controller: owner,
                  decoration: const InputDecoration(
                    labelText: 'Responsável ou aprovador',
                  ),
                ),
                TextFormField(
                  controller: externalId,
                  decoration: const InputDecoration(
                    labelText:
                        'Decisão, versão, implantação ou referência',
                  ),
                ),
                TextFormField(
                  controller: priority,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade (0 a 5)',
                  ),
                ),
                TextFormField(
                  controller: confidencePercent,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Confiança (0 a 100%)',
                  ),
                ),
                TextFormField(
                  controller: riskPercent,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Risco (0 a 100%)',
                  ),
                ),
                TextFormField(
                  controller: financialImpact,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Impacto financeiro (R\$)',
                  ),
                ),
                TextFormField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Quantidade'),
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
                    labelText: 'Prazo',
                    suffixIcon: Icon(Icons.event_busy_outlined),
                  ),
                ),
                TextFormField(
                  controller: reference,
                  decoration: const InputDecoration(
                    labelText:
                        'Evidência, teste, log ou documento',
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
  AtlasAutonomousEnterpriseModule module,
) {
  return switch (module) {
    AtlasAutonomousEnterpriseModule.aiOrchestrator =>
      Icons.auto_awesome_motion_outlined,
    AtlasAutonomousEnterpriseModule.enterpriseReleaseCenter =>
      Icons.rocket_launch_outlined,
  };
}
