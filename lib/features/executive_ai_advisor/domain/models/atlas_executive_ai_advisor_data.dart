import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasExecutiveAiAdvisorData {
  const AtlasExecutiveAiAdvisorData({
    required this.generatedAt,
    required this.title,
    required this.executiveSummary,
    required this.diagnostic,
    required this.weeklyPriorities,
    required this.monthlyPriorities,
    required this.financialOpportunities,
    required this.hiddenRisks,
    required this.operationalBottlenecks,
    required this.strategicRecommendations,
    required this.actionPlan,
    required this.advisorScore,
    required this.confidencePercent,
    required this.status,
  });

  final DateTime generatedAt;

  final String title;
  final String executiveSummary;
  final String diagnostic;

  final List<AtlasExecutiveAdvisorPriority> weeklyPriorities;

  final List<AtlasExecutiveAdvisorPriority> monthlyPriorities;

  final List<AtlasExecutiveAdvisorFinancialOpportunity> financialOpportunities;

  final List<AtlasExecutiveAdvisorRisk> hiddenRisks;

  final List<AtlasExecutiveAdvisorBottleneck> operationalBottlenecks;

  final List<AtlasExecutiveAdvisorRecommendation> strategicRecommendations;

  final List<AtlasExecutiveAdvisorAction> actionPlan;

  final double advisorScore;
  final double confidencePercent;

  final AtlasExecutiveAdvisorStatus status;

  bool get hasData {
    return weeklyPriorities.isNotEmpty ||
        monthlyPriorities.isNotEmpty ||
        financialOpportunities.isNotEmpty ||
        hiddenRisks.isNotEmpty ||
        operationalBottlenecks.isNotEmpty ||
        strategicRecommendations.isNotEmpty ||
        actionPlan.isNotEmpty;
  }
}

class AtlasExecutiveAdvisorPriority {
  const AtlasExecutiveAdvisorPriority({
    required this.position,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.deadlineDays,
    required this.confidencePercent,
    required this.expectedImpact,
  });

  final int position;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasExecutiveAdvisorPriorityLevel priority;

  final int deadlineDays;
  final double confidencePercent;

  final String expectedImpact;
}

class AtlasExecutiveAdvisorFinancialOpportunity {
  const AtlasExecutiveAdvisorFinancialOpportunity({
    required this.position,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.investmentValue,
    required this.expectedReturnValue,
    required this.roiPercent,
    required this.paybackDays,
    required this.confidencePercent,
    required this.recommendation,
  });

  final int position;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;

  final double investmentValue;
  final double expectedReturnValue;
  final double roiPercent;

  final int? paybackDays;

  final double confidencePercent;
  final String recommendation;
}

class AtlasExecutiveAdvisorRisk {
  const AtlasExecutiveAdvisorRisk({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.probabilityPercent,
    required this.financialImpactValue,
    required this.horizonDays,
    required this.recommendation,
  });

  final String id;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasExecutiveAdvisorSeverity severity;

  final double probabilityPercent;
  final double financialImpactValue;

  final int horizonDays;

  final String recommendation;
}

class AtlasExecutiveAdvisorBottleneck {
  const AtlasExecutiveAdvisorBottleneck({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.impactScore,
    required this.confidencePercent,
    required this.rootCause,
    required this.recommendation,
  });

  final String id;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasExecutiveAdvisorSeverity severity;

  final double impactScore;
  final double confidencePercent;

  final String rootCause;
  final String recommendation;
}

class AtlasExecutiveAdvisorRecommendation {
  const AtlasExecutiveAdvisorRecommendation({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.confidencePercent,
    required this.expectedImpact,
  });

  final String id;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasExecutiveAdvisorPriorityLevel priority;

  final double confidencePercent;
  final String expectedImpact;
}

class AtlasExecutiveAdvisorAction {
  const AtlasExecutiveAdvisorAction({
    required this.position,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.deadlineDays,
    required this.expectedResult,
    required this.source,
    this.responsibleName = '',
  });

  final int position;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasExecutiveAdvisorPriorityLevel priority;

  final int deadlineDays;

  final String expectedResult;
  final AtlasExecutiveAdvisorActionSource source;

  final String responsibleName;
}

enum AtlasExecutiveAdvisorStatus { excellent, adequate, attention, critical }

enum AtlasExecutiveAdvisorSeverity { low, medium, high, critical }

enum AtlasExecutiveAdvisorPriorityLevel { low, medium, high, critical }

enum AtlasExecutiveAdvisorActionSource {
  rootCause,
  forecast,
  benchmark,
  analytics,
  financial,
  strategy,
}

String atlasExecutiveAdvisorStatusLabel(AtlasExecutiveAdvisorStatus status) {
  switch (status) {
    case AtlasExecutiveAdvisorStatus.excellent:
      return 'Excelente';

    case AtlasExecutiveAdvisorStatus.adequate:
      return 'Adequado';

    case AtlasExecutiveAdvisorStatus.attention:
      return 'Atenção';

    case AtlasExecutiveAdvisorStatus.critical:
      return 'Crítico';
  }
}

String atlasExecutiveAdvisorSeverityLabel(
  AtlasExecutiveAdvisorSeverity severity,
) {
  switch (severity) {
    case AtlasExecutiveAdvisorSeverity.low:
      return 'Baixa';

    case AtlasExecutiveAdvisorSeverity.medium:
      return 'Média';

    case AtlasExecutiveAdvisorSeverity.high:
      return 'Alta';

    case AtlasExecutiveAdvisorSeverity.critical:
      return 'Crítica';
  }
}

String atlasExecutiveAdvisorPriorityLabel(
  AtlasExecutiveAdvisorPriorityLevel priority,
) {
  switch (priority) {
    case AtlasExecutiveAdvisorPriorityLevel.low:
      return 'Baixa';

    case AtlasExecutiveAdvisorPriorityLevel.medium:
      return 'Média';

    case AtlasExecutiveAdvisorPriorityLevel.high:
      return 'Alta';

    case AtlasExecutiveAdvisorPriorityLevel.critical:
      return 'Crítica';
  }
}

String atlasExecutiveAdvisorActionSourceLabel(
  AtlasExecutiveAdvisorActionSource source,
) {
  switch (source) {
    case AtlasExecutiveAdvisorActionSource.rootCause:
      return 'Causa-raiz';

    case AtlasExecutiveAdvisorActionSource.forecast:
      return 'Forecast';

    case AtlasExecutiveAdvisorActionSource.benchmark:
      return 'Benchmarking';

    case AtlasExecutiveAdvisorActionSource.analytics:
      return 'Analytics';

    case AtlasExecutiveAdvisorActionSource.financial:
      return 'Financeiro';

    case AtlasExecutiveAdvisorActionSource.strategy:
      return 'Estratégia';
  }
}
