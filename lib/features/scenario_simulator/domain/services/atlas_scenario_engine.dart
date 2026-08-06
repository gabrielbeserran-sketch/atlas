import 'dart:math' as math;

import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_score_service.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation_result.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/services/atlas_digital_twin_cloner.dart';

class AtlasScenarioEngine {
  const AtlasScenarioEngine({
    this.cloner = const AtlasDigitalTwinCloner(),
    this.scoreService = const AtlasDigitalTwinScoreService(),
  });

  final AtlasDigitalTwinCloner cloner;
  final AtlasDigitalTwinScoreService scoreService;

  AtlasSimulationResult execute({
    required AtlasDigitalTwin currentTwin,
    required AtlasSimulation simulation,
  }) {
    final clone = cloner.clone(currentTwin);
    final changes = simulation.changes;

    final simulatedHealth = AtlasFarmHealth(
      animal: scoreService.apply(
        clone.health.animal,
        changes.animalScoreChange,
      ),
      sanitary: scoreService.apply(
        clone.health.sanitary,
        changes.sanitaryScoreChange,
      ),
      reproductive: scoreService.apply(
        clone.health.reproductive,
        changes.reproductiveScoreChange,
      ),
      financial: scoreService.apply(
        clone.health.financial,
        changes.financialScoreChange,
      ),
      inventory: scoreService.apply(
        clone.health.inventory,
        changes.inventoryScoreChange,
      ),
      operational: scoreService.apply(
        clone.health.operational,
        changes.operationalScoreChange,
      ),
    );

    final simulatedScore =
        scoreService.calculateOverall(simulatedHealth);

    final scoreVariation =
        simulatedScore - currentTwin.overallScore;

    final projectedRevenueChange =
        changes.expectedMonthlyRevenueChange *
        simulation.horizonMonths;

    final projectedCostChange =
        changes.expectedMonthlyCostChange *
        simulation.horizonMonths +
        changes.initialInvestment;

    final projectedNetResult =
        projectedRevenueChange - projectedCostChange;

    final double roiPercent =
        changes.initialInvestment > 0
            ? projectedNetResult /
                changes.initialInvestment *
                100.0
            : projectedNetResult > 0
                ? 100.0
                : 0.0;

    final monthlyMargin =
        changes.expectedMonthlyRevenueChange -
        changes.expectedMonthlyCostChange;

    final paybackMonths =
        changes.initialInvestment > 0 &&
                monthlyMargin > 0
            ? changes.initialInvestment /
                monthlyMargin
            : null;

    final riskLevel = _calculateRisk(
      currentTwin: currentTwin,
      simulatedHealth: simulatedHealth,
      scoreVariation: scoreVariation,
      projectedNetResult: projectedNetResult,
      investment: changes.initialInvestment,
      herdSizeChange: changes.herdSizeChange,
    );

    final simulatedRisks = _buildSimulatedRisks(
      currentRisks: clone.risks,
      health: simulatedHealth,
      changes: changes,
    );

    final simulatedTwin = clone.copyWith(
      updatedAt: DateTime.now(),
      health: simulatedHealth,
      overallScore: simulatedScore,
      trend: scoreService.calculateTrend(
        previousScore: currentTwin.overallScore,
        currentScore: simulatedScore,
      ),
      risks: simulatedRisks,
    );

    final strengths = _buildStrengths(
      changes: changes,
      scoreVariation: scoreVariation,
      netResult: projectedNetResult,
      roiPercent: roiPercent,
    );

    final attentionPoints = _buildAttentionPoints(
      changes: changes,
      health: simulatedHealth,
      netResult: projectedNetResult,
      paybackMonths: paybackMonths,
      horizonMonths: simulation.horizonMonths,
    );

    return AtlasSimulationResult(
      id:
          'simulation_result_${DateTime.now().microsecondsSinceEpoch}',
      simulation: simulation,
      executedAt: DateTime.now(),
      currentTwin: currentTwin,
      simulatedTwin: simulatedTwin,
      scoreVariation: scoreVariation,
      projectedRevenueChange: projectedRevenueChange,
      projectedCostChange: projectedCostChange,
      projectedNetResult: projectedNetResult,
      roiPercent: roiPercent,
      paybackMonths: paybackMonths,
      riskLevel: riskLevel,
      recommendation: _buildRecommendation(
        scoreVariation: scoreVariation,
        projectedNetResult: projectedNetResult,
        riskLevel: riskLevel,
        paybackMonths: paybackMonths,
        horizonMonths: simulation.horizonMonths,
      ),
      strengths: strengths,
      attentionPoints: attentionPoints,
    );
  }

