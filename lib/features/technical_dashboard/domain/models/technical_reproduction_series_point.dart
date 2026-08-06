class TechnicalReproductionSeriesPoint {
  const TechnicalReproductionSeriesPoint({
    required this.periodStart,
    required this.label,
    required this.totalRecords,
    required this.inseminations,
    required this.positivePregnancies,
    required this.births,
  });

  final DateTime periodStart;
  final String label;
  final int totalRecords;
  final int inseminations;
  final int positivePregnancies;
  final int births;
}
