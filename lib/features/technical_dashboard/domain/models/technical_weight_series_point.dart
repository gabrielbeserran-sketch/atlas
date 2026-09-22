class TechnicalWeightSeriesPoint {
  const TechnicalWeightSeriesPoint({
    required this.periodStart,
    required this.label,
    required this.averageWeight,
    required this.measurementCount,
    required this.animalCount,
    required this.latestMeasurementDate,
  });

  final DateTime periodStart;
  final String label;
  final double averageWeight;
  final int measurementCount;
  final int animalCount;
  final DateTime latestMeasurementDate;
}
