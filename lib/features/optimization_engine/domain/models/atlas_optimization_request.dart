class AtlasOptimizationRequest {
  const AtlasOptimizationRequest({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.objective,
    required this.horizonMonths,
    required this.maxInvestment,
    required this.maxRisk,
    required this.maxHerdExpansion,
    required this.minimumScore,
    required this.generatedAt,
  });

  final String id;
  final String farmId;
  final String farmName;
  final AtlasOptimizationObjective objective;
  final int horizonMonths;
  final double maxInvestment;
  final AtlasOptimizationRiskTolerance maxRisk;
  final int maxHerdExpansion;
  final double minimumScore;
  final DateTime generatedAt;
}

enum AtlasOptimizationObjective {
  balancedGrowth,
  maximizeProfit,
  minimizeRisk,
  improveReproduction,
  improveSanitary,
  improveOperations,
}

enum AtlasOptimizationRiskTolerance {
  low,
  moderate,
  high,
}

String atlasOptimizationObjectiveLabel(
  AtlasOptimizationObjective objective,
) {
  switch (objective) {
    case AtlasOptimizationObjective.balancedGrowth:
      return 'Crescimento equilibrado';
    case AtlasOptimizationObjective.maximizeProfit:
      return 'Maximizar resultado financeiro';
    case AtlasOptimizationObjective.minimizeRisk:
      return 'Reduzir riscos';
    case AtlasOptimizationObjective.improveReproduction:
      return 'Melhorar reprodução';
    case AtlasOptimizationObjective.improveSanitary:
      return 'Melhorar sanidade';
    case AtlasOptimizationObjective.improveOperations:
      return 'Melhorar eficiência operacional';
  }
}

String atlasOptimizationRiskToleranceLabel(
  AtlasOptimizationRiskTolerance tolerance,
) {
  switch (tolerance) {
    case AtlasOptimizationRiskTolerance.low:
      return 'Baixa';
    case AtlasOptimizationRiskTolerance.moderate:
      return 'Moderada';
    case AtlasOptimizationRiskTolerance.high:
      return 'Alta';
  }
}
