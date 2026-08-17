import 'dart:math' as math;

import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/models/atlas_optimization_request.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/models/atlas_optimization_result.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation_result.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/services/atlas_scenario_engine.dart';

class AtlasOptimizationEngine {
  const AtlasOptimizationEngine({
    this.scenarioEngine = const AtlasScenarioEngine(),
  });

  final AtlasScenarioEngine scenarioEngine;

  AtlasOptimizationResult optimize({
    required AtlasDigitalTwin currentTwin,
    required AtlasOptimizationRequest request,
  }) {
    final templates = _templatesFor(request);
    final evaluated = <AtlasOptimizationCandidate>[];

    for (var index = 0; index < templates.length; index++) {
      final template = templates[index];

      final simulation = AtlasSimulation(
        id: 'optimization_simulation_${DateTime.now().microsecondsSinceEpoch}_$index',
        name: template.name,
        description: template.description,
        farmId: request.farmId,
        farmName: request.farmName,
        createdAt: DateTime.now(),
        horizonMonths: request.horizonMonths,
        changes: template.changes,
      );

      final result = scenarioEngine.execute(
        currentTwin: currentTwin,
        simulation: simulation,
      );

      evaluated.add(
        _evaluateCandidate(
          request: request,
          result: result,
          name: template.name,
        ),
      );
    }

    evaluated.sort((first, second) {
      if (first.isEligible != second.isEligible) {
        return first.isEligible ? -1 : 1;
      }

      return second.optimizationScore.compareTo(first.optimizationScore);
    });

    final ranked = <AtlasOptimizationCandidate>[];

    for (var index = 0; index < evaluated.length; index++) {
      final item = evaluated[index];

      ranked.add(
        AtlasOptimizationCandidate(
          position: index + 1,
          name: item.name,
          result: item.result,
          optimizationScore: item.optimizationScore,
          objectiveScore: item.objectiveScore,
          financialScore: item.financialScore,
          riskScore: item.riskScore,
          balanceScore: item.balanceScore,
          isEligible: item.isEligible,
          constraintNotes: item.constraintNotes,
        ),
      );
    }

    final eligible = ranked.where((item) => item.isEligible);

    final best = eligible.isNotEmpty ? eligible.first : ranked.first;

    return AtlasOptimizationResult(
      id: 'optimization_result_${DateTime.now().microsecondsSinceEpoch}',
      request: request,
      generatedAt: DateTime.now(),
      candidates: ranked,
      bestCandidate: best,
      summary: _buildSummary(request: request, best: best),
      selectionReasons: _buildSelectionReasons(request: request, best: best),
    );
  }

  AtlasOptimizationCandidate _evaluateCandidate({
    required AtlasOptimizationRequest request,
    required AtlasSimulationResult result,
    required String name,
  }) {
    final notes = <String>[];
    final changes = result.simulation.changes;

    if (changes.initialInvestment > request.maxInvestment) {
      notes.add('Investimento superior ao limite definido.');
    }

    if (changes.herdSizeChange > request.maxHerdExpansion) {
      notes.add('Expansão do rebanho superior ao limite.');
    }

    final minimumProjectedScore = <double>[
      result.simulatedTwin.health.animal,
      result.simulatedTwin.health.sanitary,
      result.simulatedTwin.health.reproductive,
      result.simulatedTwin.health.financial,
      result.simulatedTwin.health.inventory,
      result.simulatedTwin.health.operational,
    ].reduce(math.min);

    if (minimumProjectedScore < request.minimumScore) {
      notes.add('Um dos indicadores ficou abaixo do mínimo.');
    }

    if (!_riskAccepted(result.riskLevel, request.maxRisk)) {
      notes.add('Risco acima da tolerância selecionada.');
    }

    final objectiveScore = _objectiveScore(request.objective, result);

    final financialScore = _financialScore(result);
    final riskScore = _riskScore(result.riskLevel);
    final balanceScore = _balanceScore(result);

    final optimizationScore =
        (objectiveScore * 0.48 +
                financialScore * 0.20 +
                riskScore * 0.18 +
                balanceScore * 0.14)
            .clamp(0.0, 100.0)
            .toDouble();

    return AtlasOptimizationCandidate(
      position: 0,
      name: name,
      result: result,
      optimizationScore: optimizationScore,
      objectiveScore: objectiveScore,
      financialScore: financialScore,
      riskScore: riskScore,
      balanceScore: balanceScore,
      isEligible: notes.isEmpty,
      constraintNotes: notes,
    );
  }

