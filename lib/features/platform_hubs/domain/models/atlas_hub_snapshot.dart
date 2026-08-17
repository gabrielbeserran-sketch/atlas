class AtlasHubSnapshot {
  const AtlasHubSnapshot({
    required this.title,
    required this.metrics,
    required this.records,
    this.generatedAt,
  });

  final String title;
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> records;
  final DateTime? generatedAt;

  factory AtlasHubSnapshot.fromMap(String title, Map<String, dynamic> map) {
    final records = <Map<String, dynamic>>[];
    for (final value in map.values) {
      if (value is List) {
        for (final item in value) {
          if (item is Map) {
            records.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }
    return AtlasHubSnapshot(
      title: title,
      metrics: Map<String, dynamic>.from(map),
      records: records,
      generatedAt: DateTime.tryParse(map['generated_at']?.toString() ?? ''),
    );
  }

  int metricAsInt(String key) {
    final value = metrics[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double metricAsDouble(String key) {
    final value = metrics[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
