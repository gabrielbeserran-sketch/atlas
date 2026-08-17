import '../models/atlas_quality_data.dart';

class AtlasQualitySummary {
  const AtlasQualitySummary({
    required this.score,
    required this.completedChecks,
    required this.totalChecks,
    required this.openIncidents,
    required this.criticalPending,
  });

  final int score;
  final int completedChecks;
  final int totalChecks;
  final int openIncidents;
  final int criticalPending;
}

class AtlasQualityEngine {
  AtlasQualitySummary summarize(AtlasQualityState state) {
    final int total = state.checks.length;
    final int completed = state.checks
        .where((AtlasQualityCheck item) => item.completed)
        .length;
    final int openIncidents = state.incidents
        .where((AtlasQualityIncident item) => !item.resolved)
        .length;
    final int criticalPending = state.checks
        .where((AtlasQualityCheck item) => item.critical && !item.completed)
        .length;

    int score = total == 0 ? 100 : ((completed / total) * 100).round();
    score -= openIncidents * 8;
    score -= criticalPending * 5;
    if (score < 0) score = 0;
    if (score > 100) score = 100;

    return AtlasQualitySummary(
      score: score,
      completedChecks: completed,
      totalChecks: total,
      openIncidents: openIncidents,
      criticalPending: criticalPending,
    );
  }
}
