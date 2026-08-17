import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasBiAnalyticsData {
  const AtlasBiAnalyticsData({
    required this.generatedAt,
    required this.summary,
    required this.score,
    required this.bottlenecks,
    required this.investments,
    required this.correlations,
    required this.scenarios,
  });

  final DateTime generatedAt;
  final String summary;

  final double score;

  final List<AtlasBiBottleneck> bottlenecks;
  final List<AtlasBiInvestmentOpportunity> investments;
  final List<AtlasBiCorrelation> correlations;
  final List<AtlasBiScenarioAnalysis> scenarios;

  bool get hasData {
    return bottlenecks.isNotEmpty ||
        investments.isNotEmpty ||
        correlations.isNotEmpty ||
        scenarios.isNotEmpty;
  }

  AtlasBiBottleneck? get mainBottleneck {
    if (bottlenecks.isEmpty) {
      return null;
    }

    return bottlenecks.first;
  }

  AtlasBiInvestmentOpportunity? get bestInvestment {
    if (investments.isEmpty) {
      return null;
    }

    return investments.first;
  }
}

class AtlasBiBottleneck {
  const AtlasBiBottleneck({
    required this.id,
    required this.farmName,
    required this.indicatorId,
    required this.indicatorTitle,
    required this.category,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.performanceGapPercent,
    required this.financialImpactValue,
    required this.priorityScore,
    required this.severity,
    required this.cause,
    required this.recommendation,
  });

  final String id;
  final String farmName;

  final String indicatorId;
  final String indicatorTitle;

  final AtlasBiCategory category;

  final double currentValue;
  final double targetValue;
  final String unit;

  final double performanceGapPercent;
  final double financialImpactValue;
  final double priorityScore;

  final AtlasBiAnalyticsSeverity severity;

  final String cause;
  final String recommendation;
}

class AtlasBiInvestmentOpportunity {
  const AtlasBiInvestmentOpportunity({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.investmentValue,
    required this.expectedReturnValue,
    required this.roiPercent,
    required this.paybackDays,
    required this.confidencePercent,
    required this.impactScore,
    required this.effort,
    required this.recommendation,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;

  final double investmentValue;
  final double expectedReturnValue;
  final double roiPercent;

  final int? paybackDays;

  final double confidencePercent;
  final double impactScore;

  final AtlasBiAnalyticsEffort effort;

  final String recommendation;
}

class AtlasBiCorrelation {
  const AtlasBiCorrelation({
    required this.firstIndicatorId,
    required this.firstIndicatorTitle,
    required this.secondIndicatorId,
    required this.secondIndicatorTitle,
    required this.category,
    required this.coefficient,
    required this.strength,
    required this.direction,
    required this.explanation,
  });

  final String firstIndicatorId;
  final String firstIndicatorTitle;

  final String secondIndicatorId;
  final String secondIndicatorTitle;

  final AtlasBiCategory category;

  final double coefficient;

  final AtlasBiCorrelationStrength strength;
  final AtlasBiCorrelationDirection direction;

  final String explanation;
}

class AtlasBiScenarioAnalysis {
  const AtlasBiScenarioAnalysis({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.currentValue,
    required this.simulatedValue,
    required this.changePercent,
    required this.projectedFinancialImpact,
    required this.riskReductionPercent,
    required this.confidencePercent,
    required this.recommendation,
  });

  final String id;
  final String farmName;

  final String title;
  final String description;

  final AtlasBiCategory category;

  final double currentValue;
  final double simulatedValue;
  final double changePercent;

  final double projectedFinancialImpact;
  final double riskReductionPercent;
  final double confidencePercent;

  final String recommendation;
}

class AtlasBiAnalyticsInput {
  const AtlasBiAnalyticsInput({
    required this.indicators,
    required this.defaultInvestmentValue,
  });

  final List<AtlasBiIndicator> indicators;

  final double defaultInvestmentValue;
}

enum AtlasBiAnalyticsSeverity { low, medium, high, critical }

enum AtlasBiAnalyticsEffort { low, medium, high }

enum AtlasBiCorrelationStrength { weak, moderate, strong, veryStrong }

enum AtlasBiCorrelationDirection { positive, negative, neutral }

String atlasBiAnalyticsSeverityLabel(AtlasBiAnalyticsSeverity severity) {
  switch (severity) {
    case AtlasBiAnalyticsSeverity.low:
      return 'Baixa';

    case AtlasBiAnalyticsSeverity.medium:
      return 'Média';

    case AtlasBiAnalyticsSeverity.high:
      return 'Alta';

    case AtlasBiAnalyticsSeverity.critical:
      return 'Crítica';
  }
}

String atlasBiAnalyticsEffortLabel(AtlasBiAnalyticsEffort effort) {
  switch (effort) {
    case AtlasBiAnalyticsEffort.low:
      return 'Baixo';

    case AtlasBiAnalyticsEffort.medium:
      return 'Médio';

    case AtlasBiAnalyticsEffort.high:
      return 'Alto';
  }
}

String atlasBiCorrelationStrengthLabel(AtlasBiCorrelationStrength strength) {
  switch (strength) {
    case AtlasBiCorrelationStrength.weak:
      return 'Fraca';

    case AtlasBiCorrelationStrength.moderate:
      return 'Moderada';

    case AtlasBiCorrelationStrength.strong:
      return 'Forte';

    case AtlasBiCorrelationStrength.veryStrong:
      return 'Muito forte';
  }
}

String atlasBiCorrelationDirectionLabel(AtlasBiCorrelationDirection direction) {
  switch (direction) {
    case AtlasBiCorrelationDirection.positive:
      return 'Positiva';

    case AtlasBiCorrelationDirection.negative:
      return 'Negativa';

    case AtlasBiCorrelationDirection.neutral:
      return 'Neutra';
  }
}
