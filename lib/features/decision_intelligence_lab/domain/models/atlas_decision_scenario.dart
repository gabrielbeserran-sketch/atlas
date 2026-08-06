import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasDecisionScenarioInput {
  const AtlasDecisionScenarioInput({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.investment,
    required this.monthlyRevenueGain,
    required this.monthlyCostChange,
    required this.horizonMonths,
    required this.operationalComplexity,
    required this.executionReadiness,
  });

  final String id;
  final String title;
  final String description;
  final AtlasFarmAuditArea area;
  final double investment;
  final double monthlyRevenueGain;
  final double monthlyCostChange;
  final int horizonMonths;
  final double operationalComplexity;
  final double executionReadiness;
}

class AtlasDecisionScenarioResult {
  const AtlasDecisionScenarioResult({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.input,
    required this.expectedNetGain,
    required this.roiPercent,
    required this.paybackMonths,
    required this.successProbability,
    required this.confidence,
    required this.risk,
    required this.score,
    required this.currentAreaScore,
    required this.projectedAreaScore,
    required this.expectedResultMonths,
    required this.advantages,
    required this.risks,
    required this.implementationPlan,
    required this.explanation,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final AtlasDecisionScenarioInput input;
  final double expectedNetGain;
  final double roiPercent;
  final double paybackMonths;
  final double successProbability;
  final double confidence;
  final AtlasDecisionRisk risk;
  final double score;
  final double currentAreaScore;
  final double projectedAreaScore;
  final int expectedResultMonths;
  final List<String> advantages;
  final List<String> risks;
  final List<String> implementationPlan;
  final String explanation;
}

class AtlasDecisionComparison {
  const AtlasDecisionComparison({
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.results,
  });

  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final List<AtlasDecisionScenarioResult> results;

  AtlasDecisionScenarioResult? get recommended {
    if (results.isEmpty) {
      return null;
    }

    final ordered = List<AtlasDecisionScenarioResult>.from(
      results,
    )..sort(
        (first, second) =>
            second.score.compareTo(first.score),
      );

    return ordered.first;
  }
}

enum AtlasDecisionRisk {
  low,
  moderate,
  high,
  critical,
}

String atlasDecisionRiskLabel(AtlasDecisionRisk risk) {
  switch (risk) {
    case AtlasDecisionRisk.low:
      return 'Baixo';
    case AtlasDecisionRisk.moderate:
      return 'Moderado';
    case AtlasDecisionRisk.high:
      return 'Alto';
    case AtlasDecisionRisk.critical:
      return 'Crítico';
  }
}
