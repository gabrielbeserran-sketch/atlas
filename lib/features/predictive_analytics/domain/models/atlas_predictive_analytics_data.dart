import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasPredictiveAnalyticsData {
  const AtlasPredictiveAnalyticsData({
    required this.generatedAt,
    required this.summary,
    required this.horizonDays,
    required this.score,
    required this.confidencePercent,
    required this.status,
    required this.forecasts,
    required this.scenarios,
    required this.risks,
    required this.recommendations,
  });

  final DateTime generatedAt;
  final String summary;

  final int horizonDays;

  final double score;
  final double confidencePercent;

  final AtlasPredictiveAnalyticsStatus status;

  final List<AtlasPredictiveForecast> forecasts;
  final List<AtlasPredictiveScenario> scenarios;
  final List<AtlasPredictiveRisk> risks;
  final List<AtlasPredictiveRecommendation> recommendations;

  bool get hasData {
    return forecasts.isNotEmpty ||
        scenarios.isNotEmpty ||
        risks.isNotEmpty ||
        recommendations.isNotEmpty;
  }

  AtlasPredictiveForecast? get priorityForecast {
    if (forecasts.isEmpty) {
      return null;
    }

    return forecasts.first;
  }

  AtlasPredictiveRisk? get mainRisk {
    if (risks.isEmpty) {
      return null;
    }

    return risks.first;
  }
}

class AtlasPredictiveForecast {
  const AtlasPredictiveForecast({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.kind,
    required this.currentValue,
    required this.projectedValue,
    required this.expectedVariationPercent,
    required this.optimisticValue,
    required this.pessimisticValue,
    required this.unit,
    required this.horizonDays,
    required this.confidencePercent,
    required this.risk,
    required this.financialImpactValue,
    required this.recommendation,
  });

  final String id;

  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;
  final AtlasPredictiveForecastKind kind;

  final double currentValue;
  final double projectedValue;
  final double expectedVariationPercent;

  final double optimisticValue;
  final double pessimisticValue;

  final String unit;
  final int horizonDays;

  final double confidencePercent;
  final AtlasPredictiveAnalyticsRiskLevel risk;

  final double financialImpactValue;
  final String recommendation;
}

class AtlasPredictiveScenario {
  const AtlasPredictiveScenario({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.changePercent,
    required this.projectedValue,
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
  final AtlasPredictiveScenarioType type;

  final double changePercent;
  final double projectedValue;
  final double projectedFinancialImpact;
  final double riskReductionPercent;
  final double confidencePercent;

  final String recommendation;
}

class AtlasPredictiveRisk {
  const AtlasPredictiveRisk({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
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
  final AtlasPredictiveAnalyticsRiskLevel level;

  final double probabilityPercent;
  final double financialImpactValue;

  final int horizonDays;

  final String recommendation;
}

class AtlasPredictiveRecommendation {
  const AtlasPredictiveRecommendation({
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
  final AtlasPredictiveAnalyticsPriority priority;

  final double confidencePercent;
  final String expectedImpact;
}

enum AtlasPredictiveAnalyticsStatus { excellent, adequate, attention, critical }

enum AtlasPredictiveForecastKind {
  finance,
  production,
  weightGain,
  reproduction,
  health,
  cashFlow,
  pastureCapacity,
  supplementConsumption,
  purchaseNeed,
  mortalityRisk,
  operationalBottleneck,
}

enum AtlasPredictiveScenarioType { optimistic, expected, pessimistic, whatIf }

enum AtlasPredictiveAnalyticsRiskLevel { low, medium, high, critical }

enum AtlasPredictiveAnalyticsPriority { low, medium, high, critical }

String atlasPredictiveAnalyticsStatusLabel(
  AtlasPredictiveAnalyticsStatus status,
) {
  switch (status) {
    case AtlasPredictiveAnalyticsStatus.excellent:
      return 'Excelente';

    case AtlasPredictiveAnalyticsStatus.adequate:
      return 'Adequado';

    case AtlasPredictiveAnalyticsStatus.attention:
      return 'Atenção';

    case AtlasPredictiveAnalyticsStatus.critical:
      return 'Crítico';
  }
}

String atlasPredictiveForecastKindLabel(AtlasPredictiveForecastKind kind) {
  switch (kind) {
    case AtlasPredictiveForecastKind.finance:
      return 'Financeiro';

    case AtlasPredictiveForecastKind.production:
      return 'Produção';

    case AtlasPredictiveForecastKind.weightGain:
      return 'Ganho de peso';

    case AtlasPredictiveForecastKind.reproduction:
      return 'Reprodução';

    case AtlasPredictiveForecastKind.health:
      return 'Sanidade';

    case AtlasPredictiveForecastKind.cashFlow:
      return 'Fluxo de caixa';

    case AtlasPredictiveForecastKind.pastureCapacity:
      return 'Lotação de pastagens';

    case AtlasPredictiveForecastKind.supplementConsumption:
      return 'Consumo de suplemento';

    case AtlasPredictiveForecastKind.purchaseNeed:
      return 'Necessidade de compras';

    case AtlasPredictiveForecastKind.mortalityRisk:
      return 'Risco de mortalidade';

    case AtlasPredictiveForecastKind.operationalBottleneck:
      return 'Gargalo operacional';
  }
}

String atlasPredictiveScenarioTypeLabel(AtlasPredictiveScenarioType type) {
  switch (type) {
    case AtlasPredictiveScenarioType.optimistic:
      return 'Otimista';

    case AtlasPredictiveScenarioType.expected:
      return 'Esperado';

    case AtlasPredictiveScenarioType.pessimistic:
      return 'Pessimista';

    case AtlasPredictiveScenarioType.whatIf:
      return 'E se...?';
  }
}

String atlasPredictiveAnalyticsRiskLevelLabel(
  AtlasPredictiveAnalyticsRiskLevel level,
) {
  switch (level) {
    case AtlasPredictiveAnalyticsRiskLevel.low:
      return 'Baixo';

    case AtlasPredictiveAnalyticsRiskLevel.medium:
      return 'Médio';

    case AtlasPredictiveAnalyticsRiskLevel.high:
      return 'Alto';

    case AtlasPredictiveAnalyticsRiskLevel.critical:
      return 'Crítico';
  }
}

String atlasPredictiveAnalyticsPriorityLabel(
  AtlasPredictiveAnalyticsPriority priority,
) {
  switch (priority) {
    case AtlasPredictiveAnalyticsPriority.low:
      return 'Baixa';

    case AtlasPredictiveAnalyticsPriority.medium:
      return 'Média';

    case AtlasPredictiveAnalyticsPriority.high:
      return 'Alta';

    case AtlasPredictiveAnalyticsPriority.critical:
      return 'Crítica';
  }
}
