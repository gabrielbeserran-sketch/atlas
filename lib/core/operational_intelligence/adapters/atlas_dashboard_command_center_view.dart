import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_insight.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';

class AtlasDashboardCommandCenterView {
  const AtlasDashboardCommandCenterView({
    required this.generatedAt,
    required this.farmName,
    required this.totalEvents,
    required this.eventsLast24Hours,
    required this.eventsLast7Days,
    required this.criticalEvents,
    required this.highPriorityEvents,
    required this.activeModules,
    required this.topPriority,
    required this.topInsight,
  });

  factory AtlasDashboardCommandCenterView.fromSnapshot(
    AtlasCommandCenterSnapshot snapshot,
  ) {
    final metrics = snapshot.metrics;

    return AtlasDashboardCommandCenterView(
      generatedAt: snapshot.generatedAt,
      farmName: snapshot.farmName,
      totalEvents: metrics.totalEvents,
      eventsLast24Hours: metrics.eventsLast24Hours,
      eventsLast7Days: metrics.eventsLast7Days,
      criticalEvents: metrics.criticalEvents,
      highPriorityEvents: metrics.highPriorityEvents,
      activeModules: metrics.activeModules,
      topPriority: snapshot.topPriority,
      topInsight: snapshot.topInsight,
    );
  }

  final DateTime generatedAt;
  final String? farmName;
  final int totalEvents;
  final int eventsLast24Hours;
  final int eventsLast7Days;
  final int criticalEvents;
  final int highPriorityEvents;
  final int activeModules;
  final AtlasOperationalPriority? topPriority;
  final AtlasOperationalInsight? topInsight;

  bool get hasCriticalAttention => criticalEvents > 0;

  int get pendingAttentionCount {
    return criticalEvents + highPriorityEvents;
  }
}
