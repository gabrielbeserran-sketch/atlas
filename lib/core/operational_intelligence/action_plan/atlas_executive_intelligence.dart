import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';

class AtlasExecutiveKpi {
  const AtlasExecutiveKpi({
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.description,
  });

  final String title;
  final double value;
  final String unit;
  final String status;
  final String description;
}

class AtlasExecutiveScoreSet {
  const AtlasExecutiveScoreSet({
    required this.overall,
    required this.operational,
    required this.economic,
    required this.zootechnical,
    required this.sanitary,
    required this.status,
  });

  final double overall;
  final double operational;
  final double economic;
  final double zootechnical;
  final double sanitary;
  final String status;
}

class AtlasExecutiveBottleneck {
  const AtlasExecutiveBottleneck({
    required this.id,
    required this.title,
    required this.area,
    required this.severity,
    required this.impactScore,
    required this.description,
    required this.recommendation,
  });

  final String id;
  final String title;
  final AtlasOperationalArea area;
  final String severity;
  final double impactScore;
  final String description;
  final String recommendation;
}

class AtlasDecisionImpactNode {
  const AtlasDecisionImpactNode({
    required this.area,
    required this.impactPercent,
    required this.direction,
    required this.explanation,
  });

  final AtlasOperationalArea area;
  final double impactPercent;
  final String direction;
  final String explanation;
}

class AtlasWhatIfScenario {
  const AtlasWhatIfScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.baseScore,
    required this.projectedScore,
    required this.projectedFinancialImpact,
    required this.confidencePercent,
    required this.impacts,
  });

  final String id;
  final String title;
  final String description;
  final double baseScore;
  final double projectedScore;
  final double projectedFinancialImpact;
  final double confidencePercent;
  final List<AtlasDecisionImpactNode> impacts;
}

class AtlasSmartGoalProjection {
  const AtlasSmartGoalProjection({
    required this.goalId,
    required this.goalTitle,
    required this.currentProgressPercent,
    required this.projectedProgressPercent,
    required this.daysRemaining,
    required this.onTrack,
    required this.recommendation,
  });

  final String goalId;
  final String goalTitle;
  final double currentProgressPercent;
  final double projectedProgressPercent;
  final int daysRemaining;
  final bool onTrack;
  final String recommendation;
}

class AtlasExecutiveIntelligenceSnapshot {
  const AtlasExecutiveIntelligenceSnapshot({
    required this.generatedAt,
    required this.kpis,
    required this.scores,
    required this.bottlenecks,
    required this.goalProjections,
    required this.scenarios,
    required this.strategicPriorities,
  });

  final DateTime generatedAt;
  final List<AtlasExecutiveKpi> kpis;
  final AtlasExecutiveScoreSet scores;
  final List<AtlasExecutiveBottleneck> bottlenecks;
  final List<AtlasSmartGoalProjection> goalProjections;
  final List<AtlasWhatIfScenario> scenarios;
  final List<String> strategicPriorities;
}
