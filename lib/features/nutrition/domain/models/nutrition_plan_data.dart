class NutritionIngredientData {
  const NutritionIngredientData({
    required this.name,
    required this.type,
    required this.inclusionKg,
    required this.dryMatterPercent,
    required this.crudeProteinPercent,
    required this.ndfPercent,
    required this.adfPercent,
    required this.tdnPercent,
    required this.costPerKg,
  });

  final String name;
  final String type;
  final double inclusionKg;
  final double dryMatterPercent;
  final double crudeProteinPercent;
  final double ndfPercent;
  final double adfPercent;
  final double tdnPercent;
  final double costPerKg;

  double get dailyCostPerAnimal => inclusionKg * costPerKg;

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'inclusionKg': inclusionKg,
    'dryMatterPercent': dryMatterPercent,
    'crudeProteinPercent': crudeProteinPercent,
    'ndfPercent': ndfPercent,
    'adfPercent': adfPercent,
    'tdnPercent': tdnPercent,
    'costPerKg': costPerKg,
  };

  factory NutritionIngredientData.fromMap(Map<String, dynamic> map) {
    return NutritionIngredientData(
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'Outro',
      inclusionKg: (map['inclusionKg'] as num?)?.toDouble() ?? 0,
      dryMatterPercent: (map['dryMatterPercent'] as num?)?.toDouble() ?? 0,
      crudeProteinPercent:
          (map['crudeProteinPercent'] as num?)?.toDouble() ?? 0,
      ndfPercent: (map['ndfPercent'] as num?)?.toDouble() ?? 0,
      adfPercent: (map['adfPercent'] as num?)?.toDouble() ?? 0,
      tdnPercent: (map['tdnPercent'] as num?)?.toDouble() ?? 0,
      costPerKg: (map['costPerKg'] as num?)?.toDouble() ?? 0,
    );
  }
}

class NutritionPlanData {
  const NutritionPlanData({
    required this.id,
    required this.farmName,
    required this.groupName,
    required this.dietName,
    required this.category,
    required this.dailyAmountKg,
    required this.animalCount,
    required this.costPerKg,
    required this.startDate,
    required this.notes,
    this.averageBodyWeightKg = 0,
    this.targetDailyGainKg = 0,
    this.observedDailyGainKg = 0,
    this.feedConversion = 0,
    this.pastureType = '',
    this.silageType = '',
    this.concentrateType = '',
    this.mineralSupplement = '',
    this.dryMatterPercent = 0,
    this.crudeProteinPercent = 0,
    this.ndfPercent = 0,
    this.adfPercent = 0,
    this.tdnPercent = 0,
    this.stockIntegrationEnabled = false,
    this.inventoryDeducted = false,
    this.inventoryDeductionCost = 0,
    this.ingredients = const [],
  });

  final String id;
  final String farmName;
  final String groupName;
  final String dietName;
  final String category;
  final double dailyAmountKg;
  final int animalCount;
  final double costPerKg;
  final String startDate;
  final String notes;
  final double averageBodyWeightKg;
  final double targetDailyGainKg;
  final double observedDailyGainKg;
  final double feedConversion;
  final String pastureType;
  final String silageType;
  final String concentrateType;
  final String mineralSupplement;
  final double dryMatterPercent;
  final double crudeProteinPercent;
  final double ndfPercent;
  final double adfPercent;
  final double tdnPercent;
  final bool stockIntegrationEnabled;
  final bool inventoryDeducted;
  final double inventoryDeductionCost;
  final List<NutritionIngredientData> ingredients;

  double get totalDailyKg => dailyAmountKg * animalCount;
  double get dailyCost => totalDailyKg * effectiveCostPerKg;
  double get monthlyCost => dailyCost * 30;
  double get dryMatterIntakeKg => dailyAmountKg * dryMatterPercent / 100;
  double get dryMatterIntakePercentBodyWeight => averageBodyWeightKg <= 0
      ? 0
      : dryMatterIntakeKg / averageBodyWeightKg * 100;
  double get effectiveCostPerKg {
    if (ingredients.isEmpty) return costPerKg;
    final totalKg = ingredients.fold<double>(
      0,
      (sum, i) => sum + i.inclusionKg,
    );
    if (totalKg <= 0) return costPerKg;
    final totalCost = ingredients.fold<double>(
      0,
      (sum, i) => sum + i.dailyCostPerAnimal,
    );
    return totalCost / totalKg;
  }

