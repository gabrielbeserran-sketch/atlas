class TechnicalNutritionSeriesPoint {
  const TechnicalNutritionSeriesPoint({
    required this.periodStart,
    required this.label,
    required this.planCount,
    required this.animalCount,
    required this.dailyFeedKg,
    required this.dailyCost,
  });

  final DateTime periodStart;
  final String label;
  final int planCount;
  final int animalCount;
  final double dailyFeedKg;
  final double dailyCost;
}
