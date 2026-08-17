class AnimalHealthData {
  const AnimalHealthData({
    required this.id,
    required this.type,
    required this.date,
    required this.product,
    required this.dose,
    required this.responsible,
    required this.notes,
    this.protocol = '',
    this.productBatch = '',
    this.applicationRoute = '',
    this.frequency = '',
    this.diagnosis = '',
    this.severity = 'Não informada',
    this.nextDate = '',
    this.withdrawalEndDate = '',
    this.withdrawalMeatEndDate = '',
    this.withdrawalMilkEndDate = '',
    this.status = 'Concluído',
    this.isQuarantine = false,
    this.isMortality = false,
    this.necropsyResult = '',
    this.inventoryItemId = '',
    this.inventoryQuantity = 0,
    this.inventoryDeducted = false,
    this.treatmentCost = 0,
    this.synced = false,
  });
  final String id,
      type,
      date,
      product,
      dose,
      responsible,
      notes,
      protocol,
      productBatch,
      applicationRoute,
      frequency,
      diagnosis,
      severity,
      nextDate,
      withdrawalEndDate,
      withdrawalMeatEndDate,
      withdrawalMilkEndDate,
      status,
      necropsyResult,
      inventoryItemId;
  final bool isQuarantine, isMortality, inventoryDeducted, synced;
  final double inventoryQuantity, treatmentCost;
  bool get hasScheduledReturn => nextDate.trim().isNotEmpty;
  bool get hasWithdrawalPeriod =>
      withdrawalEndDate.trim().isNotEmpty ||
      withdrawalMeatEndDate.trim().isNotEmpty ||
      withdrawalMilkEndDate.trim().isNotEmpty;
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'date': date,
    'product': product,
    'dose': dose,
    'responsible': responsible,
    'notes': notes,
    'protocol': protocol,
    'productBatch': productBatch,
    'applicationRoute': applicationRoute,
    'frequency': frequency,
    'diagnosis': diagnosis,
    'severity': severity,
    'nextDate': nextDate,
    'withdrawalEndDate': withdrawalEndDate,
    'withdrawalMeatEndDate': withdrawalMeatEndDate,
    'withdrawalMilkEndDate': withdrawalMilkEndDate,
    'status': status,
    'isQuarantine': isQuarantine,
    'isMortality': isMortality,
    'necropsyResult': necropsyResult,
    'inventoryItemId': inventoryItemId,
    'inventoryQuantity': inventoryQuantity,
    'inventoryDeducted': inventoryDeducted,
    'treatmentCost': treatmentCost,
    'synced': synced,
  };
  Map<String, dynamic> toApi({
    required String farmId,
    required String animalId,
    String? lotId,
  }) => {
    'farm_id': farmId,
    'animal_id': animalId,
    'lot_id': lotId,
    'event_type': type,
    'product_name': product,
    'dosage': dose,
    'route': applicationRoute,
    'withdrawal_until': withdrawalEndDate.isEmpty
        ? null
        : _iso(withdrawalEndDate),
    'withdrawal_meat_until': withdrawalMeatEndDate.isEmpty
        ? (withdrawalEndDate.isEmpty ? null : _iso(withdrawalEndDate))
        : _iso(withdrawalMeatEndDate),
    'withdrawal_milk_until': withdrawalMilkEndDate.isEmpty
        ? null
        : _iso(withdrawalMilkEndDate),
    'occurred_at': _iso(date),
    'responsible': responsible,
    'notes': notes,
    'protocol_name': protocol,
    'product_batch': productBatch,
    'frequency': frequency,
    'diagnosis': diagnosis,
    'severity': severity,
    'next_date': nextDate.isEmpty ? null : _iso(nextDate),
    'status': status,
    'is_quarantine': isQuarantine,
    'is_mortality': isMortality,
    'necropsy_result': necropsyResult,
    'inventory_product_id': inventoryItemId.isEmpty ? null : inventoryItemId,
    'inventory_quantity': inventoryQuantity,
    'treatment_cost': treatmentCost,
  };
  Map<String, dynamic> toUpdateApi() => {
    'event_type': type,
    'product_name': product,
    'dosage': dose,
    'route': applicationRoute,
    'withdrawal_until': withdrawalEndDate.isEmpty
        ? null
        : _iso(withdrawalEndDate),
    'withdrawal_meat_until': withdrawalMeatEndDate.isEmpty
        ? (withdrawalEndDate.isEmpty ? null : _iso(withdrawalEndDate))
        : _iso(withdrawalMeatEndDate),
    'withdrawal_milk_until': withdrawalMilkEndDate.isEmpty
        ? null
        : _iso(withdrawalMilkEndDate),
    'occurred_at': _iso(date),
    'responsible': responsible,
    'notes': notes,
    'protocol_name': protocol,
    'product_batch': productBatch,
    'frequency': frequency,
    'diagnosis': diagnosis,
    'severity': severity,
    'next_date': nextDate.isEmpty ? null : _iso(nextDate),
    'status': status,
    'is_quarantine': isQuarantine,
    'is_mortality': isMortality,
    'necropsy_result': necropsyResult,
  };

  factory AnimalHealthData.fromMap(Map<String, dynamic> m) => AnimalHealthData(
    id: '${m['id'] ?? ''}',
    type: '${m['type'] ?? m['event_type'] ?? 'Outro'}',
    date: _display('${m['date'] ?? m['occurred_at'] ?? ''}'),
    product: '${m['product'] ?? m['product_name'] ?? ''}',
    dose: '${m['dose'] ?? m['dosage'] ?? ''}',
    responsible: '${m['responsible'] ?? ''}',
    notes: '${m['notes'] ?? ''}',
    protocol: '${m['protocol'] ?? m['protocol_name'] ?? ''}',
    productBatch: '${m['productBatch'] ?? m['product_batch'] ?? ''}',
    applicationRoute: '${m['applicationRoute'] ?? m['route'] ?? ''}',
    frequency: '${m['frequency'] ?? ''}',
    diagnosis: '${m['diagnosis'] ?? ''}',
    severity: '${m['severity'] ?? 'Não informada'}',
    nextDate: _display('${m['nextDate'] ?? m['next_date'] ?? ''}'),
    withdrawalEndDate: _display(
      '${m['withdrawalEndDate'] ?? m['withdrawal_until'] ?? ''}',
    ),
    withdrawalMeatEndDate: _display(
      '${m['withdrawalMeatEndDate'] ?? m['withdrawal_meat_until'] ?? ''}',
    ),
    withdrawalMilkEndDate: _display(
      '${m['withdrawalMilkEndDate'] ?? m['withdrawal_milk_until'] ?? ''}',
    ),
    status: '${m['status'] ?? 'Concluído'}',
    isQuarantine: m['isQuarantine'] == true || m['is_quarantine'] == true,
    isMortality: m['isMortality'] == true || m['is_mortality'] == true,
    necropsyResult: '${m['necropsyResult'] ?? m['necropsy_result'] ?? ''}',
    inventoryItemId:
        '${m['inventoryItemId'] ?? m['inventory_product_id'] ?? ''}',
    inventoryQuantity: _d(m['inventoryQuantity'] ?? m['inventory_quantity']),
    inventoryDeducted:
        m['inventoryDeducted'] == true ||
        ((m.containsKey('event_type')) &&
            '${m['inventory_product_id'] ?? ''}'.isNotEmpty &&
            _d(m['inventory_quantity']) > 0),
    treatmentCost: _d(m['treatmentCost'] ?? m['treatment_cost']),
    synced: m['synced'] == true || m.containsKey('event_type'),
  );
  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  static String _iso(String v) {
    final p = v.split('/');
    if (p.length != 3) return v;
    return DateTime(
      int.parse(p[2]),
      int.parse(p[1]),
      int.parse(p[0]),
    ).toUtc().toIso8601String();
  }

  static String _display(String v) {
    if (v.isEmpty || !v.contains('-')) return v;
    final d = DateTime.tryParse(v);
    return d == null
        ? v
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