  AtlasSimulationRiskLevel _calculateRisk({
    required AtlasDigitalTwin currentTwin,
    required AtlasFarmHealth simulatedHealth,
    required double scoreVariation,
    required double projectedNetResult,
    required double investment,
    required int herdSizeChange,
  }) {
    var points = 0;

    if (scoreVariation < -5) {
      points += 45;
    } else if (scoreVariation < 0) {
      points += 25;
    }

    if (projectedNetResult < 0) {
      points += 35;
    }

    if (investment > 0 &&
        projectedNetResult < investment * 0.15) {
      points += 15;
    }

    if (herdSizeChange.abs() >= 100) {
      points += 15;
    } else if (herdSizeChange.abs() >= 40) {
      points += 8;
    }

    final minimumScore = <double>[
      simulatedHealth.animal,
      simulatedHealth.sanitary,
      simulatedHealth.reproductive,
      simulatedHealth.financial,
      simulatedHealth.inventory,
      simulatedHealth.operational,
    ].reduce(math.min);

    if (minimumScore < 35) {
      points += 35;
    } else if (minimumScore < 55) {
      points += 18;
    }

    if (currentTwin.risks.any(
      (risk) =>
          risk.level == AtlasFarmRiskLevel.critical,
    )) {
      points += 10;
    }

    if (points >= 75) {
      return AtlasSimulationRiskLevel.critical;
    }

    if (points >= 50) {
      return AtlasSimulationRiskLevel.high;
    }

    if (points >= 25) {
      return AtlasSimulationRiskLevel.moderate;
    }

    return AtlasSimulationRiskLevel.low;
  }

  List<AtlasFarmRisk> _buildSimulatedRisks({
    required List<AtlasFarmRisk> currentRisks,
    required AtlasFarmHealth health,
    required AtlasSimulationChanges changes,
  }) {
    final result =
        List<AtlasFarmRisk>.from(currentRisks);

    void upsert({
      required String id,
      required AtlasDigitalTwinArea area,
      required String title,
      required double score,
    }) {
      result.removeWhere((item) => item.id == id);

      if (score < 35) {
        return;
      }

      result.add(
        AtlasFarmRisk(
          id: id,
          area: area,
          title: title,
          description:
              'Risco projetado pelo simulador de cenários.',
          score: score.clamp(0.0, 100.0).toDouble(),
          level: _farmRiskLevel(score),
          updatedAt: DateTime.now(),
          sourceEventType: 'scenarioSimulation',
        ),
      );
    }

    upsert(
      id: 'scenario_animal_risk',
      area: AtlasDigitalTwinArea.animal,
      title: 'Risco de desempenho animal',
      score: 100 - health.animal,
    );

    upsert(
      id: 'scenario_sanitary_risk',
      area: AtlasDigitalTwinArea.sanitary,
      title: 'Risco sanitário projetado',
      score: 100 - health.sanitary,
    );

    upsert(
      id: 'scenario_reproductive_risk',
      area: AtlasDigitalTwinArea.reproductive,
      title: 'Risco reprodutivo projetado',
      score: 100 - health.reproductive,
    );

    upsert(
      id: 'scenario_financial_risk',
      area: AtlasDigitalTwinArea.financial,
      title: 'Risco financeiro projetado',
      score: 100 - health.financial,
    );

    if (changes.herdSizeChange > 50) {
      upsert(
        id: 'scenario_herd_expansion_risk',
        area: AtlasDigitalTwinArea.operational,
        title: 'Expansão acelerada do rebanho',
        score:
            (45 + changes.herdSizeChange / 4)
                .clamp(0, 100)
                .toDouble(),
      );
    }

    result.sort(
      (first, second) =>
          second.score.compareTo(first.score),
    );

    return result.take(25).toList();
  }

