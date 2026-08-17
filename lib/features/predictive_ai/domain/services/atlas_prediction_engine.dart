import '../models/atlas_predictive_scenario.dart';

class AtlasPredictionEngine {
  const AtlasPredictionEngine();

  AtlasPredictionResult analyze(AtlasPredictiveScenario scenario) {
    final productivityFactor = 1 + scenario.productivityChange / 100;
    final capacityFactor = 1 + scenario.capacityChange / 100;
    final revenueFactor = 1 + scenario.revenueChange / 100;
    final costFactor = 1 + scenario.costChange / 100;

    final projectedRevenue =
        scenario.currentRevenue *
        productivityFactor *
        capacityFactor *
        revenueFactor;
    final projectedCost =
        scenario.currentCost * costFactor +
        scenario.investment /
            (scenario.horizonMonths <= 0 ? 1 : scenario.horizonMonths);
    final projectedProfit = projectedRevenue - projectedCost;
    final baseProfit = scenario.currentRevenue - scenario.currentCost;
    final incrementalProfit = projectedProfit - baseProfit;
    final roi = scenario.investment <= 0
        ? 0
        : (incrementalProfit * 12 / scenario.investment) * 100;
    final payback = incrementalProfit <= 0
        ? 999.0
        : scenario.investment / incrementalProfit;

    double risk = 18;
    if (scenario.investment > scenario.currentRevenue * .5) risk += 20;
    if (scenario.costChange > 12) risk += 15;
    if (scenario.capacityChange > 20) risk += 12;
    if (scenario.productivityChange > 20) risk += 10;
    if (projectedProfit < 0) risk += 30;
    risk = risk.clamp(5, 95).toDouble();

    final confidence =
        (92 -
                (scenario.productivityChange.abs() +
                        scenario.capacityChange.abs()) *
                    .7 -
                scenario.horizonMonths * .35)
            .clamp(45, 95)
            .toDouble();
    final riskLevel = risk >= 75
        ? AtlasRiskLevel.critical
        : risk >= 55
        ? AtlasRiskLevel.high
        : risk >= 30
        ? AtlasRiskLevel.moderate
        : AtlasRiskLevel.low;

    final recommendation = projectedProfit <= 0
        ? 'Não executar sem revisar as premissas: o cenário projeta resultado negativo.'
        : roi >= 25 && risk < 55
        ? 'Cenário atrativo. Recomenda-se avançar com implantação controlada e acompanhamento mensal.'
        : roi >= 10
        ? 'Cenário viável, porém deve ser executado em fases e com gatilhos de revisão.'
        : 'Retorno limitado. Compare alternativas antes de comprometer capital.';

    final drivers = <String>[
      'Produtividade: ${scenario.productivityChange.toStringAsFixed(1)}%',
      'Receita: ${scenario.revenueChange.toStringAsFixed(1)}%',
      'Custos: ${scenario.costChange.toStringAsFixed(1)}%',
      'Capacidade: ${scenario.capacityChange.toStringAsFixed(1)}%',
    ];

    return AtlasPredictionResult(
      scenario: scenario,
      projectedRevenue: projectedRevenue,
      projectedCost: projectedCost,
      projectedProfit: projectedProfit,
      roi: roi.toDouble(),
      paybackMonths: payback,
      confidence: confidence,
      riskLevel: riskLevel,
      riskProbability: risk,
      recommendation: recommendation,
      drivers: drivers,
    );
  }
}
