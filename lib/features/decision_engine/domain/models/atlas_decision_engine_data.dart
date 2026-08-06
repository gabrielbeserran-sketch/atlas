import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasDecisionEngineData {
  const AtlasDecisionEngineData({
    required this.generatedAt,
    required this.summary,
    required this.engineScore,
    required this.confidencePercent,
    required this.status,
    required this.decisions,
    required this.mainDecision,
  });

  final DateTime generatedAt;
  final String summary;

  final double engineScore;
  final double confidencePercent;

  final AtlasDecisionEngineStatus status;

  final List<AtlasDecisionRecommendation> decisions;
  final AtlasDecisionRecommendation? mainDecision;

  bool get hasData {
    return decisions.isNotEmpty;
  }
}

class AtlasDecisionRecommendation {
  const AtlasDecisionRecommendation({
    required this.position,
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.urgency,
    required this.risk,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.investmentValue,
    required this.expectedReturnValue,
    required this.roiPercent,
    required this.paybackDays,
    required this.deadlineDays,
    required this.expectedResult,
    required this.reasoningSummary,
    required this.executionPlan,
    required this.monitoringIndicators,
    required this.status,
  });

  final int position;
  final String id;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;

  final AtlasDecisionPriority priority;
  final AtlasDecisionUrgency urgency;
  final AtlasDecisionRisk risk;

  final double confidencePercent;

  final double expectedFinancialImpact;
  final double investmentValue;
  final double expectedReturnValue;
  final double roiPercent;

  final int? paybackDays;
  final int deadlineDays;

  final String expectedResult;
  final String reasoningSummary;

  final List<AtlasDecisionExecutionStep> executionPlan;
  final List<AtlasDecisionMonitoringIndicator> monitoringIndicators;

  final AtlasDecisionStatus status;
}

class AtlasDecisionExecutionStep {
  const AtlasDecisionExecutionStep({
    required this.position,
    required this.title,
    required this.description,
    required this.deadlineDays,
    required this.expectedResult,
    this.responsibleName = '',
  });

  final int position;

  final String title;
  final String description;

  final int deadlineDays;
  final String expectedResult;

  final String responsibleName;
}

class AtlasDecisionMonitoringIndicator {
  const AtlasDecisionMonitoringIndicator({
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.measurementFrequencyDays,
  });

  final String title;

  final double currentValue;
  final double targetValue;
  final String unit;

  final int measurementFrequencyDays;
}

enum AtlasDecisionEngineStatus {
  excellent,
  adequate,
  attention,
  critical,
}

enum AtlasDecisionPriority {
  low,
  medium,
  high,
  critical,
}

enum AtlasDecisionUrgency {
  low,
  medium,
  high,
  immediate,
}

enum AtlasDecisionRisk {
  low,
  medium,
  high,
  critical,
}

enum AtlasDecisionStatus {
  recommended,
  approved,
  inProgress,
  completed,
  cancelled,
}

String atlasDecisionEngineStatusLabel(
  AtlasDecisionEngineStatus status,
) {
  switch (status) {
    case AtlasDecisionEngineStatus.excellent:
      return 'Excelente';

    case AtlasDecisionEngineStatus.adequate:
      return 'Adequado';

    case AtlasDecisionEngineStatus.attention:
      return 'Atenção';

    case AtlasDecisionEngineStatus.critical:
      return 'Crítico';
  }
}

String atlasDecisionPriorityLabel(
  AtlasDecisionPriority priority,
) {
  switch (priority) {
    case AtlasDecisionPriority.low:
      return 'Baixa';

    case AtlasDecisionPriority.medium:
      return 'Média';

    case AtlasDecisionPriority.high:
      return 'Alta';

    case AtlasDecisionPriority.critical:
      return 'Crítica';
  }
}

String atlasDecisionUrgencyLabel(
  AtlasDecisionUrgency urgency,
) {
  switch (urgency) {
    case AtlasDecisionUrgency.low:
      return 'Baixa';

    case AtlasDecisionUrgency.medium:
      return 'Média';

    case AtlasDecisionUrgency.high:
      return 'Alta';

    case AtlasDecisionUrgency.immediate:
      return 'Imediata';
  }
}

String atlasDecisionRiskLabel(
  AtlasDecisionRisk risk,
) {
  switch (risk) {
    case AtlasDecisionRisk.low:
      return 'Baixo';

    case AtlasDecisionRisk.medium:
      return 'Médio';

    case AtlasDecisionRisk.high:
      return 'Alto';

    case AtlasDecisionRisk.critical:
      return 'Crítico';
  }
}

String atlasDecisionStatusLabel(
  AtlasDecisionStatus status,
) {
  switch (status) {
    case AtlasDecisionStatus.recommended:
      return 'Recomendada';

    case AtlasDecisionStatus.approved:
      return 'Aprovada';

    case AtlasDecisionStatus.inProgress:
      return 'Em andamento';

    case AtlasDecisionStatus.completed:
      return 'Concluída';

    case AtlasDecisionStatus.cancelled:
      return 'Cancelada';
  }
}
