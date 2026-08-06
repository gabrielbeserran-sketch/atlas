import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_insight.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_metrics.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_timeline.dart';

class AtlasCommandCenterSnapshot {
  const AtlasCommandCenterSnapshot({
    required this.generatedAt,
    required this.farmName,
    required this.timeline,
    required this.metrics,
    required this.priorities,
    required this.insights,
  });

  final DateTime generatedAt;
  final String? farmName;
  final AtlasOperationalTimeline timeline;
  final AtlasOperationalMetrics metrics;
  final List<AtlasOperationalPriority> priorities;
  final List<AtlasOperationalInsight> insights;

  bool get hasData => timeline.hasData;

  AtlasOperationalPriority? get topPriority {
    return priorities.isEmpty ? null : priorities.first;
  }

  AtlasOperationalInsight? get topInsight {
    return insights.isEmpty ? null : insights.first;
  }
}
