class AtlasValueGovernanceDecision {
  const AtlasValueGovernanceDecision({
    required this.id,
    required this.strategyPlanId,
    required this.farmId,
    required this.farmName,
    required this.strategyTitle,
    required this.createdAt,
    required this.decision,
    required this.valueScore,
    required this.financialScore,
    required this.executionScore,
    required this.riskScore,
    required this.benefitAchievement,
    required this.budgetVariance,
    required this.roiVariance,
    required this.executiveSummary,
    required this.conditions,
    required this.requiredActions,
    required this.nextReviewAt,
  });

  final String id;
  final String strategyPlanId;
  final String farmId;
  final String farmName;
  final String strategyTitle;
  final DateTime createdAt;
  final AtlasValueGovernanceDecisionType decision;
  final double valueScore;
  final double financialScore;
  final double executionScore;
  final double riskScore;
  final double benefitAchievement;
  final double budgetVariance;
  final double roiVariance;
  final String executiveSummary;
  final List<String> conditions;
  final List<String> requiredActions;
  final DateTime nextReviewAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'strategyPlanId': strategyPlanId,
        'farmId': farmId,
        'farmName': farmName,
        'strategyTitle': strategyTitle,
        'createdAt': createdAt.toIso8601String(),
        'decision': decision.name,
        'valueScore': valueScore,
        'financialScore': financialScore,
        'executionScore': executionScore,
        'riskScore': riskScore,
        'benefitAchievement': benefitAchievement,
        'budgetVariance': budgetVariance,
        'roiVariance': roiVariance,
        'executiveSummary': executiveSummary,
        'conditions': conditions,
        'requiredActions': requiredActions,
        'nextReviewAt': nextReviewAt.toIso8601String(),
      };

  factory AtlasValueGovernanceDecision.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasValueGovernanceDecision(
      id: json['id'] as String? ?? '',
      strategyPlanId: json['strategyPlanId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Fazenda',
      strategyTitle: json['strategyTitle'] as String? ?? 'Estratégia',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      decision: AtlasValueGovernanceDecisionType.values.firstWhere(
        (item) => item.name == json['decision'],
        orElse: () => AtlasValueGovernanceDecisionType.conditionalApproval,
      ),
      valueScore: (json['valueScore'] as num?)?.toDouble() ?? 0,
      financialScore: (json['financialScore'] as num?)?.toDouble() ?? 0,
      executionScore: (json['executionScore'] as num?)?.toDouble() ?? 0,
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0,
      benefitAchievement:
          (json['benefitAchievement'] as num?)?.toDouble() ?? 0,
      budgetVariance: (json['budgetVariance'] as num?)?.toDouble() ?? 0,
      roiVariance: (json['roiVariance'] as num?)?.toDouble() ?? 0,
      executiveSummary: json['executiveSummary'] as String? ?? '',
      conditions: (json['conditions'] as List? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      requiredActions:
          (json['requiredActions'] as List? ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      nextReviewAt:
          DateTime.tryParse(json['nextReviewAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

enum AtlasValueGovernanceDecisionType {
  approve,
  conditionalApproval,
  correct,
  pause,
  terminate,
}

String atlasValueGovernanceDecisionLabel(
  AtlasValueGovernanceDecisionType decision,
) {
  switch (decision) {
    case AtlasValueGovernanceDecisionType.approve:
      return 'Aprovar continuidade';
    case AtlasValueGovernanceDecisionType.conditionalApproval:
      return 'Aprovar com condições';
    case AtlasValueGovernanceDecisionType.correct:
      return 'Corrigir antes de avançar';
    case AtlasValueGovernanceDecisionType.pause:
      return 'Pausar investimento';
    case AtlasValueGovernanceDecisionType.terminate:
      return 'Encerrar estratégia';
  }
}
