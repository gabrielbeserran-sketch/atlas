class AtlasExecutiveBrainData {
  const AtlasExecutiveBrainData({
    required this.generatedAt,
    required this.summary,
    required this.brainScore,
    required this.confidencePercent,
    required this.status,
    required this.officialDecision,
    required this.strategy,
    required this.crossImpacts,
    required this.conflicts,
    required this.dailyPlan,
    required this.weeklyPlan,
    required this.monthlyPlan,
    required this.memoryInsights,
    required this.scoreDimensions,
    required this.radarItems,
  });

  final DateTime generatedAt;
  final String summary;

  final double brainScore;
  final double confidencePercent;

  final AtlasExecutiveBrainStatus status;

  final AtlasExecutiveBrainDecision? officialDecision;
  final AtlasExecutiveBrainStrategy? strategy;

  final List<AtlasExecutiveCrossImpact> crossImpacts;
  final List<AtlasExecutiveConflict> conflicts;

  final List<AtlasExecutiveBrainAction> dailyPlan;
  final List<AtlasExecutiveBrainAction> weeklyPlan;
  final List<AtlasExecutiveBrainAction> monthlyPlan;

  final List<AtlasExecutiveMemoryInsight> memoryInsights;

  final List<AtlasExecutiveScoreDimension> scoreDimensions;
  final List<AtlasExecutiveRadarItem> radarItems;

  bool get hasData {
    return officialDecision != null ||
        strategy != null ||
        crossImpacts.isNotEmpty ||
        conflicts.isNotEmpty ||
        dailyPlan.isNotEmpty ||
        weeklyPlan.isNotEmpty ||
        monthlyPlan.isNotEmpty ||
        memoryInsights.isNotEmpty ||
        scoreDimensions.isNotEmpty ||
        radarItems.isNotEmpty;
  }
}

class AtlasExecutiveBrainDecision {
  const AtlasExecutiveBrainDecision({
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.priority,
    required this.score,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineHours,
    required this.reasoning,
    required this.actions,
    required this.expectedResult,
  });

  final String id;

  final String title;
  final String description;
  final String farmName;

  final AtlasExecutiveBrainPriority priority;

  final double score;
  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineHours;

  final String reasoning;
  final List<String> actions;
  final String expectedResult;
}

class AtlasExecutiveBrainStrategy {
  const AtlasExecutiveBrainStrategy({
    required this.id,
    required this.title,
    required this.summary,
    required this.objective,
    required this.horizonDays,
    required this.successProbabilityPercent,
    required this.expectedFinancialImpact,
    required this.pillars,
  });

  final String id;

  final String title;
  final String summary;
  final String objective;

  final int horizonDays;

  final double successProbabilityPercent;
  final double expectedFinancialImpact;

  final List<AtlasExecutiveStrategyPillar> pillars;
}

class AtlasExecutiveStrategyPillar {
  const AtlasExecutiveStrategyPillar({
    required this.position,
    required this.title,
    required this.description,
    required this.weightPercent,
    required this.target,
  });

  final int position;

  final String title;
  final String description;

  final double weightPercent;

  final String target;
}

class AtlasExecutiveCrossImpact {
  const AtlasExecutiveCrossImpact({
    required this.id,
    required this.title,
    required this.description,
    required this.sourceArea,
    required this.affectedArea,
    required this.direction,
    required this.impactScore,
    required this.probabilityPercent,
    required this.financialImpact,
    required this.recommendation,
  });

  final String id;

  final String title;
  final String description;

  final String sourceArea;
  final String affectedArea;

  final AtlasExecutiveImpactDirection direction;

  final double impactScore;
  final double probabilityPercent;
  final double financialImpact;

  final String recommendation;
}

class AtlasExecutiveConflict {
  const AtlasExecutiveConflict({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.relatedEntityIds,
    required this.recommendation,
  });

  final String id;

  final String title;
  final String description;

  final AtlasExecutiveConflictType type;
  final AtlasExecutiveBrainSeverity severity;

  final List<String> relatedEntityIds;

  final String recommendation;
}

class AtlasExecutiveBrainAction {
  const AtlasExecutiveBrainAction({
    required this.position,
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.horizon,
    required this.priority,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineHours,
    required this.source,
    required this.completed,
  });

  final int position;
  final String id;

  final String title;
  final String description;
  final String farmName;

  final AtlasExecutiveBrainHorizon horizon;
  final AtlasExecutiveBrainPriority priority;

  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineHours;

  final String source;

  final bool completed;

  AtlasExecutiveBrainAction copyWith({
    bool? completed,
  }) {
    return AtlasExecutiveBrainAction(
      position: position,
      id: id,
      title: title,
      description: description,
      farmName: farmName,
      horizon: horizon,
      priority: priority,
      confidencePercent: confidencePercent,
      expectedFinancialImpact:
          expectedFinancialImpact,
      deadlineHours: deadlineHours,
      source: source,
      completed: completed ?? this.completed,
    );
  }
}

class AtlasExecutiveScoreDimension {
  const AtlasExecutiveScoreDimension({
    required this.title,
    required this.score,
    required this.weightPercent,
    required this.explanation,
  });

  final String title;
  final double score;
  final double weightPercent;
  final String explanation;

  double get weightedContribution => score * weightPercent / 100;
}

