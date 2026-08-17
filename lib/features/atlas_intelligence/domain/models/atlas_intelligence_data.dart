class AtlasIntelligenceData {
  const AtlasIntelligenceData({
    required this.generatedAt,
    required this.summary,
    required this.intelligenceScore,
    required this.confidencePercent,
    required this.status,
    required this.signals,
    required this.patterns,
    required this.hypotheses,
    required this.recommendations,
  });

  final DateTime generatedAt;
  final String summary;

  final double intelligenceScore;
  final double confidencePercent;

  final AtlasIntelligenceStatus status;

  final List<AtlasIntelligenceSignal> signals;
  final List<AtlasIntelligencePattern> patterns;
  final List<AtlasIntelligenceHypothesis> hypotheses;
  final List<AtlasIntelligenceRecommendation> recommendations;

  bool get hasData {
    return signals.isNotEmpty ||
        patterns.isNotEmpty ||
        hypotheses.isNotEmpty ||
        recommendations.isNotEmpty;
  }

  AtlasIntelligenceRecommendation? get primaryRecommendation {
    if (recommendations.isEmpty) {
      return null;
    }

    return recommendations.first;
  }
}

class AtlasIntelligenceSignal {
  const AtlasIntelligenceSignal({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.type,
    required this.severity,
    required this.relevanceScore,
    required this.confidencePercent,
    required this.financialImpact,
    required this.farmName,
  });

  final String id;

  final String title;
  final String description;

  final String source;

  final AtlasIntelligenceSignalType type;
  final AtlasIntelligenceSeverity severity;

  final double relevanceScore;
  final double confidencePercent;
  final double financialImpact;

  final String farmName;
}

class AtlasIntelligencePattern {
  const AtlasIntelligencePattern({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.strengthScore,
    required this.confidencePercent,
    required this.relatedSignalIds,
    required this.expectedConsequence,
  });

  final String id;

  final String title;
  final String description;

  final AtlasIntelligencePatternType type;

  final double strengthScore;
  final double confidencePercent;

  final List<String> relatedSignalIds;

  final String expectedConsequence;
}

class AtlasIntelligenceHypothesis {
  const AtlasIntelligenceHypothesis({
    required this.id,
    required this.title,
    required this.description,
    required this.cause,
    required this.effect,
    required this.probabilityPercent,
    required this.impactScore,
    required this.validationSteps,
  });

  final String id;

  final String title;
  final String description;

  final String cause;
  final String effect;

  final double probabilityPercent;
  final double impactScore;

  final List<String> validationSteps;
}

class AtlasIntelligenceRecommendation {
  const AtlasIntelligenceRecommendation({
    required this.position,
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.priority,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineHours,
    required this.reasoning,
    required this.actions,
  });

  final int position;
  final String id;

  final String title;
  final String description;
  final String farmName;

  final AtlasIntelligencePriority priority;

  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineHours;

  final String reasoning;
  final List<String> actions;
}

enum AtlasIntelligenceStatus { stable, attention, highRisk, critical }

enum AtlasIntelligenceSignalType {
  operational,
  financial,
  predictive,
  execution,
  strategic,
}

enum AtlasIntelligenceSeverity { low, medium, high, critical }

enum AtlasIntelligencePatternType {
  recurring,
  cascading,
  contradiction,
  opportunity,
  bottleneck,
}

enum AtlasIntelligencePriority { low, medium, high, critical }

String atlasIntelligenceStatusLabel(AtlasIntelligenceStatus status) {
  switch (status) {
    case AtlasIntelligenceStatus.stable:
      return 'Estável';

    case AtlasIntelligenceStatus.attention:
      return 'Atenção';

    case AtlasIntelligenceStatus.highRisk:
      return 'Risco alto';

    case AtlasIntelligenceStatus.critical:
      return 'Crítico';
  }
}

String atlasIntelligenceSeverityLabel(AtlasIntelligenceSeverity severity) {
  switch (severity) {
    case AtlasIntelligenceSeverity.low:
      return 'Baixa';

    case AtlasIntelligenceSeverity.medium:
      return 'Média';

    case AtlasIntelligenceSeverity.high:
      return 'Alta';

    case AtlasIntelligenceSeverity.critical:
      return 'Crítica';
  }
}

String atlasIntelligencePatternTypeLabel(AtlasIntelligencePatternType type) {
  switch (type) {
    case AtlasIntelligencePatternType.recurring:
      return 'Recorrente';

    case AtlasIntelligencePatternType.cascading:
      return 'Efeito em cadeia';

    case AtlasIntelligencePatternType.contradiction:
      return 'Contradição';

    case AtlasIntelligencePatternType.opportunity:
      return 'Oportunidade';

    case AtlasIntelligencePatternType.bottleneck:
      return 'Gargalo';
  }
}

String atlasIntelligencePriorityLabel(AtlasIntelligencePriority priority) {
  switch (priority) {
    case AtlasIntelligencePriority.low:
      return 'Baixa';

    case AtlasIntelligencePriority.medium:
      return 'Média';

    case AtlasIntelligencePriority.high:
      return 'Alta';

    case AtlasIntelligencePriority.critical:
      return 'Crítica';
  }
}
