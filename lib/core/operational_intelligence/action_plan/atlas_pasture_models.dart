enum AtlasPaddockStatus { available, occupied, resting, maintenance, reform }

String atlasPaddockStatusLabel(AtlasPaddockStatus value) {
  switch (value) {
    case AtlasPaddockStatus.available: return 'Disponível';
    case AtlasPaddockStatus.occupied: return 'Ocupado';
    case AtlasPaddockStatus.resting: return 'Descanso';
    case AtlasPaddockStatus.maintenance: return 'Manutenção';
    case AtlasPaddockStatus.reform: return 'Reforma';
  }
}

class AtlasPaddock {
  const AtlasPaddock({
    required this.id,
    required this.name,
    required this.areaHectares,
    required this.forageSpecies,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.targetHeightCm,
    required this.currentHeightCm,
    required this.dryMatterKgHa,
    required this.supportCapacityAuHa,
    required this.irrigated,
    required this.farmName,
  });

  final String id;
  final String name;
  final double areaHectares;
  final String forageSpecies;
  final AtlasPaddockStatus status;
  final double latitude;
  final double longitude;
  final double targetHeightCm;
  final double currentHeightCm;
  final double dryMatterKgHa;
  final double supportCapacityAuHa;
  final bool irrigated;
  final String? farmName;

  bool get belowTargetHeight => currentHeightCm < targetHeightCm * 0.8;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'areaHectares': areaHectares,
    'forageSpecies': forageSpecies,
    'status': status.name,
    'latitude': latitude,
    'longitude': longitude,
    'targetHeightCm': targetHeightCm,
    'currentHeightCm': currentHeightCm,
    'dryMatterKgHa': dryMatterKgHa,
    'supportCapacityAuHa': supportCapacityAuHa,
    'irrigated': irrigated,
    'farmName': farmName,
  };

  factory AtlasPaddock.fromMap(Map<String, dynamic> map) {
    double d(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return AtlasPaddock(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      areaHectares: d('areaHectares'),
      forageSpecies: map['forageSpecies']?.toString() ?? '',
      status: AtlasPaddockStatus.values.firstWhere(
        (e) => e.name == map['status']?.toString(),
        orElse: () => AtlasPaddockStatus.available,
      ),
      latitude: d('latitude'),
      longitude: d('longitude'),
      targetHeightCm: d('targetHeightCm'),
      currentHeightCm: d('currentHeightCm'),
      dryMatterKgHa: d('dryMatterKgHa'),
      supportCapacityAuHa: d('supportCapacityAuHa'),
      irrigated: map['irrigated'] == true,
      farmName: map['farmName']?.toString(),
    );
  }
}

class AtlasGrazingRotation {
  const AtlasGrazingRotation({
    required this.id,
    required this.paddockId,
    required this.lotName,
    required this.animalCount,
    required this.entryAt,
    required this.exitAt,
    required this.restDays,
    required this.farmName,
  });

  final String id;
  final String paddockId;
  final String lotName;
  final int animalCount;
  final DateTime entryAt;
  final DateTime exitAt;
  final int restDays;
  final String? farmName;

  DateTime get nextAvailableAt => exitAt.add(Duration(days: restDays));

  Map<String, dynamic> toMap() => {
    'id': id,
    'paddockId': paddockId,
    'lotName': lotName,
    'animalCount': animalCount,
    'entryAt': entryAt.toIso8601String(),
    'exitAt': exitAt.toIso8601String(),
    'restDays': restDays,
    'farmName': farmName,
  };

  factory AtlasGrazingRotation.fromMap(Map<String, dynamic> map) {
    return AtlasGrazingRotation(
      id: map['id']?.toString() ?? '',
      paddockId: map['paddockId']?.toString() ?? '',
      lotName: map['lotName']?.toString() ?? '',
      animalCount: (map['animalCount'] as num?)?.toInt() ?? 0,
      entryAt: DateTime.tryParse(map['entryAt']?.toString() ?? '') ??
          DateTime.now(),
      exitAt: DateTime.tryParse(map['exitAt']?.toString() ?? '') ??
          DateTime.now(),
      restDays: (map['restDays'] as num?)?.toInt() ?? 0,
      farmName: map['farmName']?.toString(),
    );
  }
}

enum AtlasPastureOperationType {
  fertilization,
  irrigation,
  mowing,
  weedControl,
  soilCorrection,
  reseeding,
  reform,
}

String atlasPastureOperationTypeLabel(AtlasPastureOperationType value) {
  switch (value) {
    case AtlasPastureOperationType.fertilization: return 'Adubação';
    case AtlasPastureOperationType.irrigation: return 'Irrigação';
    case AtlasPastureOperationType.mowing: return 'Roçada';
    case AtlasPastureOperationType.weedControl: return 'Controle de invasoras';
    case AtlasPastureOperationType.soilCorrection: return 'Correção do solo';
    case AtlasPastureOperationType.reseeding: return 'Ressemeadura';
    case AtlasPastureOperationType.reform: return 'Reforma';
  }
}

class AtlasPastureOperation {
  const AtlasPastureOperation({
    required this.id,
    required this.paddockId,
    required this.type,
    required this.scheduledAt,
    required this.completedAt,
    required this.product,
    required this.dose,
    required this.cost,
    required this.notes,
    required this.farmName,
  });

  final String id;
  final String paddockId;
  final AtlasPastureOperationType type;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String product;
  final String dose;
  final double cost;
  final String notes;
  final String? farmName;

  bool get isCompleted => completedAt != null;
  bool get isOverdue =>
      !isCompleted && scheduledAt.isBefore(DateTime.now());

  Map<String, dynamic> toMap() => {
    'id': id,
    'paddockId': paddockId,
    'type': type.name,
    'scheduledAt': scheduledAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'product': product,
    'dose': dose,
    'cost': cost,
    'notes': notes,
    'farmName': farmName,
  };

  factory AtlasPastureOperation.fromMap(Map<String, dynamic> map) {
    return AtlasPastureOperation(
      id: map['id']?.toString() ?? '',
      paddockId: map['paddockId']?.toString() ?? '',
      type: AtlasPastureOperationType.values.firstWhere(
        (e) => e.name == map['type']?.toString(),
        orElse: () => AtlasPastureOperationType.fertilization,
      ),
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? ''),
      product: map['product']?.toString() ?? '',
      dose: map['dose']?.toString() ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      notes: map['notes']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
    );
  }
}
