enum AtlasAssetType {
  tractor,
  vehicle,
  implement,
  machine,
  equipment,
  generator,
  pump,
  structure,
  other,
}

String atlasAssetTypeLabel(AtlasAssetType type) {
  switch (type) {
    case AtlasAssetType.tractor:
      return 'Trator';
    case AtlasAssetType.vehicle:
      return 'Veículo';
    case AtlasAssetType.implement:
      return 'Implemento';
    case AtlasAssetType.machine:
      return 'Máquina';
    case AtlasAssetType.equipment:
      return 'Equipamento';
    case AtlasAssetType.generator:
      return 'Gerador';
    case AtlasAssetType.pump:
      return 'Bomba';
    case AtlasAssetType.structure:
      return 'Estrutura';
    case AtlasAssetType.other:
      return 'Outro';
  }
}

enum AtlasAssetStatus { available, inUse, maintenance, stopped, retired }

String atlasAssetStatusLabel(AtlasAssetStatus status) {
  switch (status) {
    case AtlasAssetStatus.available:
      return 'Disponível';
    case AtlasAssetStatus.inUse:
      return 'Em uso';
    case AtlasAssetStatus.maintenance:
      return 'Em manutenção';
    case AtlasAssetStatus.stopped:
      return 'Parado';
    case AtlasAssetStatus.retired:
      return 'Baixado';
  }
}

class AtlasFarmAsset {
  const AtlasFarmAsset({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.status,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.year,
    required this.purchaseAt,
    required this.purchaseValue,
    required this.currentValue,
    required this.hourMeter,
    required this.odometerKm,
    required this.location,
    required this.responsibleName,
    required this.notes,
    required this.farmName,
    required this.active,
  });

  final String id;
  final String code;
  final String name;
  final AtlasAssetType type;
  final AtlasAssetStatus status;
  final String brand;
  final String model;
  final String serialNumber;
  final int year;
  final DateTime? purchaseAt;
  final double purchaseValue;
  final double currentValue;
  final double hourMeter;
  final double odometerKm;
  final String location;
  final String responsibleName;
  final String notes;
  final String? farmName;
  final bool active;

  double get depreciationValue =>
      (purchaseValue - currentValue).clamp(0, double.infinity);

  double get depreciationPercent =>
      purchaseValue <= 0 ? 0 : depreciationValue / purchaseValue * 100;

