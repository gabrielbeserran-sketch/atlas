import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasCopilotData {
  const AtlasCopilotData({
    required this.generatedAt,
    required this.summary,
    required this.maturityScore,
    required this.maturityLevel,
    required this.mainProblem,
    required this.topPriority,
    required this.actions,
    required this.investments,
    required this.alerts,
    required this.recommendations,
    required this.checklist,
  });

  final DateTime generatedAt;
  final String summary;

  final double maturityScore;
  final AtlasCopilotMaturityLevel maturityLevel;

  final AtlasCopilotIssue? mainProblem;
  final AtlasCopilotPriority? topPriority;

  final List<AtlasCopilotAction> actions;
  final List<AtlasCopilotInvestment> investments;
  final List<AtlasCopilotAlert> alerts;
  final List<AtlasCopilotRecommendation> recommendations;
  final List<AtlasCopilotChecklistItem> checklist;

  bool get hasData {
    return mainProblem != null ||
        topPriority != null ||
        actions.isNotEmpty ||
        investments.isNotEmpty ||
        alerts.isNotEmpty ||
        recommendations.isNotEmpty;
  }
}

class AtlasCopilotIssue {
  const AtlasCopilotIssue({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.impactScore,
    required this.financialImpactValue,
    required this.cause,
    required this.recommendation,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasCopilotSeverity severity;

  final double impactScore;
  final double financialImpactValue;

  final String cause;
  final String recommendation;
}

class AtlasCopilotPriority {
  const AtlasCopilotPriority({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.confidencePercent,
    required this.expectedResult,
    required this.deadlineDays,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasCopilotPriorityLevel priority;

  final double confidencePercent;

  final String expectedResult;
  final int deadlineDays;
}

class AtlasCopilotAction {
  const AtlasCopilotAction({
    required this.position,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.deadlineDays,
    required this.expectedResult,
    this.responsibleName = '',
  });

  final int position;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasCopilotPriorityLevel priority;

  final int deadlineDays;
  final String expectedResult;

  final String responsibleName;
}

class AtlasCopilotInvestment {
  const AtlasCopilotInvestment({
    required this.position,
    required this.farmName,
    required this.title,
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
  final AtlasBiCategory category;

  final double investmentValue;
  final double expectedReturnValue;
  final double roiPercent;

  final int? paybackDays;

  final double confidencePercent;
  final String recommendation;
}

class AtlasCopilotAlert {
  const AtlasCopilotAlert({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.source,
    required this.recommendation,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasCopilotSeverity severity;
  final AtlasCopilotAlertSource source;

  final String recommendation;
}

class AtlasCopilotRecommendation {
  const AtlasCopilotRecommendation({
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
  final AtlasCopilotPriorityLevel priority;

  final double confidencePercent;
  final String expectedImpact;
}

class AtlasCopilotChecklistItem {
  const AtlasCopilotChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.completed,
  });

  final String id;
  final String title;
  final String description;

  final AtlasCopilotPriorityLevel priority;
  final bool completed;

  AtlasCopilotChecklistItem copyWith({
    bool? completed,
  }) {
    return AtlasCopilotChecklistItem(
      id: id,
      title: title,
      description: description,
      priority: priority,
      completed: completed ?? this.completed,
    );
  }
}

enum AtlasCopilotMaturityLevel {
  initial,
  developing,
  structured,
  advanced,
  excellent,
}

enum AtlasCopilotSeverity {
  low,
  medium,
  high,
  critical,
}

enum AtlasCopilotPriorityLevel {
  low,
  medium,
  high,
  critical,
}

enum AtlasCopilotAlertSource {
  indicator,
  forecast,
  benchmark,
  analytics,
  strategy,
  goal,
}

String atlasCopilotMaturityLevelLabel(
  AtlasCopilotMaturityLevel level,
) {
  switch (level) {
    case AtlasCopilotMaturityLevel.initial:
      return 'Inicial';

    case AtlasCopilotMaturityLevel.developing:
      return 'Em desenvolvimento';

    case AtlasCopilotMaturityLevel.structured:
      return 'Estruturada';

    case AtlasCopilotMaturityLevel.advanced:
      return 'Avançada';

    case AtlasCopilotMaturityLevel.excellent:
      return 'Excelente';
  }
}

String atlasCopilotSeverityLabel(
  AtlasCopilotSeverity severity,
) {
  switch (severity) {
    case AtlasCopilotSeverity.low:
      return 'Baixa';

    case AtlasCopilotSeverity.medium:
      return 'Média';

    case AtlasCopilotSeverity.high:
      return 'Alta';

    case AtlasCopilotSeverity.critical:
      return 'Crítica';
  }
}

String atlasCopilotPriorityLabel(
  AtlasCopilotPriorityLevel priority,
) {
  switch (priority) {
    case AtlasCopilotPriorityLevel.low:
      return 'Baixa';

    case AtlasCopilotPriorityLevel.medium:
      return 'Média';

    case AtlasCopilotPriorityLevel.high:
      return 'Alta';

    case AtlasCopilotPriorityLevel.critical:
      return 'Crítica';
  }
}

String atlasCopilotAlertSourceLabel(
  AtlasCopilotAlertSource source,
) {
  switch (source) {
    case AtlasCopilotAlertSource.indicator:
      return 'Indicador';

    case AtlasCopilotAlertSource.forecast:
      return 'Forecast';

    case AtlasCopilotAlertSource.benchmark:
      return 'Benchmarking';

    case AtlasCopilotAlertSource.analytics:
      return 'Analytics';

    case AtlasCopilotAlertSource.strategy:
      return 'Estratégia';

    case AtlasCopilotAlertSource.goal:
      return 'Meta';
  }
}
