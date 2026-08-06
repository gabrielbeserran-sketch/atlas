class TechnicalInventorySeriesPoint {
  const TechnicalInventorySeriesPoint({
    required this.periodStart,
    required this.label,
    required this.entries,
    required this.exits,
    required this.entryValue,
    required this.exitValue,
  });

  final DateTime periodStart;
  final String label;
  final double entries;
  final double exits;
  final double entryValue;
  final double exitValue;

  int get totalMovements =>
      (entries > 0 ? 1 : 0) + (exits > 0 ? 1 : 0);
}
