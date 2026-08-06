class TechnicalFinancialSeriesPoint {
  const TechnicalFinancialSeriesPoint({
    required this.periodStart,
    required this.label,
    required this.income,
    required this.expenses,
  });

  final DateTime periodStart;
  final String label;
  final double income;
  final double expenses;

  double get balance => income - expenses;
}
