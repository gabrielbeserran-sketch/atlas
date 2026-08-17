enum AtlasFeedCategory {
  roughage,
  concentrate,
  mineral,
  additive,
  byproduct,
  other,
}

String atlasFeedCategoryLabel(AtlasFeedCategory value) {
  switch (value) {
    case AtlasFeedCategory.roughage:
      return 'Volumoso';
    case AtlasFeedCategory.concentrate:
      return 'Concentrado';
    case AtlasFeedCategory.mineral:
      return 'Mineral';
    case AtlasFeedCategory.additive:
      return 'Aditivo';
    case AtlasFeedCategory.byproduct:
      return 'Subproduto';
    case AtlasFeedCategory.other:
      return 'Outro';
  }
}

class AtlasFeedIngredient {
  const AtlasFeedIngredient({
    required this.id,
    required this.name,
    required this.category,
    required this.dryMatterPercent,
    required this.crudeProteinPercent,
    required this.ndfPercent,
    required this.energyMcalKg,
    required this.costPerKg,
    required this.stockKg,
    required this.minimumStockKg,
    required this.farmName,
  });

  final String id;
  final String name;
  final AtlasFeedCategory category;
  final double dryMatterPercent;
  final double crudeProteinPercent;
  final double ndfPercent;
  final double energyMcalKg;
  final double costPerKg;
  final double stockKg;
  final double minimumStockKg;
  final String? farmName;

  bool get needsRestock => stockKg <= minimumStockKg;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category.name,
    'dryMatterPercent': dryMatterPercent,
    'crudeProteinPercent': crudeProteinPercent,
    'ndfPercent': ndfPercent,
    'energyMcalKg': energyMcalKg,
    'costPerKg': costPerKg,
    'stockKg': stockKg,
    'minimumStockKg': minimumStockKg,
    'farmName': farmName,
  };

  factory AtlasFeedIngredient.fromMap(Map<String, dynamic> map) {
    double d(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return AtlasFeedIngredient(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: AtlasFeedCategory.values.firstWhere(
        (e) => e.name == map['category']?.toString(),
        orElse: () => AtlasFeedCategory.other,
      ),
      dryMatterPercent: d('dryMatterPercent'),
      crudeProteinPercent: d('crudeProteinPercent'),
      ndfPercent: d('ndfPercent'),
      energyMcalKg: d('energyMcalKg'),
      costPerKg: d('costPerKg'),
      stockKg: d('stockKg'),
      minimumStockKg: d('minimumStockKg'),
      farmName: map['farmName']?.toString(),
    );
  }
}

class AtlasDietIngredient {
  const AtlasDietIngredient({
    required this.ingredientId,
    required this.quantityKgPerAnimalDay,
  });

  final String ingredientId;
  final double quantityKgPerAnimalDay;

  Map<String, dynamic> toMap() => {
    'ingredientId': ingredientId,
    'quantityKgPerAnimalDay': quantityKgPerAnimalDay,
  };

  factory AtlasDietIngredient.fromMap(Map<String, dynamic> map) {
    return AtlasDietIngredient(
      ingredientId: map['ingredientId']?.toString() ?? '',
      quantityKgPerAnimalDay:
          (map['quantityKgPerAnimalDay'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AtlasDietPlan {
  const AtlasDietPlan({
    required this.id,
    required this.name,
    required this.lotName,
    required this.animalCount,
    required this.targetDailyGainKg,
    required this.ingredients,
    required this.startAt,
    required this.endAt,
    required this.active,
    required this.farmName,
  });

  final String id;
  final String name;
  final String lotName;
  final int animalCount;
  final double targetDailyGainKg;
  final List<AtlasDietIngredient> ingredients;
  final DateTime startAt;
  final DateTime endAt;
  final bool active;
  final String? farmName;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'lotName': lotName,
    'animalCount': animalCount,
    'targetDailyGainKg': targetDailyGainKg,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
    'active': active,
    'farmName': farmName,
  };

  factory AtlasDietPlan.fromMap(Map<String, dynamic> map) {
    return AtlasDietPlan(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      lotName: map['lotName']?.toString() ?? '',
      animalCount: (map['animalCount'] as num?)?.toInt() ?? 0,
      targetDailyGainKg: (map['targetDailyGainKg'] as num?)?.toDouble() ?? 0,
      ingredients: (map['ingredients'] as List? ?? const [])
          .map(
            (e) => AtlasDietIngredient.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      startAt:
          DateTime.tryParse(map['startAt']?.toString() ?? '') ?? DateTime.now(),
      endAt:
          DateTime.tryParse(map['endAt']?.toString() ?? '') ?? DateTime.now(),
      active: map['active'] != false,
      farmName: map['farmName']?.toString(),
    );
  }
}

class AtlasFeedConsumptionRecord {
  const AtlasFeedConsumptionRecord({
    required this.id,
    required this.dietId,
    required this.lotName,
    required this.recordedAt,
    required this.offeredKg,
    required this.leftoverKg,
    required this.animalCount,
    required this.averageWeightKg,
    required this.averageDailyGainKg,
    required this.farmName,
  });

  final String id;
  final String dietId;
  final String lotName;
  final DateTime recordedAt;
  final double offeredKg;
  final double leftoverKg;
  final int animalCount;
  final double averageWeightKg;
  final double averageDailyGainKg;
  final String? farmName;

  double get consumedKg => (offeredKg - leftoverKg).clamp(0, double.infinity);
  double get consumptionPerAnimalKg =>
      animalCount <= 0 ? 0 : consumedKg / animalCount;
  double get feedConversion =>
      averageDailyGainKg <= 0 ? 0 : consumptionPerAnimalKg / averageDailyGainKg;

  Map<String, dynamic> toMap() => {
    'id': id,
    'dietId': dietId,
    'lotName': lotName,
    'recordedAt': recordedAt.toIso8601String(),
    'offeredKg': offeredKg,
    'leftoverKg': leftoverKg,
    'animalCount': animalCount,
    'averageWeightKg': averageWeightKg,
    'averageDailyGainKg': averageDailyGainKg,
    'farmName': farmName,
  };

  factory AtlasFeedConsumptionRecord.fromMap(Map<String, dynamic> map) {
    return AtlasFeedConsumptionRecord(
      id: map['id']?.toString() ?? '',
      dietId: map['dietId']?.toString() ?? '',
      lotName: map['lotName']?.toString() ?? '',
      recordedAt:
          DateTime.tryParse(map['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
      offeredKg: (map['offeredKg'] as num?)?.toDouble() ?? 0,
      leftoverKg: (map['leftoverKg'] as num?)?.toDouble() ?? 0,
      animalCount: (map['animalCount'] as num?)?.toInt() ?? 0,
      averageWeightKg: (map['averageWeightKg'] as num?)?.toDouble() ?? 0,
      averageDailyGainKg: (map['averageDailyGainKg'] as num?)?.toDouble() ?? 0,
      farmName: map['farmName']?.toString(),
    );
  }
}
