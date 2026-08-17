import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_insight.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';

class AtlasExecutiveBrainCommandCenterView {
  const AtlasExecutiveBrainCommandCenterView({
    required this.generatedAt,
    required this.farmName,
    required this.officialPriority,
    required this.priorities,
    required this.insights,
    required this.riskLevel,
    required this.operationalScore,
  });

  factory AtlasExecutiveBrainCommandCenterView.fromSnapshot(
    AtlasCommandCenterSnapshot snapshot,
  ) {
    final priorities = snapshot.priorities;
    final insights = snapshot.insights;
    final metrics = snapshot.metrics;

    final riskPenalty =
        (metrics.criticalEvents * 20) + (metrics.highPriorityEvents * 8);

    final score = (100 - riskPenalty).clamp(0, 100).toDouble();

    return AtlasExecutiveBrainCommandCenterView(
      generatedAt: snapshot.generatedAt,
      farmName: snapshot.farmName,
      officialPriority: priorities.isEmpty ? null : priorities.first,
      priorities: List<AtlasOperationalPriority>.unmodifiable(priorities),
      insights: List<AtlasOperationalInsight>.unmodifiable(insights),
      riskLevel: _riskLevel(
        criticalEvents: metrics.criticalEvents,
        highPriorityEvents: metrics.highPriorityEvents,
      ),
      operationalScore: score,
    );
  }

  final DateTime generatedAt;
  final String? farmName;
  final AtlasOperationalPriority? officialPriority;
  final List<AtlasOperationalPriority> priorities;
  final List<AtlasOperationalInsight> insights;
  final AtlasCanonicalPriority riskLevel;
  final double operationalScore;

  bool get hasDecision => officialPriority != null;

  static AtlasCanonicalPriority _riskLevel({
    required int criticalEvents,
    required int highPriorityEvents,
  }) {
    if (criticalEvents >= 2) {
      return AtlasCanonicalPriority.critical;
    }

    if (criticalEvents == 1 || highPriorityEvents >= 3) {
      return AtlasCanonicalPriority.high;
    }

    if (highPriorityEvents > 0) {
      return AtlasCanonicalPriority.medium;
    }

    return AtlasCanonicalPriority.low;
  }
}