  double get calculatedFeedConversion {
    if (feedConversion > 0) return feedConversion;
    if (observedDailyGainKg <= 0) return 0;
    return dryMatterIntakeKg / observedDailyGainKg;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'farmName': farmName,
    'groupName': groupName,
    'dietName': dietName,
    'category': category,
    'dailyAmountKg': dailyAmountKg,
    'animalCount': animalCount,
    'costPerKg': costPerKg,
    'startDate': startDate,
    'notes': notes,
    'averageBodyWeightKg': averageBodyWeightKg,
    'targetDailyGainKg': targetDailyGainKg,
    'observedDailyGainKg': observedDailyGainKg,
    'feedConversion': feedConversion,
    'pastureType': pastureType,
    'silageType': silageType,
    'concentrateType': concentrateType,
    'mineralSupplement': mineralSupplement,
    'dryMatterPercent': dryMatterPercent,
    'crudeProteinPercent': crudeProteinPercent,
    'ndfPercent': ndfPercent,
    'adfPercent': adfPercent,
    'tdnPercent': tdnPercent,
    'stockIntegrationEnabled': stockIntegrationEnabled,
    'inventoryDeducted': inventoryDeducted,
    'inventoryDeductionCost': inventoryDeductionCost,
    'ingredients': ingredients.map((item) => item.toMap()).toList(),
  };

  factory NutritionPlanData.fromMap(Map<String, dynamic> map) {
    final ingredientMaps = (map['ingredients'] as List<dynamic>?) ?? const [];
    return NutritionPlanData(
      id: map['id'] as String? ?? '',
      farmName: map['farmName'] as String? ?? '',
      groupName: map['groupName'] as String? ?? '',
      dietName: map['dietName'] as String? ?? '',
      category: map['category'] as String? ?? 'Outro',
      dailyAmountKg: (map['dailyAmountKg'] as num?)?.toDouble() ?? 0,
      animalCount: (map['animalCount'] as num?)?.toInt() ?? 0,
      costPerKg: (map['costPerKg'] as num?)?.toDouble() ?? 0,
      startDate: map['startDate'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      averageBodyWeightKg:
          (map['averageBodyWeightKg'] as num?)?.toDouble() ?? 0,
      targetDailyGainKg: (map['targetDailyGainKg'] as num?)?.toDouble() ?? 0,
      observedDailyGainKg:
          (map['observedDailyGainKg'] as num?)?.toDouble() ?? 0,
      feedConversion: (map['feedConversion'] as num?)?.toDouble() ?? 0,
      pastureType: map['pastureType'] as String? ?? '',
      silageType: map['silageType'] as String? ?? '',
      concentrateType: map['concentrateType'] as String? ?? '',
      mineralSupplement: map['mineralSupplement'] as String? ?? '',
      dryMatterPercent: (map['dryMatterPercent'] as num?)?.toDouble() ?? 0,
      crudeProteinPercent:
          (map['crudeProteinPercent'] as num?)?.toDouble() ?? 0,
      ndfPercent: (map['ndfPercent'] as num?)?.toDouble() ?? 0,
      adfPercent: (map['adfPercent'] as num?)?.toDouble() ?? 0,
      tdnPercent: (map['tdnPercent'] as num?)?.toDouble() ?? 0,
      stockIntegrationEnabled: map['stockIntegrationEnabled'] as bool? ?? false,
      inventoryDeducted: map['inventoryDeducted'] as bool? ?? false,
      inventoryDeductionCost:
          (map['inventoryDeductionCost'] as num?)?.toDouble() ?? 0,
      ingredients: ingredientMaps
          .map(
            (item) => NutritionIngredientData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  NutritionPlanData copyWith({
    bool? inventoryDeducted,
    double? inventoryDeductionCost,
  }) {
    return NutritionPlanData(
      id: id,
      farmName: farmName,
      groupName: groupName,
      dietName: dietName,
      category: category,
      dailyAmountKg: dailyAmountKg,
      animalCount: animalCount,
      costPerKg: costPerKg,
      startDate: startDate,
      notes: notes,
      averageBodyWeightKg: averageBodyWeightKg,
      targetDailyGainKg: targetDailyGainKg,
      observedDailyGainKg: observedDailyGainKg,
      feedConversion: feedConversion,
      pastureType: pastureType,
      silageType: silageType,
      concentrateType: concentrateType,
      mineralSupplement: mineralSupplement,
      dryMatterPercent: dryMatterPercent,
      crudeProteinPercent: crudeProteinPercent,
      ndfPercent: ndfPercent,
      adfPercent: adfPercent,
      tdnPercent: tdnPercent,
      stockIntegrationEnabled: stockIntegrationEnabled,
      inventoryDeducted: inventoryDeducted ?? this.inventoryDeducted,
      inventoryDeductionCost:
          inventoryDeductionCost ?? this.inventoryDeductionCost,
      ingredients: ingredients,
    );
  }
}