  AtlasFarmAsset copyWith({
    String? code,
    String? name,
    AtlasAssetType? type,
    AtlasAssetStatus? status,
    String? brand,
    String? model,
    String? serialNumber,
    int? year,
    DateTime? purchaseAt,
    bool clearPurchaseAt = false,
    double? purchaseValue,
    double? currentValue,
    double? hourMeter,
    double? odometerKm,
    String? location,
    String? responsibleName,
    String? notes,
    bool? active,
  }) {
    return AtlasFarmAsset(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      year: year ?? this.year,
      purchaseAt: clearPurchaseAt ? null : purchaseAt ?? this.purchaseAt,
      purchaseValue: purchaseValue ?? this.purchaseValue,
      currentValue: currentValue ?? this.currentValue,
      hourMeter: hourMeter ?? this.hourMeter,
      odometerKm: odometerKm ?? this.odometerKm,
      location: location ?? this.location,
      responsibleName: responsibleName ?? this.responsibleName,
      notes: notes ?? this.notes,
      farmName: farmName,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'code': code,
    'name': name,
    'type': type.name,
    'status': status.name,
    'brand': brand,
    'model': model,
    'serialNumber': serialNumber,
    'year': year,
    'purchaseAt': purchaseAt?.toIso8601String(),
    'purchaseValue': purchaseValue,
    'currentValue': currentValue,
    'hourMeter': hourMeter,
    'odometerKm': odometerKm,
    'location': location,
    'responsibleName': responsibleName,
    'notes': notes,
    'farmName': farmName,
    'active': active,
  };

  factory AtlasFarmAsset.fromMap(Map<String, dynamic> map) {
    return AtlasFarmAsset(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: AtlasAssetType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasAssetType.other,
      ),
      status: AtlasAssetStatus.values.firstWhere(
        (value) => value.name == map['status']?.toString(),
        orElse: () => AtlasAssetStatus.available,
      ),
      brand: map['brand']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      serialNumber: map['serialNumber']?.toString() ?? '',
      year: _readInt(map['year']),
      purchaseAt: DateTime.tryParse(map['purchaseAt']?.toString() ?? ''),
      purchaseValue: _readDouble(map['purchaseValue']),
      currentValue: _readDouble(map['currentValue']),
      hourMeter: _readDouble(map['hourMeter']),
      odometerKm: _readDouble(map['odometerKm']),
      location: map['location']?.toString() ?? '',
      responsibleName: map['responsibleName']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
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

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

enum AtlasMaintenanceType {
  preventive,
  corrective,
  predictive,
  inspection,
  calibration,
  cleaning,
}

String atlasMaintenanceTypeLabel(AtlasMaintenanceType type) {
  switch (type) {
    case AtlasMaintenanceType.preventive:
      return 'Preventiva';
    case AtlasMaintenanceType.corrective:
      return 'Corretiva';
    case AtlasMaintenanceType.predictive:
      return 'Preditiva';
    case AtlasMaintenanceType.inspection:
      return 'Inspeção';
    case AtlasMaintenanceType.calibration:
      return 'Calibração';
    case AtlasMaintenanceType.cleaning:
      return 'Limpeza';
  }
}

enum AtlasMaintenanceStatus {
  planned,
  approved,
  inProgress,
  completed,
  cancelled,
  overdue,
}

String atlasMaintenanceStatusLabel(AtlasMaintenanceStatus status) {
  switch (status) {
    case AtlasMaintenanceStatus.planned:
      return 'Planejada';
    case AtlasMaintenanceStatus.approved:
      return 'Aprovada';
    case AtlasMaintenanceStatus.inProgress:
      return 'Em execução';
    case AtlasMaintenanceStatus.completed:
      return 'Concluída';
    case AtlasMaintenanceStatus.cancelled:
      return 'Cancelada';
    case AtlasMaintenanceStatus.overdue:
      return 'Atrasada';
  }
}

class AtlasMaintenanceOrder {
  const AtlasMaintenanceOrder({
    required this.id,
    required this.assetId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.startedAt,
    required this.completedAt,
    required this.responsibleName,
    required this.supplierName,
    required this.laborCost,
    required this.partsCost,
    required this.downtimeHours,
    required this.hourMeterAtService,
    required this.odometerAtServiceKm,
    required this.nextServiceAt,
    required this.nextServiceHourMeter,
    required this.nextServiceOdometerKm,
    required this.notes,
    required this.farmName,
  });

  final String id;
  final String assetId;
  final AtlasMaintenanceType type;
  final AtlasMaintenanceStatus status;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String responsibleName;
  final String supplierName;
  final double laborCost;
  final double partsCost;
  final double downtimeHours;
  final double hourMeterAtService;
  final double odometerAtServiceKm;
  final DateTime? nextServiceAt;
  final double nextServiceHourMeter;
  final double nextServiceOdometerKm;
  final String notes;
  final String? farmName;

  double get totalCost => laborCost + partsCost;

  bool get isOverdue {
    return status != AtlasMaintenanceStatus.completed &&
        status != AtlasMaintenanceStatus.cancelled &&
        scheduledAt.isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'assetId': assetId,
    'type': type.name,
    'status': status.name,
    'title': title,
    'description': description,
    'scheduledAt': scheduledAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'responsibleName': responsibleName,
    'supplierName': supplierName,
    'laborCost': laborCost,
    'partsCost': partsCost,
    'downtimeHours': downtimeHours,
    'hourMeterAtService': hourMeterAtService,
    'odometerAtServiceKm': odometerAtServiceKm,
    'nextServiceAt': nextServiceAt?.toIso8601String(),
    'nextServiceHourMeter': nextServiceHourMeter,
    'nextServiceOdometerKm': nextServiceOdometerKm,
    'notes': notes,
    'farmName': farmName,
  };

  factory AtlasMaintenanceOrder.fromMap(Map<String, dynamic> map) {
    return AtlasMaintenanceOrder(
      id: map['id']?.toString() ?? '',
      assetId: map['assetId']?.toString() ?? '',
      type: AtlasMaintenanceType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasMaintenanceType.preventive,
      ),
      status: AtlasMaintenanceStatus.values.firstWhere(
        (value) => value.name == map['status']?.toString(),
        orElse: () => AtlasMaintenanceStatus.planned,
      ),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      scheduledAt:
          DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      startedAt: DateTime.tryParse(map['startedAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? ''),
      responsibleName: map['responsibleName']?.toString() ?? '',
      supplierName: map['supplierName']?.toString() ?? '',
      laborCost: _readDouble(map['laborCost']),
      partsCost: _readDouble(map['partsCost']),
      downtimeHours: _readDouble(map['downtimeHours']),
      hourMeterAtService: _readDouble(map['hourMeterAtService']),
      odometerAtServiceKm: _readDouble(map['odometerAtServiceKm']),
      nextServiceAt: DateTime.tryParse(map['nextServiceAt']?.toString() ?? ''),
      nextServiceHourMeter: _readDouble(map['nextServiceHourMeter']),
      nextServiceOdometerKm: _readDouble(map['nextServiceOdometerKm']),
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

class AtlasAssetUsageRecord {
  const AtlasAssetUsageRecord({
    required this.id,
    required this.assetId,
    required this.occurredAt,
    required this.operatorName,
    required this.activity,
    required this.startHourMeter,
    required this.endHourMeter,
    required this.startOdometerKm,
    required this.endOdometerKm,
    required this.fuelLiters,
    required this.lubricantLiters,
    required this.areaWorkedHectares,
    required this.notes,
    required this.farmName,
  });

  final String id;
  final String assetId;
  final DateTime occurredAt;
  final String operatorName;
  final String activity;
  final double startHourMeter;
  final double endHourMeter;
  final double startOdometerKm;
  final double endOdometerKm;
  final double fuelLiters;
  final double lubricantLiters;
  final double areaWorkedHectares;
  final String notes;
  final String? farmName;

  double get workedHours =>
      (endHourMeter - startHourMeter).clamp(0, double.infinity);

  double get traveledKm =>
      (endOdometerKm - startOdometerKm).clamp(0, double.infinity);

  double get litersPerHour => workedHours <= 0 ? 0 : fuelLiters / workedHours;

  double get litersPerHectare =>
      areaWorkedHectares <= 0 ? 0 : fuelLiters / areaWorkedHectares;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'assetId': assetId,
    'occurredAt': occurredAt.toIso8601String(),
    'operatorName': operatorName,
    'activity': activity,
    'startHourMeter': startHourMeter,
    'endHourMeter': endHourMeter,
    'startOdometerKm': startOdometerKm,
    'endOdometerKm': endOdometerKm,
    'fuelLiters': fuelLiters,
    'lubricantLiters': lubricantLiters,
    'areaWorkedHectares': areaWorkedHectares,
    'notes': notes,
    'farmName': farmName,
  };

  factory AtlasAssetUsageRecord.fromMap(Map<String, dynamic> map) {
    return AtlasAssetUsageRecord(
      id: map['id']?.toString() ?? '',
      assetId: map['assetId']?.toString() ?? '',
      occurredAt:
          DateTime.tryParse(map['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      operatorName: map['operatorName']?.toString() ?? '',
      activity: map['activity']?.toString() ?? '',
      startHourMeter: _readDouble(map['startHourMeter']),
      endHourMeter: _readDouble(map['endHourMeter']),
      startOdometerKm: _readDouble(map['startOdometerKm']),
      endOdometerKm: _readDouble(map['endOdometerKm']),
      fuelLiters: _readDouble(map['fuelLiters']),
      lubricantLiters: _readDouble(map['lubricantLiters']),
      areaWorkedHectares: _readDouble(map['areaWorkedHectares']),
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

class AtlasAssetMaintenanceSummary {
  const AtlasAssetMaintenanceSummary({
    required this.totalAssets,
    required this.availableAssets,
    required this.assetsInMaintenance,
    required this.stoppedAssets,
    required this.openOrders,
    required this.overdueOrders,
    required this.monthlyMaintenanceCost,
    required this.totalDowntimeHours,
    required this.monthlyFuelLiters,
    required this.averageFuelPerHour,
    required this.totalCurrentAssetValue,
  });

  final int totalAssets;
  final int availableAssets;
  final int assetsInMaintenance;
  final int stoppedAssets;
  final int openOrders;
  final int overdueOrders;
  final double monthlyMaintenanceCost;
  final double totalDowntimeHours;
  final double monthlyFuelLiters;
  final double averageFuelPerHour;
  final double totalCurrentAssetValue;
}
