enum AtlasEsgCategory {
  carbon,
  water,
  energy,
  biodiversity,
  preservation,
  waste,
  social,
  governance,
}

String atlasEsgCategoryLabel(AtlasEsgCategory value) {
  switch (value) {
    case AtlasEsgCategory.carbon:
      return 'Carbono';
    case AtlasEsgCategory.water:
      return 'Água';
    case AtlasEsgCategory.energy:
      return 'Energia';
    case AtlasEsgCategory.biodiversity:
      return 'Biodiversidade';
    case AtlasEsgCategory.preservation:
      return 'Preservação';
    case AtlasEsgCategory.waste:
      return 'Resíduos';
    case AtlasEsgCategory.social:
      return 'Social';
    case AtlasEsgCategory.governance:
      return 'Governança';
  }
}

class AtlasEsgRecord {
  const AtlasEsgRecord({
    required this.id,
    required this.category,
    required this.occurredAt,
    required this.title,
    required this.value,
    required this.unit,
    required this.financialValue,
    required this.evidence,
    required this.responsibleName,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final AtlasEsgCategory category;
  final DateTime occurredAt;
  final String title;
  final double value;
  final String unit;
  final double financialValue;
  final String evidence;
  final String responsibleName;
  final String? farmName;
  final String notes;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'category': category.name,
        'occurredAt': occurredAt.toIso8601String(),
        'title': title,
        'value': value,
        'unit': unit,
        'financialValue': financialValue,
        'evidence': evidence,
        'responsibleName': responsibleName,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasEsgRecord.fromMap(Map<String, dynamic> map) {
    return AtlasEsgRecord(
      id: map['id']?.toString() ?? '',
      category: AtlasEsgCategory.values.firstWhere(
        (item) => item.name == map['category']?.toString(),
        orElse: () => AtlasEsgCategory.governance,
      ),
      occurredAt: DateTime.tryParse(
            map['occurredAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      title: map['title']?.toString() ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      financialValue:
          (map['financialValue'] as num?)?.toDouble() ?? 0,
      evidence: map['evidence']?.toString() ?? '',
      responsibleName:
          map['responsibleName']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasCarbonInventory {
  const AtlasCarbonInventory({
    required this.entericMethaneTco2e,
    required this.manureTco2e,
    required this.fuelTco2e,
    required this.electricityTco2e,
    required this.soilAndFertilizerTco2e,
    required this.sequestrationTco2e,
  });

  final double entericMethaneTco2e;
  final double manureTco2e;
  final double fuelTco2e;
  final double electricityTco2e;
  final double soilAndFertilizerTco2e;
  final double sequestrationTco2e;

  double get grossEmissionsTco2e =>
      entericMethaneTco2e +
      manureTco2e +
      fuelTco2e +
      electricityTco2e +
      soilAndFertilizerTco2e;

  double get netEmissionsTco2e =>
      grossEmissionsTco2e - sequestrationTco2e;
}

class AtlasEsgExecutiveSnapshot {
  const AtlasEsgExecutiveSnapshot({
    required this.carbonInventory,
    required this.waterConsumptionM3,
    required this.energyConsumptionKwh,
    required this.renewableEnergyPercent,
    required this.preservedAreaHectares,
    required this.recoveredAreaHectares,
    required this.wasteRecoveredPercent,
    required this.socialScore,
    required this.governanceScore,
    required this.esgScore,
  });

  final AtlasCarbonInventory carbonInventory;
  final double waterConsumptionM3;
  final double energyConsumptionKwh;
  final double renewableEnergyPercent;
  final double preservedAreaHectares;
  final double recoveredAreaHectares;
  final double wasteRecoveredPercent;
  final double socialScore;
  final double governanceScore;
  final double esgScore;
}
