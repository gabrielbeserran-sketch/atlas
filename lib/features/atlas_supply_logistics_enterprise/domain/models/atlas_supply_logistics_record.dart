enum AtlasSupplyLogisticsModule {
  intelligentPurchasing,
  supplierManagement,
  automatedQuotation,
  purchaseApproval,
  multiWarehouseStock,
  batchesAndExpiry,
  intelligentInventory,
  transportLogistics,
  fuelManagement,
  supplyLogisticsCenter,
}

extension AtlasSupplyLogisticsModuleX on AtlasSupplyLogisticsModule {
  String get code => switch (this) {
    AtlasSupplyLogisticsModule.intelligentPurchasing =>
      'intelligent_purchasing',
    AtlasSupplyLogisticsModule.supplierManagement => 'supplier_management',
    AtlasSupplyLogisticsModule.automatedQuotation => 'automated_quotation',
    AtlasSupplyLogisticsModule.purchaseApproval => 'purchase_approval',
    AtlasSupplyLogisticsModule.multiWarehouseStock => 'multi_warehouse_stock',
    AtlasSupplyLogisticsModule.batchesAndExpiry => 'batches_and_expiry',
    AtlasSupplyLogisticsModule.intelligentInventory => 'intelligent_inventory',
    AtlasSupplyLogisticsModule.transportLogistics => 'transport_logistics',
    AtlasSupplyLogisticsModule.fuelManagement => 'fuel_management',
    AtlasSupplyLogisticsModule.supplyLogisticsCenter =>
      'supply_logistics_center',
  };

  String get title => switch (this) {
    AtlasSupplyLogisticsModule.intelligentPurchasing => 'Compras Inteligentes',
    AtlasSupplyLogisticsModule.supplierManagement => 'Gestão de Fornecedores',
    AtlasSupplyLogisticsModule.automatedQuotation => 'Cotação Automatizada',
    AtlasSupplyLogisticsModule.purchaseApproval => 'Aprovação de Compras',
    AtlasSupplyLogisticsModule.multiWarehouseStock => 'Estoque Multidepósito',
    AtlasSupplyLogisticsModule.batchesAndExpiry => 'Lotes e Validades',
    AtlasSupplyLogisticsModule.intelligentInventory => 'Inventário Inteligente',
    AtlasSupplyLogisticsModule.transportLogistics => 'Logística de Transporte',
    AtlasSupplyLogisticsModule.fuelManagement => 'Gestão de Combustíveis',
    AtlasSupplyLogisticsModule.supplyLogisticsCenter =>
      'Central de Suprimentos e Logística',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasSupplyLogisticsModule.intelligentPurchasing => const [
      'Solicitação de compra',
      'Cotação',
      'Comparação',
      'Pedido',
      'Recebimento',
    ],
    AtlasSupplyLogisticsModule.supplierManagement => const [
      'Cadastro',
      'Documentos',
      'Produtos e serviços',
      'Avaliação',
      'Histórico comercial',
    ],
    AtlasSupplyLogisticsModule.automatedQuotation => const [
      'Preço',
      'Condição de pagamento',
      'Frete',
      'Prazo',
      'Custo final',
    ],
    AtlasSupplyLogisticsModule.purchaseApproval => const [
      'Faixa de valor',
      'Categoria',
      'Centro de custo',
      'Aprovadores',
      'Histórico de decisão',
    ],
    AtlasSupplyLogisticsModule.multiWarehouseStock => const [
      'Depósitos',
      'Saldos',
      'Transferências',
      'Reservas',
      'Disponibilidade',
    ],
    AtlasSupplyLogisticsModule.batchesAndExpiry => const [
      'Lote',
      'Fabricação',
      'Validade',
      'Fornecedor',
      'Rastreabilidade',
    ],
    AtlasSupplyLogisticsModule.intelligentInventory => const [
      'Contagem',
      'Divergências',
      'Ajustes',
      'Auditoria',
      'Inventário cíclico',
    ],
    AtlasSupplyLogisticsModule.transportLogistics => const [
      'Veículos',
      'Motoristas',
      'Cargas',
      'Rotas',
      'Entregas',
    ],
    AtlasSupplyLogisticsModule.fuelManagement => const [
      'Abastecimentos',
      'Consumo por máquina',
      'Estoque',
      'Custo por operação',
      'Desvios',
    ],
    AtlasSupplyLogisticsModule.supplyLogisticsCenter => const [
      'Compras',
      'Fornecedores',
      'Estoque',
      'Transporte',
      'Painel executivo',
    ],
  };
}

class AtlasSupplyLogisticsRecord {
  const AtlasSupplyLogisticsRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.farmName,
    required this.supplierName,
    required this.warehouseName,
    required this.itemName,
    required this.batchCode,
    required this.vehicleName,
    required this.driverName,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.freightCost,
    required this.plannedValue,
    required this.actualValue,
    required this.progressPercent,
    required this.qualityPercent,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasSupplyLogisticsModule module;
  final String feature;
  final String title;
  final String date;
  final String dueDate;
  final String status;
  final String priority;
  final String farmName;
  final String supplierName;
  final String warehouseName;
  final String itemName;
  final String batchCode;
  final String vehicleName;
  final String driverName;
  final double quantity;
  final String unit;
  final double unitCost;
  final double freightCost;
  final double plannedValue;
  final double actualValue;
  final int progressPercent;
  final double qualityPercent;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Atrasado' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Aprovado' ||
      status == 'Em trânsito' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasSupplyDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Cancelado';
  }

  double get totalCost => quantity * unitCost + freightCost;

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module.code,
    'feature': feature,
    'title': title,
    'date': date,
    'dueDate': dueDate,
    'status': status,
    'priority': priority,
    'farmName': farmName,
    'supplierName': supplierName,
    'warehouseName': warehouseName,
    'itemName': itemName,
    'batchCode': batchCode,
    'vehicleName': vehicleName,
    'driverName': driverName,
    'quantity': quantity,
    'unit': unit,
    'unitCost': unitCost,
    'freightCost': freightCost,
    'plannedValue': plannedValue,
    'actualValue': actualValue,
    'progressPercent': progressPercent,
    'qualityPercent': qualityPercent,
    'alertCount': alertCount,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AtlasSupplyLogisticsRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasSupplyLogisticsModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasSupplyLogisticsModule.intelligentPurchasing,
    );

    return AtlasSupplyLogisticsRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      dueDate: map['dueDate']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      farmName: map['farmName']?.toString() ?? '',
      supplierName: map['supplierName']?.toString() ?? '',
      warehouseName: map['warehouseName']?.toString() ?? '',
      itemName: map['itemName']?.toString() ?? '',
      batchCode: map['batchCode']?.toString() ?? '',
      vehicleName: map['vehicleName']?.toString() ?? '',
      driverName: map['driverName']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0,
      freightCost: (map['freightCost'] as num?)?.toDouble() ?? 0,
      plannedValue: (map['plannedValue'] as num?)?.toDouble() ?? 0,
      actualValue: (map['actualValue'] as num?)?.toDouble() ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      qualityPercent: (map['qualityPercent'] as num?)?.toDouble() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasSupplyDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return DateTime(1900);
  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;
  final parts = text.split('/');
  if (parts.length != 3) return DateTime(1900);
  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasSupplyDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
