enum AtlasCropStatus {
  planned,
  planted,
  developing,
  harvesting,
  completed,
  cancelled,
}

String atlasCropStatusLabel(AtlasCropStatus value) {
  switch (value) {
    case AtlasCropStatus.planned:
      return 'Planejada';
    case AtlasCropStatus.planted:
      return 'Plantada';
    case AtlasCropStatus.developing:
      return 'Em desenvolvimento';
    case AtlasCropStatus.harvesting:
      return 'Em colheita';
    case AtlasCropStatus.completed:
      return 'Concluída';
    case AtlasCropStatus.cancelled:
      return 'Cancelada';
  }
}

enum AtlasAgriculturalOperationType {
  soilSampling,
  soilCorrection,
  fertilization,
  planting,
  spraying,
  irrigation,
  monitoring,
  harvesting,
  transport,
  other,
}

String atlasAgriculturalOperationTypeLabel(
  AtlasAgriculturalOperationType value,
) {
  switch (value) {
    case AtlasAgriculturalOperationType.soilSampling:
      return 'Amostragem de solo';
    case AtlasAgriculturalOperationType.soilCorrection:
      return 'Correção do solo';
    case AtlasAgriculturalOperationType.fertilization:
      return 'Adubação';
    case AtlasAgriculturalOperationType.planting:
      return 'Plantio';
    case AtlasAgriculturalOperationType.spraying:
      return 'Pulverização';
    case AtlasAgriculturalOperationType.irrigation:
      return 'Irrigação';
    case AtlasAgriculturalOperationType.monitoring:
      return 'Monitoramento';
    case AtlasAgriculturalOperationType.harvesting:
      return 'Colheita';
    case AtlasAgriculturalOperationType.transport:
      return 'Transporte';
    case AtlasAgriculturalOperationType.other:
      return 'Outra';
  }
}

