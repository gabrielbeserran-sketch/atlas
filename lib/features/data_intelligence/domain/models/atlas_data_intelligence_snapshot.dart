class AtlasDataIntelligenceSnapshot {
  const AtlasDataIntelligenceSnapshot({
    required this.analytics,
    required this.platform,
    required this.realtime,
    required this.generatedAt,
  });

  final Map<String, dynamic> analytics;
  final Map<String, dynamic> platform;
  final List<Map<String, dynamic>> realtime;
  final DateTime generatedAt;

  factory AtlasDataIntelligenceSnapshot.fromResponses({
    required Map<String, dynamic> analytics,
    required Map<String, dynamic> platform,
    required List<Map<String, dynamic>> realtime,
  }) {
    return AtlasDataIntelligenceSnapshot(
      analytics: Map<String, dynamic>.unmodifiable(analytics),
      platform: Map<String, dynamic>.unmodifiable(platform),
      realtime: List<Map<String, dynamic>>.unmodifiable(realtime),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  int intMetric(String key) {
    final value = analytics[key] ?? platform[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> records(String key) {
    final value = analytics[key] ?? platform[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
