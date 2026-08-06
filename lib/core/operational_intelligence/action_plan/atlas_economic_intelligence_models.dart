enum AtlasEconomicActivity {
  breeding,
  rearing,
  finishing,
  dairy,
  agriculture,
  services,
  other,
}

String atlasEconomicActivityLabel(AtlasEconomicActivity value) {
  switch (value) {
    case AtlasEconomicActivity.breeding:
      return 'Cria';
    case AtlasEconomicActivity.rearing:
      return 'Recria';
    case AtlasEconomicActivity.finishing:
      return 'Engorda';
    case AtlasEconomicActivity.dairy:
      return 'Leite';
    case AtlasEconomicActivity.agriculture:
      return 'Agricultura';
    case AtlasEconomicActivity.services:
      return 'Serviços';
    case AtlasEconomicActivity.other:
      return 'Outra';
  }
}

enum AtlasEconomicScenarioType {
  conservative,
  base,
  optimistic,
}

String atlasEconomicScenarioTypeLabel(
  AtlasEconomicScenarioType value,
) {
  switch (value) {
    case AtlasEconomicScenarioType.conservative:
      return 'Conservador';
    case AtlasEconomicScenarioType.base:
      return 'Base';
    case AtlasEconomicScenarioType.optimistic:
      return 'Otimista';
  }
}

class AtlasEconomicProductionMetric {
  const AtlasEconomicProductionMetric({
    required this.id,
    required this.activity,
    required this.periodStart,
    required this.periodEnd,
    required this.hectares,
    required this.animalCount,
    required this.arrobasProduced,
    required this.litersProduced,
    required this.kilogramsProduced,
    required this.revenue,
    required this.variableCost,
    required this.fixedCost,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final AtlasEconomicActivity activity;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double hectares;
  final int animalCount;
  final double arrobasProduced;
  final double litersProduced;
  final double kilogramsProduced;
  final double revenue;
  final double variableCost;
  final double fixedCost;
  final String? farmName;
  final String notes;

  double get totalCost => variableCost + fixedCost;
  double get operatingResult => revenue - totalCost;
  double get marginPercent =>
      revenue <= 0 ? 0 : operatingResult / revenue * 100;
  double get costPerHectare =>
      hectares <= 0 ? 0 : totalCost / hectares;
  double get costPerAnimal =>
      animalCount <= 0 ? 0 : totalCost / animalCount;
  double get costPerArroba =>
      arrobasProduced <= 0 ? 0 : totalCost / arrobasProduced;
  double get costPerLiter =>
      litersProduced <= 0 ? 0 : totalCost / litersProduced;
  double get costPerKilogram =>
      kilogramsProduced <= 0 ? 0 : totalCost / kilogramsProduced;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'activity': activity.name,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'hectares': hectares,
        'animalCount': animalCount,
        'arrobasProduced': arrobasProduced,
        'litersProduced': litersProduced,
        'kilogramsProduced': kilogramsProduced,
        'revenue': revenue,
        'variableCost': variableCost,
        'fixedCost': fixedCost,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasEconomicProductionMetric.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasEconomicProductionMetric(
      id: map['id']?.toString() ?? '',
      activity: AtlasEconomicActivity.values.firstWhere(
        (value) => value.name == map['activity']?.toString(),
        orElse: () => AtlasEconomicActivity.other,
      ),
      periodStart: DateTime.tryParse(
            map['periodStart']?.toString() ?? '',
          ) ??
          DateTime.now(),
      periodEnd: DateTime.tryParse(
            map['periodEnd']?.toString() ?? '',
          ) ??
          DateTime.now(),
      hectares: _readDouble(map['hectares']),
      animalCount: _readInt(map['animalCount']),
      arrobasProduced: _readDouble(map['arrobasProduced']),
      litersProduced: _readDouble(map['litersProduced']),
      kilogramsProduced:
          _readDouble(map['kilogramsProduced']),
      revenue: _readDouble(map['revenue']),
      variableCost: _readDouble(map['variableCost']),
      fixedCost: _readDouble(map['fixedCost']),
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasEconomicInvestmentScenario {
  const AtlasEconomicInvestmentScenario({
    required this.id,
    required this.title,
    required this.type,
    required this.initialInvestment,
    required this.monthlyRevenueIncrease,
    required this.monthlyCostIncrease,
    required this.horizonMonths,
    required this.discountRatePercent,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String title;
  final AtlasEconomicScenarioType type;
  final double initialInvestment;
  final double monthlyRevenueIncrease;
  final double monthlyCostIncrease;
  final int horizonMonths;
  final double discountRatePercent;
  final String? farmName;
  final String notes;

  double get monthlyNetBenefit =>
      monthlyRevenueIncrease - monthlyCostIncrease;

  double get projectedNetResult =>
      monthlyNetBenefit * horizonMonths - initialInvestment;

  double get roiPercent => initialInvestment <= 0
      ? 0
      : projectedNetResult / initialInvestment * 100;

  double? get paybackMonths {
    if (monthlyNetBenefit <= 0) {
      return null;
    }
    return initialInvestment / monthlyNetBenefit;
  }

  double get presentValue {
    final monthlyRate = discountRatePercent / 100 / 12;
    var result = -initialInvestment;
    for (var month = 1; month <= horizonMonths; month++) {
      result += monthlyNetBenefit /
          _pow(1 + monthlyRate, month);
    }
    return result;
  }

  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'type': type.name,
        'initialInvestment': initialInvestment,
        'monthlyRevenueIncrease': monthlyRevenueIncrease,
        'monthlyCostIncrease': monthlyCostIncrease,
        'horizonMonths': horizonMonths,
        'discountRatePercent': discountRatePercent,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasEconomicInvestmentScenario.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasEconomicInvestmentScenario(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      type: AtlasEconomicScenarioType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasEconomicScenarioType.base,
      ),
      initialInvestment:
          _readDouble(map['initialInvestment']),
      monthlyRevenueIncrease:
          _readDouble(map['monthlyRevenueIncrease']),
      monthlyCostIncrease:
          _readDouble(map['monthlyCostIncrease']),
      horizonMonths: _readInt(map['horizonMonths']),
      discountRatePercent:
          _readDouble(map['discountRatePercent']),
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasEconomicSnapshot {
  const AtlasEconomicSnapshot({
    required this.revenue,
    required this.variableCosts,
    required this.fixedCosts,
    required this.ebitda,
    required this.netResult,
    required this.operatingMarginPercent,
    required this.roiPercent,
    required this.liquidity,
    required this.projectedBalance30Days,
    required this.projectedBalance90Days,
    required this.projectedBalance365Days,
    required this.financialScore,
  });

  final double revenue;
  final double variableCosts;
  final double fixedCosts;
  final double ebitda;
  final double netResult;
  final double operatingMarginPercent;
  final double roiPercent;
  final double liquidity;
  final double projectedBalance30Days;
  final double projectedBalance90Days;
  final double projectedBalance365Days;
  final double financialScore;
}
