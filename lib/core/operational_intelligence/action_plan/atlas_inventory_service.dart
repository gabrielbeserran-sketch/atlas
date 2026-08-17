import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_inventory_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasInventoryService {
  AtlasInventoryService._();

  static final AtlasInventoryService instance = AtlasInventoryService._();

  static const String _locationsKey = 'atlas_inventory_locations_v1';
  static const String _suppliersKey = 'atlas_inventory_suppliers_v1';
  static const String _itemsKey = 'atlas_inventory_items_v1';
  static const String _batchesKey = 'atlas_inventory_batches_v1';
  static const String _movementsKey = 'atlas_inventory_movements_v1';
  static const String _purchaseOrdersKey = 'atlas_purchase_orders_v1';
  static const String _lastAutomaticConsumptionKey =
      'atlas_inventory_last_automatic_consumption_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasInventoryLocation>> loadLocations({String? farmName}) async {
    final all = await _decodeList(
      _locationsKey,
      AtlasInventoryLocation.fromMap,
    );
    if (all.isEmpty) {
      final defaults = <AtlasInventoryLocation>[
        AtlasInventoryLocation(
          id: 'inventory_location_main',
          name: 'Almoxarifado principal',
          description: 'Local principal de armazenamento.',
          responsibleName: '',
          farmName: farmName,
          active: true,
        ),
      ];
      await _saveList(
        _locationsKey,
        defaults.map((item) => item.toMap()).toList(),
      );
      return defaults;
    }
    return _filterFarm(all, farmName, (item) => item.farmName);
  }

  Future<void> saveLocation(AtlasInventoryLocation location) async {
    final all = await _decodeList(
      _locationsKey,
      AtlasInventoryLocation.fromMap,
    );
    _upsert(all, location, (item) => item.id);
    await _saveList(_locationsKey, all.map((item) => item.toMap()).toList());
  }

  Future<List<AtlasSupplier>> loadSuppliers({String? farmName}) async {
    final all = await _decodeList(_suppliersKey, AtlasSupplier.fromMap);
    return _filterFarm(all, farmName, (item) => item.farmName);
  }

  Future<void> saveSupplier(AtlasSupplier supplier) async {
    final all = await _decodeList(_suppliersKey, AtlasSupplier.fromMap);
    _upsert(all, supplier, (item) => item.id);
    await _saveList(_suppliersKey, all.map((item) => item.toMap()).toList());
  }

  Future<List<AtlasInventoryItem>> loadItems({String? farmName}) async {
    final all = await _decodeList(_itemsKey, AtlasInventoryItem.fromMap);
    final filtered = _filterFarm(all, farmName, (item) => item.farmName)
      ..sort((first, second) => first.name.compareTo(second.name));
    return filtered;
  }

  Future<void> saveItem(AtlasInventoryItem item) async {
    final all = await _decodeList(_itemsKey, AtlasInventoryItem.fromMap);
    _upsert(all, item, (entry) => entry.id);
    await _saveList(_itemsKey, all.map((entry) => entry.toMap()).toList());
  }

  Future<List<AtlasInventoryBatch>> loadBatches({String? farmName}) async {
    final all = await _decodeList(_batchesKey, AtlasInventoryBatch.fromMap);
    final filtered = _filterFarm(all, farmName, (item) => item.farmName)
      ..sort((first, second) {
        final firstDate = first.expiresAt ?? DateTime(9999);
        final secondDate = second.expiresAt ?? DateTime(9999);
        return firstDate.compareTo(secondDate);
      });
    return filtered;
  }

  Future<void> saveBatch(AtlasInventoryBatch batch) async {
    final all = await _decodeList(_batchesKey, AtlasInventoryBatch.fromMap);
    _upsert(all, batch, (item) => item.id);
    await _saveList(_batchesKey, all.map((item) => item.toMap()).toList());
  }

  Future<List<AtlasInventoryMovement>> loadMovements({String? farmName}) async {
    final all = await _decodeList(
      _movementsKey,
      AtlasInventoryMovement.fromMap,
    );
    final filtered = _filterFarm(all, farmName, (item) => item.farmName)
      ..sort((first, second) => second.occurredAt.compareTo(first.occurredAt));
    return filtered;
  }

  Future<List<AtlasPurchaseOrder>> loadPurchaseOrders({
    String? farmName,
  }) async {
    final all = await _decodeList(
      _purchaseOrdersKey,
      AtlasPurchaseOrder.fromMap,
    );
    final filtered = _filterFarm(all, farmName, (item) => item.farmName)
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return filtered;
  }

  Future<void> savePurchaseOrder(AtlasPurchaseOrder order) async {
    final all = await _decodeList(
      _purchaseOrdersKey,
      AtlasPurchaseOrder.fromMap,
    );
    _upsert(all, order, (item) => item.id);
    await _saveList(
      _purchaseOrdersKey,
      all.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> registerMovement(AtlasInventoryMovement movement) async {
    final items = await _decodeList(_itemsKey, AtlasInventoryItem.fromMap);
    final index = items.indexWhere((item) => item.id == movement.itemId);
    if (index == -1) {
      throw StateError('Item de estoque não encontrado.');
    }

    final current = items[index];
    var newQuantity = current.currentQuantity;
    switch (movement.type) {
      case AtlasInventoryMovementType.entry:
        newQuantity += movement.quantity;
      case AtlasInventoryMovementType.exit:
      case AtlasInventoryMovementType.loss:
      case AtlasInventoryMovementType.automaticConsumption:
        newQuantity -= movement.quantity;
      case AtlasInventoryMovementType.adjustment:
        newQuantity = movement.quantity;
      case AtlasInventoryMovementType.transfer:
        newQuantity = current.currentQuantity;
    }

    newQuantity = newQuantity.clamp(0, double.infinity);
    var newAverageCost = current.averageUnitCost;
    if (movement.type == AtlasInventoryMovementType.entry &&
        movement.quantity > 0) {
      final previousValue = current.currentQuantity * current.averageUnitCost;
      final incomingValue = movement.quantity * movement.unitCost;
      final totalQuantity = current.currentQuantity + movement.quantity;
      if (totalQuantity > 0) {
        newAverageCost = (previousValue + incomingValue) / totalQuantity;
      }
    }

    items[index] = current.copyWith(
      currentQuantity: newQuantity,
      averageUnitCost: newAverageCost,
    );
    await _saveList(_itemsKey, items.map((item) => item.toMap()).toList());

    final movements =
        await _decodeList(_movementsKey, AtlasInventoryMovement.fromMap)
          ..add(movement);
    await _saveList(
      _movementsKey,
      movements.map((item) => item.toMap()).toList(),
    );
  }

  Future<int> processAutomaticConsumption({String? farmName}) async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastKey = await _preferences.getString(_lastAutomaticConsumptionKey);
    if (lastKey == todayKey) {
      return 0;
    }

    final items = await loadItems(farmName: farmName);
    var processed = 0;

    for (final item in items.where(
      (entry) =>
          entry.active &&
          entry.automaticConsumptionEnabled &&
          entry.automaticConsumptionPerDay > 0 &&
          entry.currentQuantity > 0,
    )) {
      final quantity = item.automaticConsumptionPerDay.clamp(
        0,
        item.currentQuantity,
      );
      await registerMovement(
        AtlasInventoryMovement(
          id:
              'automatic_consumption_'
              '${item.id}_${today.microsecondsSinceEpoch}',
          itemId: item.id,
          batchId: null,
          type: AtlasInventoryMovementType.automaticConsumption,
          quantity: quantity.toDouble(),
          unitCost: item.averageUnitCost,
          occurredAt: today,
          sourceLocationId: item.locationId,
          destinationLocationId: null,
          responsibleName: 'Sistema Atlas',
          reference: 'Consumo diário automático',
          notes: 'Baixa automática configurada no cadastro do item.',
          farmName: item.farmName,
        ),
      );
      processed++;
    }

    await _preferences.setString(_lastAutomaticConsumptionKey, todayKey);
    return processed;
  }

  List<AtlasPurchaseOrder> buildRestockSuggestions({
    required List<AtlasInventoryItem> items,
  }) {
    final grouped = <String?, List<AtlasPurchaseOrderLine>>{};

    for (final item in items.where(
      (entry) =>
          entry.active &&
          entry.needsRestock &&
          entry.suggestedPurchaseQuantity > 0,
    )) {
      grouped
          .putIfAbsent(
            item.preferredSupplierId,
            () => <AtlasPurchaseOrderLine>[],
          )
          .add(
            AtlasPurchaseOrderLine(
              itemId: item.id,
              quantity: item.suggestedPurchaseQuantity,
              unitCost: item.averageUnitCost,
            ),
          );
    }

    final now = DateTime.now();
    return grouped.entries.map((entry) {
      return AtlasPurchaseOrder(
        id:
            'restock_suggestion_'
            '${now.microsecondsSinceEpoch}_'
            '${entry.key ?? 'no_supplier'}',
        supplierId: entry.key,
        status: AtlasPurchaseOrderStatus.draft,
        createdAt: now,
        expectedAt: now.add(const Duration(days: 7)),
        receivedAt: null,
        lines: entry.value,
        responsibleName: '',
        notes: 'Sugestão automática baseada em estoque mínimo e máximo.',
        farmName: items.isEmpty ? null : items.first.farmName,
      );
    }).toList();
  }

  AtlasInventorySummary buildSummary({
    required List<AtlasInventoryItem> items,
    required List<AtlasInventoryBatch> batches,
    required List<AtlasInventoryMovement> movements,
    required List<AtlasPurchaseOrder> purchaseOrders,
  }) {
    final now = DateTime.now();
    final monthMovements = movements.where(
      (movement) =>
          movement.occurredAt.year == now.year &&
          movement.occurredAt.month == now.month,
    );

    final entriesValue = monthMovements
        .where((movement) => movement.type == AtlasInventoryMovementType.entry)
        .fold<double>(0, (total, movement) => total + movement.totalValue);
    final exitsValue = monthMovements
        .where(
          (movement) =>
              movement.type == AtlasInventoryMovementType.exit ||
              movement.type == AtlasInventoryMovementType.loss ||
              movement.type == AtlasInventoryMovementType.automaticConsumption,
        )
        .fold<double>(0, (total, movement) => total + movement.totalValue);

    return AtlasInventorySummary(
      totalItems: items.where((item) => item.active).length,
      totalStockValue: items.fold<double>(
        0,
        (total, item) => total + item.stockValue,
      ),
      lowStockItems: items.where((item) => item.needsRestock).length,
      expiringBatches: batches.where((batch) => batch.expiresSoon).length,
      expiredBatches: batches.where((batch) => batch.isExpired).length,
      openPurchaseOrders: purchaseOrders.where((order) {
        return order.status != AtlasPurchaseOrderStatus.received &&
            order.status != AtlasPurchaseOrderStatus.cancelled;
      }).length,
      monthlyEntriesValue: entriesValue,
      monthlyExitsValue: exitsValue,
    );
  }

  List<String> buildAlerts({
    required List<AtlasInventoryItem> items,
    required List<AtlasInventoryBatch> batches,
    required List<AtlasPurchaseOrder> orders,
  }) {
    final alerts = <String>[];

    for (final item in items) {
      if (item.needsRestock) {
        alerts.add(
          '${item.name}: estoque em '
          '${item.currentQuantity.toStringAsFixed(2)} ${item.unit}, '
          'mínimo de ${item.minimumQuantity.toStringAsFixed(2)}.',
        );
      }
      final days = item.estimatedDaysUntilStockout;
      if (days != null && days <= 7) {
        alerts.add('${item.name}: previsão de ruptura em $days dia(s).');
      }
    }

    for (final batch in batches) {
      if (batch.isExpired) {
        alerts.add('Lote ${batch.batchNumber}: produto vencido.');
      } else if (batch.expiresSoon) {
        alerts.add('Lote ${batch.batchNumber}: validade em até 30 dias.');
      }
    }

    for (final order in orders) {
      if (order.expectedAt != null &&
          order.status != AtlasPurchaseOrderStatus.received &&
          order.status != AtlasPurchaseOrderStatus.cancelled &&
          order.expectedAt!.isBefore(DateTime.now())) {
        alerts.add('Pedido ${order.id}: recebimento atrasado.');
      }
    }

    if (alerts.isEmpty) {
      alerts.add('Nenhum alerta crítico de estoque no momento.');
    }
    return alerts;
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final encoded = await _preferences.getString(key);
    if (encoded == null || encoded.trim().isEmpty) {
      return <T>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map((item) => fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> values) {
    return _preferences.setString(key, jsonEncode(values));
  }

  void _upsert<T>(List<T> values, T value, String Function(T) readId) {
    final id = readId(value);
    final index = values.indexWhere((item) => readId(item) == id);
    if (index == -1) {
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  List<T> _filterFarm<T>(
    List<T> values,
    String? farmName,
    String? Function(T) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return values;
    }

    return values.where((value) {
      return readFarm(value)?.trim().toLowerCase() == normalized;
    }).toList();
  }
}
