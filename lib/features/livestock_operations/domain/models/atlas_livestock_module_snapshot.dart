enum AtlasLivestockModule {
  reproduction,
  health,
  nutrition,
  inventory,
  finance,
}

class AtlasMetricData {
  const AtlasMetricData({
    required this.label,
    required this.value,
    this.subtitle = '',
  });

  final String label;
  final String value;
  final String subtitle;
}

class AtlasModuleItemData {
  const AtlasModuleItemData({
    required this.title,
    this.subtitle = '',
    this.status = '',
    this.payload = const <String, dynamic>{},
  });

  final String title;
  final String subtitle;
  final String status;
  final Map<String, dynamic> payload;
}

class AtlasLivestockModuleSnapshot {
  const AtlasLivestockModuleSnapshot({
    required this.module,
    required this.farmId,
    required this.metrics,
    required this.items,
    required this.loadedAt,
  });

  final AtlasLivestockModule module;
  final String farmId;
  final List<AtlasMetricData> metrics;
  final List<AtlasModuleItemData> items;
  final DateTime loadedAt;

  int get attentionCount => items.where((item) {
    final value = item.status.toLowerCase();
    return value.contains('critical') ||
        value.contains('high') ||
        value.contains('overdue') ||
        value.contains('expired') ||
        value.contains('pending');
  }).length;
}
