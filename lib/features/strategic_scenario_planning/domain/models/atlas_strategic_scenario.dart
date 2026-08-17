class AtlasStrategicScenario {
  const AtlasStrategicScenario({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.horizonYears,
    required this.initialInvestment,
    required this.workingCapital,
    required this.annualAdditionalRevenue,
    required this.annualAdditionalCost,
    required this.residualValue,
    required this.discountRatePercent,
    required this.priceSensitivityPercent,
    required this.costSensitivityPercent,
    required this.productiveImpacts,
    required this.risks,
  });

  final String id;
  final String farmId;
  final String farmName;
  final String title;
  final String description;
  final AtlasStrategicScenarioType type;
  final DateTime createdAt;
  final int horizonYears;
  final double initialInvestment;
  final double workingCapital;
  final double annualAdditionalRevenue;
  final double annualAdditionalCost;
  final double residualValue;
  final double discountRatePercent;
  final double priceSensitivityPercent;
  final double costSensitivityPercent;
  final AtlasProductiveImpacts productiveImpacts;
  final AtlasScenarioRisks risks;

  AtlasStrategicScenario copyWith({
    String? id,
    String? farmId,
    String? farmName,
    String? title,
    String? description,
    AtlasStrategicScenarioType? type,
    DateTime? createdAt,
    int? horizonYears,
    double? initialInvestment,
    double? workingCapital,
    double? annualAdditionalRevenue,
    double? annualAdditionalCost,
    double? residualValue,
    double? discountRatePercent,
    double? priceSensitivityPercent,
    double? costSensitivityPercent,
    AtlasProductiveImpacts? productiveImpacts,
    AtlasScenarioRisks? risks,
  }) {
    return AtlasStrategicScenario(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      horizonYears: horizonYears ?? this.horizonYears,
      initialInvestment: initialInvestment ?? this.initialInvestment,
      workingCapital: workingCapital ?? this.workingCapital,
      annualAdditionalRevenue:
          annualAdditionalRevenue ?? this.annualAdditionalRevenue,
      annualAdditionalCost: annualAdditionalCost ?? this.annualAdditionalCost,
      residualValue: residualValue ?? this.residualValue,
      discountRatePercent: discountRatePercent ?? this.discountRatePercent,
      priceSensitivityPercent:
          priceSensitivityPercent ?? this.priceSensitivityPercent,
      costSensitivityPercent:
          costSensitivityPercent ?? this.costSensitivityPercent,
      productiveImpacts: productiveImpacts ?? this.productiveImpacts,
      risks: risks ?? this.risks,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'farmId': farmId,
      'farmName': farmName,
      'title': title,
      'description': description,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'horizonYears': horizonYears,
      'initialInvestment': initialInvestment,
      'workingCapital': workingCapital,
      'annualAdditionalRevenue': annualAdditionalRevenue,
      'annualAdditionalCost': annualAdditionalCost,
      'residualValue': residualValue,
      'discountRatePercent': discountRatePercent,
      'priceSensitivityPercent': priceSensitivityPercent,
      'costSensitivityPercent': costSensitivityPercent,
      'productiveImpacts': productiveImpacts.toJson(),
      'risks': risks.toJson(),
    };
  }

  factory AtlasStrategicScenario.fromJson(Map<String, dynamic> json) {
    return AtlasStrategicScenario(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: AtlasStrategicScenarioType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => AtlasStrategicScenarioType.pastureIntensification,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      horizonYears: (json['horizonYears'] as num?)?.toInt() ?? 5,
      initialInvestment: (json['initialInvestment'] as num?)?.toDouble() ?? 0,
      workingCapital: (json['workingCapital'] as num?)?.toDouble() ?? 0,
      annualAdditionalRevenue:
          (json['annualAdditionalRevenue'] as num?)?.toDouble() ?? 0,
      annualAdditionalCost:
          (json['annualAdditionalCost'] as num?)?.toDouble() ?? 0,
      residualValue: (json['residualValue'] as num?)?.toDouble() ?? 0,
      discountRatePercent:
          (json['discountRatePercent'] as num?)?.toDouble() ?? 10,
      priceSensitivityPercent:
          (json['priceSensitivityPercent'] as num?)?.toDouble() ?? 10,
      costSensitivityPercent:
          (json['costSensitivityPercent'] as num?)?.toDouble() ?? 10,
      productiveImpacts: AtlasProductiveImpacts.fromJson(
        Map<String, dynamic>.from(
          json['productiveImpacts'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      risks: AtlasScenarioRisks.fromJson(
        Map<String, dynamic>.from(
          json['risks'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class AtlasProductiveImpacts {
  const AtlasProductiveImpacts({
    required this.pregnancyRateChange,
    required this.weaningRateChange,
    required this.dailyGainChange,
    required this.stockingRateChange,
    required this.arrobasPerYearChange,
    required this.productivityPerHectareChange,
    required this.mortalityReduction,
  });

  final double pregnancyRateChange;
  final double weaningRateChange;
  final double dailyGainChange;
  final double stockingRateChange;
  final double arrobasPerYearChange;
  final double productivityPerHectareChange;
  final double mortalityReduction;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pregnancyRateChange': pregnancyRateChange,
      'weaningRateChange': weaningRateChange,
      'dailyGainChange': dailyGainChange,
      'stockingRateChange': stockingRateChange,
      'arrobasPerYearChange': arrobasPerYearChange,
      'productivityPerHectareChange': productivityPerHectareChange,
      'mortalityReduction': mortalityReduction,
    };
  }

  factory AtlasProductiveImpacts.fromJson(Map<String, dynamic> json) {
    return AtlasProductiveImpacts(
      pregnancyRateChange:
          (json['pregnancyRateChange'] as num?)?.toDouble() ?? 0,
      weaningRateChange: (json['weaningRateChange'] as num?)?.toDouble() ?? 0,
      dailyGainChange: (json['dailyGainChange'] as num?)?.toDouble() ?? 0,
      stockingRateChange: (json['stockingRateChange'] as num?)?.toDouble() ?? 0,
      arrobasPerYearChange:
          (json['arrobasPerYearChange'] as num?)?.toDouble() ?? 0,
      productivityPerHectareChange:
          (json['productivityPerHectareChange'] as num?)?.toDouble() ?? 0,
      mortalityReduction: (json['mortalityReduction'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AtlasScenarioRisks {
  const AtlasScenarioRisks({
    required this.climate,
    required this.sanitary,
    required this.financial,
    required this.operational,
    required this.market,
  });

  final double climate;
  final double sanitary;
  final double financial;
  final double operational;
  final double market;

  double get average {
    return (climate + sanitary + financial + operational + market) / 5;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'climate': climate,
      'sanitary': sanitary,
      'financial': financial,
      'operational': operational,
      'market': market,
    };
  }

  factory AtlasScenarioRisks.fromJson(Map<String, dynamic> json) {
    return AtlasScenarioRisks(
      climate: (json['climate'] as num?)?.toDouble() ?? 50,
      sanitary: (json['sanitary'] as num?)?.toDouble() ?? 50,
      financial: (json['financial'] as num?)?.toDouble() ?? 50,
      operational: (json['operational'] as num?)?.toDouble() ?? 50,
      market: (json['market'] as num?)?.toDouble() ?? 50,
    );
  }
}

enum AtlasStrategicScenarioType {
  herdExpansion,
  iatf,
  breedingFemales,
  pastureIntensification,
  feedlot,
  semiFeedlot,
  cropLivestockIntegration,
  geneticImprovement,
  machinery,
  infrastructure,
  workforce,
  custom,
}

String atlasStrategicScenarioTypeLabel(AtlasStrategicScenarioType type) {
  switch (type) {
    case AtlasStrategicScenarioType.herdExpansion:
      return 'Expansão do rebanho';
    case AtlasStrategicScenarioType.iatf:
      return 'Implantação de IATF';
    case AtlasStrategicScenarioType.breedingFemales:
      return 'Compra de matrizes';
    case AtlasStrategicScenarioType.pastureIntensification:
      return 'Intensificação de pastagens';
    case AtlasStrategicScenarioType.feedlot:
      return 'Confinamento';
    case AtlasStrategicScenarioType.semiFeedlot:
      return 'Semi-confinamento';
    case AtlasStrategicScenarioType.cropLivestockIntegration:
      return 'Integração Lavoura-Pecuária';
    case AtlasStrategicScenarioType.geneticImprovement:
      return 'Melhoramento genético';
    case AtlasStrategicScenarioType.machinery:
      return 'Aquisição de máquinas';
    case AtlasStrategicScenarioType.infrastructure:
      return 'Construção de instalações';
    case AtlasStrategicScenarioType.workforce:
      return 'Contratação de equipe';
    case AtlasStrategicScenarioType.custom:
      return 'Cenário personalizado';
  }
}
