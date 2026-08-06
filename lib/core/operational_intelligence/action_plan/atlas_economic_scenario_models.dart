enum AtlasAdvancedEconomicScenarioType {
  pessimistic,
  realistic,
  optimistic,
}

String atlasAdvancedEconomicScenarioTypeLabel(
  AtlasAdvancedEconomicScenarioType value,
) {
  switch (value) {
    case AtlasAdvancedEconomicScenarioType.pessimistic:
      return 'Pessimista';
    case AtlasAdvancedEconomicScenarioType.realistic:
      return 'Realista';
    case AtlasAdvancedEconomicScenarioType.optimistic:
      return 'Otimista';
  }
}

class AtlasAdvancedEconomicScenarioInput {
  const AtlasAdvancedEconomicScenarioInput({
    required this.type,
    required this.inputInflationPercent,
    required this.arrobaVariationPercent,
    required this.supplementVariationPercent,
    required this.healthCostVariationPercent,
    required this.geneticInvestment,
    required this.productivityVariationPercent,
    required this.horizonMonths,
  });

  final AtlasAdvancedEconomicScenarioType type;
  final double inputInflationPercent;
  final double arrobaVariationPercent;
  final double supplementVariationPercent;
  final double healthCostVariationPercent;
  final double geneticInvestment;
  final double productivityVariationPercent;
  final int horizonMonths;
}

class AtlasMonthlyEconomicProjection {
  const AtlasMonthlyEconomicProjection({
    required this.month,
    required this.revenue,
    required this.expenses,
    required this.balance,
    required this.accumulatedBalance,
  });

  final int month;
  final double revenue;
  final double expenses;
  final double balance;
  final double accumulatedBalance;
}

class AtlasAdvancedEconomicScenarioResult {
  const AtlasAdvancedEconomicScenarioResult({
    required this.input,
    required this.baseRevenue,
    required this.baseExpenses,
    required this.projectedRevenue,
    required this.projectedExpenses,
    required this.projectedNetResult,
    required this.projectedMarginPercent,
    required this.projectedRoiPercent,
    required this.paybackMonths,
    required this.economicScore,
    required this.monthlyProjection,
    required this.recommendations,
  });

  final AtlasAdvancedEconomicScenarioInput input;
  final double baseRevenue;
  final double baseExpenses;
  final double projectedRevenue;
  final double projectedExpenses;
  final double projectedNetResult;
  final double projectedMarginPercent;
  final double projectedRoiPercent;
  final double? paybackMonths;
  final double economicScore;
  final List<AtlasMonthlyEconomicProjection> monthlyProjection;
  final List<String> recommendations;
}
