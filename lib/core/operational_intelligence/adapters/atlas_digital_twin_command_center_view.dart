import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_insight.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';

class AtlasDigitalTwinCommandCenterView {
  const AtlasDigitalTwinCommandCenterView({
    required this.generatedAt,
    required this.farmName,
    required this.operationalHealthPercent,
    required this.riskLevel,
    required this.activeModules,
    required this.recentEvents,
    required this.priorities,
    required this.insights,
  });

  factory AtlasDigitalTwinCommandCenterView.fromSnapshot(
    AtlasCommandCenterSnapshot snapshot,
  ) {
    final metrics = snapshot.metrics;
    final penalty =
        (metrics.criticalEvents * 18) +
        (metrics.highPriorityEvents * 7);

    final health =
        (100 - penalty).clamp(0, 100).toDouble();

    return AtlasDigitalTwinCommandCenterView(
      generatedAt: snapshot.generatedAt,
      farmName: snapshot.farmName,
      operationalHealthPercent: health,
      riskLevel: _riskLevel(
        metrics.criticalEvents,
        metrics.highPriorityEvents,
      ),
      activeModules: metrics.activeModules,
      recentEvents: metrics.eventsLast24Hours,
      priorities:
          List<AtlasOperationalPriority>.unmodifiable(
        snapshot.priorities.take(10),
      ),
      insights:
          List<AtlasOperationalInsight>.unmodifiable(
        snapshot.insights.take(10),
      ),
    );
  }

  final DateTime generatedAt;
  final String? farmName;
  final double operationalHealthPercent;
  final AtlasCanonicalPriority riskLevel;
  final int activeModules;
  final int recentEvents;
  final List<AtlasOperationalPriority> priorities;
  final List<AtlasOperationalInsight> insights;

  static AtlasCanonicalPriority _riskLevel(
    int criticalEvents,
    int highPriorityEvents,
  ) {
    if (criticalEvents > 0) {
      return AtlasCanonicalPriority.critical;
    }

    if (highPriorityEvents >= 3) {
      return AtlasCanonicalPriority.high;
    }

    if (highPriorityEvents > 0) {
      return AtlasCanonicalPriority.medium;
    }

    return AtlasCanonicalPriority.low;
  }
}
