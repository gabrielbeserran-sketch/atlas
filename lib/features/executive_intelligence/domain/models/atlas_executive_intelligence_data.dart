import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasExecutiveIntelligenceData {
  const AtlasExecutiveIntelligenceData({
    required this.generatedAt,
    required this.summary,
    required this.intelligenceScore,
    required this.maturity,
    required this.rootCauses,
    required this.cascadeEffects,
    required this.consequences,
    required this.priorities,
    required this.insights,
  });

  final DateTime generatedAt;
  final String summary;

  final double intelligenceScore;
  final AtlasExecutiveIntelligenceMaturity maturity;

  final List<AtlasExecutiveRootCause> rootCauses;
  final List<AtlasExecutiveCascadeEffect> cascadeEffects;
  final List<AtlasExecutiveConsequence> consequences;
  final List<AtlasExecutivePriority> priorities;
  final List<AtlasExecutiveInsight> insights;

  bool get hasData {
    return rootCauses.isNotEmpty ||
        cascadeEffects.isNotEmpty ||
        consequences.isNotEmpty ||
        priorities.isNotEmpty ||
        insights.isNotEmpty;
  }

  AtlasExecutiveRootCause? get mainRootCause {
    if (rootCauses.isEmpty) {
      return null;
    }

    return rootCauses.first;
  }

  AtlasExecutivePriority? get topPriority {
    if (priorities.isEmpty) {
      return null;
    }

    return priorities.first;
  }
}

class AtlasExecutiveRootCause {
  const AtlasExecutiveRootCause({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.confidencePercent,
    required this.impactScore,
    required this.severity,
    required this.evidences,
    required this.recommendation,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;

  final double confidencePercent;
  final double impactScore;

  final AtlasExecutiveIntelligenceSeverity severity;

  final List<String> evidences;
  final String recommendation;
}

class AtlasExecutiveCascadeEffect {
  const AtlasExecutiveCascadeEffect({
    required this.id,
    required this.farmName,
    required this.sourceTitle,
    required this.targetTitle,
    required this.category,
    required this.direction,
    required this.strengthPercent,
    required this.explanation,
  });

  final String id;
  final String farmName;

  final String sourceTitle;
  final String targetTitle;

  final AtlasBiCategory category;

  final AtlasExecutiveCascadeDirection direction;
  final double strengthPercent;

  final String explanation;
}

class AtlasExecutiveConsequence {
  const AtlasExecutiveConsequence({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.horizonDays,
    required this.probabilityPercent,
    required this.financialImpactValue,
    required this.riskReductionPotentialPercent,
    required this.severity,
    required this.recommendation,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;

  final int horizonDays;
  final double probabilityPercent;
  final double financialImpactValue;
  final double riskReductionPotentialPercent;

  final AtlasExecutiveIntelligenceSeverity severity;

  final String recommendation;
}

class AtlasExecutivePriority {
  const AtlasExecutivePriority({
    required this.position,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priorityScore,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineDays,
    required this.severity,
    required this.recommendation,
  });

  final int position;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;

  final double priorityScore;
  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineDays;

  final AtlasExecutiveIntelligenceSeverity severity;

  final String recommendation;
}

class AtlasExecutiveInsight {
  const AtlasExecutiveInsight({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.priority,
    required this.confidencePercent,
    required this.recommendation,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;

  final AtlasExecutiveInsightType type;
  final AtlasExecutiveInsightPriority priority;

  final double confidencePercent;
  final String recommendation;
}

enum AtlasExecutiveIntelligenceMaturity {
  initial,
  developing,
  structured,
  advanced,
  autonomous,
}

enum AtlasExecutiveIntelligenceSeverity {
  low,
  medium,
  high,
  critical,
}

enum AtlasExecutiveCascadeDirection {
  positive,
  negative,
  neutral,
}

enum AtlasExecutiveInsightType {
  rootCause,
  cascade,
  forecast,
  benchmark,
  economic,
  operational,
  strategic,
}

enum AtlasExecutiveInsightPriority {
  low,
  medium,
  high,
  critical,
}

String atlasExecutiveIntelligenceMaturityLabel(
  AtlasExecutiveIntelligenceMaturity maturity,
) {
  switch (maturity) {
    case AtlasExecutiveIntelligenceMaturity.initial:
      return 'Inicial';

    case AtlasExecutiveIntelligenceMaturity.developing:
      return 'Em desenvolvimento';

    case AtlasExecutiveIntelligenceMaturity.structured:
      return 'Estruturada';

    case AtlasExecutiveIntelligenceMaturity.advanced:
      return 'Avançada';

    case AtlasExecutiveIntelligenceMaturity.autonomous:
      return 'Autônoma';
  }
}

String atlasExecutiveIntelligenceSeverityLabel(
  AtlasExecutiveIntelligenceSeverity severity,
) {
  switch (severity) {
    case AtlasExecutiveIntelligenceSeverity.low:
      return 'Baixa';

    case AtlasExecutiveIntelligenceSeverity.medium:
      return 'Média';

    case AtlasExecutiveIntelligenceSeverity.high:
      return 'Alta';

    case AtlasExecutiveIntelligenceSeverity.critical:
      return 'Crítica';
  }
}

String atlasExecutiveCascadeDirectionLabel(
  AtlasExecutiveCascadeDirection direction,
) {
  switch (direction) {
    case AtlasExecutiveCascadeDirection.positive:
      return 'Positiva';

    case AtlasExecutiveCascadeDirection.negative:
      return 'Negativa';

    case AtlasExecutiveCascadeDirection.neutral:
      return 'Neutra';
  }
}

String atlasExecutiveInsightTypeLabel(
  AtlasExecutiveInsightType type,
) {
  switch (type) {
    case AtlasExecutiveInsightType.rootCause:
      return 'Causa-raiz';

    case AtlasExecutiveInsightType.cascade:
      return 'Efeito em cadeia';

    case AtlasExecutiveInsightType.forecast:
      return 'Forecast';

    case AtlasExecutiveInsightType.benchmark:
      return 'Benchmarking';

    case AtlasExecutiveInsightType.economic:
      return 'Econômico';

    case AtlasExecutiveInsightType.operational:
      return 'Operacional';

    case AtlasExecutiveInsightType.strategic:
      return 'Estratégico';
  }
}
