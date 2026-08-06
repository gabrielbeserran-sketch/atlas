import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/strategic_alignment/domain/models/atlas_strategic_alignment.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';

class AtlasStrategicAlignmentEngine {
  const AtlasStrategicAlignmentEngine();

  AtlasStrategicAlignmentAssessment assess({
    required List<AtlasStrategyExecutionPlan> plans,
  }) {
    final objectives = _defaultObjectives(plans);

    final items = plans.map((plan) {
      final objective = _bestObjective(
        plan: plan,
        objectives: objectives,
      );

      final alignmentScore = objective == null
          ? 0.0
          : _alignmentScore(
              plan: plan,
              objective: objective,
            );

      final contributionScore = objective == null
          ? 0.0
          : _contributionScore(
              plan: plan,
              objective: objective,
            );

      final executionConfidence = (
        plan.confidence * 0.55 +
        plan.progressPercent * 0.30 +
        _statusScore(plan.status) * 0.15
      ).clamp(0.0, 100.0).toDouble();

      final status = _status(alignmentScore);

      return AtlasStrategyAlignmentItem(
        plan: plan,
        objective: objective,
        alignmentScore: alignmentScore,
        contributionScore: contributionScore,
        executionConfidence: executionConfidence,
        status: status,
        recommendation: _recommendation(
          status: status,
          plan: plan,
          objective: objective,
        ),
      );
    }).toList()
      ..sort(
        (first, second) =>
            second.alignmentScore.compareTo(
          first.alignmentScore,
        ),
      );

    return AtlasStrategicAlignmentAssessment(
      generatedAt: DateTime.now(),
      objectives: objectives,
      items: items,
    );
  }

  List<AtlasStrategicObjective> _defaultObjectives(
    List<AtlasStrategyExecutionPlan> plans,
  ) {
    final expectedGain = plans.fold<double>(
      0,
      (sum, item) => sum + item.expectedNetGain,
    );

    final averageProgress = plans.isEmpty
        ? 0.0
        : plans.fold<double>(
              0,
              (sum, item) => sum + item.progressPercent,
            ) /
            plans.length;

    final reproductionPlans = plans
        .where(
          (item) =>
              item.area ==
              AtlasFarmAuditArea.reproduction,
        )
        .length;

    final sanitaryPlans = plans
        .where(
          (item) =>
              item.area ==
                  AtlasFarmAuditArea.sanitary ||
              item.area ==
                  AtlasFarmAuditArea.biosecurity,
        )
        .length;

    return <AtlasStrategicObjective>[
      AtlasStrategicObjective(
        id: 'objective_profitability',
        title: 'Elevar rentabilidade da propriedade',
        description:
            'Aumentar geração de valor econômico com disciplina de capital.',
        horizon: AtlasStrategicHorizon.mediumTerm,
        weightPercent: 35,
        keyResults: <AtlasKeyResult>[
          AtlasKeyResult(
            id: 'kr_expected_value',
            title: 'Valor econômico projetado',
            currentValue: expectedGain,
            targetValue:
                expectedGain <= 0 ? 100000 : expectedGain * 1.20,
            unit: 'R\$',
          ),
          AtlasKeyResult(
            id: 'kr_portfolio_progress',
            title: 'Progresso médio das estratégias',
            currentValue: averageProgress,
            targetValue: 85,
            unit: '%',
          ),
        ],
      ),
      AtlasStrategicObjective(
        id: 'objective_productivity',
        title: 'Aumentar produtividade e eficiência',
        description:
            'Melhorar desempenho operacional, nutricional e de pastagens.',
        horizon: AtlasStrategicHorizon.mediumTerm,
        weightPercent: 25,
        keyResults: <AtlasKeyResult>[
          AtlasKeyResult(
            id: 'kr_operational_execution',
            title: 'Execução das iniciativas produtivas',
            currentValue: plans
                .where(
                  (item) =>
                      item.area ==
                          AtlasFarmAuditArea.operational ||
                      item.area ==
                          AtlasFarmAuditArea.nutrition ||
                      item.area ==
                          AtlasFarmAuditArea.pastures,
                )
                .fold<double>(
                  0,
                  (sum, item) =>
                      sum + item.progressPercent,
                ),
            targetValue: 240,
            unit: 'pontos',
          ),
        ],
      ),
      AtlasStrategicObjective(
        id: 'objective_reproduction',
        title: 'Fortalecer desempenho reprodutivo',
        description:
            'Elevar eficiência reprodutiva, genética e regularidade dos resultados.',
        horizon: AtlasStrategicHorizon.longTerm,
        weightPercent: 20,
        keyResults: <AtlasKeyResult>[
          AtlasKeyResult(
            id: 'kr_reproduction_plans',
            title: 'Estratégias reprodutivas ativas',
            currentValue:
                reproductionPlans.toDouble(),
            targetValue:
                reproductionPlans <= 0 ? 1 : reproductionPlans.toDouble(),
            unit: 'estratégias',
          ),
        ],
      ),
      AtlasStrategicObjective(
        id: 'objective_resilience',
        title: 'Aumentar resiliência e controle de riscos',
        description:
            'Reduzir vulnerabilidades sanitárias, operacionais e financeiras.',
        horizon: AtlasStrategicHorizon.shortTerm,
        weightPercent: 20,
        keyResults: <AtlasKeyResult>[
          AtlasKeyResult(
            id: 'kr_risk_plans',
            title: 'Iniciativas de proteção e risco',
            currentValue: sanitaryPlans.toDouble(),
            targetValue:
                sanitaryPlans <= 0 ? 1 : sanitaryPlans.toDouble(),
            unit: 'estratégias',
          ),
        ],
      ),
    ];
  }

