enum AtlasInventoryItemCategory {
  medication,
  vaccine,
  feed,
  mineral,
  reproductive,
  maintenance,
  fuel,
  equipment,
  other,
}

String atlasInventoryItemCategoryLabel(AtlasInventoryItemCategory category) {
  switch (category) {
    case AtlasInventoryItemCategory.medication:
      return 'Medicamento';
    case AtlasInventoryItemCategory.vaccine:
      return 'Vacina';
    case AtlasInventoryItemCategory.feed:
      return 'Alimento';
    case AtlasInventoryItemCategory.mineral:
      return 'Mineral';
    case AtlasInventoryItemCategory.reproductive:
      return 'Reprodução';
    case AtlasInventoryItemCategory.maintenance:
      return 'Manutenção';
    case AtlasInventoryItemCategory.fuel:
      return 'Combustível';
    case AtlasInventoryItemCategory.equipment:
      return 'Equipamento';
    case AtlasInventoryItemCategory.other:
      return 'Outro';
  }
}

enum AtlasInventoryMovementType {
  entry,
  exit,
  adjustment,
  transfer,
  loss,
  automaticConsumption,
}

String atlasInventoryMovementTypeLabel(AtlasInventoryMovementType type) {
  switch (type) {
    case AtlasInventoryMovementType.entry:
      return 'Entrada';
    case AtlasInventoryMovementType.exit:
      return 'Saída';
    case AtlasInventoryMovementType.adjustment:
      return 'Ajuste';
    case AtlasInventoryMovementType.transfer:
      return 'Transferência';
    case AtlasInventoryMovementType.loss:
      return 'Perda';
    case AtlasInventoryMovementType.automaticConsumption:
      return 'Consumo automático';
  }
}

class AtlasInventoryLocation {
  const AtlasInventoryLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.responsibleName,
    required this.farmName,
    required this.active,
  });

  final String id;
  final String name;
  final String description;
  final String responsibleName;
  final String? farmName;
  final bool active;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
    'responsibleName': responsibleName,
    'farmName': farmName,
    'active': active,
  };

  factory AtlasInventoryLocation.fromMap(Map<String, dynamic> map) {
    return AtlasInventoryLocation(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      responsibleName: map['responsibleName']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      active: map['active'] != false,
    );
  }
}

class AtlasSupplier {
  const AtlasSupplier({
    required this.id,
    required this.name,
    required this.document,
    required this.phone,
    required this.email,
    required this.notes,
    required this.farmName,
    required this.active,
  });

  final String id;
  final String name;
  final String document;
  final String phone;
  final String email;
  final String notes;
  final String? farmName;
  final bool active;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'document': document,
    'phone': phone,
    'email': email,
    'notes': notes,
    'farmName': farmName,
    'active': active,
  };

  factory AtlasSupplier.fromMap(Map<String, dynamic> map) {
    return AtlasSupplier(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      document: map['document']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      active: map['active'] != false,
    );
  }
}

