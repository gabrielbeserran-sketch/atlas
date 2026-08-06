import 'package:projeto_atlas/features/benefits_realization/domain/models/atlas_benefit_realization.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';
import 'package:projeto_atlas/features/value_governance/domain/models/atlas_value_governance.dart';
import 'package:projeto_atlas/features/portfolio_management/domain/models/atlas_portfolio_item.dart';

class AtlasPortfolioManagementEngine {
  const AtlasPortfolioManagementEngine();

  AtlasPortfolioSummary build({
    required List<AtlasStrategyExecutionPlan> plans,
    required List<AtlasBenefitRealization> realizations,
    required List<AtlasValueGovernanceDecision> decisions,
  }) {
    final realizationByPlan = <String, AtlasBenefitRealization>{
      for (final item in realizations)
        item.strategyPlanId: item,
    };

    final decisionByPlan = <String, AtlasValueGovernanceDecision>{
      for (final item in decisions)
        item.strategyPlanId: item,
    };

    final items = plans.map((plan) {
      final realization = realizationByPlan[plan.id];
      final governance = decisionByPlan[plan.id];

      final financialScore = realization == null
          ? 55.0
          : (50 +
                  realization.roiVariance +
                  realization.benefitAchievement * 0.35 -
                  realization.budgetVariance.abs() /
                      (plan.budget <= 0 ? 1 : plan.budget) *
                      100)
              .clamp(0.0, 100.0)
              .toDouble();

      final executionScore = (
        plan.progressPercent * 0.70 +
        _statusScore(plan.status) * 0.30
      ).clamp(0.0, 100.0).toDouble();

      final governanceScore =
          governance?.valueScore ?? 55.0;

      final healthScore = (
        financialScore * 0.40 +
        executionScore * 0.35 +
        governanceScore * 0.25
      ).clamp(0.0, 100.0).toDouble();

      final urgency = _urgency(plan, realization, governance);
      final impact = _impact(plan);
      final priorityScore = (
        impact * 0.45 +
        urgency * 0.35 +
        (100 - healthScore) * 0.20
      ).clamp(0.0, 100.0).toDouble();

      final valueAtRisk = (
        plan.expectedNetGain *
        (100 - healthScore) /
        100
      ).clamp(0.0, double.infinity).toDouble();

      final resourceLoad = (
        plan.totalMilestones * 4 +
        plan.gates.length * 6 +
        (100 - plan.progressPercent) * 0.35
      ).clamp(0.0, 100.0).toDouble();

      return AtlasPortfolioItem(
        plan: plan,
        realization: realization,
        governance: governance,
        priorityScore: priorityScore,
        healthScore: healthScore,
        valueAtRisk: valueAtRisk,
        resourceLoad: resourceLoad,
        recommendation: _recommendation(
          healthScore: healthScore,
          resourceLoad: resourceLoad,
          governance: governance,
          realization: realization,
        ),
      );
    }).toList()
      ..sort(
        (first, second) =>
            second.priorityScore.compareTo(first.priorityScore),
      );

    return AtlasPortfolioSummary(
      items: items,
      generatedAt: DateTime.now(),
    );
  }

  double _statusScore(
    AtlasStrategyExecutionStatus status,
  ) {
    switch (status) {
      case AtlasStrategyExecutionStatus.planned:
        return 55;
      case AtlasStrategyExecutionStatus.active:
        return 75;
      case AtlasStrategyExecutionStatus.paused:
        return 30;
      case AtlasStrategyExecutionStatus.completed:
        return 100;
      case AtlasStrategyExecutionStatus.cancelled:
        return 10;
    }
  }

  double _urgency(
    AtlasStrategyExecutionPlan plan,
    AtlasBenefitRealization? realization,
    AtlasValueGovernanceDecision? governance,
  ) {
    var urgency = 35.0;

    if (plan.targetDate.isBefore(
      DateTime.now().add(const Duration(days: 30)),
    )) {
      urgency += 20;
    }

    if (realization?.status ==
        AtlasBenefitRealizationStatus.offTrack) {
      urgency += 25;
    }

    if (realization?.status ==
        AtlasBenefitRealizationStatus.critical) {
      urgency += 40;
    }

    if (governance?.decision ==
            AtlasValueGovernanceDecisionType.pause ||
        governance?.decision ==
            AtlasValueGovernanceDecisionType.terminate) {
      urgency += 30;
    }

    return urgency.clamp(0.0, 100.0).toDouble();
  }

  double _impact(AtlasStrategyExecutionPlan plan) {
    final normalized = (
      plan.expectedNetGain / 10000 +
      plan.expectedRoi * 0.45 +
      plan.confidence * 0.25
    );

    return normalized.clamp(0.0, 100.0).toDouble();
  }

  String _recommendation({
    required double healthScore,
    required double resourceLoad,
    required AtlasValueGovernanceDecision? governance,
    required AtlasBenefitRealization? realization,
  }) {
    if (governance?.decision ==
        AtlasValueGovernanceDecisionType.terminate) {
      return 'Encerrar de forma controlada e registrar lições aprendidas.';
    }

    if (governance?.decision ==
            AtlasValueGovernanceDecisionType.pause ||
        healthScore < 35) {
      return 'Pausar novas despesas e abrir revisão executiva imediata.';
    }

    if (resourceLoad > 85) {
      return 'Reduzir concorrência por recursos e replanejar capacidade.';
    }

    if (realization?.status ==
            AtlasBenefitRealizationStatus.offTrack ||
        healthScore < 60) {
      return 'Executar plano corretivo antes de ampliar o investimento.';
    }

    if (healthScore >= 82) {
      return 'Manter prioridade e considerar expansão controlada.';
    }

    return 'Manter execução com revisão quinzenal de valor e risco.';
  }
}
