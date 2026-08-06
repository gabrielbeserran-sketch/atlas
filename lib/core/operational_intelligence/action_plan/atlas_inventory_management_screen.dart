import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_inventory_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_inventory_service.dart';

class AtlasInventoryManagementScreen extends StatefulWidget {
  const AtlasInventoryManagementScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasInventoryManagementScreen> createState() =>
      _AtlasInventoryManagementScreenState();
}

class _AtlasInventoryManagementScreenState
    extends State<AtlasInventoryManagementScreen> {
  final AtlasInventoryService service = AtlasInventoryService.instance;

  List<AtlasInventoryLocation> locations = <AtlasInventoryLocation>[];
  List<AtlasSupplier> suppliers = <AtlasSupplier>[];
  List<AtlasInventoryItem> items = <AtlasInventoryItem>[];
  List<AtlasInventoryBatch> batches = <AtlasInventoryBatch>[];
  List<AtlasInventoryMovement> movements = <AtlasInventoryMovement>[];
  List<AtlasPurchaseOrder> purchaseOrders = <AtlasPurchaseOrder>[];
  bool isLoading = false;
  bool isProcessingConsumption = false;

  AtlasInventorySummary get summary => service.buildSummary(
    items: items,
    batches: batches,
    movements: movements,
    purchaseOrders: purchaseOrders,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    locations = await service.loadLocations(
      farmName: widget.actionController.farmName,
    );
    suppliers = await service.loadSuppliers(
      farmName: widget.actionController.farmName,
    );
    items = await service.loadItems(farmName: widget.actionController.farmName);
    batches = await service.loadBatches(
      farmName: widget.actionController.farmName,
    );
    movements = await service.loadMovements(
      farmName: widget.actionController.farmName,
    );
    purchaseOrders = await service.loadPurchaseOrders(
      farmName: widget.actionController.farmName,
    );

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editLocation({AtlasInventoryLocation? location}) async {
    final name = TextEditingController(text: location?.name ?? '');
    final description = TextEditingController(
      text: location?.description ?? '',
    );
    final responsible = TextEditingController(
      text: location?.responsibleName ?? '',
    );
    var active = location?.active ?? true;

    final result = await showDialog<AtlasInventoryLocation>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                location == null ? 'Novo almoxarifado' : 'Editar almoxarifado',
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
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
                    TextField(
                      controller: responsible,
                      decoration: const InputDecoration(
                        labelText: 'Responsável',
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
                      AtlasInventoryLocation(
                        id:
                            location?.id ??
                            'inventory_location_'
                                '${now.microsecondsSinceEpoch}',
                        name: name.text.trim(),
                        description: description.text.trim(),
                        responsibleName: responsible.text.trim(),
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

    name.dispose();
    description.dispose();
    responsible.dispose();

    if (result != null) {
      await service.saveLocation(result);
      await _load();
    }
  }

  Future<void> _editSupplier({AtlasSupplier? supplier}) async {
    final name = TextEditingController(text: supplier?.name ?? '');
    final document = TextEditingController(text: supplier?.document ?? '');
    final phone = TextEditingController(text: supplier?.phone ?? '');
    final email = TextEditingController(text: supplier?.email ?? '');
    final notes = TextEditingController(text: supplier?.notes ?? '');
    var active = supplier?.active ?? true;

    final result = await showDialog<AtlasSupplier>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                supplier == null ? 'Novo fornecedor' : 'Editar fornecedor',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: document,
                        decoration: const InputDecoration(
                          labelText: 'CPF/CNPJ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        TextField(
                          controller: phone,
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          controller: email,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(),
                          ),
                        ),
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
                      AtlasSupplier(
                        id:
                            supplier?.id ??
                            'supplier_'
                                '${now.microsecondsSinceEpoch}',
                        name: name.text.trim(),
                        document: document.text.trim(),
                        phone: phone.text.trim(),
                        email: email.text.trim(),
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

    name.dispose();
    document.dispose();
    phone.dispose();
    email.dispose();
    notes.dispose();

    if (result != null) {
      await service.saveSupplier(result);
      await _load();
    }
  }

  Future<void> _editItem({AtlasInventoryItem? item}) async {
    final code = TextEditingController(text: item?.code ?? '');
    final name = TextEditingController(text: item?.name ?? '');
    final unit = TextEditingController(text: item?.unit ?? '');
    final current = TextEditingController(
      text: item?.currentQuantity.toString() ?? '',
    );
    final minimum = TextEditingController(
      text: item?.minimumQuantity.toString() ?? '',
    );
    final maximum = TextEditingController(
      text: item?.maximumQuantity.toString() ?? '',
    );
    final cost = TextEditingController(
      text: item?.averageUnitCost.toString() ?? '',
    );
    final automaticPerDay = TextEditingController(
      text: item?.automaticConsumptionPerDay.toString() ?? '',
    );
    var category = item?.category ?? AtlasInventoryItemCategory.other;
    String? locationId = item?.locationId;
    String? supplierId = item?.preferredSupplierId;
    var automatic = item?.automaticConsumptionEnabled ?? false;
    var active = item?.active ?? true;

    final result = await showDialog<AtlasInventoryItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                item == null
                    ? 'Novo item de estoque'
                    : 'Editar item de estoque',
              ),
              content: SizedBox(
                width: 660,
                height: 640,
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
                      DropdownButtonFormField<AtlasInventoryItemCategory>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasInventoryItemCategory.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  atlasInventoryItemCategoryLabel(value),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      TextField(
                        controller: unit,
                        decoration: const InputDecoration(
                          labelText: 'Unidade',
                          hintText: 'kg, L, dose, unidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(current, 'Quantidade atual'),
                      _number(cost, 'Custo médio unitário'),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      _number(minimum, 'Estoque mínimo'),
                      _number(maximum, 'Estoque máximo'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: locationId,
                      decoration: const InputDecoration(
                        labelText: 'Almoxarifado',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sem localização'),
                        ),
                        ...locations.map(
                          (location) => DropdownMenuItem<String?>(
                            value: location.id,
                            child: Text(location.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => locationId = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: supplierId,
                      decoration: const InputDecoration(
                        labelText: 'Fornecedor preferencial',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sem fornecedor'),
                        ),
                        ...suppliers.map(
                          (supplier) => DropdownMenuItem<String?>(
                            value: supplier.id,
                            child: Text(supplier.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => supplierId = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Consumo automático diário'),
                      subtitle: const Text(
                        'O Atlas realiza uma baixa por dia.',
                      ),
                      value: automatic,
                      onChanged: (value) {
                        setDialogState(() => automatic = value);
                      },
                    ),
                    if (automatic)
                      _number(automaticPerDay, 'Quantidade consumida por dia'),
                    SwitchListTile(
                      title: const Text('Item ativo'),
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
                    if (name.text.trim().isEmpty || unit.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasInventoryItem(
                        id:
                            item?.id ??
                            'inventory_item_'
                                '${now.microsecondsSinceEpoch}',
                        code: code.text.trim(),
                        name: name.text.trim(),
                        category: category,
                        unit: unit.text.trim(),
                        currentQuantity: _double(current.text),
                        minimumQuantity: _double(minimum.text),
                        maximumQuantity: _double(maximum.text),
                        averageUnitCost: _double(cost.text),
                        locationId: locationId,
                        preferredSupplierId: supplierId,
                        automaticConsumptionEnabled: automatic,
                        automaticConsumptionPerDay: automatic
                            ? _double(automaticPerDay.text)
                            : 0,
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
      unit,
      current,
      minimum,
      maximum,
      cost,
      automaticPerDay,
    ]) {
      controller.dispose();
    }

    if (result != null) {
      await service.saveItem(result);
      await _load();
    }
  }

  Future<void> _registerMovement({
    AtlasInventoryMovementType initialType = AtlasInventoryMovementType.entry,
  }) async {
    if (items.isEmpty) {
      return;
    }

    var itemId = items.first.id;
    var type = initialType;
    final quantity = TextEditingController();
    final unitCost = TextEditingController();
    final responsible = TextEditingController();
    final reference = TextEditingController();
    final notes = TextEditingController();
    var occurredAt = DateTime.now();

    final result = await showDialog<AtlasInventoryMovement>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedItem = items.firstWhere((item) => item.id == itemId);

            return AlertDialog(
              title: const Text('Movimentação de estoque'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: itemId,
                        decoration: const InputDecoration(
                          labelText: 'Item',
                          border: OutlineInputBorder(),
                        ),
                        items: items
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => itemId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<AtlasInventoryMovementType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasInventoryMovementType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  atlasInventoryMovementTypeLabel(value),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => type = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _row(
                        _number(
                          quantity,
                          type == AtlasInventoryMovementType.adjustment
                              ? 'Nova quantidade'
                              : 'Quantidade',
                        ),
                        _number(unitCost, 'Custo unitário'),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Saldo atual: '
                          '${selectedItem.currentQuantity.toStringAsFixed(2)} '
                          '${selectedItem.unit}',
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(occurredAt),
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: dialogContext,
                            initialDate: occurredAt,
                            firstDate: DateTime(2010),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setDialogState(() => occurredAt = selected);
                          }
                        },
                      ),
                      TextField(
                        controller: responsible,
                        decoration: const InputDecoration(
                          labelText: 'Responsável',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: reference,
                        decoration: const InputDecoration(
                          labelText: 'Referência',
                          hintText: 'Nota fiscal, ordem, tratamento',
                          border: OutlineInputBorder(),
                        ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = _double(quantity.text);
                    if (amount <= 0) {
                      return;
                    }
                    final selectedItem = items.firstWhere(
                      (item) => item.id == itemId,
                    );
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasInventoryMovement(
                        id:
                            'inventory_movement_'
                            '${now.microsecondsSinceEpoch}',
                        itemId: itemId,
                        batchId: null,
                        type: type,
                        quantity: amount,
                        unitCost: _double(unitCost.text) > 0
                            ? _double(unitCost.text)
                            : selectedItem.averageUnitCost,
                        occurredAt: occurredAt,
                        sourceLocationId: selectedItem.locationId,
                        destinationLocationId: null,
                        responsibleName: responsible.text.trim(),
                        reference: reference.text.trim(),
                        notes: notes.text.trim(),
                        farmName: widget.actionController.farmName,
                      ),
                    );
                  },
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );

    quantity.dispose();
    unitCost.dispose();
    responsible.dispose();
    reference.dispose();
    notes.dispose();

    if (result != null) {
      await service.registerMovement(result);
      await _load();
    }
  }

  Future<void> _addBatch() async {
    if (items.isEmpty) {
      return;
    }

    var itemId = items.first.id;
    String? supplierId;
    String? locationId;
    final number = TextEditingController();
    final quantity = TextEditingController();
    final unitCost = TextEditingController();
    DateTime? manufacturedAt;
    DateTime? expiresAt;
    var receivedAt = DateTime.now();

    final result = await showDialog<AtlasInventoryBatch>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo lote'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: itemId,
                        decoration: const InputDecoration(
                          labelText: 'Item',
                          border: OutlineInputBorder(),
                        ),
                        items: items
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => itemId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: number,
                        decoration: const InputDecoration(
                          labelText: 'Número do lote',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _row(
                        _number(quantity, 'Quantidade'),
                        _number(unitCost, 'Custo unitário'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: supplierId,
                        decoration: const InputDecoration(
                          labelText: 'Fornecedor',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sem fornecedor'),
                          ),
                          ...suppliers.map(
                            (supplier) => DropdownMenuItem<String?>(
                              value: supplier.id,
                              child: Text(supplier.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => supplierId = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: locationId,
                        decoration: const InputDecoration(
                          labelText: 'Almoxarifado',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sem localização'),
                          ),
                          ...locations.map(
                            (location) => DropdownMenuItem<String?>(
                              value: location.id,
                              child: Text(location.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => locationId = value);
                        },
                      ),
                      _DateSelector(
                        title: 'Fabricação',
                        date: manufacturedAt,
                        onSelect: () async {
                          final selected = await showDatePicker(
                            context: dialogContext,
                            initialDate: manufacturedAt ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setDialogState(() => manufacturedAt = selected);
                          }
                        },
                      ),
                      _DateSelector(
                        title: 'Validade',
                        date: expiresAt,
                        onSelect: () async {
                          final selected = await showDatePicker(
                            context: dialogContext,
                            initialDate:
                                expiresAt ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setDialogState(() => expiresAt = selected);
                          }
                        },
                      ),
                      _DateSelector(
                        title: 'Recebimento',
                        date: receivedAt,
                        onSelect: () async {
                          final selected = await showDatePicker(
                            context: dialogContext,
                            initialDate: receivedAt,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setDialogState(() => receivedAt = selected);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (number.text.trim().isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasInventoryBatch(
                        id:
                            'inventory_batch_'
                            '${now.microsecondsSinceEpoch}',
                        itemId: itemId,
                        batchNumber: number.text.trim(),
                        manufacturedAt: manufacturedAt,
                        expiresAt: expiresAt,
                        quantity: _double(quantity.text),
                        unitCost: _double(unitCost.text),
                        supplierId: supplierId,
                        locationId: locationId,
                        receivedAt: receivedAt,
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

    number.dispose();
    quantity.dispose();
    unitCost.dispose();

    if (result != null) {
      await service.saveBatch(result);
      if (result.quantity > 0) {
        await service.registerMovement(
          AtlasInventoryMovement(
            id:
                'batch_entry_'
                '${DateTime.now().microsecondsSinceEpoch}',
            itemId: result.itemId,
            batchId: result.id,
            type: AtlasInventoryMovementType.entry,
            quantity: result.quantity,
            unitCost: result.unitCost,
            occurredAt: result.receivedAt,
            sourceLocationId: null,
            destinationLocationId: result.locationId,
            responsibleName: '',
            reference: 'Entrada do lote ${result.batchNumber}',
            notes: 'Entrada gerada pelo cadastro de lote.',
            farmName: result.farmName,
          ),
        );
      }
      await _load();
    }
  }

  Future<void> _createPurchaseOrder({AtlasPurchaseOrder? suggestion}) async {
    if (items.isEmpty) {
      return;
    }

    String? supplierId = suggestion?.supplierId;
    var status = suggestion?.status ?? AtlasPurchaseOrderStatus.requested;
    final responsible = TextEditingController(
      text: suggestion?.responsibleName ?? '',
    );
    final notes = TextEditingController(text: suggestion?.notes ?? '');
    DateTime? expectedAt =
        suggestion?.expectedAt ?? DateTime.now().add(const Duration(days: 7));
    final quantities = <String, TextEditingController>{
      for (final item in items)
        item.id: TextEditingController(
          text: _suggestedQuantity(suggestion, item.id),
        ),
    };
    final costs = <String, TextEditingController>{
      for (final item in items)
        item.id: TextEditingController(
          text: item.averageUnitCost > 0 ? item.averageUnitCost.toString() : '',
        ),
    };

    final result = await showDialog<AtlasPurchaseOrder>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pedido de compra'),
              content: SizedBox(
                width: 700,
                height: 640,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: supplierId,
                      decoration: const InputDecoration(
                        labelText: 'Fornecedor',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sem fornecedor'),
                        ),
                        ...suppliers.map(
                          (supplier) => DropdownMenuItem<String?>(
                            value: supplier.id,
                            child: Text(supplier.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => supplierId = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AtlasPurchaseOrderStatus>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Situação',
                        border: OutlineInputBorder(),
                      ),
                      items: AtlasPurchaseOrderStatus.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(atlasPurchaseOrderStatusLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: responsible,
                      decoration: const InputDecoration(
                        labelText: 'Responsável',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    _DateSelector(
                      title: 'Previsão de entrega',
                      date: expectedAt,
                      onSelect: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: expectedAt ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(() => expectedAt = selected);
                        }
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Itens do pedido',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(item.name)),
                            Expanded(
                              child: _number(
                                quantities[item.id]!,
                                'Quantidade',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _number(costs[item.id]!, 'Custo unit.'),
                            ),
                          ],
                        ),
                      ),
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
                    final lines = items
                        .where((item) => _double(quantities[item.id]!.text) > 0)
                        .map(
                          (item) => AtlasPurchaseOrderLine(
                            itemId: item.id,
                            quantity: _double(quantities[item.id]!.text),
                            unitCost: _double(costs[item.id]!.text),
                          ),
                        )
                        .toList();
                    if (lines.isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasPurchaseOrder(
                        id:
                            suggestion?.id ??
                            'purchase_order_'
                                '${now.microsecondsSinceEpoch}',
                        supplierId: supplierId,
                        status: status,
                        createdAt: suggestion?.createdAt ?? now,
                        expectedAt: expectedAt,
                        receivedAt: status == AtlasPurchaseOrderStatus.received
                            ? now
                            : null,
                        lines: lines,
                        responsibleName: responsible.text.trim(),
                        notes: notes.text.trim(),
                        farmName: widget.actionController.farmName,
                      ),
                    );
                  },
                  child: const Text('Salvar pedido'),
                ),
              ],
            );
          },
        );
      },
    );

    responsible.dispose();
    notes.dispose();
    for (final controller in quantities.values) {
      controller.dispose();
    }
    for (final controller in costs.values) {
      controller.dispose();
    }

    if (result != null) {
      await service.savePurchaseOrder(result);
      await _load();
    }
  }

  Future<void> _processAutomaticConsumption() async {
    setState(() => isProcessingConsumption = true);
    final count = await service.processAutomaticConsumption(
      farmName: widget.actionController.farmName,
    );
    await _load();

    if (!mounted) {
      return;
    }

    setState(() => isProcessingConsumption = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'O consumo automático de hoje já foi processado.'
              : '$count item(ns) atualizado(s) pelo consumo automático.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = service.buildAlerts(
      items: items,
      batches: batches,
      orders: purchaseOrders,
    );
    final suggestions = service.buildRestockSuggestions(items: items);

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão inteligente de estoque'),
          actions: [
            IconButton(
              tooltip: 'Processar consumo automático',
              onPressed: isProcessingConsumption
                  ? null
                  : _processAutomaticConsumption,
              icon: isProcessingConsumption
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_mode),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Resumo', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Almoxarifado', icon: Icon(Icons.warehouse_outlined)),
              Tab(text: 'Movimentações', icon: Icon(Icons.swap_vert)),
              Tab(text: 'Inventário', icon: Icon(Icons.inventory_outlined)),
              Tab(
                text: 'Validade e lotes',
                icon: Icon(Icons.event_busy_outlined),
              ),
              Tab(text: 'Compras', icon: Icon(Icons.shopping_cart_outlined)),
              Tab(
                text: 'Fornecedores',
                icon: Icon(Icons.local_shipping_outlined),
              ),
              Tab(text: 'Reposição', icon: Icon(Icons.auto_awesome)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _registerMovement(),
          icon: const Icon(Icons.add),
          label: const Text('Movimentar estoque'),
        ),
        body: isLoading && items.isEmpty && locations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _InventorySummaryTab(summary: summary, alerts: alerts),
                  _WarehouseTab(
                    locations: locations,
                    items: items,
                    onAddLocation: () => _editLocation(),
                    onEditLocation: (location) =>
                        _editLocation(location: location),
                    onAddItem: () => _editItem(),
                    onEditItem: (item) => _editItem(item: item),
                  ),
                  _MovementsTab(
                    movements: movements,
                    items: items,
                    onEntry: () => _registerMovement(
                      initialType: AtlasInventoryMovementType.entry,
                    ),
                    onExit: () => _registerMovement(
                      initialType: AtlasInventoryMovementType.exit,
                    ),
                  ),
                  _PhysicalInventoryTab(
                    items: items,
                    onAdjust: () => _registerMovement(
                      initialType: AtlasInventoryMovementType.adjustment,
                    ),
                  ),
                  _BatchesTab(batches: batches, items: items, onAdd: _addBatch),
                  _PurchasesTab(
                    orders: purchaseOrders,
                    suppliers: suppliers,
                    onAdd: () => _createPurchaseOrder(),
                    onEdit: (order) => _createPurchaseOrder(suggestion: order),
                  ),
                  _SuppliersTab(
                    suppliers: suppliers,
                    onAdd: () => _editSupplier(),
                    onEdit: (supplier) => _editSupplier(supplier: supplier),
                  ),
                  _RestockTab(
                    items: items,
                    suggestions: suggestions,
                    onCreateOrder: (suggestion) =>
                        _createPurchaseOrder(suggestion: suggestion),
                  ),
                ],
              ),
      ),
    );
  }

  static String _suggestedQuantity(AtlasPurchaseOrder? order, String itemId) {
    if (order == null) {
      return '';
    }
    for (final line in order.lines) {
      if (line.itemId == itemId) {
        return line.quantity.toString();
      }
    }
    return '';
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

class _InventorySummaryTab extends StatelessWidget {
  const _InventorySummaryTab({required this.summary, required this.alerts});

  final AtlasInventorySummary summary;
  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InventoryMetric(
              title: 'Itens ativos',
              value: summary.totalItems.toDouble(),
              unit: '',
            ),
            _InventoryMetric(
              title: 'Valor do estoque',
              value: summary.totalStockValue,
              unit: 'R\$',
            ),
            _InventoryMetric(
              title: 'Estoque baixo',
              value: summary.lowStockItems.toDouble(),
              unit: '',
            ),
            _InventoryMetric(
              title: 'Lotes a vencer',
              value: summary.expiringBatches.toDouble(),
              unit: '',
            ),
            _InventoryMetric(
              title: 'Lotes vencidos',
              value: summary.expiredBatches.toDouble(),
              unit: '',
            ),
            _InventoryMetric(
              title: 'Pedidos abertos',
              value: summary.openPurchaseOrders.toDouble(),
              unit: '',
            ),
            _InventoryMetric(
              title: 'Entradas no mês',
              value: summary.monthlyEntriesValue,
              unit: 'R\$',
            ),
            _InventoryMetric(
              title: 'Saídas no mês',
              value: summary.monthlyExitsValue,
              unit: 'R\$',
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Alertas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...alerts.map(
          (alert) => Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: Text(alert),
            ),
          ),
        ),
      ],
    );
  }
}

class _WarehouseTab extends StatelessWidget {
  const _WarehouseTab({
    required this.locations,
    required this.items,
    required this.onAddLocation,
    required this.onEditLocation,
    required this.onAddItem,
    required this.onEditItem,
  });

  final List<AtlasInventoryLocation> locations;
  final List<AtlasInventoryItem> items;
  final VoidCallback onAddLocation;
  final ValueChanged<AtlasInventoryLocation> onEditLocation;
  final VoidCallback onAddItem;
  final ValueChanged<AtlasInventoryItem> onEditItem;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Almoxarifados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddLocation,
              icon: const Icon(Icons.add),
              label: const Text('Novo local'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...locations.map(
          (location) => Card(
            child: ListTile(
              onTap: () => onEditLocation(location),
              leading: const Icon(Icons.warehouse_outlined),
              title: Text(location.name),
              subtitle: Text(
                '${location.description}'
                '${location.responsibleName.isEmpty ? '' : ' • ${location.responsibleName}'}',
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Itens armazenados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Novo item'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Card(
            child: ListTile(
              onTap: () => onEditItem(item),
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(
                '${item.code.isEmpty ? '' : '${item.code} — '}${item.name}',
              ),
              subtitle: Text(
                '${atlasInventoryItemCategoryLabel(item.category)} • '
                'R\$ ${item.averageUnitCost.toStringAsFixed(2)} por ${item.unit}',
              ),
              trailing: Text(
                '${item.currentQuantity.toStringAsFixed(2)} ${item.unit}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: item.needsRestock
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MovementsTab extends StatelessWidget {
  const _MovementsTab({
    required this.movements,
    required this.items,
    required this.onEntry,
    required this.onExit,
  });

  final List<AtlasInventoryMovement> movements;
  final List<AtlasInventoryItem> items;
  final VoidCallback onEntry;
  final VoidCallback onExit;

  String itemName(String id) {
    for (final item in items) {
      if (item.id == id) {
        return item.name;
      }
    }
    return 'Item';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                onPressed: onEntry,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Entrada'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onExit,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Saída'),
              ),
            ],
          ),
        ),
        Expanded(
          child: movements.isEmpty
              ? const Center(child: Text('Nenhuma movimentação registrada.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: movements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            movement.type == AtlasInventoryMovementType.entry
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                          ),
                        ),
                        title: Text(
                          '${itemName(movement.itemId)} — '
                          '${atlasInventoryMovementTypeLabel(movement.type)}',
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(movement.occurredAt)}'
                          '${movement.reference.isEmpty ? '' : ' • ${movement.reference}'}',
                        ),
                        trailing: Text(
                          movement.quantity.toStringAsFixed(2),
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

class _PhysicalInventoryTab extends StatelessWidget {
  const _PhysicalInventoryTab({required this.items, required this.onAdjust});

  final List<AtlasInventoryItem> items;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text(
            'Inventário físico',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: const Text('Compare a contagem física e ajuste o saldo.'),
          trailing: FilledButton.icon(
            onPressed: onAdjust,
            icon: const Icon(Icons.tune),
            label: const Text('Ajustar'),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Nenhum item cadastrado.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.fact_check),
                        title: Text(item.name),
                        subtitle: Text(
                          'Mínimo ${item.minimumQuantity.toStringAsFixed(2)} • '
                          'Máximo ${item.maximumQuantity.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          '${item.currentQuantity.toStringAsFixed(2)} ${item.unit}',
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

class _BatchesTab extends StatelessWidget {
  const _BatchesTab({
    required this.batches,
    required this.items,
    required this.onAdd,
  });

  final List<AtlasInventoryBatch> batches;
  final List<AtlasInventoryItem> items;
  final VoidCallback onAdd;

  String itemName(String id) {
    for (final item in items) {
      if (item.id == id) {
        return item.name;
      }
    }
    return 'Item';
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
              label: const Text('Novo lote'),
            ),
          ),
        ),
        Expanded(
          child: batches.isEmpty
              ? const Center(child: Text('Nenhum lote cadastrado.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: batches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final batch = batches[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.qr_code_2),
                        title: Text(
                          '${itemName(batch.itemId)} — lote ${batch.batchNumber}',
                        ),
                        subtitle: Text(
                          batch.expiresAt == null
                              ? 'Sem validade informada'
                              : 'Validade: '
                                    '${DateFormat('dd/MM/yyyy').format(batch.expiresAt!)}',
                        ),
                        trailing: Text(
                          batch.quantity.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: batch.isExpired
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

class _PurchasesTab extends StatelessWidget {
  const _PurchasesTab({
    required this.orders,
    required this.suppliers,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasPurchaseOrder> orders;
  final List<AtlasSupplier> suppliers;
  final VoidCallback onAdd;
  final ValueChanged<AtlasPurchaseOrder> onEdit;

  String supplierName(String? id) {
    if (id == null) {
      return 'Sem fornecedor';
    }
    for (final supplier in suppliers) {
      if (supplier.id == id) {
        return supplier.name;
      }
    }
    return 'Fornecedor';
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
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Novo pedido'),
            ),
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const Center(child: Text('Nenhum pedido de compra.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(order),
                        leading: const Icon(Icons.shopping_cart_checkout),
                        title: Text(supplierName(order.supplierId)),
                        subtitle: Text(
                          '${atlasPurchaseOrderStatusLabel(order.status)} • '
                          '${order.lines.length} item(ns)',
                        ),
                        trailing: Text(
                          'R\$ ${order.totalValue.toStringAsFixed(2)}',
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

class _SuppliersTab extends StatelessWidget {
  const _SuppliersTab({
    required this.suppliers,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AtlasSupplier> suppliers;
  final VoidCallback onAdd;
  final ValueChanged<AtlasSupplier> onEdit;

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
              label: const Text('Novo fornecedor'),
            ),
          ),
        ),
        Expanded(
          child: suppliers.isEmpty
              ? const Center(child: Text('Nenhum fornecedor cadastrado.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(supplier),
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: Text(supplier.name),
                        subtitle: Text(
                          '${supplier.phone}'
                          '${supplier.email.isEmpty ? '' : ' • ${supplier.email}'}',
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

class _RestockTab extends StatelessWidget {
  const _RestockTab({
    required this.items,
    required this.suggestions,
    required this.onCreateOrder,
  });

  final List<AtlasInventoryItem> items;
  final List<AtlasPurchaseOrder> suggestions;
  final ValueChanged<AtlasPurchaseOrder> onCreateOrder;

  String itemName(String id) {
    for (final item in items) {
      if (item.id == id) {
        return item.name;
      }
    }
    return 'Item';
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = items.where((item) => item.needsRestock).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Itens que precisam de reposição',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (lowStock.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Nenhum item abaixo do estoque mínimo.'),
            ),
          ),
        ...lowStock.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(item.name),
              subtitle: Text(
                'Atual ${item.currentQuantity.toStringAsFixed(2)} • '
                'mínimo ${item.minimumQuantity.toStringAsFixed(2)}',
              ),
              trailing: Text(
                'Comprar ${item.suggestedPurchaseQuantity.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Pedidos sugeridos pelo Atlas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (suggestions.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('Nenhuma sugestão de compra necessária.'),
            ),
          ),
        ...suggestions.map(
          (suggestion) => Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text('${suggestion.lines.length} item(ns) para reposição'),
              subtitle: Text(
                suggestion.lines
                    .map(
                      (line) =>
                          '${itemName(line.itemId)}: ${line.quantity.toStringAsFixed(2)}',
                    )
                    .join(' • '),
              ),
              trailing: FilledButton(
                onPressed: () => onCreateOrder(suggestion),
                child: const Text('Criar pedido'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InventoryMetric extends StatelessWidget {
  const _InventoryMetric({
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
                '${value.toStringAsFixed(unit.isEmpty ? 0 : 2)}',
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