class AtlasInventoryItem {
  const AtlasInventoryItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentQuantity,
    required this.minimumQuantity,
    required this.maximumQuantity,
    required this.averageUnitCost,
    required this.locationId,
    required this.preferredSupplierId,
    required this.automaticConsumptionEnabled,
    required this.automaticConsumptionPerDay,
    required this.farmName,
    required this.active,
  });

  final String id;
  final String code;
  final String name;
  final AtlasInventoryItemCategory category;
  final String unit;
  final double currentQuantity;
  final double minimumQuantity;
  final double maximumQuantity;
  final double averageUnitCost;
  final String? locationId;
  final String? preferredSupplierId;
  final bool automaticConsumptionEnabled;
  final double automaticConsumptionPerDay;
  final String? farmName;
  final bool active;

  bool get needsRestock => active && currentQuantity <= minimumQuantity;

  double get stockValue => currentQuantity * averageUnitCost;

  double get suggestedPurchaseQuantity {
    if (!needsRestock) {
      return 0;
    }
    final target = maximumQuantity > minimumQuantity
        ? maximumQuantity
        : minimumQuantity * 2;
    return (target - currentQuantity).clamp(0, double.infinity);
  }

  int? get estimatedDaysUntilStockout {
    if (!automaticConsumptionEnabled || automaticConsumptionPerDay <= 0) {
      return null;
    }
    return (currentQuantity / automaticConsumptionPerDay).floor();
  }

  AtlasInventoryItem copyWith({
    String? code,
    String? name,
    AtlasInventoryItemCategory? category,
    String? unit,
    double? currentQuantity,
    double? minimumQuantity,
    double? maximumQuantity,
    double? averageUnitCost,
    String? locationId,
    bool clearLocationId = false,
    String? preferredSupplierId,
    bool clearPreferredSupplierId = false,
    bool? automaticConsumptionEnabled,
    double? automaticConsumptionPerDay,
    bool? active,
  }) {
    return AtlasInventoryItem(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      maximumQuantity: maximumQuantity ?? this.maximumQuantity,
      averageUnitCost: averageUnitCost ?? this.averageUnitCost,
      locationId: clearLocationId ? null : locationId ?? this.locationId,
      preferredSupplierId: clearPreferredSupplierId
          ? null
          : preferredSupplierId ?? this.preferredSupplierId,
      automaticConsumptionEnabled:
          automaticConsumptionEnabled ?? this.automaticConsumptionEnabled,
      automaticConsumptionPerDay:
          automaticConsumptionPerDay ?? this.automaticConsumptionPerDay,
      farmName: farmName,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'code': code,
    'name': name,
    'category': category.name,
    'unit': unit,
    'currentQuantity': currentQuantity,
    'minimumQuantity': minimumQuantity,
    'maximumQuantity': maximumQuantity,
    'averageUnitCost': averageUnitCost,
    'locationId': locationId,
    'preferredSupplierId': preferredSupplierId,
    'automaticConsumptionEnabled': automaticConsumptionEnabled,
    'automaticConsumptionPerDay': automaticConsumptionPerDay,
    'farmName': farmName,
    'active': active,
  };

  factory AtlasInventoryItem.fromMap(Map<String, dynamic> map) {
    return AtlasInventoryItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: AtlasInventoryItemCategory.values.firstWhere(
        (value) => value.name == map['category']?.toString(),
        orElse: () => AtlasInventoryItemCategory.other,
      ),
      unit: map['unit']?.toString() ?? '',
      currentQuantity: _readDouble(map['currentQuantity']),
      minimumQuantity: _readDouble(map['minimumQuantity']),
      maximumQuantity: _readDouble(map['maximumQuantity']),
      averageUnitCost: _readDouble(map['averageUnitCost']),
      locationId: map['locationId']?.toString(),
      preferredSupplierId: map['preferredSupplierId']?.toString(),
      automaticConsumptionEnabled: map['automaticConsumptionEnabled'] == true,
      automaticConsumptionPerDay: _readDouble(
        map['automaticConsumptionPerDay'],
      ),
      farmName: map['farmName']?.toString(),
      active: map['active'] != false,
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasInventoryBatch {
  const AtlasInventoryBatch({
    required this.id,
    required this.itemId,
    required this.batchNumber,
    required this.manufacturedAt,
    required this.expiresAt,
    required this.quantity,
    required this.unitCost,
    required this.supplierId,
    required this.locationId,
    required this.receivedAt,
    required this.farmName,
  });

  final String id;
  final String itemId;
  final String batchNumber;
  final DateTime? manufacturedAt;
  final DateTime? expiresAt;
  final double quantity;
  final double unitCost;
  final String? supplierId;
  final String? locationId;
  final DateTime receivedAt;
  final String? farmName;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get expiresSoon =>
      expiresAt != null &&
      !isExpired &&
      expiresAt!.difference(DateTime.now()).inDays <= 30;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'itemId': itemId,
    'batchNumber': batchNumber,
    'manufacturedAt': manufacturedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'quantity': quantity,
    'unitCost': unitCost,
    'supplierId': supplierId,
    'locationId': locationId,
    'receivedAt': receivedAt.toIso8601String(),
    'farmName': farmName,
  };

  factory AtlasInventoryBatch.fromMap(Map<String, dynamic> map) {
    return AtlasInventoryBatch(
      id: map['id']?.toString() ?? '',
      itemId: map['itemId']?.toString() ?? '',
      batchNumber: map['batchNumber']?.toString() ?? '',
      manufacturedAt: DateTime.tryParse(
        map['manufacturedAt']?.toString() ?? '',
      ),
      expiresAt: DateTime.tryParse(map['expiresAt']?.toString() ?? ''),
      quantity: _readDouble(map['quantity']),
      unitCost: _readDouble(map['unitCost']),
      supplierId: map['supplierId']?.toString(),
      locationId: map['locationId']?.toString(),
      receivedAt:
          DateTime.tryParse(map['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
      farmName: map['farmName']?.toString(),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasInventoryMovement {
  const AtlasInventoryMovement({
    required this.id,
    required this.itemId,
    required this.batchId,
    required this.type,
    required this.quantity,
    required this.unitCost,
    required this.occurredAt,
    required this.sourceLocationId,
    required this.destinationLocationId,
    required this.responsibleName,
    required this.reference,
    required this.notes,
    required this.farmName,
  });

  final String id;
  final String itemId;
  final String? batchId;
  final AtlasInventoryMovementType type;
  final double quantity;
  final double unitCost;
  final DateTime occurredAt;
  final String? sourceLocationId;
  final String? destinationLocationId;
  final String responsibleName;
  final String reference;
  final String notes;
  final String? farmName;

  double get totalValue => quantity * unitCost;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'itemId': itemId,
    'batchId': batchId,
    'type': type.name,
    'quantity': quantity,
    'unitCost': unitCost,
    'occurredAt': occurredAt.toIso8601String(),
    'sourceLocationId': sourceLocationId,
    'destinationLocationId': destinationLocationId,
    'responsibleName': responsibleName,
    'reference': reference,
    'notes': notes,
    'farmName': farmName,
  };

  factory AtlasInventoryMovement.fromMap(Map<String, dynamic> map) {
    return AtlasInventoryMovement(
      id: map['id']?.toString() ?? '',
      itemId: map['itemId']?.toString() ?? '',
      batchId: map['batchId']?.toString(),
      type: AtlasInventoryMovementType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasInventoryMovementType.adjustment,
      ),
      quantity: _readDouble(map['quantity']),
      unitCost: _readDouble(map['unitCost']),
      occurredAt:
          DateTime.tryParse(map['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      sourceLocationId: map['sourceLocationId']?.toString(),
      destinationLocationId: map['destinationLocationId']?.toString(),
      responsibleName: map['responsibleName']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

enum AtlasPurchaseOrderStatus {
  draft,
  requested,
  approved,
  ordered,
  partiallyReceived,
  received,
  cancelled,
}

String atlasPurchaseOrderStatusLabel(AtlasPurchaseOrderStatus status) {
  switch (status) {
    case AtlasPurchaseOrderStatus.draft:
      return 'Rascunho';
    case AtlasPurchaseOrderStatus.requested:
      return 'Solicitado';
    case AtlasPurchaseOrderStatus.approved:
      return 'Aprovado';
    case AtlasPurchaseOrderStatus.ordered:
      return 'Pedido realizado';
    case AtlasPurchaseOrderStatus.partiallyReceived:
      return 'Recebido parcialmente';
    case AtlasPurchaseOrderStatus.received:
      return 'Recebido';
    case AtlasPurchaseOrderStatus.cancelled:
      return 'Cancelado';
  }
}

class AtlasPurchaseOrderLine {
  const AtlasPurchaseOrderLine({
    required this.itemId,
    required this.quantity,
    required this.unitCost,
  });

  final String itemId;
  final double quantity;
  final double unitCost;

  double get total => quantity * unitCost;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'itemId': itemId,
    'quantity': quantity,
    'unitCost': unitCost,
  };

  factory AtlasPurchaseOrderLine.fromMap(Map<String, dynamic> map) {
    return AtlasPurchaseOrderLine(
      itemId: map['itemId']?.toString() ?? '',
      quantity: _readDouble(map['quantity']),
      unitCost: _readDouble(map['unitCost']),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasPurchaseOrder {
  const AtlasPurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.status,
    required this.createdAt,
    required this.expectedAt,
    required this.receivedAt,
    required this.lines,
    required this.responsibleName,
    required this.notes,
    required this.farmName,
  });

  final String id;
  final String? supplierId;
  final AtlasPurchaseOrderStatus status;
  final DateTime createdAt;
  final DateTime? expectedAt;
  final DateTime? receivedAt;
  final List<AtlasPurchaseOrderLine> lines;
  final String responsibleName;
  final String notes;
  final String? farmName;

  double get totalValue =>
      lines.fold<double>(0, (total, line) => total + line.total);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'supplierId': supplierId,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'expectedAt': expectedAt?.toIso8601String(),
    'receivedAt': receivedAt?.toIso8601String(),
    'lines': lines.map((item) => item.toMap()).toList(),
    'responsibleName': responsibleName,
    'notes': notes,
    'farmName': farmName,
  };

  factory AtlasPurchaseOrder.fromMap(Map<String, dynamic> map) {
    return AtlasPurchaseOrder(
      id: map['id']?.toString() ?? '',
      supplierId: map['supplierId']?.toString(),
      status: AtlasPurchaseOrderStatus.values.firstWhere(
        (value) => value.name == map['status']?.toString(),
        orElse: () => AtlasPurchaseOrderStatus.draft,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      expectedAt: DateTime.tryParse(map['expectedAt']?.toString() ?? ''),
      receivedAt: DateTime.tryParse(map['receivedAt']?.toString() ?? ''),
      lines: map['lines'] is List
          ? (map['lines'] as List)
                .map(
                  (item) => AtlasPurchaseOrderLine.fromMap(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : <AtlasPurchaseOrderLine>[],
      responsibleName: map['responsibleName']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
    );
  }
}

class AtlasInventorySummary {
  const AtlasInventorySummary({
    required this.totalItems,
    required this.totalStockValue,
    required this.lowStockItems,
    required this.expiringBatches,
    required this.expiredBatches,
    required this.openPurchaseOrders,
    required this.monthlyEntriesValue,
    required this.monthlyExitsValue,
  });

  final int totalItems;
  final double totalStockValue;
  final int lowStockItems;
  final int expiringBatches;
  final int expiredBatches;
  final int openPurchaseOrders;
  final double monthlyEntriesValue;
  final double monthlyExitsValue;
}
