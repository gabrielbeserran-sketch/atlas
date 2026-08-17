import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_supply_chain/data/services/atlas_supply_chain_storage_service.dart';
import 'package:projeto_atlas/features/atlas_supply_chain/domain/models/atlas_supply_chain_record.dart';
import 'package:projeto_atlas/features/atlas_supply_chain/domain/services/atlas_supply_chain_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasSupplyChainScreen extends StatefulWidget {
  const AtlasSupplyChainScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasSupplyChainModule initialModule;

  @override
  State<AtlasSupplyChainScreen> createState() => _AtlasSupplyChainScreenState();
}

class _AtlasSupplyChainScreenState extends State<AtlasSupplyChainScreen> {
  final AtlasSupplyChainStorageService storage =
      AtlasSupplyChainStorageService();
  final AtlasSupplyChainAnalyticsService analyticsService =
      const AtlasSupplyChainAnalyticsService();

  late AtlasSupplyChainModule selectedModule;
  List<AtlasSupplyChainRecord> records = [];
  bool loading = true;
  String selectedFeature = 'Todos';

  @override
  void initState() {
    super.initState();
    selectedModule = widget.initialModule;
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final loaded = await storage.load(
      farmName: widget.farm.name,
      animalId: widget.animal.id,
    );

    loaded.sort(
      (first, second) => parseAtlasSupplyDate(
        second.date,
      ).compareTo(parseAtlasSupplyDate(first.date)),
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

  List<AtlasSupplyChainRecord> get visibleRecords {
    return records
        .where((record) {
          final moduleMatches = record.module == selectedModule;
          final featureMatches =
              selectedFeature == 'Todos' || record.feature == selectedFeature;
          return moduleMatches && featureMatches;
        })
        .toList(growable: false);
  }

  Future<void> openForm([AtlasSupplyChainRecord? current]) async {
    final result = await showDialog<AtlasSupplyChainRecord>(
      context: context,
      builder: (context) =>
          _SupplyRecordForm(module: selectedModule, record: current),
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

  Future<void> deleteRecord(AtlasSupplyChainRecord record) async {
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
            constraints: const BoxConstraints(maxWidth: 1220),
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
                            subtitle: 'Funcionalidades com registros',
                            icon: Icons.grid_view_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Score operacional',
                            value: '${analytics.score}/100',
                            subtitle: analytics.score >= 70
                                ? 'Estrutura consistente'
                                : 'Requer evolução',
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
                            title: 'Concluídos',
                            value: '${analytics.completedCount}',
                            subtitle: 'Processos finalizados',
                            icon: Icons.task_alt_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Alertas',
                            value: '${analytics.alertCount}',
                            subtitle: 'Atenção e crítico',
                            icon: Icons.warning_amber_outlined,
                            warning: analytics.alertCount > 0,
                          ),
                          EnterpriseMetricCard(
                            title: 'Valor total',
                            value: _money(analytics.totalValue),
                            subtitle: 'Média ${_money(analytics.averageValue)}',
                            icon: Icons.attach_money,
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
                        'Registros operacionais',
                        'Histórico ordenado da data mais recente.',
                      ),
                      const SizedBox(height: 12),
                      if (visibleRecords.isEmpty)
                        Card(
                          child: ListTile(
                            leading: Icon(_moduleIcon(selectedModule)),
                            title: const Text('Nenhum registro encontrado.'),
                            subtitle: const Text(
                              'Cadastre o primeiro registro '
                              'para iniciar os indicadores.',
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

  final AtlasSupplyChainModule selected;
  final ValueChanged<AtlasSupplyChainModule> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: AtlasSupplyChainModule.values
              .map((module) {
                final active = module == selected;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: module == AtlasSupplyChainModule.values.last
                          ? 0
                          : 8,
                    ),
                    child: FilledButton.tonalIcon(
                      onPressed: () => onSelected(module),
                      style: FilledButton.styleFrom(
                        backgroundColor: active
                            ? const Color(0xFF1B5E20)
                            : null,
                        foregroundColor: active ? Colors.white : null,
                      ),
                      icon: Icon(_moduleIcon(module)),
                      label: Text(module.packageLabel),
                    ),
                  ),
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

  final AtlasSupplyChainModule module;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = ['Todos', ...module.features];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((feature) {
            return ChoiceChip(
              label: Text(feature),
              selected: feature == selected,
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

  final AtlasSupplyChainRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (record.status) {
      'Crítico' => Colors.red.shade700,
      'Atenção' => Colors.orange.shade800,
      'Concluído' || 'Recebido' => Colors.green.shade800,
      _ => Colors.blueGrey,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(_moduleIcon(record.module), color: statusColor),
        ),
        title: Text(record.title),
        subtitle: Text(
          '${record.feature}\n'
          '${record.date} • ${record.status} • '
          '${record.quantity.toStringAsFixed(2).replaceAll('.', ',')} × '
          '${_money(record.unitValue)} = '
          '${_money(record.totalValue)}'
          '${record.counterparty.isEmpty ? '' : '\n${record.counterparty}'}',
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

class _SupplyRecordForm extends StatefulWidget {
  const _SupplyRecordForm({required this.module, this.record});

  final AtlasSupplyChainModule module;
  final AtlasSupplyChainRecord? record;

  @override
  State<_SupplyRecordForm> createState() => _SupplyRecordFormState();
}

class _SupplyRecordFormState extends State<_SupplyRecordForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController quantity;
  late final TextEditingController unitValue;
  late final TextEditingController counterparty;
  late final TextEditingController document;
  late final TextEditingController origin;
  late final TextEditingController destination;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    feature = record?.feature ?? widget.module.features.first;
    status = record?.status ?? 'Planejado';

    title = TextEditingController(text: record?.title ?? '');
    date = TextEditingController(
      text: record?.date ?? formatAtlasSupplyDate(DateTime.now()),
    );
    quantity = TextEditingController(
      text: record == null ? '' : record.quantity.toString(),
    );
    unitValue = TextEditingController(
      text: record == null ? '' : record.unitValue.toString(),
    );
    counterparty = TextEditingController(text: record?.counterparty ?? '');
    document = TextEditingController(text: record?.document ?? '');
    origin = TextEditingController(text: record?.origin ?? '');
    destination = TextEditingController(text: record?.destination ?? '');
    notes = TextEditingController(text: record?.notes ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    date.dispose();
    quantity.dispose();
    unitValue.dispose();
    counterparty.dispose();
    document.dispose();
    origin.dispose();
    destination.dispose();
    notes.dispose();
    super.dispose();
  }

  double number(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  Future<void> chooseDate() async {
    final parsed = parseAtlasSupplyDate(date.text);

    final selected = await showDatePicker(
      context: context,
      initialDate: parsed.year == 1900 ? DateTime.now() : parsed,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null) return;

    setState(() {
      date.text = formatAtlasSupplyDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();
    final current = widget.record;

    Navigator.pop(
      context,
      AtlasSupplyChainRecord(
        id: current?.id ?? 'supply_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        status: status,
        quantity: number(quantity),
        unitValue: number(unitValue),
        counterparty: counterparty.text.trim(),
        document: document.text.trim(),
        origin: origin.text.trim(),
        destination: destination.text.trim(),
        notes: notes.text.trim(),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.record == null ? 'Novo registro' : 'Editar registro'),
      content: SizedBox(
        width: 680,
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
                            'Em andamento',
                            'Aprovado',
                            'Recebido',
                            'Concluído',
                            'Atenção',
                            'Crítico',
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
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
                TextFormField(
                  controller: unitValue,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor unitário',
                  ),
                ),
                TextFormField(
                  controller: counterparty,
                  decoration: const InputDecoration(
                    labelText: 'Fornecedor, comprador ou transportador',
                  ),
                ),
                TextFormField(
                  controller: document,
                  decoration: const InputDecoration(
                    labelText: 'Documento, contrato, GTA ou romaneio',
                  ),
                ),
                TextFormField(
                  controller: origin,
                  decoration: const InputDecoration(labelText: 'Origem'),
                ),
                TextFormField(
                  controller: destination,
                  decoration: const InputDecoration(labelText: 'Destino'),
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

IconData _moduleIcon(AtlasSupplyChainModule module) {
  return switch (module) {
    AtlasSupplyChainModule.purchases => Icons.shopping_cart_outlined,
    AtlasSupplyChainModule.commercialization => Icons.attach_money,
    AtlasSupplyChainModule.logistics => Icons.local_shipping_outlined,
  };
}

String _money(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
