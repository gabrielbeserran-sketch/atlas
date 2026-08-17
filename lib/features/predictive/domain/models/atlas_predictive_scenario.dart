import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasPredictiveScenarioRequest {
  const AtlasPredictiveScenarioRequest({
    required this.type,
    required this.title,
    required this.description,
    required this.changePercent,
    this.investmentValue = 0,
    this.executionDays = 30,
  });

  final AtlasPredictiveScenarioType type;

  final String title;
  final String description;

  final double changePercent;
  final double investmentValue;

  final int executionDays;
}

class AtlasPredictiveScenarioResult {
  const AtlasPredictiveScenarioResult({
    required this.generatedAt,
    required this.scopeLabel,
    required this.request,
    required this.currentScore,
    required this.projectedScore,
    required this.scoreVariation,
    required this.currentLevel,
    required this.projectedLevel,
    required this.financialImpact,
    required this.riskReductionPercent,
    required this.confidence,
    required this.effort,
    required this.recommendation,
    required this.mainEvidence,
    required this.projections,
    required this.actions,
  });

  final DateTime generatedAt;
  final String scopeLabel;

  final AtlasPredictiveScenarioRequest request;

  final double currentScore;
  final double projectedScore;
  final double scoreVariation;

  final AtlasDiagnosticLevel currentLevel;
  final AtlasDiagnosticLevel projectedLevel;

  final AtlasPredictiveFinancialImpact financialImpact;

  final double riskReductionPercent;
  final double confidence;

  final AtlasPredictiveEffort effort;

  final String recommendation;
  final String mainEvidence;

  final List<AtlasPredictiveProjection> projections;
  final List<AtlasPredictiveAction> actions;

  bool get improvesScore {
    return scoreVariation > 0;
  }

  bool get hasPositiveFinancialImpact {
    return financialImpact.probableValue > 0;
  }

  double get impactEffortScore {
    final effortWeight = switch (effort) {
      AtlasPredictiveEffort.low => 1.0,
      AtlasPredictiveEffort.medium => 0.78,
      AtlasPredictiveEffort.high => 0.56,
    };

    return ((scoreVariation * 5) +
            riskReductionPercent * 0.45 +
            confidence * 0.20) *
        effortWeight;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'scopeLabel': scopeLabel,
      'request': {
        'type': request.type.name,
        'title': request.title,
        'description': request.description,
        'changePercent': request.changePercent,
        'investmentValue': request.investmentValue,
        'executionDays': request.executionDays,
      },
      'currentScore': currentScore,
      'projectedScore': projectedScore,
      'scoreVariation': scoreVariation,
      'currentLevel': currentLevel.name,
      'projectedLevel': projectedLevel.name,
      'financialImpact': financialImpact.toJson(),
      'riskReductionPercent': riskReductionPercent,
      'confidence': confidence,
      'effort': effort.name,
      'recommendation': recommendation,
      'mainEvidence': mainEvidence,
      'projections': projections.map((item) {
        return item.toJson();
      }).toList(),
      'actions': actions.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class AtlasPredictiveFinancialImpact {
  const AtlasPredictiveFinancialImpact({
    required this.conservativeValue,
    required this.probableValue,
    required this.optimisticValue,
    required this.investmentValue,
    required this.returnOnInvestmentPercent,
    required this.paybackDays,
  });

  final double conservativeValue;
  final double probableValue;
  final double optimisticValue;

  final double investmentValue;
  final double returnOnInvestmentPercent;

  final int? paybackDays;

  Map<String, dynamic> toJson() {
    return {
      'conservativeValue': conservativeValue,
      'probableValue': probableValue,
      'optimisticValue': optimisticValue,
      'investmentValue': investmentValue,
      'returnOnInvestmentPercent': returnOnInvestmentPercent,
      'paybackDays': paybackDays,
    };
  }
}

class AtlasPredictiveProjection {
  const AtlasPredictiveProjection({
    required this.kind,
    required this.label,
    required this.projectedScore,
    required this.financialImpact,
    required this.riskReductionPercent,
    required this.confidence,
  });

  final AtlasPredictiveProjectionKind kind;
  final String label;

  final double projectedScore;
  final double financialImpact;
  final double riskReductionPercent;
  final double confidence;

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      'label': label,
      'projectedScore': projectedScore,
      'financialImpact': financialImpact,
      'riskReductionPercent': riskReductionPercent,
      'confidence': confidence,
    };
  }
}

class AtlasPredictiveAction {
  const AtlasPredictiveAction({
    required this.position,
    required this.title,
    required this.description,
    required this.expectedResult,
    required this.area,
    required this.deadlineDays,
  });

  final int position;

  final String title;
  final String description;
  final String expectedResult;

  final AtlasFarmAnalysisArea area;

  final int deadlineDays;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'title': title,
      'description': description,
      'expectedResult': expectedResult,
      'area': area.name,
      'deadlineDays': deadlineDays,
    };
  }
}

class AtlasPredictiveScenarioRanking {
  const AtlasPredictiveScenarioRanking({
    required this.generatedAt,
    required this.scopeLabel,
    required this.results,
    required this.bestScenario,
    required this.summary,
  });

  final DateTime generatedAt;
  final String scopeLabel;

  final List<AtlasPredictiveScenarioResult> results;

  final AtlasPredictiveScenarioResult? bestScenario;

  final String summary;
}

enum AtlasPredictiveScenarioType {
  reduceCosts,
  increaseRevenue,
  reduceOverdueTasks,
  reduceInventoryLosses,
  improveHerdRecords,
  improvePaddockUse,
  custom,
}

enum AtlasPredictiveProjectionKind { conservative, probable, optimistic }

enum AtlasPredictiveEffort { low, medium, high }

String atlasPredictiveScenarioTypeLabel(AtlasPredictiveScenarioType type) {
  switch (type) {
    case AtlasPredictiveScenarioType.reduceCosts:
      return 'Redução de custos';

    case AtlasPredictiveScenarioType.increaseRevenue:
      return 'Aumento de receita';

    case AtlasPredictiveScenarioType.reduceOverdueTasks:
      return 'Redução de atrasos';

    case AtlasPredictiveScenarioType.reduceInventoryLosses:
      return 'Redução de perdas no estoque';

    case AtlasPredictiveScenarioType.improveHerdRecords:
      return 'Melhoria do cadastro do rebanho';

    case AtlasPredictiveScenarioType.improvePaddockUse:
      return 'Melhoria do uso dos piquetes';

    case AtlasPredictiveScenarioType.custom:
      return 'Cenário personalizado';
  }
}

String atlasPredictiveEffortLabel(AtlasPredictiveEffort effort) {
  switch (effort) {
    case AtlasPredictiveEffort.low:
      return 'Baixo';

    case AtlasPredictiveEffort.medium:
      return 'Médio';

    case AtlasPredictiveEffort.high:
      return 'Alto';
  }
}
