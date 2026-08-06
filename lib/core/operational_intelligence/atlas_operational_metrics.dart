class AtlasOperationalMetrics {
  const AtlasOperationalMetrics({
    required this.generatedAt,
    required this.farmName,
    required this.totalEvents,
    required this.eventsLast24Hours,
    required this.eventsLast7Days,
    required this.criticalEvents,
    required this.highPriorityEvents,
    required this.activeModules,
    required this.eventsByModule,
    required this.eventsByEntityType,
    required this.numericIndicators,
  });

  final DateTime generatedAt;
  final String? farmName;
  final int totalEvents;
  final int eventsLast24Hours;
  final int eventsLast7Days;
  final int criticalEvents;
  final int highPriorityEvents;
  final int activeModules;
  final Map<String, int> eventsByModule;
  final Map<String, int> eventsByEntityType;
  final Map<String, double> numericIndicators;

  bool get hasData => totalEvents > 0;
}
