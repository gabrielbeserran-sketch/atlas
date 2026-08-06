import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/models/atlas_optimization_result.dart';

class AtlasConsultantReport {
  const AtlasConsultantReport({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.executiveDiagnosis,
    required this.overallPriority,
    required this.farmScore,
    required this.trend,
    required this.actions,
    required this.optimizationResult,
    required this.strategicSummary,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final String executiveDiagnosis;
  final AtlasConsultantPriority overallPriority;
  final double farmScore;
  final AtlasDigitalTwinTrend trend;
  final List<AtlasConsultantAction> actions;
  final AtlasOptimizationResult optimizationResult;
  final String strategicSummary;

  int get criticalActions {
    return actions
        .where(
          (item) =>
              item.priority ==
              AtlasConsultantPriority.critical,
        )
        .length;
  }

  int get highPriorityActions {
    return actions
        .where(
          (item) =>
              item.priority ==
              AtlasConsultantPriority.high,
        )
        .length;
  }
}

class AtlasConsultantAction {
  const AtlasConsultantAction({
    required this.id,
    required this.title,
    required this.description,
    required this.justification,
    required this.area,
    required this.priority,
    required this.deadlineDays,
    required this.expectedScoreImpact,
    required this.estimatedEconomicImpact,
    required this.riskOfInaction,
    required this.indicators,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final String justification;
  final AtlasDigitalTwinArea area;
  final AtlasConsultantPriority priority;
  final int deadlineDays;
  final double expectedScoreImpact;
  final double estimatedEconomicImpact;
  final String riskOfInaction;
  final List<String> indicators;
  final List<String> steps;
}

enum AtlasConsultantPriority {
  low,
  moderate,
  high,
  critical,
}

String atlasConsultantPriorityLabel(
  AtlasConsultantPriority priority,
) {
  switch (priority) {
    case AtlasConsultantPriority.low:
      return 'Baixa';
    case AtlasConsultantPriority.moderate:
      return 'Moderada';
    case AtlasConsultantPriority.high:
      return 'Alta';
    case AtlasConsultantPriority.critical:
      return 'Crítica';
  }
}
