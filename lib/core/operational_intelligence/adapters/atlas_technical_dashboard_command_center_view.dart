import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';

class AtlasTechnicalDashboardCommandCenterView {
  const AtlasTechnicalDashboardCommandCenterView({
    required this.generatedAt,
    required this.farmName,
    required this.totalEvents,
    required this.eventsLast24Hours,
    required this.eventsLast7Days,
    required this.criticalEvents,
    required this.highPriorityEvents,
    required this.eventsByModule,
    required this.eventsByEntityType,
    required this.numericIndicators,
  });

  factory AtlasTechnicalDashboardCommandCenterView.fromSnapshot(
    AtlasCommandCenterSnapshot snapshot,
  ) {
    final metrics = snapshot.metrics;

    return AtlasTechnicalDashboardCommandCenterView(
      generatedAt: snapshot.generatedAt,
      farmName: snapshot.farmName,
      totalEvents: metrics.totalEvents,
      eventsLast24Hours: metrics.eventsLast24Hours,
      eventsLast7Days: metrics.eventsLast7Days,
      criticalEvents: metrics.criticalEvents,
      highPriorityEvents: metrics.highPriorityEvents,
      eventsByModule: Map<String, int>.unmodifiable(metrics.eventsByModule),
      eventsByEntityType: Map<String, int>.unmodifiable(
        metrics.eventsByEntityType,
      ),
      numericIndicators: Map<String, double>.unmodifiable(
        metrics.numericIndicators,
      ),
    );
  }

  final DateTime generatedAt;
  final String? farmName;
  final int totalEvents;
  final int eventsLast24Hours;
  final int eventsLast7Days;
  final int criticalEvents;
  final int highPriorityEvents;
  final Map<String, int> eventsByModule;
  final Map<String, int> eventsByEntityType;
  final Map<String, double> numericIndicators;

  int eventsForModule(String module) {
    return eventsByModule[module] ?? 0;
  }

  double? indicator(String key) {
    return numericIndicators[key];
  }
}
