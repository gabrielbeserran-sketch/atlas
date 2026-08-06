import 'package:projeto_atlas/features/benefits_realization/domain/models/atlas_benefit_realization.dart';
import 'package:projeto_atlas/features/value_governance/domain/models/atlas_value_governance.dart';

class AtlasValueGovernanceEngine {
  const AtlasValueGovernanceEngine();

  AtlasValueGovernanceDecision govern(
    AtlasBenefitRealization realization,
  ) {
    final financial = _financial(realization);
    final execution = _execution(realization);
    final risk = _risk(realization);

    final valueScore = (
      financial * 0.42 +
      execution * 0.33 +
      (100 - risk) * 0.25
    ).clamp(0.0, 100.0).toDouble();

    final decision = _decision(
      valueScore,
      realization.status,
    );

    return AtlasValueGovernanceDecision(
      id: 'governance_${realization.strategyPlanId}',
      strategyPlanId: realization.strategyPlanId,
      farmId: realization.farmId,
      farmName: realization.farmName,
      strategyTitle: realization.strategyTitle,
      createdAt: DateTime.now(),
      decision: decision,
      valueScore: valueScore,
      financialScore: financial,
      executionScore: execution,
      riskScore: risk,
      benefitAchievement: realization.benefitAchievement,
      budgetVariance: realization.budgetVariance,
      roiVariance: realization.roiVariance,
      executiveSummary:
          'Score executivo de ${valueScore.toStringAsFixed(1)}. '
          'Benefício realizado em '
          '${realization.benefitAchievement.toStringAsFixed(1)}%. '
          'Decisão: ${atlasValueGovernanceDecisionLabel(decision)}.',
      conditions: _conditions(realization),
      requiredActions: {
        ...realization.correctiveActions,
        _mainAction(decision),
      }.toList(),
      nextReviewAt: DateTime.now().add(
        Duration(days: _reviewDays(decision)),
      ),
    );
  }

  double _financial(AtlasBenefitRealization item) {
    final achievement =
        item.benefitAchievement.clamp(0.0, 120.0).toDouble();
    final roi = (50 + item.roiVariance)
        .clamp(0.0, 100.0)
        .toDouble();
    final budgetPenalty = item.plannedBudget <= 0
        ? 0.0
        : (item.budgetVariance / item.plannedBudget * 100)
            .clamp(0.0, 60.0)
            .toDouble();

    return (
      achievement * 0.55 +
      roi * 0.30 +
      (100 - budgetPenalty) * 0.15
    ).clamp(0.0, 100.0).toDouble();
  }

  double _execution(AtlasBenefitRealization item) {
    final progress =
        (100 + item.progressVariance).clamp(0.0, 100.0);
    final indicator =
        (100 + item.indicatorVariance).clamp(0.0, 100.0);

    return (progress * 0.55 + indicator * 0.45)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _risk(AtlasBenefitRealization item) {
    switch (item.status) {
      case AtlasBenefitRealizationStatus.onTrack:
        return 15;
      case AtlasBenefitRealizationStatus.attention:
        return 38;
      case AtlasBenefitRealizationStatus.offTrack:
        return 68;
      case AtlasBenefitRealizationStatus.critical:
        return 92;
    }
  }

  AtlasValueGovernanceDecisionType _decision(
    double score,
    AtlasBenefitRealizationStatus status,
  ) {
    if (status == AtlasBenefitRealizationStatus.critical ||
        score < 25) {
      return AtlasValueGovernanceDecisionType.terminate;
    }
    if (status == AtlasBenefitRealizationStatus.offTrack ||
        score < 45) {
      return AtlasValueGovernanceDecisionType.pause;
    }
    if (score < 65) {
      return AtlasValueGovernanceDecisionType.correct;
    }
    if (score < 82) {
      return AtlasValueGovernanceDecisionType.conditionalApproval;
    }
    return AtlasValueGovernanceDecisionType.approve;
  }

  List<String> _conditions(AtlasBenefitRealization item) {
    return <String>[
      if (item.budgetVariance > 0)
        'Não ampliar o orçamento sem justificar o desvio atual.',
      if (item.progressVariance < 0)
        'Recuperar o cronograma antes do próximo gate.',
      if (item.roiVariance < 0)
        'Revalidar premissas financeiras e retorno esperado.',
      'Confirmar os resultados na próxima revisão executiva.',
    ];
  }

  String _mainAction(
    AtlasValueGovernanceDecisionType decision,
  ) {
    switch (decision) {
      case AtlasValueGovernanceDecisionType.approve:
        return 'Autorizar continuidade conforme o plano.';
      case AtlasValueGovernanceDecisionType.conditionalApproval:
        return 'Registrar condições, prazo e responsáveis.';
      case AtlasValueGovernanceDecisionType.correct:
        return 'Abrir plano corretivo antes de avançar.';
      case AtlasValueGovernanceDecisionType.pause:
        return 'Bloquear novas despesas até nova revisão.';
      case AtlasValueGovernanceDecisionType.terminate:
        return 'Encerrar de forma controlada e registrar aprendizados.';
    }
  }

  int _reviewDays(
    AtlasValueGovernanceDecisionType decision,
  ) {
    switch (decision) {
      case AtlasValueGovernanceDecisionType.approve:
        return 30;
      case AtlasValueGovernanceDecisionType.conditionalApproval:
        return 15;
      case AtlasValueGovernanceDecisionType.correct:
        return 10;
      case AtlasValueGovernanceDecisionType.pause:
        return 7;
      case AtlasValueGovernanceDecisionType.terminate:
        return 3;
    }
  }
}
