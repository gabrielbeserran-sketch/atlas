import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_enterprise_suite/presentation/widgets/enterprise_module_widgets.dart';
import 'package:projeto_atlas/features/atlas_supply_logistics_enterprise/data/services/atlas_supply_logistics_storage_service.dart';
import 'package:projeto_atlas/features/atlas_supply_logistics_enterprise/domain/models/atlas_supply_logistics_record.dart';
import 'package:projeto_atlas/features/atlas_supply_logistics_enterprise/domain/services/atlas_supply_logistics_analytics_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AtlasSupplyLogisticsScreen extends StatefulWidget {
  const AtlasSupplyLogisticsScreen({
    required this.animal,
    required this.farm,
    required this.group,
    required this.initialModule,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final AtlasSupplyLogisticsModule initialModule;

  @override
  State<AtlasSupplyLogisticsScreen> createState() =>
      _AtlasSupplyLogisticsScreenState();
}

class _AtlasSupplyLogisticsScreenState
    extends State<AtlasSupplyLogisticsScreen> {
  final storage = AtlasSupplyLogisticsStorageService();
  final analyticsService =
      const AtlasSupplyLogisticsAnalyticsService();

  late AtlasSupplyLogisticsModule selectedModule;
  List<AtlasSupplyLogisticsRecord> records = [];
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
      (a, b) => parseAtlasSupplyDate(b.date)
          .compareTo(parseAtlasSupplyDate(a.date)),
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

  List<AtlasSupplyLogisticsRecord> get visibleRecords =>
      records.where((record) {
        return record.module == selectedModule &&
            (selectedFeature == 'Todos' ||
                record.feature == selectedFeature);
      }).toList(growable: false);

  Future<void> openForm([
    AtlasSupplyLogisticsRecord? current,
  ]) async {
    final result = await showDialog<AtlasSupplyLogisticsRecord>(
      context: context,
      builder: (_) => _SupplyForm(
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
    AtlasSupplyLogisticsRecord record,
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
                            'Fase 32 — Suprimentos e Logística Enterprise',
                          ),
                          subtitle: Text(
                            'A entrega organiza compras, fornecedores, estoques, transporte e combustível. '
                            'Integrações fiscais e financeiras reais exigem backend e validação profissional.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AtlasSupplyLogisticsModule.values
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
                            title: 'Score logístico',
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
                            title: 'Quantidade',
                            value:
                                analytics.totalQuantity.toStringAsFixed(2),
                            subtitle: 'Total consolidado',
                            icon: Icons.inventory_2_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Planejado',
                            value:
                                'R\$ ${analytics.totalPlannedValue.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Valor consolidado',
                            icon: Icons.request_quote_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Realizado',
                            value:
                                'R\$ ${analytics.totalActualValue.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle:
                                'Desvio R\$ ${analytics.valueDeviation.toStringAsFixed(2).replaceAll('.', ',')}',
                            icon: Icons.payments_outlined,
                          ),
                          EnterpriseMetricCard(
                            title: 'Custo calculado',
                            value:
                                'R\$ ${analytics.totalCalculatedCost.toStringAsFixed(2).replaceAll('.', ',')}',
                            subtitle: 'Itens e frete',
                            icon: Icons.calculate_outlined,
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
                        'Registros de suprimentos e logística',
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
                              'Cadastre a primeira compra, movimentação, entrega ou abastecimento.',
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
                                '${record.itemName.isEmpty ? 'Sem item informado' : record.itemName}',
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

class _SupplyForm extends StatefulWidget {
  const _SupplyForm({
    required this.module,
    this.current,
  });

  final AtlasSupplyLogisticsModule module;
  final AtlasSupplyLogisticsRecord? current;

  @override
  State<_SupplyForm> createState() => _SupplyFormState();
}

class _SupplyFormState extends State<_SupplyForm> {
  final formKey = GlobalKey<FormState>();

  late String feature;
  late String status;
  late String priority;

  late final TextEditingController title;
  late final TextEditingController date;
  late final TextEditingController dueDate;
  late final TextEditingController farmName;
  late final TextEditingController supplierName;
  late final TextEditingController warehouseName;
  late final TextEditingController itemName;
  late final TextEditingController batchCode;
  late final TextEditingController vehicleName;
  late final TextEditingController driverName;
  late final TextEditingController quantity;
  late final TextEditingController unit;
  late final TextEditingController unitCost;
  late final TextEditingController freightCost;
  late final TextEditingController plannedValue;
  late final TextEditingController actualValue;
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
          formatAtlasSupplyDate(DateTime.now()),
    );
    dueDate = TextEditingController(text: current?.dueDate ?? '');
    farmName = TextEditingController(text: current?.farmName ?? '');
    supplierName =
        TextEditingController(text: current?.supplierName ?? '');
    warehouseName =
        TextEditingController(text: current?.warehouseName ?? '');
    itemName = TextEditingController(text: current?.itemName ?? '');
    batchCode = TextEditingController(text: current?.batchCode ?? '');
    vehicleName =
        TextEditingController(text: current?.vehicleName ?? '');
    driverName =
        TextEditingController(text: current?.driverName ?? '');
    quantity = TextEditingController(
      text: current == null || current.quantity == 0
          ? ''
          : current.quantity.toString(),
    );
    unit = TextEditingController(text: current?.unit ?? '');
    unitCost = TextEditingController(
      text: current == null || current.unitCost == 0
          ? ''
          : current.unitCost.toString(),
    );
    freightCost = TextEditingController(
      text: current == null || current.freightCost == 0
          ? ''
          : current.freightCost.toString(),
    );
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
      supplierName,
      warehouseName,
      itemName,
      batchCode,
      vehicleName,
      driverName,
      quantity,
      unit,
      unitCost,
      freightCost,
      plannedValue,
      actualValue,
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
    final parsed = parseAtlasSupplyDate(controller.text);
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
      controller.text = formatAtlasSupplyDate(selected);
    });
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final current = widget.current;
    final now = DateTime.now().toIso8601String();

    Navigator.pop(
      context,
      AtlasSupplyLogisticsRecord(
        id: current?.id ??
            'supply_${DateTime.now().microsecondsSinceEpoch}',
        module: widget.module,
        feature: feature,
        title: title.text.trim(),
        date: date.text.trim(),
        dueDate: dueDate.text.trim(),
        status: status,
        priority: priority,
        farmName: farmName.text.trim(),
        supplierName: supplierName.text.trim(),
        warehouseName: warehouseName.text.trim(),
        itemName: itemName.text.trim(),
        batchCode: batchCode.text.trim(),
        vehicleName: vehicleName.text.trim(),
        driverName: driverName.text.trim(),
        quantity: decimal(quantity),
        unit: unit.text.trim(),
        unitCost: decimal(unitCost),
        freightCost: decimal(freightCost),
        plannedValue: decimal(plannedValue),
        actualValue: decimal(actualValue),
        progressPercent:
            integer(progressPercent).clamp(0, 100),
        qualityPercent:
            decimal(qualityPercent).clamp(0, 100),
        alertCount:
            integer(alertCount) < 0 ? 0 : integer(alertCount),
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
                    labelText: 'Prazo ou validade',
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
                    'Aprovado',
                    'Em trânsito',
                    'Concluído',
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
                ...[
                  (farmName, 'Fazenda'),
                  (supplierName, 'Fornecedor'),
                  (warehouseName, 'Depósito'),
                  (itemName, 'Item, produto ou serviço'),
                  (batchCode, 'Lote'),
                  (vehicleName, 'Veículo'),
                  (driverName, 'Motorista'),
                  (unit, 'Unidade'),
                ].map(
                  (item) => TextFormField(
                    controller: item.$1,
                    decoration: InputDecoration(
                      labelText: item.$2,
                    ),
                  ),
                ),
                ...[
                  (quantity, 'Quantidade'),
                  (unitCost, 'Custo unitário (R\$)'),
                  (freightCost, 'Frete (R\$)'),
                  (plannedValue, 'Valor planejado (R\$)'),
                  (actualValue, 'Valor realizado (R\$)'),
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
  AtlasSupplyLogisticsModule module,
) {
  return switch (module) {
    AtlasSupplyLogisticsModule.intelligentPurchasing =>
      Icons.shopping_cart_checkout_outlined,
    AtlasSupplyLogisticsModule.supplierManagement =>
      Icons.handshake_outlined,
    AtlasSupplyLogisticsModule.automatedQuotation =>
      Icons.compare_arrows_outlined,
    AtlasSupplyLogisticsModule.purchaseApproval =>
      Icons.approval_outlined,
    AtlasSupplyLogisticsModule.multiWarehouseStock =>
      Icons.warehouse_outlined,
    AtlasSupplyLogisticsModule.batchesAndExpiry =>
      Icons.qr_code_2_outlined,
    AtlasSupplyLogisticsModule.intelligentInventory =>
      Icons.inventory_2_outlined,
    AtlasSupplyLogisticsModule.transportLogistics =>
      Icons.local_shipping_outlined,
    AtlasSupplyLogisticsModule.fuelManagement =>
      Icons.local_gas_station_outlined,
    AtlasSupplyLogisticsModule.supplyLogisticsCenter =>
      Icons.dashboard_outlined,
  };
}
