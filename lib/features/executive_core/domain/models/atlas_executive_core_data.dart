class AtlasExecutiveCoreData {
  const AtlasExecutiveCoreData({
    required this.generatedAt,
    required this.summary,
    required this.executiveScore,
    required this.financialIndex,
    required this.operationalIndex,
    required this.strategicIndex,
    required this.predictiveIndex,
    required this.healthIndex,
    required this.confidencePercent,
    required this.status,
    required this.priorities,
    required this.risks,
    required this.opportunities,
    required this.bestDecisionOfWeek,
    required this.nextMission,
    required this.memoryRecords,
  });

  final DateTime generatedAt;
  final String summary;

  final double executiveScore;
  final double financialIndex;
  final double operationalIndex;
  final double strategicIndex;
  final double predictiveIndex;
  final double healthIndex;
  final double confidencePercent;

  final AtlasExecutiveCoreStatus status;

  final List<AtlasExecutiveCorePriority> priorities;
  final List<AtlasExecutiveCoreRisk> risks;
  final List<AtlasExecutiveCoreOpportunity> opportunities;

  final AtlasExecutiveCoreDecision? bestDecisionOfWeek;
  final AtlasExecutiveCoreMission? nextMission;

  final List<AtlasExecutiveMemoryRecord> memoryRecords;

  bool get hasData {
    return priorities.isNotEmpty ||
        risks.isNotEmpty ||
        opportunities.isNotEmpty ||
        bestDecisionOfWeek != null ||
        nextMission != null ||
        memoryRecords.isNotEmpty;
  }
}

class AtlasExecutiveCorePriority {
  const AtlasExecutiveCorePriority({
    required this.position,
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.priority,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineHours,
    required this.source,
  });

  final int position;
  final String id;

  final String title;
  final String description;
  final String farmName;

  final AtlasExecutiveCorePriorityLevel priority;

  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineHours;

  final String source;
}

class AtlasExecutiveCoreRisk {
  const AtlasExecutiveCoreRisk({
    required this.position,
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.severity,
    required this.probabilityPercent,
    required this.expectedFinancialImpact,
    required this.recommendation,
  });

  final int position;
  final String id;

  final String title;
  final String description;
  final String farmName;

  final AtlasExecutiveCoreSeverity severity;

  final double probabilityPercent;
  final double expectedFinancialImpact;

  final String recommendation;
}

class AtlasExecutiveCoreOpportunity {
  const AtlasExecutiveCoreOpportunity({
    required this.position,
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.expectedReturn,
    required this.investmentValue,
    required this.roiPercent,
    required this.confidencePercent,
    required this.recommendation,
  });

  final int position;
  final String id;

  final String title;
  final String description;
  final String farmName;

  final double expectedReturn;
  final double investmentValue;
  final double roiPercent;
  final double confidencePercent;

  final String recommendation;
}

class AtlasExecutiveCoreDecision {
  const AtlasExecutiveCoreDecision({
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.score,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.deadlineHours,
    required this.reasoning,
    required this.actions,
  });

  final String id;

  final String title;
  final String description;
  final String farmName;

  final double score;
  final double confidencePercent;
  final double expectedFinancialImpact;

  final int deadlineHours;

  final String reasoning;
  final List<String> actions;
}

class AtlasExecutiveCoreMission {
  const AtlasExecutiveCoreMission({
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.objective,
    required this.deadlineDays,
    required this.expectedImpact,
    required this.successProbabilityPercent,
    required this.steps,
  });

  final String id;

  final String title;
  final String description;
  final String farmName;
  final String objective;

  final int deadlineDays;

  final String expectedImpact;
  final double successProbabilityPercent;

  final List<String> steps;
}

class AtlasExecutiveMemoryRecord {
  const AtlasExecutiveMemoryRecord({
    required this.id,
    required this.recordedAt,
    required this.title,
    required this.description,
    required this.type,
    required this.farmName,
    required this.relevanceScore,
    required this.relatedEntityIds,
  });

  final String id;
  final DateTime recordedAt;

  final String title;
  final String description;

  final AtlasExecutiveMemoryType type;

  final String farmName;
  final double relevanceScore;

  final List<String> relatedEntityIds;
}

enum AtlasExecutiveCoreStatus { excellent, adequate, attention, critical }

enum AtlasExecutiveCorePriorityLevel { low, medium, high, critical }

enum AtlasExecutiveCoreSeverity { low, medium, high, critical }

enum AtlasExecutiveMemoryType { decision, risk, opportunity, pattern, mission }

String atlasExecutiveCoreStatusLabel(AtlasExecutiveCoreStatus status) {
  switch (status) {
    case AtlasExecutiveCoreStatus.excellent:
      return 'Excelente';

    case AtlasExecutiveCoreStatus.adequate:
      return 'Adequado';

    case AtlasExecutiveCoreStatus.attention:
      return 'Atenção';

    case AtlasExecutiveCoreStatus.critical:
      return 'Crítico';
  }
}

String atlasExecutiveCorePriorityLabel(
  AtlasExecutiveCorePriorityLevel priority,
) {
  switch (priority) {
    case AtlasExecutiveCorePriorityLevel.low:
      return 'Baixa';

    case AtlasExecutiveCorePriorityLevel.medium:
      return 'Média';

    case AtlasExecutiveCorePriorityLevel.high:
      return 'Alta';

    case AtlasExecutiveCorePriorityLevel.critical:
      return 'Crítica';
  }
}

String atlasExecutiveCoreSeverityLabel(AtlasExecutiveCoreSeverity severity) {
  switch (severity) {
    case AtlasExecutiveCoreSeverity.low:
      return 'Baixa';

    case AtlasExecutiveCoreSeverity.medium:
      return 'Média';

    case AtlasExecutiveCoreSeverity.high:
      return 'Alta';

    case AtlasExecutiveCoreSeverity.critical:
      return 'Crítica';
  }
}

String atlasExecutiveMemoryTypeLabel(AtlasExecutiveMemoryType type) {
  switch (type) {
    case AtlasExecutiveMemoryType.decision:
      return 'Decisão';

    case AtlasExecutiveMemoryType.risk:
      return 'Risco';

    case AtlasExecutiveMemoryType.opportunity:
      return 'Oportunidade';

    case AtlasExecutiveMemoryType.pattern:
      return 'Padrão';

    case AtlasExecutiveMemoryType.mission:
      return 'Missão';
  }
}
