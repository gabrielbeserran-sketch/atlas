import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation.dart';

class AtlasSimulationResult {
  const AtlasSimulationResult({
    required this.id,
    required this.simulation,
    required this.executedAt,
    required this.currentTwin,
    required this.simulatedTwin,
    required this.scoreVariation,
    required this.projectedRevenueChange,
    required this.projectedCostChange,
    required this.projectedNetResult,
    required this.roiPercent,
    required this.paybackMonths,
    required this.riskLevel,
    required this.recommendation,
    required this.strengths,
    required this.attentionPoints,
  });

  final String id;
  final AtlasSimulation simulation;
  final DateTime executedAt;
  final AtlasDigitalTwin currentTwin;
  final AtlasDigitalTwin simulatedTwin;
  final double scoreVariation;
  final double projectedRevenueChange;
  final double projectedCostChange;
  final double projectedNetResult;
  final double roiPercent;
  final double? paybackMonths;
  final AtlasSimulationRiskLevel riskLevel;
  final String recommendation;
  final List<String> strengths;
  final List<String> attentionPoints;

  bool get isFavorable {
    return scoreVariation > 0 &&
        projectedNetResult >= 0 &&
        riskLevel != AtlasSimulationRiskLevel.critical;
  }
}

enum AtlasSimulationRiskLevel { low, moderate, high, critical }

String atlasSimulationRiskLevelLabel(AtlasSimulationRiskLevel level) {
  switch (level) {
    case AtlasSimulationRiskLevel.low:
      return 'Baixo';
    case AtlasSimulationRiskLevel.moderate:
      return 'Moderado';
    case AtlasSimulationRiskLevel.high:
      return 'Alto';
    case AtlasSimulationRiskLevel.critical:
      return 'Crítico';
  }
}
