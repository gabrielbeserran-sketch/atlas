import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_asset_maintenance_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_asset_maintenance_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';

class AtlasAssetMaintenanceScreen extends StatefulWidget {
  const AtlasAssetMaintenanceScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasAssetMaintenanceScreen> createState() =>
      _AtlasAssetMaintenanceScreenState();
}

class _AtlasAssetMaintenanceScreenState
    extends State<AtlasAssetMaintenanceScreen> {
  final AtlasAssetMaintenanceService service =
      AtlasAssetMaintenanceService.instance;

  List<AtlasFarmAsset> assets = <AtlasFarmAsset>[];
  List<AtlasMaintenanceOrder> orders = <AtlasMaintenanceOrder>[];
  List<AtlasAssetUsageRecord> usage = <AtlasAssetUsageRecord>[];
  bool isLoading = false;

  AtlasAssetMaintenanceSummary get summary =>
      service.buildSummary(assets: assets, orders: orders, usage: usage);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    assets = await service.loadAssets(
      farmName: widget.actionController.farmName,
    );
    orders = await service.loadOrders(
      farmName: widget.actionController.farmName,
    );
    usage = await service.loadUsage(farmName: widget.actionController.farmName);

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editAsset({AtlasFarmAsset? asset}) async {
    final code = TextEditingController(text: asset?.code ?? '');
    final name = TextEditingController(text: asset?.name ?? '');
    final brand = TextEditingController(text: asset?.brand ?? '');
    final model = TextEditingController(text: asset?.model ?? '');
    final serial = TextEditingController(text: asset?.serialNumber ?? '');
    final year = TextEditingController(
      text: asset?.year == 0 ? '' : asset?.year.toString(),
    );
    final purchaseValue = TextEditingController(
      text: asset?.purchaseValue.toString() ?? '',
    );
    final currentValue = TextEditingController(
      text: asset?.currentValue.toString() ?? '',
    );
    final hourMeter = TextEditingController(
      text: asset?.hourMeter.toString() ?? '',
    );
    final odometer = TextEditingController(
      text: asset?.odometerKm.toString() ?? '',
    );
    final location = TextEditingController(text: asset?.location ?? '');
    final responsible = TextEditingController(
      text: asset?.responsibleName ?? '',
    );
    final notes = TextEditingController(text: asset?.notes ?? '');

    var type = asset?.type ?? AtlasAssetType.tractor;
    var status = asset?.status ?? AtlasAssetStatus.available;
    var active = asset?.active ?? true;
    DateTime? purchaseAt = asset?.purchaseAt;

    final result = await showDialog<AtlasFarmAsset>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(asset == null ? 'Novo ativo' : 'Editar ativo'),
              content: SizedBox(
                width: 700,
                height: 650,
                child: ListView(
                  children: [
                    _row(
                      TextField(
                        controller: code,
                        decoration: const InputDecoration(
                          labelText: 'Código',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      DropdownButtonFormField<AtlasAssetType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasAssetType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(atlasAssetTypeLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => type = value);
                          }
                        },
                      ),
                      DropdownButtonFormField<AtlasAssetStatus>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Situação',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasAssetStatus.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(atlasAssetStatusLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      TextField(
                        controller: brand,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      TextField(
                        controller: model,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      TextField(
                        controller: serial,
                        decoration: const InputDecoration(
                          labelText: 'Número de série',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      _number(year, 'Ano'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(purchaseValue, 'Valor de compra'),
                      _number(currentValue, 'Valor atual'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(hourMeter, 'Horímetro'),
                      _number(odometer, 'Odômetro (km)'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      TextField(
                        controller: location,
                        decoration: const InputDecoration(
                          labelText: 'Localização',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      TextField(
                        controller: responsible,
                        decoration: const InputDecoration(
                          labelText: 'Responsável',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    _DateSelector(
                      title: 'Data de aquisição',
                      date: purchaseAt,
                      onSelect: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: purchaseAt ?? DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(() => purchaseAt = selected);
                        }
                      },
                    ),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Ativo'),
                      value: active,
                      onChanged: (value) {
                        setDialogState(() => active = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (name.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasFarmAsset(
                        id:
                            asset?.id ??
                            'farm_asset_'
                                '${now.microsecondsSinceEpoch}',
                        code: code.text.trim(),
                        name: name.text.trim(),
                        type: type,
                        status: status,
                        brand: brand.text.trim(),
                        model: model.text.trim(),
                        serialNumber: serial.text.trim(),
                        year: int.tryParse(year.text) ?? 0,
                        purchaseAt: purchaseAt,
                        purchaseValue: _double(purchaseValue.text),
                        currentValue: _double(currentValue.text),
                        hourMeter: _double(hourMeter.text),
                        odometerKm: _double(odometer.text),
                        location: location.text.trim(),
                        responsibleName: responsible.text.trim(),
                        notes: notes.text.trim(),
                        farmName: widget.actionController.farmName,
                        active: active,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in [
      code,
      name,
      brand,
      model,
      serial,
      year,
      purchaseValue,
      currentValue,
      hourMeter,
      odometer,
      location,
      responsible,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveAsset(result);
      await _load();
    }
  }

  Future<void> _editOrder({
    AtlasMaintenanceOrder? order,
    AtlasMaintenanceType? initialType,
  }) async {
    if (assets.isEmpty) {
      return;
    }

    var assetId = order?.assetId ?? assets.first.id;
    var type = order?.type ?? initialType ?? AtlasMaintenanceType.preventive;
    var status = order?.status ?? AtlasMaintenanceStatus.planned;
    var scheduledAt = order?.scheduledAt ?? DateTime.now();
    DateTime? startedAt = order?.startedAt;
    DateTime? completedAt = order?.completedAt;
    DateTime? nextServiceAt = order?.nextServiceAt;

    final title = TextEditingController(text: order?.title ?? '');
    final description = TextEditingController(text: order?.description ?? '');
    final responsible = TextEditingController(
      text: order?.responsibleName ?? '',
    );
    final supplier = TextEditingController(text: order?.supplierName ?? '');
    final laborCost = TextEditingController(
      text: order?.laborCost.toString() ?? '',
    );
    final partsCost = TextEditingController(
      text: order?.partsCost.toString() ?? '',
    );
    final downtime = TextEditingController(
      text: order?.downtimeHours.toString() ?? '',
    );
    final hourMeter = TextEditingController(
      text: order?.hourMeterAtService.toString() ?? '',
    );
    final odometer = TextEditingController(
      text: order?.odometerAtServiceKm.toString() ?? '',
    );
    final nextHourMeter = TextEditingController(
      text: order?.nextServiceHourMeter.toString() ?? '',
    );
    final nextOdometer = TextEditingController(
      text: order?.nextServiceOdometerKm.toString() ?? '',
    );
    final notes = TextEditingController(text: order?.notes ?? '');

    final result = await showDialog<AtlasMaintenanceOrder>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                order == null
                    ? 'Nova ordem de manutenção'
                    : 'Editar ordem de manutenção',
              ),
              content: SizedBox(
                width: 720,
                height: 680,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: assetId,
                      decoration: const InputDecoration(
                        labelText: 'Ativo',
                        border: OutlineInputBorder(),
                      ),
                      items: assets
                          .map(
                            (asset) => DropdownMenuItem(
                              value: asset.id,
                              child: Text(asset.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => assetId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _row(
                      DropdownButtonFormField<AtlasMaintenanceType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasMaintenanceType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(atlasMaintenanceTypeLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => type = value);
                          }
                        },
                      ),
                      DropdownButtonFormField<AtlasMaintenanceStatus>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Situação',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasMaintenanceStatus.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(atlasMaintenanceStatusLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      TextField(
                        controller: responsible,
                        decoration: const InputDecoration(
                          labelText: 'Responsável',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      TextField(
                        controller: supplier,
                        decoration: const InputDecoration(
                          labelText: 'Oficina/fornecedor',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(laborCost, 'Custo de mão de obra'),
                      _number(partsCost, 'Custo de peças'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(downtime, 'Horas parado'),
                      _number(hourMeter, 'Horímetro na manutenção'),
                    ),
                    const SizedBox(height: 10),
                    _number(odometer, 'Odômetro na manutenção'),
                    _DateSelector(
                      title: 'Data programada',
                      date: scheduledAt,
                      onSelect: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: scheduledAt,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(() => scheduledAt = selected);
                        }
                      },
                    ),
                    _DateSelector(
                      title: 'Início',
                      date: startedAt,
                      onSelect: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: startedAt ?? scheduledAt,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(() => startedAt = selected);
                        }
                      },
                    ),
                    _DateSelector(
                      title: 'Conclusão',
                      date: completedAt,
                      onSelect: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: completedAt ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(() => completedAt = selected);
                        }
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Próxima revisão',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    _DateSelector(
                      title: 'Próxima data',
                      date: nextServiceAt,
                      onSelect: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate:
                              nextServiceAt ??
                              DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(() => nextServiceAt = selected);
                        }
                      },
                    ),
                    _row(
                      _number(nextHourMeter, 'Próximo horímetro'),
                      _number(nextOdometer, 'Próximo odômetro'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (title.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasMaintenanceOrder(
                        id:
                            order?.id ??
                            'maintenance_order_'
                                '${now.microsecondsSinceEpoch}',
                        assetId: assetId,
                        type: type,
                        status: status,
                        title: title.text.trim(),
                        description: description.text.trim(),
                        scheduledAt: scheduledAt,
                        startedAt: startedAt,
                        completedAt: status == AtlasMaintenanceStatus.completed
                            ? completedAt ?? now
                            : completedAt,
                        responsibleName: responsible.text.trim(),
                        supplierName: supplier.text.trim(),
                        laborCost: _double(laborCost.text),
                        partsCost: _double(partsCost.text),
                        downtimeHours: _double(downtime.text),
                        hourMeterAtService: _double(hourMeter.text),
                        odometerAtServiceKm: _double(odometer.text),
                        nextServiceAt: nextServiceAt,
                        nextServiceHourMeter: _double(nextHourMeter.text),
                        nextServiceOdometerKm: _double(nextOdometer.text),
                        notes: notes.text.trim(),
                        farmName: widget.actionController.farmName,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in [
      title,
      description,
      responsible,
      supplier,
      laborCost,
      partsCost,
      downtime,
      hourMeter,
      odometer,
      nextHourMeter,
      nextOdometer,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveOrder(result);
      await _load();
    }
  }

  Future<void> _editUsage({AtlasAssetUsageRecord? record}) async {
    if (assets.isEmpty) {
      return;
    }

    var assetId = record?.assetId ?? assets.first.id;
    var occurredAt = record?.occurredAt ?? DateTime.now();

    final operator = TextEditingController(text: record?.operatorName ?? '');
    final activity = TextEditingController(text: record?.activity ?? '');
    final startHour = TextEditingController(
      text: record?.startHourMeter.toString() ?? '',
    );
    final endHour = TextEditingController(
      text: record?.endHourMeter.toString() ?? '',
    );
    final startKm = TextEditingController(
      text: record?.startOdometerKm.toString() ?? '',
    );
    final endKm = TextEditingController(
      text: record?.endOdometerKm.toString() ?? '',
    );
    final fuel = TextEditingController(
      text: record?.fuelLiters.toString() ?? '',
    );
    final lubricant = TextEditingController(
      text: record?.lubricantLiters.toString() ?? '',
    );
    final area = TextEditingController(
      text: record?.areaWorkedHectares.toString() ?? '',
    );
    final notes = TextEditingController(text: record?.notes ?? '');

    final result = await showDialog<AtlasAssetUsageRecord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                record == null
                    ? 'Novo registro de uso'
                    : 'Editar registro de uso',
              ),
              content: SizedBox(
                width: 650,
                height: 620,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: assetId,
                      decoration: const InputDecoration(
                        labelText: 'Ativo',
                        border: OutlineInputBorder(),
                      ),
                      items: assets
                          .map(
                            (asset) => DropdownMenuItem(
                              value: asset.id,
                              child: Text(asset.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => assetId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _row(
                      TextField(
                        controller: operator,
                        decoration: const InputDecoration(
                          labelText: 'Operador',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      TextField(
                        controller: activity,
                        decoration: const InputDecoration(
                          labelText: 'Atividade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(startHour, 'Horímetro inicial'),
                      _number(endHour, 'Horímetro final'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(startKm, 'Odômetro inicial'),
                      _number(endKm, 'Odômetro final'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(fuel, 'Combustível (L)'),
                      _number(lubricant, 'Lubrificante (L)'),
                    ),
                    const SizedBox(height: 10),
                    _number(area, 'Área trabalhada (ha)'),
                    _DateSelector(
                      title: 'Data',
                      date: occurredAt,
                      onSelect: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: occurredAt,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(() => occurredAt = selected);
                        }
                      },
                    ),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasAssetUsageRecord(
                        id:
                            record?.id ??
                            'asset_usage_'
                                '${now.microsecondsSinceEpoch}',
                        assetId: assetId,
                        occurredAt: occurredAt,
                        operatorName: operator.text.trim(),
                        activity: activity.text.trim(),
                        startHourMeter: _double(startHour.text),
                        endHourMeter: _double(endHour.text),
                        startOdometerKm: _double(startKm.text),
                        endOdometerKm: _double(endKm.text),
                        fuelLiters: _double(fuel.text),
                        lubricantLiters: _double(lubricant.text),
                        areaWorkedHectares: _double(area.text),
                        notes: notes.text.trim(),
                        farmName: widget.actionController.farmName,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in [
      operator,
      activity,
      startHour,
      endHour,
      startKm,
      endKm,
      fuel,
      lubricant,
      area,
      notes,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveUsage(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = service.buildAlerts(assets: assets, orders: orders);
    final costByAsset = service.maintenanceCostByAsset(
      assets: assets,
      orders: orders,
    );
    final fuelByAsset = service.fuelConsumptionByAsset(
      assets: assets,
      usage: usage,
    );
    final preventivePlan = service.preventivePlan(orders: orders);

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Máquinas, equipamentos e manutenção'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Painel', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Ativos', icon: Icon(Icons.agriculture_outlined)),
              Tab(
                text: 'Preventiva',
                icon: Icon(Icons.event_available_outlined),
              ),
              Tab(text: 'Ordens', icon: Icon(Icons.build_outlined)),
              Tab(text: 'Uso', icon: Icon(Icons.timer_outlined)),
              Tab(
                text: 'Combustível',
                icon: Icon(Icons.local_gas_station_outlined),
              ),
              Tab(text: 'Custos', icon: Icon(Icons.attach_money)),
              Tab(text: 'Alertas', icon: Icon(Icons.warning_amber)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _editOrder(),
          icon: const Icon(Icons.add),
          label: const Text('Nova manutenção'),
        ),
        body: isLoading && assets.isEmpty && orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _AssetSummaryTab(summary: summary),
                  _AssetsTab(
                    assets: assets,
                    onAdd: () => _editAsset(),
                    onEdit: (asset) => _editAsset(asset: asset),
                  ),
                  _PreventiveTab(
                    orders: preventivePlan,
                    assets: assets,
                    onAdd: () => _editOrder(
                      initialType: AtlasMaintenanceType.preventive,
                    ),
                    onEdit: (order) => _editOrder(order: order),
                  ),
                  _OrdersTab(
                    orders: orders,
                    assets: assets,
                    onAdd: () => _editOrder(),
                    onEdit: (order) => _editOrder(order: order),
                  ),
                  _UsageTab(
                    usage: usage,
                    assets: assets,
                    onAdd: () => _editUsage(),
                    onEdit: (record) => _editUsage(record: record),
                  ),
                  _FuelTab(
                    usage: usage,
                    assets: assets,
                    fuelByAsset: fuelByAsset,
                  ),
                  _CostsTab(
                    summary: summary,
                    costByAsset: costByAsset,
                    assets: assets,
                  ),
                  _AlertsTab(alerts: alerts),
                ],
              ),
      ),
    );
  }

  static Widget _row(Widget first, Widget second) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }

  static Widget _number(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static double _double(String value) {
    var normalized = value.trim();
    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.title,
    required this.date,
    required this.onSelect,
  });

  final String title;
  final DateTime? date;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        date == null ? 'Não informada' : DateFormat('dd/MM/yyyy').format(date!),
      ),
      trailing: const Icon(Icons.calendar_month),
      onTap: onSelect,
    );
  }
}

class _AssetSummaryTab extends StatelessWidget {
  const _AssetSummaryTab({required this.summary});

  final AtlasAssetMaintenanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              title: 'Ativos',
              value: summary.totalAssets.toDouble(),
              unit: '',
            ),
            _MetricCard(
              title: 'Disponíveis',
              value: summary.availableAssets.toDouble(),
              unit: '',
            ),
            _MetricCard(
              title: 'Em manutenção',
              value: summary.assetsInMaintenance.toDouble(),
              unit: '',
            ),
            _MetricCard(
              title: 'Parados',
              value: summary.stoppedAssets.toDouble(),
              unit: '',
            ),
            _MetricCard(
              title: 'Ordens abertas',
              value: summary.openOrders.toDouble(),
              unit: '',
            ),
            _MetricCard(
              title: 'Ordens atrasadas',
              value: summary.overdueOrders.toDouble(),
              unit: '',
            ),
            _MetricCard(
              title: 'Custo mensal',
              value: summary.monthlyMaintenanceCost,
              unit: 'R\$',
            ),
            _MetricCard(
              title: 'Horas paradas',
              value: summary.totalDowntimeHours,
              unit: 'h',
            ),
            _MetricCard(
              title: 'Combustível no mês',
              value: summary.monthlyFuelLiters,
              unit: 'L',
            ),
            _MetricCard(
              title: 'Consumo médio',
              value: summary.averageFuelPerHour,
              unit: 'L/h',
            ),
            _MetricCard(
              title: 'Valor dos ativos',
              value: summary.totalCurrentAssetValue,
              unit: 'R\$',
            ),
          ],
        ),
      ],
    );
  }
}

class _AssetsTab extends StatelessWidget {
  const _AssetsTab({
    required this.assets,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasFarmAsset> assets;
  final VoidCallback onAdd;
  final ValueChanged<AtlasFarmAsset> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Novo ativo'),
            ),
          ),
        ),
        Expanded(
          child: assets.isEmpty
              ? const Center(child: Text('Nenhum ativo cadastrado.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: assets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(asset),
                        leading: const CircleAvatar(
                          child: Icon(Icons.agriculture),
                        ),
                        title: Text(
                          '${asset.code.isEmpty ? '' : '${asset.code} — '}${asset.name}',
                        ),
                        subtitle: Text(
                          '${atlasAssetTypeLabel(asset.type)} • '
                          '${asset.brand} ${asset.model} • '
                          '${atlasAssetStatusLabel(asset.status)}',
                        ),
                        trailing: Text(
                          'R\$ ${asset.currentValue.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PreventiveTab extends StatelessWidget {
  const _PreventiveTab({
    required this.orders,
    required this.assets,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasMaintenanceOrder> orders;
  final List<AtlasFarmAsset> assets;
  final VoidCallback onAdd;
  final ValueChanged<AtlasMaintenanceOrder> onEdit;

  String assetName(String id) {
    for (final asset in assets) {
      if (asset.id == id) {
        return asset.name;
      }
    }
    return 'Ativo';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Programar preventiva'),
            ),
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const Center(
                  child: Text('Nenhuma manutenção preventiva programada.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(order),
                        leading: const Icon(Icons.event_available_outlined),
                        title: Text(order.title),
                        subtitle: Text(
                          '${assetName(order.assetId)} • '
                          '${DateFormat('dd/MM/yyyy').format(order.scheduledAt)}',
                        ),
                        trailing: Text(
                          atlasMaintenanceStatusLabel(order.status),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({
    required this.orders,
    required this.assets,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasMaintenanceOrder> orders;
  final List<AtlasFarmAsset> assets;
  final VoidCallback onAdd;
  final ValueChanged<AtlasMaintenanceOrder> onEdit;

  String assetName(String id) {
    for (final asset in assets) {
      if (asset.id == id) {
        return asset.name;
      }
    }
    return 'Ativo';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Nova ordem'),
            ),
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const Center(child: Text('Nenhuma ordem de manutenção.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(order),
                        leading: const CircleAvatar(child: Icon(Icons.build)),
                        title: Text(order.title),
                        subtitle: Text(
                          '${assetName(order.assetId)} • '
                          '${atlasMaintenanceTypeLabel(order.type)} • '
                          '${DateFormat('dd/MM/yyyy').format(order.scheduledAt)}',
                        ),
                        trailing: Text(
                          'R\$ ${order.totalCost.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: order.isOverdue
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _UsageTab extends StatelessWidget {
  const _UsageTab({
    required this.usage,
    required this.assets,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasAssetUsageRecord> usage;
  final List<AtlasFarmAsset> assets;
  final VoidCallback onAdd;
  final ValueChanged<AtlasAssetUsageRecord> onEdit;

  String assetName(String id) {
    for (final asset in assets) {
      if (asset.id == id) {
        return asset.name;
      }
    }
    return 'Ativo';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Registrar uso'),
            ),
          ),
        ),
        Expanded(
          child: usage.isEmpty
              ? const Center(child: Text('Nenhum registro de uso.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: usage.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = usage[index];
                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(record),
                        title: Text(
                          '${assetName(record.assetId)} — ${record.activity}',
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(record.occurredAt)} • '
                          '${record.operatorName} • '
                          '${record.workedHours.toStringAsFixed(2)} h',
                        ),
                        trailing: Text(
                          '${record.fuelLiters.toStringAsFixed(2)} L',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FuelTab extends StatelessWidget {
  const _FuelTab({
    required this.usage,
    required this.assets,
    required this.fuelByAsset,
  });

  final List<AtlasAssetUsageRecord> usage;
  final List<AtlasFarmAsset> assets;
  final Map<String, double> fuelByAsset;

  @override
  Widget build(BuildContext context) {
    final ordered = fuelByAsset.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Consumo por ativo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (ordered.isEmpty)
          const Card(
            child: ListTile(title: Text('Nenhum consumo registrado.')),
          ),
        ...ordered.map(
          (entry) => Card(
            child: ListTile(
              leading: const Icon(Icons.local_gas_station_outlined),
              title: Text(entry.key),
              trailing: Text(
                '${entry.value.toStringAsFixed(2)} L',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Eficiência recente',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...usage
            .take(20)
            .map(
              (record) => Card(
                child: ListTile(
                  title: Text(record.activity),
                  subtitle: Text(
                    '${record.litersPerHour.toStringAsFixed(2)} L/h • '
                    '${record.litersPerHectare.toStringAsFixed(2)} L/ha',
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _CostsTab extends StatelessWidget {
  const _CostsTab({
    required this.summary,
    required this.costByAsset,
    required this.assets,
  });

  final AtlasAssetMaintenanceSummary summary;
  final Map<String, double> costByAsset;
  final List<AtlasFarmAsset> assets;

  @override
  Widget build(BuildContext context) {
    final ordered = costByAsset.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              title: 'Manutenção no mês',
              value: summary.monthlyMaintenanceCost,
              unit: 'R\$',
            ),
            _MetricCard(
              title: 'Valor atual dos ativos',
              value: summary.totalCurrentAssetValue,
              unit: 'R\$',
            ),
            _MetricCard(
              title: 'Horas improdutivas',
              value: summary.totalDowntimeHours,
              unit: 'h',
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Custos acumulados por ativo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (ordered.isEmpty)
          const Card(child: ListTile(title: Text('Nenhum custo registrado.'))),
        ...ordered.map(
          (entry) => Card(
            child: ListTile(
              title: Text(entry.key),
              trailing: Text(
                'R\$ ${entry.value.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Depreciação patrimonial',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...assets.map(
          (asset) => Card(
            child: ListTile(
              title: Text(asset.name),
              subtitle: Text(
                '${asset.depreciationPercent.toStringAsFixed(1)}% depreciado',
              ),
              trailing: Text(
                'R\$ ${asset.depreciationValue.toStringAsFixed(2)}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({required this.alerts});

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text(alerts[index]),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
  });

  final String title;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                '${unit == 'R\$' ? 'R\$ ' : ''}'
                '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}'
                '${unit == 'R\$' || unit.isEmpty ? '' : ' $unit'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