  AtlasFarmRiskLevel _farmRiskLevel(
    double score,
  ) {
    if (score >= 80) {
      return AtlasFarmRiskLevel.critical;
    }

    if (score >= 60) {
      return AtlasFarmRiskLevel.high;
    }

    if (score >= 35) {
      return AtlasFarmRiskLevel.moderate;
    }

    return AtlasFarmRiskLevel.low;
  }

  List<String> _buildStrengths({
    required AtlasSimulationChanges changes,
    required double scoreVariation,
    required double netResult,
    required double roiPercent,
  }) {
    final items = <String>[];

    if (scoreVariation >= 3) {
      items.add(
        'Elevação relevante do Atlas Farm Index.',
      );
    } else if (scoreVariation > 0) {
      items.add(
        'Melhora gradual do índice geral da fazenda.',
      );
    }

    if (netResult > 0) {
      items.add(
        'Resultado financeiro projetado positivo.',
      );
    }

    if (roiPercent >= 20) {
      items.add(
        'Retorno projetado atrativo sobre o investimento.',
      );
    }

    if (changes.sanitaryScoreChange > 0) {
      items.add(
        'Fortalecimento da segurança sanitária.',
      );
    }

    if (changes.reproductiveScoreChange > 0) {
      items.add(
        'Melhora esperada no desempenho reprodutivo.',
      );
    }

    if (changes.operationalScoreChange > 0) {
      items.add(
        'Ganho de eficiência operacional.',
      );
    }

    if (items.isEmpty) {
      items.add(
        'Cenário preserva a estabilidade da operação.',
      );
    }

    return items;
  }

  List<String> _buildAttentionPoints({
    required AtlasSimulationChanges changes,
    required AtlasFarmHealth health,
    required double netResult,
    required double? paybackMonths,
    required int horizonMonths,
  }) {
    final items = <String>[];

    if (netResult < 0) {
      items.add(
        'O resultado líquido projetado é negativo.',
      );
    }

    if (paybackMonths != null &&
        paybackMonths > horizonMonths) {
      items.add(
        'O retorno do investimento ultrapassa o horizonte analisado.',
      );
    }

    if (changes.herdSizeChange > 0 &&
        changes.inventoryScoreChange <= 0) {
      items.add(
        'A expansão do rebanho não foi acompanhada por reforço de estoque.',
      );
    }

    if (changes.herdSizeChange > 0 &&
        changes.operationalScoreChange <= 0) {
      items.add(
        'A expansão do rebanho pode pressionar a capacidade operacional.',
      );
    }

    if (health.sanitary < 55) {
      items.add(
        'O score sanitário projetado permanece em faixa de atenção.',
      );
    }

    if (health.financial < 55) {
      items.add(
        'O score financeiro projetado permanece em faixa de atenção.',
      );
    }

    if (items.isEmpty) {
      items.add(
        'Nenhum ponto crítico adicional foi identificado.',
      );
    }

    return items;
  }

  String _buildRecommendation({
    required double scoreVariation,
    required double projectedNetResult,
    required AtlasSimulationRiskLevel riskLevel,
    required double? paybackMonths,
    required int horizonMonths,
  }) {
    if (riskLevel == AtlasSimulationRiskLevel.critical) {
      return 'Não executar neste formato. O cenário apresenta risco crítico e deve ser redesenhado antes de qualquer aplicação real.';
    }

    if (riskLevel == AtlasSimulationRiskLevel.high) {
      return 'Executar apenas após reduzir os principais riscos e validar a capacidade financeira e operacional da fazenda.';
    }

    if (scoreVariation > 0 &&
        projectedNetResult > 0 &&
        (paybackMonths == null ||
            paybackMonths <= horizonMonths)) {
      return 'Cenário favorável. Recomenda-se avançar para um plano piloto, definir metas e acompanhar os indicadores antes da expansão completa.';
    }

    if (scoreVariation > 0 &&
        projectedNetResult <= 0) {
      return 'O cenário melhora o desempenho estratégico, mas precisa de ajuste financeiro para evitar destruição de valor.';
    }

    if (scoreVariation <= 0 &&
        projectedNetResult > 0) {
      return 'O cenário gera retorno financeiro, porém reduz o equilíbrio operacional. Avalie medidas compensatórias antes da execução.';
    }

    return 'Cenário neutro ou pouco atrativo. Revise as premissas e compare com alternativas antes de decidir.';
  }
}