class AtlasCropField {
  const AtlasCropField({
    required this.id,
    required this.name,
    required this.crop,
    required this.variety,
    required this.areaHectares,
    required this.status,
    required this.plantingAt,
    required this.expectedHarvestAt,
    required this.targetProductivityKgHa,
    required this.actualProductivityKgHa,
    required this.latitude,
    required this.longitude,
    required this.integratedLivestock,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String name;
  final String crop;
  final String variety;
  final double areaHectares;
  final AtlasCropStatus status;
  final DateTime? plantingAt;
  final DateTime? expectedHarvestAt;
  final double targetProductivityKgHa;
  final double actualProductivityKgHa;
  final double latitude;
  final double longitude;
  final bool integratedLivestock;
  final String? farmName;
  final String notes;

  double get productivityAchievementPercent =>
      targetProductivityKgHa <= 0
          ? 0
          : actualProductivityKgHa /
              targetProductivityKgHa *
              100;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'crop': crop,
        'variety': variety,
        'areaHectares': areaHectares,
        'status': status.name,
        'plantingAt': plantingAt?.toIso8601String(),
        'expectedHarvestAt':
            expectedHarvestAt?.toIso8601String(),
        'targetProductivityKgHa': targetProductivityKgHa,
        'actualProductivityKgHa': actualProductivityKgHa,
        'latitude': latitude,
        'longitude': longitude,
        'integratedLivestock': integratedLivestock,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasCropField.fromMap(Map<String, dynamic> map) {
    return AtlasCropField(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      crop: map['crop']?.toString() ?? '',
      variety: map['variety']?.toString() ?? '',
      areaHectares:
          (map['areaHectares'] as num?)?.toDouble() ?? 0,
      status: AtlasCropStatus.values.firstWhere(
        (value) => value.name == map['status']?.toString(),
        orElse: () => AtlasCropStatus.planned,
      ),
      plantingAt: DateTime.tryParse(
        map['plantingAt']?.toString() ?? '',
      ),
      expectedHarvestAt: DateTime.tryParse(
        map['expectedHarvestAt']?.toString() ?? '',
      ),
      targetProductivityKgHa:
          (map['targetProductivityKgHa'] as num?)
                  ?.toDouble() ??
              0,
      actualProductivityKgHa:
          (map['actualProductivityKgHa'] as num?)
                  ?.toDouble() ??
              0,
      latitude:
          (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude:
          (map['longitude'] as num?)?.toDouble() ?? 0,
      integratedLivestock:
          map['integratedLivestock'] == true,
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasSoilSample {
  const AtlasSoilSample({
    required this.id,
    required this.fieldId,
    required this.sampledAt,
    required this.depthCm,
    required this.ph,
    required this.organicMatterPercent,
    required this.phosphorusMgDm3,
    required this.potassiumMgDm3,
    required this.baseSaturationPercent,
    required this.clayPercent,
    required this.laboratory,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String fieldId;
  final DateTime sampledAt;
  final double depthCm;
  final double ph;
  final double organicMatterPercent;
  final double phosphorusMgDm3;
  final double potassiumMgDm3;
  final double baseSaturationPercent;
  final double clayPercent;
  final String laboratory;
  final String? farmName;
  final String notes;

  double get soilScore {
    var score = 100.0;
    if (ph < 5.2) score -= 20;
    if (organicMatterPercent < 2) score -= 15;
    if (phosphorusMgDm3 < 8) score -= 15;
    if (potassiumMgDm3 < 50) score -= 15;
    if (baseSaturationPercent < 50) score -= 20;
    return score.clamp(0, 100);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'fieldId': fieldId,
        'sampledAt': sampledAt.toIso8601String(),
        'depthCm': depthCm,
        'ph': ph,
        'organicMatterPercent': organicMatterPercent,
        'phosphorusMgDm3': phosphorusMgDm3,
        'potassiumMgDm3': potassiumMgDm3,
        'baseSaturationPercent': baseSaturationPercent,
        'clayPercent': clayPercent,
        'laboratory': laboratory,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasSoilSample.fromMap(Map<String, dynamic> map) {
    double value(String key) =>
        (map[key] as num?)?.toDouble() ?? 0;
    return AtlasSoilSample(
      id: map['id']?.toString() ?? '',
      fieldId: map['fieldId']?.toString() ?? '',
      sampledAt: DateTime.tryParse(
            map['sampledAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      depthCm: value('depthCm'),
      ph: value('ph'),
      organicMatterPercent: value('organicMatterPercent'),
      phosphorusMgDm3: value('phosphorusMgDm3'),
      potassiumMgDm3: value('potassiumMgDm3'),
      baseSaturationPercent:
          value('baseSaturationPercent'),
      clayPercent: value('clayPercent'),
      laboratory: map['laboratory']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasAgriculturalOperation {
  const AtlasAgriculturalOperation({
    required this.id,
    required this.fieldId,
    required this.type,
    required this.scheduledAt,
    required this.completedAt,
    required this.product,
    required this.dose,
    required this.areaHectares,
    required this.cost,
    required this.responsibleName,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String fieldId;
  final AtlasAgriculturalOperationType type;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String product;
  final String dose;
  final double areaHectares;
  final double cost;
  final String responsibleName;
  final String? farmName;
  final String notes;

  bool get isCompleted => completedAt != null;
  bool get isOverdue =>
      !isCompleted && scheduledAt.isBefore(DateTime.now());

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'fieldId': fieldId,
        'type': type.name,
        'scheduledAt': scheduledAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'product': product,
        'dose': dose,
        'areaHectares': areaHectares,
        'cost': cost,
        'responsibleName': responsibleName,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasAgriculturalOperation.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasAgriculturalOperation(
      id: map['id']?.toString() ?? '',
      fieldId: map['fieldId']?.toString() ?? '',
      type: AtlasAgriculturalOperationType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasAgriculturalOperationType.other,
      ),
      scheduledAt: DateTime.tryParse(
            map['scheduledAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      completedAt: DateTime.tryParse(
        map['completedAt']?.toString() ?? '',
      ),
      product: map['product']?.toString() ?? '',
      dose: map['dose']?.toString() ?? '',
      areaHectares:
          (map['areaHectares'] as num?)?.toDouble() ?? 0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      responsibleName:
          map['responsibleName']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasAgricultureExecutiveSnapshot {
  const AtlasAgricultureExecutiveSnapshot({
    required this.totalFields,
    required this.totalAreaHectares,
    required this.plantedAreaHectares,
    required this.integratedAreaHectares,
    required this.averageTargetProductivityKgHa,
    required this.averageActualProductivityKgHa,
    required this.totalOperatingCost,
    required this.overdueOperations,
    required this.averageSoilScore,
    required this.agricultureScore,
  });

  final int totalFields;
  final double totalAreaHectares;
  final double plantedAreaHectares;
  final double integratedAreaHectares;
  final double averageTargetProductivityKgHa;
  final double averageActualProductivityKgHa;
  final double totalOperatingCost;
  final int overdueOperations;
  final double averageSoilScore;
  final double agricultureScore;
}
