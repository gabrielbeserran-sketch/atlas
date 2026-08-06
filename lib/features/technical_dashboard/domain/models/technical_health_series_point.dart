class TechnicalHealthSeriesPoint {
  const TechnicalHealthSeriesPoint({
    required this.periodStart,
    required this.label,
    required this.totalRecords,
    required this.vaccinations,
    required this.treatments,
    required this.exams,
    required this.mortalities,
  });

  final DateTime periodStart;
  final String label;
  final int totalRecords;
  final int vaccinations;
  final int treatments;
  final int exams;
  final int mortalities;
}
