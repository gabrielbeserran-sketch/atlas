import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_intelligence_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_scenario_models.dart';

class AtlasEconomicScenarioService {
  const AtlasEconomicScenarioService();

  Future<AtlasAdvancedEconomicScenarioResult> simulate({
    required String? farmName,
    required AtlasAdvancedEconomicScenarioInput input,
  }) async {
    final economicService = AtlasEconomicIntelligenceService.instance;
    final metrics = await economicService.loadMetrics(farmName: farmName);
    final snapshot = await economicService.buildSnapshot(
      farmName: farmName,
      metrics: metrics,
    );

    final baseExpenses = snapshot.variableCosts + snapshot.fixedCosts;

    final revenueFactor =
        1 +
        input.arrobaVariationPercent / 100 +
        input.productivityVariationPercent / 100;

    final generalCostFactor = 1 + input.inputInflationPercent / 100;

    final supplementImpact =
        snapshot.variableCosts * 0.35 * input.supplementVariationPercent / 100;

    final healthImpact =
        snapshot.variableCosts * 0.12 * input.healthCostVariationPercent / 100;

    final geneticMonthlyBenefit = input.geneticInvestment <= 0
        ? 0.0
        : input.geneticInvestment * 0.018;

    final projectedRevenue =
        snapshot.revenue * revenueFactor +
        geneticMonthlyBenefit * input.horizonMonths;

    final projectedExpenses =
        baseExpenses * generalCostFactor +
        supplementImpact +
        healthImpact +
        input.geneticInvestment;

    final projectedNetResult = projectedRevenue - projectedExpenses;

    final projectedMargin = projectedRevenue <= 0
        ? 0.0
        : projectedNetResult / projectedRevenue * 100;

    final investedCapital = projectedExpenses <= 0 ? 1.0 : projectedExpenses;

    final roi = projectedNetResult / investedCapital * 100;

    final monthlyNetGeneticBenefit = geneticMonthlyBenefit;
    final payback =
        input.geneticInvestment <= 0 || monthlyNetGeneticBenefit <= 0
        ? null
        : input.geneticInvestment / monthlyNetGeneticBenefit;

    final monthlyProjection = _buildMonthlyProjection(
      horizonMonths: input.horizonMonths,
      annualRevenue: projectedRevenue,
      annualExpenses: projectedExpenses,
      type: input.type,
    );

    final score = _buildScore(
      margin: projectedMargin,
      roi: roi,
      netResult: projectedNetResult,
      liquidity: snapshot.liquidity,
    );

    return AtlasAdvancedEconomicScenarioResult(
      input: input,
      baseRevenue: snapshot.revenue,
      baseExpenses: baseExpenses,
      projectedRevenue: projectedRevenue,
      projectedExpenses: projectedExpenses,
      projectedNetResult: projectedNetResult,
      projectedMarginPercent: projectedMargin,
      projectedRoiPercent: roi,
      paybackMonths: payback,
      economicScore: score,
      monthlyProjection: monthlyProjection,
      recommendations: _buildRecommendations(
        input: input,
        margin: projectedMargin,
        roi: roi,
        netResult: projectedNetResult,
        score: score,
      ),
    );
  }

  List<AtlasMonthlyEconomicProjection> _buildMonthlyProjection({
    required int horizonMonths,
    required double annualRevenue,
    required double annualExpenses,
    required AtlasAdvancedEconomicScenarioType type,
  }) {
    final months = horizonMonths.clamp(1, 60);
    final monthlyRevenue = annualRevenue / months;
    final monthlyExpenses = annualExpenses / months;
    var accumulated = 0.0;

    return List<AtlasMonthlyEconomicProjection>.generate(months, (index) {
      final month = index + 1;
      final seasonality = switch (type) {
        AtlasAdvancedEconomicScenarioType.pessimistic =>
          month % 4 == 0 ? 0.90 : 0.96,
        AtlasAdvancedEconomicScenarioType.realistic =>
          month % 4 == 0 ? 1.02 : 1.0,
        AtlasAdvancedEconomicScenarioType.optimistic =>
          month % 4 == 0 ? 1.10 : 1.04,
      };
      final revenue = monthlyRevenue * seasonality;
      final expenses = monthlyExpenses;
      final balance = revenue - expenses;
      accumulated += balance;

      return AtlasMonthlyEconomicProjection(
        month: month,
        revenue: revenue,
        expenses: expenses,
        balance: balance,
        accumulatedBalance: accumulated,
      );
    });
  }

  double _buildScore({
    required double margin,
    required double roi,
    required double netResult,
    required double liquidity,
  }) {
    var score = 50.0;
    score += margin.clamp(-25, 25);
    score += (roi / 2).clamp(-20, 20);
    score += ((liquidity - 1) * 12).clamp(-15, 15);
    score += netResult >= 0 ? 10 : -15;
    return score.clamp(0, 100);
  }

  List<String> _buildRecommendations({
    required AtlasAdvancedEconomicScenarioInput input,
    required double margin,
    required double roi,
    required double netResult,
    required double score,
  }) {
    final values = <String>[];

    if (input.inputInflationPercent > 10) {
      values.add(
        'Inflação de insumos acima de 10%. Antecipe compras críticas e renegocie contratos.',
      );
    }
    if (input.supplementVariationPercent > 12) {
      values.add(
        'A suplementação apresenta forte pressão de custo. Compare ingredientes substitutos e custo por ganho.',
      );
    }
    if (input.healthCostVariationPercent > 15) {
      values.add(
        'O custo sanitário projetado aumentou significativamente. Reforce prevenção e compras programadas.',
      );
    }
    if (margin < 10) {
      values.add(
        'Margem projetada abaixo de 10%. Revise preço de venda, produtividade e custos variáveis.',
      );
    }
    if (roi < 5) {
      values.add(
        'ROI projetado baixo. Reavalie o momento e o tamanho dos investimentos.',
      );
    }
    if (netResult < 0) {
      values.add(
        'O cenário gera resultado negativo. Priorize preservação de caixa e redução de exposição.',
      );
    }
    if (score >= 80) {
      values.add(
        'Cenário economicamente favorável. Estruture execução, metas e monitoramento mensal.',
      );
    }
    if (values.isEmpty) {
      values.add(
        'O cenário apresenta equilíbrio econômico. Acompanhe mensalmente margens, custos e liquidez.',
      );
    }
    return values;
  }
}