class AtlasExecutiveRadarItem {
  const AtlasExecutiveRadarItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.expectedFinancialImpact,
    required this.confidencePercent,
    required this.recommendedAction,
  });

  final String id;
  final String title;
  final String description;
  final AtlasExecutiveRadarType type;
  final AtlasExecutiveBrainPriority priority;
  final double expectedFinancialImpact;
  final double confidencePercent;
  final String recommendedAction;
}

enum AtlasExecutiveRadarType {
  opportunity,
  risk,
  quickWin,
  waste,
  criticalActivity,
}

String atlasExecutiveRadarTypeLabel(AtlasExecutiveRadarType type) {
  switch (type) {
    case AtlasExecutiveRadarType.opportunity:
      return 'Oportunidade';
    case AtlasExecutiveRadarType.risk:
      return 'Risco';
    case AtlasExecutiveRadarType.quickWin:
      return 'Ganho rápido';
    case AtlasExecutiveRadarType.waste:
      return 'Desperdício';
    case AtlasExecutiveRadarType.criticalActivity:
      return 'Atividade crítica';
  }
}

class AtlasExecutiveMemoryInsight {
  const AtlasExecutiveMemoryInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.farmName,
    required this.relevanceScore,
    required this.recommendation,
  });

  final String id;

  final String title;
  final String description;

  final AtlasExecutiveMemoryInsightType type;

  final String farmName;
  final double relevanceScore;

  final String recommendation;
}

enum AtlasExecutiveBrainStatus {
  excellent,
  adequate,
  attention,
  critical,
}

enum AtlasExecutiveBrainPriority {
  low,
  medium,
  high,
  critical,
}

enum AtlasExecutiveBrainSeverity {
  low,
  medium,
  high,
  critical,
}

enum AtlasExecutiveBrainHorizon {
  today,
  week,
  month,
}

enum AtlasExecutiveImpactDirection {
  positive,
  negative,
  mixed,
}

enum AtlasExecutiveConflictType {
  resource,
  priority,
  deadline,
  strategy,
  execution,
}

enum AtlasExecutiveMemoryInsightType {
  recurringPattern,
  historicalRisk,
  repeatedOpportunity,
  decisionLesson,
  missionLesson,
}

String atlasExecutiveBrainStatusLabel(
  AtlasExecutiveBrainStatus status,
) {
  switch (status) {
    case AtlasExecutiveBrainStatus.excellent:
      return 'Excelente';

    case AtlasExecutiveBrainStatus.adequate:
      return 'Adequado';

    case AtlasExecutiveBrainStatus.attention:
      return 'Atenção';

    case AtlasExecutiveBrainStatus.critical:
      return 'Crítico';
  }
}

String atlasExecutiveBrainPriorityLabel(
  AtlasExecutiveBrainPriority priority,
) {
  switch (priority) {
    case AtlasExecutiveBrainPriority.low:
      return 'Baixa';

    case AtlasExecutiveBrainPriority.medium:
      return 'Média';

    case AtlasExecutiveBrainPriority.high:
      return 'Alta';

    case AtlasExecutiveBrainPriority.critical:
      return 'Crítica';
  }
}

String atlasExecutiveBrainSeverityLabel(
  AtlasExecutiveBrainSeverity severity,
) {
  switch (severity) {
    case AtlasExecutiveBrainSeverity.low:
      return 'Baixa';

    case AtlasExecutiveBrainSeverity.medium:
      return 'Média';

    case AtlasExecutiveBrainSeverity.high:
      return 'Alta';

    case AtlasExecutiveBrainSeverity.critical:
      return 'Crítica';
  }
}

String atlasExecutiveBrainHorizonLabel(
  AtlasExecutiveBrainHorizon horizon,
) {
  switch (horizon) {
    case AtlasExecutiveBrainHorizon.today:
      return 'Hoje';

    case AtlasExecutiveBrainHorizon.week:
      return 'Esta semana';

    case AtlasExecutiveBrainHorizon.month:
      return 'Este mês';
  }
}

String atlasExecutiveImpactDirectionLabel(
  AtlasExecutiveImpactDirection direction,
) {
  switch (direction) {
    case AtlasExecutiveImpactDirection.positive:
      return 'Positivo';

    case AtlasExecutiveImpactDirection.negative:
      return 'Negativo';

    case AtlasExecutiveImpactDirection.mixed:
      return 'Misto';
  }
}

String atlasExecutiveConflictTypeLabel(
  AtlasExecutiveConflictType type,
) {
  switch (type) {
    case AtlasExecutiveConflictType.resource:
      return 'Recursos';

    case AtlasExecutiveConflictType.priority:
      return 'Prioridade';

    case AtlasExecutiveConflictType.deadline:
      return 'Prazo';

    case AtlasExecutiveConflictType.strategy:
      return 'Estratégia';

    case AtlasExecutiveConflictType.execution:
      return 'Execução';
  }
}

String atlasExecutiveMemoryInsightTypeLabel(
  AtlasExecutiveMemoryInsightType type,
) {
  switch (type) {
    case AtlasExecutiveMemoryInsightType.recurringPattern:
      return 'Padrão recorrente';

    case AtlasExecutiveMemoryInsightType.historicalRisk:
      return 'Risco histórico';

    case AtlasExecutiveMemoryInsightType.repeatedOpportunity:
      return 'Oportunidade repetida';

    case AtlasExecutiveMemoryInsightType.decisionLesson:
      return 'Aprendizado de decisão';

    case AtlasExecutiveMemoryInsightType.missionLesson:
      return 'Aprendizado de missão';
  }
}
