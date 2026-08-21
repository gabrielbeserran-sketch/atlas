import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/services/farm_inventory_event_service.dart';
import 'package:projeto_atlas/features/farm_inventory/presentation/screens/farm_inventory_form_screen.dart';

class _InventoryMovementResult {
  const _InventoryMovementResult({
    required this.newQuantity,
    required this.movementQuantity,
    required this.movementType,
    required this.registerFinancialExpense,
  });

  final double newQuantity;
  final double movementQuantity;
  final String movementType;
  final bool registerFinancialExpense;
}

class FarmInventoryListScreen extends StatefulWidget {
  const FarmInventoryListScreen({
    required this.farm,
    this.autoOpenCreate = false,
    super.key,
  });

  final FarmData farm;
  final bool autoOpenCreate;

  @override
  State<FarmInventoryListScreen> createState() {
    return _FarmInventoryListScreenState();
  }
}

class _FarmInventoryListScreenState extends State<FarmInventoryListScreen> {
  final FarmInventoryStorageService storage = FarmInventoryStorageService();
  final FarmFinanceStorageService financeStorage = FarmFinanceStorageService();

  final FarmInventoryEventService eventService =
      const FarmInventoryEventService();

  List<FarmInventoryData> items = [];

  bool isLoading = true;

  String selectedFilter = 'Todos';
  String searchText = '';

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await loadItems();
    if (widget.autoOpenCreate && mounted) {
      await openItemForm();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<FarmInventoryData> get visibleItems {
    return items.where((item) {
      final normalizedSearch = searchText.trim().toLowerCase();

      final matchesSearch =
          normalizedSearch.isEmpty ||
          item.name.toLowerCase().contains(normalizedSearch) ||
          item.category.toLowerCase().contains(normalizedSearch) ||
          item.supplier.toLowerCase().contains(normalizedSearch) ||
          item.internalCode.toLowerCase().contains(normalizedSearch) ||
          item.barcode.toLowerCase().contains(normalizedSearch) ||
          item.brand.toLowerCase().contains(normalizedSearch) ||
          item.manufacturer.toLowerCase().contains(normalizedSearch) ||
          item.batch.toLowerCase().contains(normalizedSearch);

      if (!matchesSearch) {
        return false;
      }

      if (selectedFilter == 'Estoque baixo') {
        return item.hasLowStock;
      }

      if (selectedFilter == 'Vencidos') {
        return expirationStatus(item) == InventoryExpirationStatus.expired;
      }

      if (selectedFilter == 'Vencimento próximo') {
        return expirationStatus(item) ==
            InventoryExpirationStatus.nearExpiration;
      }

      return true;
    }).toList();
  }

  int get lowStockCount {
    return items.where((item) {
      return item.hasLowStock;
    }).length;
  }

  int get expiredCount {
    return items.where((item) {
      return expirationStatus(item) == InventoryExpirationStatus.expired;
    }).length;
  }

  int get nearExpirationCount {
    return items.where((item) {
      return expirationStatus(item) == InventoryExpirationStatus.nearExpiration;
    }).length;
  }

  double get totalInventoryValue {
    return items.fold<double>(0, (total, item) {
      return total + item.totalValue;
    });
  }

  Future<void> loadItems() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
      final savedItems = await storage
          .loadItems(widget.farm.name, farmId: widget.farm.id ?? '')
          .timeout(const Duration(seconds: 8));
      if (!mounted) {
        return;
      }
      setState(() {
        items = savedItems;
        sortItems();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível carregar o Estoque: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> saveItems() async {
    await storage.saveItems(farmName: widget.farm.name, items: items);
  }

  Future<void> openItemForm() async {
    final newItem = await Navigator.push<FarmInventoryData>(
      context,
      MaterialPageRoute<FarmInventoryData>(
        builder: (context) {
          return const FarmInventoryFormScreen();
        },
      ),
    );

    if (newItem == null || !mounted) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    final savedItem = farmId.isEmpty
        ? newItem
        : await storage.createItem(
            farmName: widget.farm.name,
            farmId: farmId,
            item: newItem,
          );
    if (!mounted) {
      return;
    }
    setState(() {
      items.add(savedItem);
      sortItems();
    });

    if (farmId.isEmpty) {
      await saveItems();
    }

    await eventService.publishItemCreated(
      farmName: widget.farm.name,
      item: newItem,
      totalInventoryValue: totalInventoryValue,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produto cadastrado no estoque.')),
    );
  }

  Future<void> editItem(FarmInventoryData item) async {
    final editedItem = await Navigator.push<FarmInventoryData>(
      context,
      MaterialPageRoute<FarmInventoryData>(
        builder: (context) {
          return FarmInventoryFormScreen(item: item);
        },
      ),
    );

    if (editedItem == null || !mounted) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    final savedItem = farmId.isEmpty
        ? editedItem
        : await storage.updateItem(
            farmName: widget.farm.name,
            farmId: farmId,
            item: editedItem,
          );
    final itemIndex = items.indexWhere(
      (currentItem) => currentItem.id == item.id,
    );
    if (itemIndex == -1 || !mounted) {
      return;
    }

    setState(() {
      items[itemIndex] = savedItem;
      sortItems();
    });

    if (farmId.isEmpty) {
      await saveItems();
    }

    await eventService.publishItemUpdated(
      farmName: widget.farm.name,
      previousItem: item,
      updatedItem: savedItem,
      totalInventoryValue: totalInventoryValue,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Produto atualizado.')));
  }

  Future<void> changeQuantity(FarmInventoryData item) async {
    final controller = TextEditingController();

    String movementType = 'Entrada';
    bool registerFinancialExpense = true;

    final result = await showDialog<_InventoryMovementResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Movimentar estoque'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'Entrada',
                          label: Text('Entrada'),
                          icon: Icon(Icons.add_circle_outline),
                        ),
                        ButtonSegment<String>(
                          value: 'Saída',
                          label: Text('Saída'),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                      ],
                      selected: {movementType},
                      onSelectionChanged: (selection) {
                        setDialogState(() {
                          movementType = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Quantidade da movimentação',
                        suffixText: item.unit,
                        prefixIcon: const Icon(Icons.numbers_outlined),
                      ),
                    ),
                    if (movementType == 'Entrada') ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: registerFinancialExpense,
                        onChanged: (value) {
                          setDialogState(() {
                            registerFinancialExpense = value ?? true;
                          });
                        },
                        title: const Text('Registrar despesa no Financeiro'),
                        subtitle: Text(
                          'Valor unitário atual: ${formatCurrency(item.unitValue)}',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = parseNumber(controller.text);

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Digite uma quantidade válida.'),
                        ),
                      );
                      return;
                    }

                    final newQuantity = movementType == 'Entrada'
                        ? item.quantity + amount
                        : item.quantity - amount;

                    if (newQuantity < 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A saída é maior que o estoque disponível.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _InventoryMovementResult(
                        newQuantity: newQuantity,
                        movementQuantity: amount,
                        movementType: movementType,
                        registerFinancialExpense:
                            movementType == 'Entrada' &&
                            registerFinancialExpense,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == null || !mounted) {
      return;
    }

    final itemIndex = items.indexWhere((currentItem) {
      return currentItem.id == item.id;
    });

    if (itemIndex == -1) {
      return;
    }

    final movement = FarmInventoryMovement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: result.movementType,
      quantity: result.movementQuantity,
      date: formatDate(DateTime.now()),
      responsible: 'Usuário Atlas',
      reason: result.movementType == 'Entrada'
          ? 'Compra ou reposição de estoque'
          : 'Movimentação manual',
      document: item.purchaseDocument,
      unitValue: item.unitValue,
    );

    final updatedItem = item.copyWith(
      quantity: result.newQuantity,
      lastPurchaseValue: result.movementType == 'Entrada'
          ? item.unitValue
          : item.lastPurchaseValue,
      movements: <FarmInventoryMovement>[movement, ...item.movements],
    );

    final farmId = widget.farm.id ?? '';
    final persistedItem = farmId.isEmpty
        ? updatedItem
        : await storage.registerMovement(
            farmName: widget.farm.name,
            item: item,
            movement: movement,
          );
    if (!mounted) {
      return;
    }
    setState(() {
      items[itemIndex] = persistedItem;
    });

    if (farmId.isEmpty) {
      await saveItems();
    }

    if (result.registerFinancialExpense && item.unitValue > 0) {
      await registerInventoryExpense(item: item, movement: movement);
    }

    await eventService.publishItemUpdated(
      farmName: widget.farm.name,
      previousItem: item,
      updatedItem: persistedItem,
      totalInventoryValue: totalInventoryValue,
      reason: 'Quantidade do estoque atualizada',
    );

    if (!mounted) {
      return;
    }

    final message = result.registerFinancialExpense && item.unitValue > 0
        ? 'Entrada registrada no Estoque e no Financeiro.'
        : 'Quantidade atualizada.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> registerInventoryExpense({
    required FarmInventoryData item,
    required FarmInventoryMovement movement,
  }) async {
    final farmId = widget.farm.id ?? '';
    final records = await financeStorage.loadRecords(
      widget.farm.name,
      farmId: farmId,
    );
    final amount = movement.quantity * movement.unitValue;
    final now = DateTime.now();
    final formattedDate = formatDate(now);
    final competence =
        '${now.month.toString().padLeft(2, '0')}/${now.year.toString()}';

    final expense = FarmFinanceData(
      id: 'inventory_${movement.id}',
      type: 'Despesa',
      category: inventoryFinanceCategory(item.category),
      date: formattedDate,
      description:
          'Compra de estoque: ${item.name} (${formatNumber(movement.quantity)} ${item.unit})',
      amount: amount,
      paymentMethod: 'Não informado',
      notes: 'Lançamento automático gerado pelo módulo Estoque.',
      status: 'Pago',
      dueDate: formattedDate,
      paymentDate: formattedDate,
      competence: competence,
      costCenter: inventoryCostCenter(item.category),
      counterparty: item.supplier,
      documentNumber: item.purchaseDocument,
    );

    final alreadyExists = farmId.isNotEmpty
        ? await financeStorage.hasReference(
            farmId: farmId,
            referenceType: 'inventory_movement',
            referenceId: movement.id,
          )
        : records.any((record) => record.id == expense.id);
    if (alreadyExists) {
      return;
    }

    if (farmId.isNotEmpty) {
      await financeStorage.createRecord(
        farmName: widget.farm.name,
        farmId: farmId,
        record: expense,
        referenceType: 'inventory_movement',
        referenceId: movement.id,
      );
    } else {
      await financeStorage.saveRecords(
        farmName: widget.farm.name,
        records: <FarmFinanceData>[expense, ...records],
      );
    }
  }

  String inventoryFinanceCategory(String inventoryCategory) {
    final value = inventoryCategory.toLowerCase();
    if (value.contains('medic') || value.contains('vacina')) {
      return 'Sanidade';
    }
    if (value.contains('ração') ||
        value.contains('suplement') ||
        value.contains('aliment')) {
      return 'Nutrição';
    }
    if (value.contains('fertiliz') || value.contains('semente')) {
      return 'Pastagens';
    }
    if (value.contains('equip') || value.contains('máquina')) {
      return 'Máquinas e equipamentos';
    }
    return 'Insumos';
  }

  String inventoryCostCenter(String inventoryCategory) {
    final value = inventoryCategory.toLowerCase();
    if (value.contains('medic') || value.contains('vacina')) {
      return 'Sanidade';
    }
    if (value.contains('ração') ||
        value.contains('suplement') ||
        value.contains('aliment')) {
      return 'Nutrição';
    }
    if (value.contains('fertiliz') || value.contains('semente')) {
      return 'Pastagens';
    }
    if (value.contains('equip') || value.contains('máquina')) {
      return 'Máquinas';
    }
    return 'Geral';
  }

  Future<void> deleteItem(FarmInventoryData item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir produto'),
          content: Text('Deseja excluir ${item.name} do estoque?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    if (farmId.isNotEmpty) {
      await storage.deleteItem(farmName: widget.farm.name, productId: item.id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      items.removeWhere((currentItem) => currentItem.id == item.id);
    });

    if (farmId.isEmpty) {
      await saveItems();
    }

    await eventService.publishItemDeleted(
      farmName: widget.farm.name,
      deletedItem: item,
      totalInventoryValue: totalInventoryValue,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Produto excluído.')));
  }

  void sortItems() {
    items.sort((first, second) {
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = visibleItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : loadItems,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openItemForm,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadItems,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        InventoryHeader(
                          farm: widget.farm,
                          productCount: items.length,
                          totalValue: totalInventoryValue,
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            InventorySummaryCard(
                              title: 'Produtos',
                              value: items.length.toString(),
                              icon: Icons.inventory_2_outlined,
                              color: const Color(0xFF1B5E20),
                            ),
                            InventorySummaryCard(
                              title: 'Estoque baixo',
                              value: lowStockCount.toString(),
                              icon: Icons.warning_amber_outlined,
                              color: lowStockCount > 0
                                  ? const Color(0xFFEF6C00)
                                  : const Color(0xFF1B5E20),
                            ),
                            InventorySummaryCard(
                              title: 'Vencidos',
                              value: expiredCount.toString(),
                              icon: Icons.event_busy_outlined,
                              color: expiredCount > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                            InventorySummaryCard(
                              title: 'Próximos do vencimento',
                              value: nearExpirationCount.toString(),
                              icon: Icons.schedule_outlined,
                              color: nearExpirationCount > 0
                                  ? const Color(0xFFEF6C00)
                                  : const Color(0xFF1B5E20),
                            ),
                            InventorySummaryCard(
                              title: 'Valor do estoque',
                              value: formatCurrency(totalInventoryValue),
                              icon: Icons.account_balance_wallet_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchText = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Pesquisar produto',
                            hintText: 'Nome, categoria ou fornecedor',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            InventoryFilterChip(
                              label: 'Todos',
                              selected: selectedFilter == 'Todos',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Todos';
                                });
                              },
                            ),
                            InventoryFilterChip(
                              label: 'Estoque baixo',
                              selected: selectedFilter == 'Estoque baixo',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Estoque baixo';
                                });
                              },
                            ),
                            InventoryFilterChip(
                              label: 'Vencidos',
                              selected: selectedFilter == 'Vencidos',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Vencidos';
                                });
                              },
                            ),
                            InventoryFilterChip(
                              label: 'Vencimento próximo',
                              selected: selectedFilter == 'Vencimento próximo',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Vencimento próximo';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Produtos cadastrados',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${filteredItems.length} produtos',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Controle de quantidades, valores e validades.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        if (filteredItems.isEmpty)
                          EmptyInventoryMessage(
                            hasFilter:
                                selectedFilter != 'Todos' ||
                                searchText.trim().isNotEmpty,
                          )
                        else
                          ...filteredItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: InventoryItemCard(
                                item: item,
                                expirationStatus: expirationStatus(item),
                                onEdit: () {
                                  editItem(item);
                                },
                                onMove: () {
                                  changeQuantity(item);
                                },
                                onDelete: () {
                                  deleteItem(item);
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class InventoryHeader extends StatelessWidget {
  const InventoryHeader({
    required this.farm,
    required this.productCount,
    required this.totalValue,
    super.key,
  });

  final FarmData farm;
  final int productCount;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestão de estoque',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  farm.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${farm.city} - ${farm.state}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              InventoryHeaderMetric(
                value: productCount.toString(),
                label: 'produtos',
              ),
              InventoryHeaderMetric(
                value: formatCompactCurrency(totalValue),
                label: 'valor',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InventoryHeaderMetric extends StatelessWidget {
  const InventoryHeaderMetric({
    required this.value,
    required this.label,
    super.key,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class InventorySummaryCard extends StatelessWidget {
  const InventorySummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 205,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryFilterChip extends StatelessWidget {
  const InventoryFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onSelected();
      },
    );
  }
}

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    required this.item,
    required this.expirationStatus,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    super.key,
  });

  final FarmInventoryData item;
  final InventoryExpirationStatus expirationStatus;
  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = inventoryStatusColor(item, expirationStatus);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  categoryIcon(item.category),
                  color: statusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.category,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 18,
                      runSpacing: 9,
                      children: [
                        InventoryInformation(
                          icon: Icons.inventory_outlined,
                          text: '${formatNumber(item.quantity)} ${item.unit}',
                        ),
                        InventoryInformation(
                          icon: Icons.account_balance_wallet_outlined,
                          text: formatCurrency(item.totalValue),
                        ),
                        if (item.supplier.isNotEmpty)
                          InventoryInformation(
                            icon: Icons.business_outlined,
                            text: item.supplier,
                          ),
                        if (item.batch.isNotEmpty)
                          InventoryInformation(
                            icon: Icons.qr_code_outlined,
                            text: 'Lote ${item.batch}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (item.hasLowStock)
                          InventoryStatusBadge(
                            label: 'Estoque baixo',
                            icon: Icons.warning_amber_outlined,
                            color: const Color(0xFFEF6C00),
                          ),
                        if (expirationStatus ==
                            InventoryExpirationStatus.expired)
                          InventoryStatusBadge(
                            label: 'Vencido',
                            icon: Icons.event_busy_outlined,
                            color: Colors.red.shade700,
                          ),
                        if (expirationStatus ==
                            InventoryExpirationStatus.nearExpiration)
                          const InventoryStatusBadge(
                            label: 'Próximo do vencimento',
                            icon: Icons.schedule_outlined,
                            color: Color(0xFFEF6C00),
                          ),
                        if (expirationStatus ==
                                InventoryExpirationStatus.valid &&
                            item.expirationDate.isNotEmpty)
                          InventoryStatusBadge(
                            label: 'Validade ${item.expirationDate}',
                            icon: Icons.event_outlined,
                            color: const Color(0xFF1B5E20),
                          ),
                      ],
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(item.notes, style: const TextStyle(height: 1.4)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${formatNumber(item.quantity)} ${item.unit}',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.minimumQuantity > 0)
                    Text(
                      'Mínimo: '
                      '${formatNumber(item.minimumQuantity)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (value) {
                  if (value == 'move') {
                    onMove();
                  }

                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'move',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_alt_outlined,
                            color: Color(0xFF1565C0),
                          ),
                          SizedBox(width: 10),
                          Text('Movimentar estoque'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Color(0xFF1B5E20)),
                          SizedBox(width: 10),
                          Text('Editar produto'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Excluir produto'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryInformation extends StatelessWidget {
  const InventoryInformation({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class InventoryStatusBadge extends StatelessWidget {
  const InventoryStatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyInventoryMessage extends StatelessWidget {
  const EmptyInventoryMessage({required this.hasFilter, super.key});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Color(0xFF1B5E20),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'Nenhum produto encontrado.'
                  : 'Nenhum produto no estoque.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Altere a pesquisa ou o filtro selecionado.'
                  : 'Cadastre o primeiro medicamento, insumo ou material.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

enum InventoryExpirationStatus { noExpiration, valid, nearExpiration, expired }

InventoryExpirationStatus expirationStatus(FarmInventoryData item) {
  if (item.expirationDate.trim().isEmpty) {
    return InventoryExpirationStatus.noExpiration;
  }

  final date = parseDate(item.expirationDate);

  if (date == null) {
    return InventoryExpirationStatus.noExpiration;
  }

  final today = DateTime.now();

  final normalizedToday = DateTime(today.year, today.month, today.day);

  final difference = date.difference(normalizedToday).inDays;

  if (difference < 0) {
    return InventoryExpirationStatus.expired;
  }

  if (difference <= 30) {
    return InventoryExpirationStatus.nearExpiration;
  }

  return InventoryExpirationStatus.valid;
}

Color inventoryStatusColor(
  FarmInventoryData item,
  InventoryExpirationStatus expirationStatus,
) {
  if (expirationStatus == InventoryExpirationStatus.expired) {
    return Colors.red.shade700;
  }

  if (item.hasLowStock ||
      expirationStatus == InventoryExpirationStatus.nearExpiration) {
    return const Color(0xFFEF6C00);
  }

  return const Color(0xFF1B5E20);
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Medicamento':
      return Icons.medication_outlined;
    case 'Vacina':
      return Icons.vaccines_outlined;
    case 'Vermífugo':
      return Icons.medical_services_outlined;
    case 'Ração':
      return Icons.grass_outlined;
    case 'Suplemento':
      return Icons.science_outlined;
    case 'Sal mineral':
      return Icons.agriculture_outlined;
    case 'Semente':
      return Icons.spa_outlined;
    case 'Combustível':
      return Icons.local_gas_station_outlined;
    case 'Material':
      return Icons.handyman_outlined;
    default:
      return Icons.inventory_2_outlined;
  }
}

DateTime? parseDate(String value) {
  final parts = value.trim().split('/');

  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return null;
  }

  final date = DateTime(year, month, day);

  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

double? parseNumber(String value) {
  var normalized = value.trim().replaceAll(' ', '');

  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (normalized.contains(',')) {
    normalized = normalized.replaceAll(',', '.');
  }

  return double.tryParse(normalized);
}

String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String formatCurrency(double value) {
  final parts = value.abs().toStringAsFixed(2).split('.');

  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();

  for (var index = 0; index < integerPart.length; index++) {
    final positionFromEnd = integerPart.length - index;

    buffer.write(integerPart[index]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},$decimalPart';
}

String formatCompactCurrency(double value) {
  if (value >= 1000000) {
    return 'R\$ ${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi';
  }

  if (value >= 1000) {
    return 'R\$ ${(value / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil';
  }

  return 'R\$ ${value.toStringAsFixed(0)}';
}
