import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_finance_enterprise/data/services/atlas_finance_enterprise_storage_service.dart';
import 'package:projeto_atlas/features/atlas_finance_enterprise/domain/models/atlas_finance_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_finance_enterprise/domain/services/atlas_finance_enterprise_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasFinanceEnterpriseScreen extends StatefulWidget {
  const AtlasFinanceEnterpriseScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasFinanceEnterpriseModule initialModule;

  @override
  State<AtlasFinanceEnterpriseScreen> createState() =>
      _AtlasFinanceEnterpriseScreenState();
}

class _AtlasFinanceEnterpriseScreenState
    extends State<AtlasFinanceEnterpriseScreen> {
  final AtlasFinanceEnterpriseStorageService storage =
      AtlasFinanceEnterpriseStorageService();
  final AtlasFinanceEnterpriseAnalyticsService analyticsService =
      const AtlasFinanceEnterpriseAnalyticsService();

  late AtlasFinanceEnterpriseModule selectedModule;
  List<AtlasFinanceEnterpriseRecord> records = [];
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
      (first, second) => parseAtlasFinanceEnterpriseDate(
        second.date,
      ).compareTo(parseAtlasFinanceEnterpriseDate(first.date)),
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

  List<AtlasFinanceEnterpriseRecord> get visibleRecords {
    return records
        .where((record) {
          final moduleMatches = record.module == selectedModule;
          final featureMatches =
              selectedFeature == 'Todos' || record.feature == selectedFeature;
          return moduleMatches && featureMatches;
        })
        .toList(growable: false);
  }

  Future<void> openForm([AtlasFinanceEnterpriseRecord? current]) async {
    final result = await showDialog<AtlasFinanceEnterpriseRecord>(
      context: context,
      builder: (context) =>
          _FinanceEnterpriseForm(module: selectedModule, current: current),
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

  Future<void> deleteRecord(AtlasFinanceEnterpriseRecord record) async {
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
                          title: Text('Financeiro Enterprise'),
                          subtitle: Text(
                            'A entrega organiza orçamento, fluxo, indicadores e cenários. '
                            'Decisões financeiras reais exigem contabilidade, contratos e validação profissional.',
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
                            title: 'Score financeiro',
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
                            subtitle: 'Ativos ou validados',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Riscos e desvios',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Planejado',
                            value:
                                'R\$ ${analytics.totalPlanned.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Valor consolidado',
                            icon: Icons.event_note_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Realizado',
                            value:
                                'R\$ ${analytics.totalActual.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Valor consolidado',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Projetado',
                            value:
                                'R\$ ${analytics.totalProjected.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Valor consolidado',
                            icon: Icons.auto_graph_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Desvio',
                            value:
                                '${analytics.consolidatedDeviationPercent.toStringAsFixed(1)}%',
                            subtitle:
                                'R\$ ${analytics.consolidatedDeviation.toStringAsFixed(2).replaceAll('.', ',')}',
                            icon: Icons.compare_arrows_outlined,
                            warning:
                                analytics.consolidatedDeviationPercent.abs() >=
                                10,
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
                            title: 'Confiança média',
                            value:
                                '${analytics.averageConfidence.toStringAsFixed(1)}%',
                            subtitle: 'Confiabilidade informada',
                            icon: Icons.verified_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Progresso médio',
                            value:
                                '${analytics.averageProgress.toStringAsFixed(0)}%',
                            subtitle: 'Evolução das análises',
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
                        'Registros financeiros enterprise',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre o primeiro orçamento, indicador ou cenário.',
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

  final AtlasFinanceEnterpriseModule selected;
  final ValueChanged<AtlasFinanceEnterpriseModule> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AtlasFinanceEnterpriseModule.values
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

  final AtlasFinanceEnterpriseModule module;
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

  final AtlasFinanceEnterpriseRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (record.status) {
      'Crítico' || 'Bloqueado' || 'Inadimplente' => Colors.red.shade800,
      'Atenção' => Colors.orange.shade800,
      'Ativo' ||
      'Validado' ||
      'Monitorado' ||
      'Concluído' => Colors.green.shade800,
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
          '${record.date} • ${AtlasUiText.status(record.status)} • '
          '${record.progressPercent}%\n'
          'Planejado R\$ ${record.plannedValue.toStringAsFixed(2)} • '
          'Realizado R\$ ${record.actualValue.toStringAsFixed(2)}',
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

class _FinanceEnterpriseForm extends StatefulWidget {
  const _FinanceEnterpriseForm({required this.module, this.current});

  final AtlasFinanceEnterpriseModule module;
  final AtlasFinanceEnterpriseRecord? current;

  @override
  State<_FinanceEnterpriseForm> createState() => _FinanceEnterpriseFormState();
}

class _FinanceEnterpriseFormState extends State<_FinanceEnterpriseForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController companyName;
  late final TextEditingController farmName;
  late final TextEditingController category;
  late final TextEditingController plannedValue;
  late final TextEditingController actualValue;
  late final TextEditingController projectedValue;
  late final TextEditingController referenceValue;
  late final TextEditingController riskPercent;
  late final TextEditingController confidencePercent;
  late final TextEditingController progressPercent;
  late final TextEditingController alertCount;
  late final TextEditingController periodLabel;
  late final TextEditingController responsible;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final current = widget.current;

    feature = current?.feature ?? widget.module.features.first;
    status = current?.status ?? 'Planejado';

    title = TextEditingController(text: current?.title ?? '');
    date = TextEditingController(
      text: current?.date ?? formatAtlasFinanceEnterpriseDate(DateTime.now()),
    );
    companyName = TextEditingController(text: current?.companyName ?? '');
    farmName = TextEditingController(text: current?.farmName ?? '');
    category = TextEditingController(text: current?.category ?? '');
    plannedValue = TextEditingController(
      text: current == null || current.plannedValue == 0
          ? ''
          : current.plannedValue.toString(),
    );
    actualValue = TextEditingController(
      text: current == null || current.actualValue == 0
          ? ''
          : current.actualValue.toString(),
    );
    projectedValue = TextEditingController(
      text: current == null || current.projectedValue == 0
          ? ''
          : current.projectedValue.toString(),
    );
    referenceValue = TextEditingController(
      text: current == null || current.referenceValue == 0
          ? ''
          : current.referenceValue.toString(),
    );
    riskPercent = TextEditingController(
      text: current == null || current.riskPercent == 0
          ? ''
          : current.riskPercent.toString(),
    );
    confidencePercent = TextEditingController(
      text: current == null || current.confidencePercent == 0
          ? ''
          : current.confidencePercent.toString(),
    );
    progressPercent = TextEditingController(
      text: current == null ? '' : current.progressPercent.toString(),
    );
    alertCount = TextEditingController(
      text: current == null || current.alertCount == 0
          ? ''
          : current.alertCount.toString(),
    );
    periodLabel = TextEditingController(text: current?.periodLabel ?? '');
    responsible = TextEditingController(text: current?.responsible ?? '');
    notes = TextEditingController(text: current?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    companyName.dispose();
    farmName.dispose();
    category.dispose();
    plannedValue.dispose();
    actualValue.dispose();
    projectedValue.dispose();
    referenceValue.dispose();
    riskPercent.dispose();
    confidencePercent.dispose();
    progressPercent.dispose();
    alertCount.dispose();
    periodLabel.dispose();
    responsible.dispose();
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

  Future<void> chooseDate() async {
    final parsed = parseAtlasFinanceEnterpriseDate(date.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      date.text = formatAtlasFinanceEnterpriseDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.current;

    Navigator.pop(
      context,
      AtlasFinanceEnterpriseRecord(
        id: current?.id ?? 'finance_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        companyName: companyName.text.trim(),
        farmName: farmName.text.trim(),
        category: category.text.trim(),
        plannedValue: decimal(plannedValue),
        actualValue: decimal(actualValue),
        projectedValue: decimal(projectedValue),
        referenceValue: decimal(referenceValue),
        riskPercent: percent(riskPercent),
        confidencePercent: percent(confidencePercent),
        progressPercent: integer(progressPercent).clamp(0, 100),
        alertCount: nonNegative(alertCount),
        periodLabel: periodLabel.text.trim(),
        responsible: responsible.text.trim(),
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
                  onTap: chooseDate,
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
                            'Validado',
                            'Monitorado',
                            'Concluído',
                            'Atenção',
                            'Inadimplente',
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
                  controller: companyName,
                  decoration: const InputDecoration(labelText: 'Empresa'),
                ),
                TextFormField(
                  controller: farmName,
                  decoration: const InputDecoration(labelText: 'Fazenda'),
                ),
                TextFormField(
                  controller: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoria ou centro de custo',
                  ),
                ),
                TextFormField(
                  controller: plannedValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor planejado (R\$)',
                  ),
                ),
                TextFormField(
                  controller: actualValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor realizado (R\$)',
                  ),
                ),
                TextFormField(
                  controller: projectedValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor projetado (R\$)',
                  ),
                ),
                TextFormField(
                  controller: referenceValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor de referência (R\$)',
                  ),
                ),
                TextFormField(
                  controller: riskPercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Risco (0 a 100%)',
                  ),
                ),
                TextFormField(
                  controller: confidencePercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Confiança (0 a 100%)',
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
                  controller: periodLabel,
                  decoration: const InputDecoration(
                    labelText: 'Período de referência',
                  ),
                ),
                TextFormField(
                  controller: responsible,
                  decoration: const InputDecoration(labelText: 'Responsável'),
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

IconData _moduleIcon(AtlasFinanceEnterpriseModule module) {
  return switch (module) {
    AtlasFinanceEnterpriseModule.projectedCashFlow =>
      Icons.trending_up_outlined,
    AtlasFinanceEnterpriseModule.consolidatedCashFlow =>
      Icons.account_balance_wallet_outlined,
    AtlasFinanceEnterpriseModule.annualBudget => Icons.event_note_outlined,
    AtlasFinanceEnterpriseModule.actualVsPlanned =>
      Icons.compare_arrows_outlined,
    AtlasFinanceEnterpriseModule.economicSimulations =>
      Icons.analytics_outlined,
    AtlasFinanceEnterpriseModule.bankingIndicators =>
      Icons.account_balance_outlined,
    AtlasFinanceEnterpriseModule.roi => Icons.percent_outlined,
    AtlasFinanceEnterpriseModule.ebitda => Icons.bar_chart_outlined,
    AtlasFinanceEnterpriseModule.assetValuation => Icons.home_work_outlined,
    AtlasFinanceEnterpriseModule.enterpriseFinanceCenter =>
      Icons.dashboard_outlined,
  };
}