  double _objectiveScore(
    AtlasOptimizationObjective objective,
    AtlasSimulationResult result,
  ) {
    final health = result.simulatedTwin.health;

    switch (objective) {
      case AtlasOptimizationObjective.balancedGrowth:
        return (50 + result.scoreVariation * 5 + _balanceScore(result) * 0.35)
            .clamp(0.0, 100.0)
            .toDouble();

      case AtlasOptimizationObjective.maximizeProfit:
        final netComponent = result.projectedNetResult / 2500;
        final roiComponent = result.roiPercent.clamp(-50.0, 100.0) * 0.35;

        return (45 + netComponent + roiComponent).clamp(0.0, 100.0).toDouble();

      case AtlasOptimizationObjective.minimizeRisk:
        return (_riskScore(result.riskLevel) * 0.75 +
                result.simulatedTwin.overallScore * 0.25)
            .clamp(0.0, 100.0)
            .toDouble();

      case AtlasOptimizationObjective.improveReproduction:
        return (health.reproductive * 0.75 +
                result.simulatedTwin.overallScore * 0.25)
            .clamp(0.0, 100.0)
            .toDouble();

      case AtlasOptimizationObjective.improveSanitary:
        return (health.sanitary * 0.75 +
                result.simulatedTwin.overallScore * 0.25)
            .clamp(0.0, 100.0)
            .toDouble();

      case AtlasOptimizationObjective.improveOperations:
        return (health.operational * 0.55 +
                health.inventory * 0.20 +
                result.simulatedTwin.overallScore * 0.25)
            .clamp(0.0, 100.0)
            .toDouble();
    }
  }

  double _financialScore(AtlasSimulationResult result) {
    var score = 50.0;

    score += result.projectedNetResult / 4000;
    score += result.roiPercent.clamp(-50.0, 100.0) * 0.25;

    if (result.paybackMonths != null) {
      score += (24 - result.paybackMonths!).clamp(-20.0, 20.0);
    }

    return score.clamp(0.0, 100.0).toDouble();
  }

  double _riskScore(AtlasSimulationRiskLevel level) {
    switch (level) {
      case AtlasSimulationRiskLevel.low:
        return 100;
      case AtlasSimulationRiskLevel.moderate:
        return 72;
      case AtlasSimulationRiskLevel.high:
        return 38;
      case AtlasSimulationRiskLevel.critical:
        return 5;
    }
  }

