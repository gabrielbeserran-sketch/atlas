class TechnicalWeightSeriesPoint {
  const TechnicalWeightSeriesPoint({
    required this.periodStart,
    required this.label,
    required this.averageWeight,
    required this.measurementCount,
    required this.animalCount,
  });

  final DateTime periodStart;
  final String label;
  final double averageWeight;
  final int measurementCount;
  final int animalCount;
}
