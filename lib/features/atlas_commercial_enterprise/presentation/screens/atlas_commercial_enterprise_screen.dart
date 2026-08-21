import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_commercial_enterprise/data/services/atlas_commercial_enterprise_storage_service.dart';
import 'package:projeto_atlas/features/atlas_commercial_enterprise/domain/models/atlas_commercial_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_commercial_enterprise/domain/services/atlas_commercial_enterprise_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasCommercialEnterpriseScreen extends StatefulWidget {
  const AtlasCommercialEnterpriseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasCommercialEnterpriseModule initialModule;

  @override
  State<AtlasCommercialEnterpriseScreen> createState() =>
      _AtlasCommercialEnterpriseScreenState();
}

class _AtlasCommercialEnterpriseScreenState
    extends State<AtlasCommercialEnterpriseScreen> {
  final AtlasCommercialEnterpriseStorageService storage =
      AtlasCommercialEnterpriseStorageService();
  final AtlasCommercialEnterpriseAnalyticsService analyticsService =
      const AtlasCommercialEnterpriseAnalyticsService();

  late AtlasCommercialEnterpriseModule selectedModule;
  List<AtlasCommercialEnterpriseRecord> records = [];
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
      (first, second) => parseAtlasCommercialDate(
        second.date,
      ).compareTo(parseAtlasCommercialDate(first.date)),
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

  List<AtlasCommercialEnterpriseRecord> get visibleRecords {
    return records
        .where((record) {
          final moduleMatches = record.module == selectedModule;
          final featureMatches =
              selectedFeature == 'Todos' || record.feature == selectedFeature;
          return moduleMatches && featureMatches;
        })
        .toList(growable: false);
  }

  Future<void> openForm([AtlasCommercialEnterpriseRecord? current]) async {
    final result = await showDialog<AtlasCommercialEnterpriseRecord>(
      context: context,
      builder: (context) =>
          _CommercialEnterpriseForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasCommercialEnterpriseRecord record) async {
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
                          title: Text('Comercial Enterprise'),
                          subtitle: Text(
                            'A entrega organiza clientes, pipeline, contratos e receita. '
                            'Assinaturas, leilões e pagamentos reais exigem provedores e validação jurídica.',
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
                            title: 'Score comercial',
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
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Riscos e prazos',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor potencial',
                            value:
                                'R\$ ${analytics.totalPotentialValue.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Pipeline consolidado',
                            icon: Icons.savings_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor realizado',
                            value:
                                'R\$ ${analytics.totalActualValue.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Receita consolidada',
                            icon: Icons.payments_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Conversão',
                            value:
                                '${analytics.conversionPercent.toStringAsFixed(1)}%',
                            subtitle: 'Realizado sobre potencial',
                            icon: Icons.percent_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Probabilidade média',
                            value:
                                '${analytics.averageProbability.toStringAsFixed(1)}%',
                            subtitle: 'Chance informada',
                            icon: Icons.track_changes_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Satisfação média',
                            value:
                                '${analytics.averageSatisfaction.toStringAsFixed(1)}%',
                            subtitle: 'Satisfação informada',
                            icon: Icons.sentiment_satisfied_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Progresso médio',
                            value:
                                '${analytics.averageProgress.toStringAsFixed(0)}%',
                            subtitle: 'Evolução dos processos',
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
                        'Registros comerciais enterprise',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre o primeiro cliente, oportunidade ou contrato.',
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

  final AtlasCommercialEnterpriseModule selected;
  final ValueChanged<AtlasCommercialEnterpriseModule> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AtlasCommercialEnterpriseModule.values
              .map((module) {
                final active = module == selected;

                return FilledButton.tonalIcon(
                  onPressed: () => onSelected(module),
                  style: FilledButton.styleFrom(
                    backgroundColor: active ? const Color(0xFF1B5E20) : null,
                    foregroundColor: active ? Colors.white : null,
                  ),
                  icon: Icon(_moduleIcon(module)),
                  label: Text(module.title),
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

  final AtlasCommercialEnterpriseModule module;
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

  final AtlasCommercialEnterpriseRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      'Crítico' || 'Bloqueado' || 'Perdido' => Colors.red.shade800,
      'Atenção' => Colors.orange.shade800,
      'Ativo' ||
      'Aprovado' ||
      'Assinado' ||
      'Concluído' ||
      'Ganho' => Colors.green.shade800,
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
          '${record.customerName} • '
          'R\$ ${record.potentialValue.toStringAsFixed(2)}',
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

class _CommercialEnterpriseForm extends StatefulWidget {
  const _CommercialEnterpriseForm({required this.module, this.current});

  final AtlasCommercialEnterpriseModule module;
  final AtlasCommercialEnterpriseRecord? current;

  @override
  State<_CommercialEnterpriseForm> createState() =>
      _CommercialEnterpriseFormState();
}

class _CommercialEnterpriseFormState extends State<_CommercialEnterpriseForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController customerName;
  late final TextEditingController companyName;
  late final TextEditingController referenceId;
  late final TextEditingController stage;
  late final TextEditingController owner;
  late final TextEditingController potentialValue;
  late final TextEditingController actualValue;
  late final TextEditingController probabilityPercent;
  late final TextEditingController progressPercent;
  late final TextEditingController satisfactionPercent;
  late final TextEditingController alertCount;
  late final TextEditingController dueDate;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final current = widget.current;

    feature = current?.feature ?? widget.module.features.first;
    status = current?.status ?? 'Planejado';

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ?? formatAtlasCommercialDate(DateTime.now()),
    );
    customerName = TextEditingController(text: current?.customerName ?? '');
    companyName = TextEditingController(text: current?.companyName ?? '');
    referenceId = TextEditingController(text: current?.referenceId ?? '');
    stage = TextEditingController(text: current?.stage ?? '');
    owner = TextEditingController(text: current?.owner ?? '');
    potentialValue = TextEditingController(
      text: current == null || current.potentialValue == 0
          ? ''
          : current.potentialValue.toString(),
    );
    actualValue = TextEditingController(
      text: current == null || current.actualValue == 0
          ? ''
          : current.actualValue.toString(),
    );
    probabilityPercent = TextEditingController(
      text: current == null || current.probabilityPercent == 0
          ? ''
          : current.probabilityPercent.toString(),
    );
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
    );
    satisfactionPercent = TextEditingController(
      text: current == null || current.satisfactionPercent == 0
          ? ''
          : current.satisfactionPercent.toString(),
    );
    alertCount = TextEditingController(
      text: current == null || current.alertCount == 0
          ? ''
          : current.alertCount.toString(),
    );
    dueDate = TextEditingController(text: current?.dueDate ?? '');
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    customerName.dispose();
    companyName.dispose();
    referenceId.dispose();
    stage.dispose();
    owner.dispose();
    potentialValue.dispose();
    actualValue.dispose();
    probabilityPercent.dispose();
    progressPercent.dispose();
    satisfactionPercent.dispose();
    alertCount.dispose();
    dueDate.dispose();
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
    final parsed = parseAtlasCommercialDate(controller.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      controller.text = formatAtlasCommercialDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasCommercialEnterpriseRecord(
        id:
            current?.id ??
            'commercial_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        customerName: customerName.text.trim(),
        companyName: companyName.text.trim(),
        referenceId: referenceId.text.trim(),
        stage: stage.text.trim(),
        owner: owner.text.trim(),
        potentialValue: decimal(potentialValue),
        actualValue: decimal(actualValue),
        probabilityPercent: percent(probabilityPercent),
        progressPercent: integer(progressPercent).clamp(0, 100),
        satisfactionPercent: percent(satisfactionPercent),
        alertCount: nonNegative(alertCount),
        dueDate: dueDate.text.trim(),
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
                            'Aprovado',
                            'Assinado',
                            'Concluído',
                            'Ganho',
                            'Atenção',
                            'Perdido',
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
                  controller: customerName,
                  decoration: const InputDecoration(
                    labelText: 'Cliente ou interessado',
                  ),
                ),
                TextFormField(
                  controller: companyName,
                  decoration: const InputDecoration(labelText: 'Empresa'),
                ),
                TextFormField(
                  controller: referenceId,
                  decoration: const InputDecoration(
                    labelText: 'Oportunidade, contrato, lote ou referência',
                  ),
                ),
                TextFormField(
                  controller: stage,
                  decoration: const InputDecoration(labelText: 'Etapa ou fase'),
                ),
                TextFormField(
                  controller: owner,
                  decoration: const InputDecoration(
                    labelText: 'Responsável comercial',
                  ),
                ),
                TextFormField(
                  controller: potentialValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor potencial (R\$)',
                  ),
                ),
                TextFormField(
                  controller: actualValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor realizado (R\$)',
                  ),
                ),
                TextFormField(
                  controller: probabilityPercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Probabilidade (0 a 100%)',
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
                  controller: satisfactionPercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Satisfação (0 a 100%)',
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
                    labelText: 'Prazo ou vencimento',
                    suffixIcon: Icon(Icons.event_busy_outlined),
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

IconData _moduleIcon(AtlasCommercialEnterpriseModule module) {
  return switch (module) {
    AtlasCommercialEnterpriseModule.premiumCrm => Icons.contacts_outlined,
    AtlasCommercialEnterpriseModule.intelligentPipeline =>
      Icons.filter_alt_outlined,
    AtlasCommercialEnterpriseModule.digitalContracts =>
      Icons.description_outlined,
    AtlasCommercialEnterpriseModule.electronicSignature => Icons.draw_outlined,
    AtlasCommercialEnterpriseModule.customerManagement => Icons.groups_outlined,
    AtlasCommercialEnterpriseModule.afterSales => Icons.support_agent_outlined,
    AtlasCommercialEnterpriseModule.commercialIndicators =>
      Icons.insights_outlined,
    AtlasCommercialEnterpriseModule.servicesMarketplace =>
      Icons.storefront_outlined,
    AtlasCommercialEnterpriseModule.auctions => Icons.gavel_outlined,
    AtlasCommercialEnterpriseModule.commercialCenter =>
      Icons.dashboard_outlined,
  };
}
