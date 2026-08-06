import 'dart:math' as math;

import 'package:projeto_atlas/features/strategic_scenario_planning/domain/models/atlas_scenario_analysis.dart';
import 'package:projeto_atlas/features/strategic_scenario_planning/domain/models/atlas_strategic_scenario.dart';

class AtlasStrategicScenarioEngine {
  const AtlasStrategicScenarioEngine();

  AtlasScenarioPortfolioAnalysis analyzeAll(
    List<AtlasStrategicScenario> scenarios,
  ) {
    final items = scenarios
        .map(analyze)
        .toList()
      ..sort(
        (first, second) =>
            second.netPresentValue.compareTo(
          first.netPresentValue,
        ),
      );

    return AtlasScenarioPortfolioAnalysis(
      generatedAt: DateTime.now(),
      items: items,
    );
  }

  AtlasScenarioAnalysis analyze(
    AtlasStrategicScenario scenario,
  ) {
    final baseCashFlows = _cashFlows(
      scenario: scenario,
      revenueFactor: 1,
      costFactor: 1,
    );

    final optimisticCashFlows = _cashFlows(
      scenario: scenario,
      revenueFactor:
          1 + scenario.priceSensitivityPercent / 100,
      costFactor:
          1 - scenario.costSensitivityPercent / 200,
    );

    final pessimisticCashFlows = _cashFlows(
      scenario: scenario,
      revenueFactor:
          1 - scenario.priceSensitivityPercent / 100,
      costFactor:
          1 + scenario.costSensitivityPercent / 100,
    );

    final npv = _npv(
      baseCashFlows,
      scenario.discountRatePercent / 100,
    );

    final irr = _irr(baseCashFlows);
    final totalInvestment =
        scenario.initialInvestment +
        scenario.workingCapital;
    final totalNetGain =
        baseCashFlows.fold<double>(0, (sum, item) => sum + item);
    final roi = totalInvestment <= 0
        ? 0.0
        : totalNetGain / totalInvestment * 100;
    final payback = _payback(baseCashFlows);
    final risk = scenario.risks.average.clamp(0.0, 100.0);
    final resilience = _resilience(
      scenario: scenario,
      risk: risk,
      baseNpv: npv,
      pessimisticNpv: _npv(
        pessimisticCashFlows,
        scenario.discountRatePercent / 100,
      ),
    );

    final classification = _classification(
      npv: npv,
      roi: roi,
      risk: risk,
      payback: payback,
      horizonYears: scenario.horizonYears,
    );

    return AtlasScenarioAnalysis(
      scenario: scenario,
      cashFlows: baseCashFlows,
      netPresentValue: npv,
      internalRateOfReturn: irr * 100,
      roiPercent: roi,
      paybackYears: payback,
      totalNetGain: totalNetGain,
      riskScore: risk,
      resilienceScore: resilience,
      recommendation: _recommendation(
        classification: classification,
        risk: risk,
        npv: npv,
        pessimisticNpv: _npv(
          pessimisticCashFlows,
          scenario.discountRatePercent / 100,
        ),
      ),
      classification: classification,
      optimisticNetPresentValue: _npv(
        optimisticCashFlows,
        scenario.discountRatePercent / 100,
      ),
      pessimisticNetPresentValue: _npv(
        pessimisticCashFlows,
        scenario.discountRatePercent / 100,
      ),
    );
  }

  List<double> _cashFlows({
    required AtlasStrategicScenario scenario,
    required double revenueFactor,
    required double costFactor,
  }) {
    final flows = <double>[
      -(scenario.initialInvestment + scenario.workingCapital),
    ];

    for (var year = 1;
        year <= scenario.horizonYears;
        year++) {
      final maturityFactor =
          math.min(1.0, 0.55 + year * 0.15);
      var flow =
          scenario.annualAdditionalRevenue *
              revenueFactor *
              maturityFactor -
          scenario.annualAdditionalCost *
              costFactor;

      if (year == scenario.horizonYears) {
        flow += scenario.residualValue +
            scenario.workingCapital;
      }

      flows.add(flow);
    }

    return flows;
  }

  double _npv(
    List<double> cashFlows,
    double rate,
  ) {
    var result = 0.0;

    for (var year = 0;
        year < cashFlows.length;
        year++) {
      result += cashFlows[year] /
          math.pow(1 + rate, year);
    }

    return result;
  }

  double _irr(List<double> cashFlows) {
    var low = -0.95;
    var high = 5.0;

    final lowNpv = _npv(cashFlows, low);
    final highNpv = _npv(cashFlows, high);

    if (lowNpv.sign == highNpv.sign) {
      return 0;
    }

    for (var index = 0; index < 120; index++) {
      final middle = (low + high) / 2;
      final middleNpv = _npv(cashFlows, middle);

      if (middleNpv.abs() < 0.01) {
        return middle;
      }

      if (middleNpv.sign == lowNpv.sign) {
        low = middle;
      } else {
        high = middle;
      }
    }

    return (low + high) / 2;
  }

  double _payback(List<double> cashFlows) {
    var accumulated = cashFlows.first;

    if (accumulated >= 0) {
      return 0;
    }

    for (var year = 1;
        year < cashFlows.length;
        year++) {
      final previous = accumulated;
      accumulated += cashFlows[year];

      if (accumulated >= 0) {
        final annualFlow = cashFlows[year];

        if (annualFlow <= 0) {
          return year.toDouble();
        }

        return (year - 1) +
            (-previous / annualFlow);
      }
    }

    return double.infinity;
  }

  double _resilience({
    required AtlasStrategicScenario scenario,
    required double risk,
    required double baseNpv,
    required double pessimisticNpv,
  }) {
    final downsideProtection = baseNpv == 0
        ? 0.0
        : (
            100 -
            ((baseNpv - pessimisticNpv).abs() /
                    baseNpv.abs() *
                100)
          ).clamp(0.0, 100.0);

    return (
      (100 - risk) * 0.60 +
      downsideProtection * 0.40
    ).clamp(0.0, 100.0).toDouble();
  }

  AtlasScenarioClassification _classification({
    required double npv,
    required double roi,
    required double risk,
    required double payback,
    required int horizonYears,
  }) {
    if (npv > 0 &&
        roi >= 25 &&
        risk <= 55 &&
        payback <= horizonYears) {
      return AtlasScenarioClassification.recommended;
    }

    if (npv > 0 &&
        roi >= 12 &&
        risk <= 75) {
      return AtlasScenarioClassification.recommendedInPhases;
    }

    if (npv > 0 || roi > 0) {
      return AtlasScenarioClassification.review;
    }

    return AtlasScenarioClassification.notRecommended;
  }

  String _recommendation({
    required AtlasScenarioClassification classification,
    required double risk,
    required double npv,
    required double pessimisticNpv,
  }) {
    switch (classification) {
      case AtlasScenarioClassification.recommended:
        return 'Cenário economicamente atrativo. Avançar para validação operacional e definição dos gates de investimento.';
      case AtlasScenarioClassification.recommendedInPhases:
        return 'Implantar em fases, liberando capital conforme os resultados e a capacidade da equipe.';
      case AtlasScenarioClassification.review:
        if (pessimisticNpv < 0) {
          return 'Revisar premissas e proteger o caixa: o cenário pessimista destrói valor.';
        }
        return 'Revisar custos, prazo e escala antes da aprovação executiva.';
      case AtlasScenarioClassification.notRecommended:
        return 'Não aprovar nas condições atuais. O retorno não compensa o investimento e os riscos.';
    }
  }
}
