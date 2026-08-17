import 'package:projeto_atlas/features/strategic_scenario_planning/domain/models/atlas_strategic_scenario.dart';

class AtlasScenarioAnalysis {
  const AtlasScenarioAnalysis({
    required this.scenario,
    required this.cashFlows,
    required this.netPresentValue,
    required this.internalRateOfReturn,
    required this.roiPercent,
    required this.paybackYears,
    required this.totalNetGain,
    required this.riskScore,
    required this.resilienceScore,
    required this.recommendation,
    required this.classification,
    required this.optimisticNetPresentValue,
    required this.pessimisticNetPresentValue,
  });

  final AtlasStrategicScenario scenario;
  final List<double> cashFlows;
  final double netPresentValue;
  final double internalRateOfReturn;
  final double roiPercent;
  final double paybackYears;
  final double totalNetGain;
  final double riskScore;
  final double resilienceScore;
  final String recommendation;
  final AtlasScenarioClassification classification;
  final double optimisticNetPresentValue;
  final double pessimisticNetPresentValue;
}

class AtlasScenarioPortfolioAnalysis {
  const AtlasScenarioPortfolioAnalysis({
    required this.generatedAt,
    required this.items,
  });

  final DateTime generatedAt;
  final List<AtlasScenarioAnalysis> items;

  AtlasScenarioAnalysis? get bestReturn {
    if (items.isEmpty) {
      return null;
    }

    return items.reduce(
      (first, second) =>
          first.netPresentValue >= second.netPresentValue ? first : second,
    );
  }

  AtlasScenarioAnalysis? get lowestRisk {
    if (items.isEmpty) {
      return null;
    }

    return items.reduce(
      (first, second) => first.riskScore <= second.riskScore ? first : second,
    );
  }

  AtlasScenarioAnalysis? get bestBalance {
    if (items.isEmpty) {
      return null;
    }

    return items.reduce(
      (first, second) => _balance(first) >= _balance(second) ? first : second,
    );
  }

  double _balance(AtlasScenarioAnalysis item) {
    return (item.roiPercent * 0.40 +
        item.resilienceScore * 0.35 +
        (100 - item.riskScore) * 0.25);
  }
}

enum AtlasScenarioClassification {
  recommended,
  recommendedInPhases,
  review,
  notRecommended,
}

String atlasScenarioClassificationLabel(
  AtlasScenarioClassification classification,
) {
  switch (classification) {
    case AtlasScenarioClassification.recommended:
      return 'Recomendado';
    case AtlasScenarioClassification.recommendedInPhases:
      return 'Executar em fases';
    case AtlasScenarioClassification.review:
      return 'Revisar';
    case AtlasScenarioClassification.notRecommended:
      return 'Não recomendado';
  }
}
