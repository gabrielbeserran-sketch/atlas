class FarmInventoryMovement {
  const FarmInventoryMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.date,
    required this.responsible,
    required this.reason,
    required this.document,
    required this.unitValue,
  });

  final String id;
  final String type;
  final double quantity;
  final String date;
  final String responsible;
  final String reason;
  final String document;
  final double unitValue;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'type': type,
    'quantity': quantity,
    'date': date,
    'responsible': responsible,
    'reason': reason,
    'document': document,
    'unitValue': unitValue,
  };

  factory FarmInventoryMovement.fromMap(Map<String, dynamic> map) {
    return FarmInventoryMovement(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'Ajuste',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      date: map['date'] as String? ?? '',
      responsible: map['responsible'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      document: map['document'] as String? ?? '',
      unitValue: (map['unitValue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FarmInventoryData {
  const FarmInventoryData({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minimumQuantity,
    required this.unit,
    required this.unitValue,
    required this.expirationDate,
    required this.supplier,
    required this.batch,
    required this.notes,
    this.internalCode = '',
    this.barcode = '',
    this.brand = '',
    this.manufacturer = '',
    this.maximumQuantity = 0,
    this.lastPurchaseValue = 0,
    this.manufacturingDate = '',
    this.withdrawalDays = 0,
    this.storageLocation = '',
    this.activeIngredient = '',
    this.purchaseDocument = '',
    this.lastInventoryDate = '',
    this.movements = const <FarmInventoryMovement>[],
  });

  final String id;
  final String name;
  final String category;
  final double quantity;
  final double minimumQuantity;
  final String unit;
  final double unitValue;
  final String expirationDate;
  final String supplier;
  final String batch;
  final String notes;
  final String internalCode;
  final String barcode;
  final String brand;
  final String manufacturer;
  final double maximumQuantity;
  final double lastPurchaseValue;
  final String manufacturingDate;
  final int withdrawalDays;
  final String storageLocation;
  final String activeIngredient;
  final String purchaseDocument;
  final String lastInventoryDate;
  final List<FarmInventoryMovement> movements;

  bool get hasLowStock => quantity <= minimumQuantity;
  bool get isOutOfStock => quantity <= 0;
  double get totalValue => quantity * unitValue;
  double get suggestedPurchaseQuantity {
    final target = maximumQuantity > minimumQuantity
        ? maximumQuantity
        : minimumQuantity * 2;
    final difference = target - quantity;
    return difference > 0 ? difference : 0;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'minimumQuantity': minimumQuantity,
    'unit': unit,
    'unitValue': unitValue,
    'expirationDate': expirationDate,
    'supplier': supplier,
    'batch': batch,
    'notes': notes,
    'internalCode': internalCode,
    'barcode': barcode,
    'brand': brand,
    'manufacturer': manufacturer,
    'maximumQuantity': maximumQuantity,
    'lastPurchaseValue': lastPurchaseValue,
    'manufacturingDate': manufacturingDate,
    'withdrawalDays': withdrawalDays,
    'storageLocation': storageLocation,
    'activeIngredient': activeIngredient,
    'purchaseDocument': purchaseDocument,
    'lastInventoryDate': lastInventoryDate,
    'movements': movements.map((movement) => movement.toMap()).toList(),
  };

  factory FarmInventoryData.fromMap(Map<String, dynamic> map) {
    final movementMaps =
        map['movements'] as List<dynamic>? ?? const <dynamic>[];
    return FarmInventoryData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Outro',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      minimumQuantity: (map['minimumQuantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'unidade',
      unitValue: (map['unitValue'] as num?)?.toDouble() ?? 0,
      expirationDate: map['expirationDate'] as String? ?? '',
      supplier: map['supplier'] as String? ?? '',
      batch: map['batch'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      internalCode: map['internalCode'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      manufacturer: map['manufacturer'] as String? ?? '',
      maximumQuantity: (map['maximumQuantity'] as num?)?.toDouble() ?? 0,
      lastPurchaseValue:
          (map['lastPurchaseValue'] as num?)?.toDouble() ??
          (map['unitValue'] as num?)?.toDouble() ??
          0,
      manufacturingDate: map['manufacturingDate'] as String? ?? '',
      withdrawalDays: (map['withdrawalDays'] as num?)?.toInt() ?? 0,
      storageLocation: map['storageLocation'] as String? ?? '',
      activeIngredient: map['activeIngredient'] as String? ?? '',
      purchaseDocument: map['purchaseDocument'] as String? ?? '',
      lastInventoryDate: map['lastInventoryDate'] as String? ?? '',
      movements: movementMaps
          .map(
            (value) => FarmInventoryMovement.fromMap(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
    );
  }

  FarmInventoryData copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    double? minimumQuantity,
    String? unit,
    double? unitValue,
    String? expirationDate,
    String? supplier,
    String? batch,
    String? notes,
    String? internalCode,
    String? barcode,
    String? brand,
    String? manufacturer,
    double? maximumQuantity,
    double? lastPurchaseValue,
    String? manufacturingDate,
    int? withdrawalDays,
    String? storageLocation,
    String? activeIngredient,
    String? purchaseDocument,
    String? lastInventoryDate,
    List<FarmInventoryMovement>? movements,
  }) {
    return FarmInventoryData(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      unit: unit ?? this.unit,
      unitValue: unitValue ?? this.unitValue,
      expirationDate: expirationDate ?? this.expirationDate,
      supplier: supplier ?? this.supplier,
      batch: batch ?? this.batch,
      notes: notes ?? this.notes,
      internalCode: internalCode ?? this.internalCode,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      manufacturer: manufacturer ?? this.manufacturer,
      maximumQuantity: maximumQuantity ?? this.maximumQuantity,
      lastPurchaseValue: lastPurchaseValue ?? this.lastPurchaseValue,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      withdrawalDays: withdrawalDays ?? this.withdrawalDays,
      storageLocation: storageLocation ?? this.storageLocation,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      purchaseDocument: purchaseDocument ?? this.purchaseDocument,
      lastInventoryDate: lastInventoryDate ?? this.lastInventoryDate,
      movements: movements ?? this.movements,
    );
  }
}