  double _balanceScore(AtlasSimulationResult result) {
    final values = <double>[
      result.simulatedTwin.health.animal,
      result.simulatedTwin.health.sanitary,
      result.simulatedTwin.health.reproductive,
      result.simulatedTwin.health.financial,
      result.simulatedTwin.health.inventory,
      result.simulatedTwin.health.operational,
    ];

    final average = values.reduce((a, b) => a + b) / values.length;

    final variance =
        values
            .map((value) => math.pow(value - average, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;

    final deviation = math.sqrt(variance);

    return (average - deviation * 1.6).clamp(0.0, 100.0).toDouble();
  }

  bool _riskAccepted(
    AtlasSimulationRiskLevel level,
    AtlasOptimizationRiskTolerance tolerance,
  ) {
    switch (tolerance) {
      case AtlasOptimizationRiskTolerance.low:
        return level == AtlasSimulationRiskLevel.low;
      case AtlasOptimizationRiskTolerance.moderate:
        return level == AtlasSimulationRiskLevel.low ||
            level == AtlasSimulationRiskLevel.moderate;
      case AtlasOptimizationRiskTolerance.high:
        return level != AtlasSimulationRiskLevel.critical;
    }
  }

  List<_OptimizationTemplate> _templatesFor(AtlasOptimizationRequest request) {
    final maxInvestment = request.maxInvestment;
    final smallInvestment = maxInvestment * 0.25;
    final mediumInvestment = maxInvestment * 0.55;
    final largeInvestment = maxInvestment * 0.90;

    final herdSmall = (request.maxHerdExpansion * 0.25).round();
    final herdMedium = (request.maxHerdExpansion * 0.55).round();
    final herdLarge = (request.maxHerdExpansion * 0.90).round();

    final base = <_OptimizationTemplate>[
      _OptimizationTemplate(
        name: 'Eficiência com baixo investimento',
        description:
            'Prioriza ganhos operacionais com menor necessidade de capital.',
        changes: AtlasSimulationChanges(
          animalScoreChange: 2,
          sanitaryScoreChange: 2,
          reproductiveScoreChange: 2,
          financialScoreChange: 4,
          inventoryScoreChange: 3,
          operationalScoreChange: 7,
          herdSizeChange: 0,
          initialInvestment: smallInvestment,
          expectedMonthlyRevenueChange: smallInvestment * 0.12,
          expectedMonthlyCostChange: smallInvestment * 0.035,
        ),
      ),
      _OptimizationTemplate(
        name: 'Expansão moderada do rebanho',
        description: 'Amplia a produção preservando equilíbrio operacional.',
        changes: AtlasSimulationChanges(
          animalScoreChange: 4,
          sanitaryScoreChange: 2,
          reproductiveScoreChange: 4,
          financialScoreChange: 3,
          inventoryScoreChange: 3,
          operationalScoreChange: 2,
          herdSizeChange: herdMedium,
          initialInvestment: mediumInvestment,
          expectedMonthlyRevenueChange: mediumInvestment * 0.15,
          expectedMonthlyCostChange: mediumInvestment * 0.07,
        ),
      ),
      _OptimizationTemplate(
        name: 'Intensificação produtiva',
        description: 'Busca crescimento mais forte de produção e resultado.',
        changes: AtlasSimulationChanges(
          animalScoreChange: 8,
          sanitaryScoreChange: 1,
          reproductiveScoreChange: 5,
          financialScoreChange: 6,
          inventoryScoreChange: 1,
          operationalScoreChange: -1,
          herdSizeChange: herdLarge,
          initialInvestment: largeInvestment,
          expectedMonthlyRevenueChange: largeInvestment * 0.21,
          expectedMonthlyCostChange: largeInvestment * 0.11,
        ),
      ),
      _OptimizationTemplate(
        name: 'Blindagem sanitária',
        description:
            'Reduz exposição a perdas sanitárias e fortalece prevenção.',
        changes: AtlasSimulationChanges(
          animalScoreChange: 2,
          sanitaryScoreChange: 12,
          reproductiveScoreChange: 3,
          financialScoreChange: 1,
          inventoryScoreChange: 4,
          operationalScoreChange: 4,
          herdSizeChange: 0,
          initialInvestment: mediumInvestment * 0.75,
          expectedMonthlyRevenueChange: mediumInvestment * 0.08,
          expectedMonthlyCostChange: mediumInvestment * 0.035,
        ),
      ),
      _OptimizationTemplate(
        name: 'Aceleração reprodutiva',
        description:
            'Concentra recursos em reprodução, prenhez e planejamento do rebanho.',
        changes: AtlasSimulationChanges(
          animalScoreChange: 3,
          sanitaryScoreChange: 3,
          reproductiveScoreChange: 13,
          financialScoreChange: 3,
          inventoryScoreChange: 2,
          operationalScoreChange: 4,
          herdSizeChange: herdSmall,
          initialInvestment: mediumInvestment,
          expectedMonthlyRevenueChange: mediumInvestment * 0.14,
          expectedMonthlyCostChange: mediumInvestment * 0.055,
        ),
      ),
      _OptimizationTemplate(
        name: 'Redução de custos',
        description: 'Melhora margem por controle de despesas e eficiência.',
        changes: AtlasSimulationChanges(
          animalScoreChange: 0,
          sanitaryScoreChange: 1,
          reproductiveScoreChange: 0,
          financialScoreChange: 8,
          inventoryScoreChange: 5,
          operationalScoreChange: 6,
          herdSizeChange: 0,
          initialInvestment: smallInvestment * 0.55,
          expectedMonthlyRevenueChange: smallInvestment * 0.025,
          expectedMonthlyCostChange: -smallInvestment * 0.07,
        ),
      ),
      _OptimizationTemplate(
        name: 'Equilíbrio integral',
        description:
            'Distribui os investimentos entre todas as áreas estratégicas.',
        changes: AtlasSimulationChanges(
          animalScoreChange: 5,
          sanitaryScoreChange: 5,
          reproductiveScoreChange: 5,
          financialScoreChange: 5,
          inventoryScoreChange: 5,
          operationalScoreChange: 5,
          herdSizeChange: herdSmall,
          initialInvestment: mediumInvestment,
          expectedMonthlyRevenueChange: mediumInvestment * 0.13,
          expectedMonthlyCostChange: mediumInvestment * 0.055,
        ),
      ),
      _OptimizationTemplate(
        name: 'Crescimento agressivo',
        description:
            'Busca expansão rápida com maior exposição financeira e operacional.',
        changes: AtlasSimulationChanges(
          animalScoreChange: 10,
          sanitaryScoreChange: -2,
          reproductiveScoreChange: 7,
          financialScoreChange: 7,
          inventoryScoreChange: -3,
          operationalScoreChange: -4,
          herdSizeChange: request.maxHerdExpansion,
          initialInvestment: maxInvestment,
          expectedMonthlyRevenueChange: maxInvestment * 0.25,
          expectedMonthlyCostChange: maxInvestment * 0.14,
        ),
      ),
    ];

    return base;
  }

  String _buildSummary({
    required AtlasOptimizationRequest request,
    required AtlasOptimizationCandidate best,
  }) {
    final eligibility = best.isEligible
        ? 'respeita todas as restrições definidas'
        : 'foi a melhor alternativa encontrada, mas ainda possui restrições pendentes';

    return 'O cenário “${best.name}” recebeu '
        '${best.optimizationScore.toStringAsFixed(1)} pontos de otimização e '
        '$eligibility. A recomendação foi gerada para o objetivo '
        '“${atlasOptimizationObjectiveLabel(request.objective)}”.';
  }

  List<String> _buildSelectionReasons({
    required AtlasOptimizationRequest request,
    required AtlasOptimizationCandidate best,
  }) {
    final result = best.result;
    final reasons = <String>[
      'Score de otimização: '
          '${best.optimizationScore.toStringAsFixed(1)} de 100.',
      'Variação do Atlas Farm Index: '
          '${result.scoreVariation >= 0 ? '+' : ''}'
          '${result.scoreVariation.toStringAsFixed(1)} pontos.',
      'Resultado líquido projetado: '
          '${_formatCurrency(result.projectedNetResult)}.',
      'Risco classificado como '
          '${atlasSimulationRiskLevelLabel(result.riskLevel)}.',
    ];

    if (result.paybackMonths != null) {
      reasons.add(
        'Payback estimado em '
        '${result.paybackMonths!.toStringAsFixed(1)} meses.',
      );
    }

    if (!best.isEligible) {
      reasons.addAll(best.constraintNotes);
    }

    return reasons;
  }

  String _formatCurrency(double value) {
    final sign = value < 0 ? '-' : '';
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final integer = parts.first;
    final decimal = parts.last;
    final buffer = StringBuffer();

    for (var index = 0; index < integer.length; index++) {
      final remaining = integer.length - index;
      buffer.write(integer[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${sign}R\$ ${buffer.toString()},$decimal';
  }
}

class _OptimizationTemplate {
  const _OptimizationTemplate({
    required this.name,
    required this.description,
    required this.changes,
  });

  final String name;
  final String description;
  final AtlasSimulationChanges changes;
}
