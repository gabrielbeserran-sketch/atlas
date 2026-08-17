class AtlasFlutterQualityReport {
  const AtlasFlutterQualityReport({
    required this.checks,
    required this.generatedAt,
  });
  final Map<String, bool> checks;
  final DateTime generatedAt;
  int get passed => checks.values.where((value) => value).length;
  int get total => checks.length;
  double get percent => total == 0 ? 0 : passed * 100 / total;
  bool get approved => total > 0 && passed == total;
}
