class AtlasNutritionExecutiveSnapshot {
  const AtlasNutritionExecutiveSnapshot({
    required this.activeDiets,
    required this.totalAnimals,
    required this.dailyFeedCost,
    required this.monthlyFeedCost,
    required this.averageDailyGainKg,
    required this.averageFeedConversion,
    required this.averageConsumptionKg,
    required this.lowStockIngredients,
    required this.wastePercent,
    required this.nutritionScore,
  });

  final int activeDiets;
  final int totalAnimals;
  final double dailyFeedCost;
  final double monthlyFeedCost;
  final double averageDailyGainKg;
  final double averageFeedConversion;
  final double averageConsumptionKg;
  final int lowStockIngredients;
  final double wastePercent;
  final double nutritionScore;
}

class AtlasNutritionProjection {
  const AtlasNutritionProjection({
    required this.lotName,
    required this.projectedConsumption30DaysKg,
    required this.projectedCost30Days,
    required this.projectedWeightGain30DaysKg,
    required this.stockCoverageDays,
    required this.riskLevel,
  });

  final String lotName;
  final double projectedConsumption30DaysKg;
  final double projectedCost30Days;
  final double projectedWeightGain30DaysKg;
  final double stockCoverageDays;
  final String riskLevel;
}

class AtlasNutritionAnnualPlan {
  const AtlasNutritionAnnualPlan({
    required this.id,
    required this.title,
    required this.year,
    required this.targetLot,
    required this.targetDailyGainKg,
    required this.targetFeedConversion,
    required this.budget,
    required this.responsibleName,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String title;
  final int year;
  final String targetLot;
  final double targetDailyGainKg;
  final double targetFeedConversion;
  final double budget;
  final String responsibleName;
  final String? farmName;
  final String notes;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'title': title,
    'year': year,
    'targetLot': targetLot,
    'targetDailyGainKg': targetDailyGainKg,
    'targetFeedConversion': targetFeedConversion,
    'budget': budget,
    'responsibleName': responsibleName,
    'farmName': farmName,
    'notes': notes,
  };

  factory AtlasNutritionAnnualPlan.fromMap(Map<String, dynamic> map) {
    return AtlasNutritionAnnualPlan(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      year: (map['year'] as num?)?.toInt() ?? 0,
      targetLot: map['targetLot']?.toString() ?? '',
      targetDailyGainKg: (map['targetDailyGainKg'] as num?)?.toDouble() ?? 0,
      targetFeedConversion:
          (map['targetFeedConversion'] as num?)?.toDouble() ?? 0,
      budget: (map['budget'] as num?)?.toDouble() ?? 0,
      responsibleName: map['responsibleName']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}