  AtlasStrategicObjective? _bestObjective({
    required AtlasStrategyExecutionPlan plan,
    required List<AtlasStrategicObjective> objectives,
  }) {
    final preferredId = _objectiveForArea(plan.area);

    for (final objective in objectives) {
      if (objective.id == preferredId) {
        return objective;
      }
    }

    return objectives.isEmpty ? null : objectives.first;
  }

  String _objectiveForArea(
    AtlasFarmAuditArea area,
  ) {
    switch (area) {
      case AtlasFarmAuditArea.financial:
      case AtlasFarmAuditArea.inventory:
        return 'objective_profitability';
      case AtlasFarmAuditArea.nutrition:
      case AtlasFarmAuditArea.pastures:
      case AtlasFarmAuditArea.operational:
      case AtlasFarmAuditArea.people:
      case AtlasFarmAuditArea.animalWelfare:
        return 'objective_productivity';
      case AtlasFarmAuditArea.reproduction:
      case AtlasFarmAuditArea.genetics:
        return 'objective_reproduction';
      case AtlasFarmAuditArea.sanitary:
      case AtlasFarmAuditArea.biosecurity:
      case AtlasFarmAuditArea.sustainability:
        return 'objective_resilience';
    }
  }

  double _alignmentScore({
    required AtlasStrategyExecutionPlan plan,
    required AtlasStrategicObjective objective,
  }) {
    final areaFit =
        _objectiveForArea(plan.area) == objective.id
            ? 100.0
            : 35.0;

    final valueFit = (
      plan.expectedRoi * 0.55 +
      plan.confidence * 0.45
    ).clamp(0.0, 100.0).toDouble();

    return (
      areaFit * 0.55 +
      valueFit * 0.30 +
      _statusScore(plan.status) * 0.15
    ).clamp(0.0, 100.0).toDouble();
  }

  double _contributionScore({
    required AtlasStrategyExecutionPlan plan,
    required AtlasStrategicObjective objective,
  }) {
    final economicContribution = (
      plan.expectedNetGain / 10000
    ).clamp(0.0, 100.0).toDouble();

    final deliveryContribution = (
      plan.progressPercent * 0.60 +
      plan.confidence * 0.40
    ).clamp(0.0, 100.0).toDouble();

    return (
      economicContribution * 0.45 +
      deliveryContribution * 0.55
    ).clamp(0.0, 100.0).toDouble();
  }

  double _statusScore(
    AtlasStrategyExecutionStatus status,
  ) {
    switch (status) {
      case AtlasStrategyExecutionStatus.planned:
        return 55;
      case AtlasStrategyExecutionStatus.active:
        return 80;
      case AtlasStrategyExecutionStatus.paused:
        return 30;
      case AtlasStrategyExecutionStatus.completed:
        return 100;
      case AtlasStrategyExecutionStatus.cancelled:
        return 5;
    }
  }

  AtlasAlignmentStatus _status(
    double score,
  ) {
    if (score >= 82) {
      return AtlasAlignmentStatus.strong;
    }

    if (score >= 65) {
      return AtlasAlignmentStatus.acceptable;
    }

    if (score >= 40) {
      return AtlasAlignmentStatus.weak;
    }

    return AtlasAlignmentStatus.unaligned;
  }

  String _recommendation({
    required AtlasAlignmentStatus status,
    required AtlasStrategyExecutionPlan plan,
    required AtlasStrategicObjective? objective,
  }) {
    switch (status) {
      case AtlasAlignmentStatus.strong:
        return 'Manter prioridade e vincular os resultados ao objetivo "${objective?.title ?? ''}".';
      case AtlasAlignmentStatus.acceptable:
        return 'Reforçar indicadores de contribuição e confirmar a meta executiva.';
      case AtlasAlignmentStatus.weak:
        return 'Revisar escopo, benefícios e indicadores antes de ampliar recursos.';
      case AtlasAlignmentStatus.unaligned:
        return 'Pausar a expansão até definir claramente qual objetivo estratégico será atendido.';
    }
  }
}
