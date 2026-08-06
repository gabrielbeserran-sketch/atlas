import 'package:projeto_atlas/features/benefits_realization/domain/models/atlas_benefit_realization.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';
import 'package:projeto_atlas/features/value_governance/domain/models/atlas_value_governance.dart';

class AtlasPortfolioItem {
  const AtlasPortfolioItem({
    required this.plan,
    required this.realization,
    required this.governance,
    required this.priorityScore,
    required this.healthScore,
    required this.valueAtRisk,
    required this.resourceLoad,
    required this.recommendation,
  });

  final AtlasStrategyExecutionPlan plan;
  final AtlasBenefitRealization? realization;
  final AtlasValueGovernanceDecision? governance;
  final double priorityScore;
  final double healthScore;
  final double valueAtRisk;
  final double resourceLoad;
  final String recommendation;

  bool get isCritical {
    return healthScore < 45 ||
        governance?.decision ==
            AtlasValueGovernanceDecisionType.pause ||
        governance?.decision ==
            AtlasValueGovernanceDecisionType.terminate;
  }

  bool get isCompleted {
    return plan.status ==
        AtlasStrategyExecutionStatus.completed;
  }
}

class AtlasPortfolioSummary {
  const AtlasPortfolioSummary({
    required this.items,
    required this.generatedAt,
  });

  final List<AtlasPortfolioItem> items;
  final DateTime generatedAt;

  int get totalStrategies => items.length;

  int get activeStrategies {
    return items
        .where(
          (item) =>
              item.plan.status ==
                  AtlasStrategyExecutionStatus.active ||
              item.plan.status ==
                  AtlasStrategyExecutionStatus.planned,
        )
        .length;
  }

  int get criticalStrategies {
    return items.where((item) => item.isCritical).length;
  }

  double get committedInvestment {
    return items.fold<double>(
      0,
      (sum, item) => sum + item.plan.budget,
    );
  }

  double get expectedValue {
    return items.fold<double>(
      0,
      (sum, item) => sum + item.plan.expectedNetGain,
    );
  }

  double get realizedValue {
    return items.fold<double>(
      0,
      (sum, item) =>
          sum + (item.realization?.actualNetGain ?? 0),
    );
  }

  double get totalValueAtRisk {
    return items.fold<double>(
      0,
      (sum, item) => sum + item.valueAtRisk,
    );
  }

  double get averageHealth {
    if (items.isEmpty) {
      return 0;
    }

    return items.fold<double>(
          0,
          (sum, item) => sum + item.healthScore,
        ) /
        items.length;
  }

  double get averageProgress {
    if (items.isEmpty) {
      return 0;
    }

    return items.fold<double>(
          0,
          (sum, item) => sum + item.plan.progressPercent,
        ) /
        items.length;
  }

  double get resourceLoad {
    return items.fold<double>(
      0,
      (sum, item) => sum + item.resourceLoad,
    );
  }
}
