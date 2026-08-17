enum AtlasInvestmentCategory {
  pasture,
  reproduction,
  nutrition,
  infrastructure,
  technology,
  sustainability,
  herd,
  other,
}

enum AtlasInvestmentDecision { approve, phase, postpone, reject }

String atlasInvestmentCategoryLabel(AtlasInvestmentCategory value) {
  switch (value) {
    case AtlasInvestmentCategory.pasture:
      return 'Pastagens';
    case AtlasInvestmentCategory.reproduction:
      return 'Reprodução';
    case AtlasInvestmentCategory.nutrition:
      return 'Nutrição';
    case AtlasInvestmentCategory.infrastructure:
      return 'Infraestrutura';
    case AtlasInvestmentCategory.technology:
      return 'Tecnologia';
    case AtlasInvestmentCategory.sustainability:
      return 'Sustentabilidade';
    case AtlasInvestmentCategory.herd:
      return 'Rebanho';
    case AtlasInvestmentCategory.other:
      return 'Outros';
  }
}

String atlasInvestmentDecisionLabel(AtlasInvestmentDecision value) {
  switch (value) {
    case AtlasInvestmentDecision.approve:
      return 'Aprovar';
    case AtlasInvestmentDecision.phase:
      return 'Executar em fases';
    case AtlasInvestmentDecision.postpone:
      return 'Adiar';
    case AtlasInvestmentDecision.reject:
      return 'Não recomendado';
  }
}

class AtlasInvestmentProject {
  const AtlasInvestmentProject({
    required this.id,
    required this.farmId,
    required this.name,
    required this.description,
    required this.category,
    required this.initialInvestment,
    required this.workingCapital,
    required this.annualRevenue,
    required this.annualOperatingCost,
    required this.residualValue,
    required this.horizonYears,
    required this.strategicAlignment,
    required this.operationalCapacity,
    required this.riskScore,
    required this.mandatory,
    required this.createdAt,
  });

  final String id;
  final String farmId;
  final String name;
  final String description;
  final AtlasInvestmentCategory category;
  final double initialInvestment;
  final double workingCapital;
  final double annualRevenue;
  final double annualOperatingCost;
  final double residualValue;
  final int horizonYears;
  final double strategicAlignment;
  final double operationalCapacity;
  final double riskScore;
  final bool mandatory;
  final DateTime createdAt;

  double get totalCapital => initialInvestment + workingCapital;
  double get annualNetCashFlow => annualRevenue - annualOperatingCost;

  AtlasInvestmentProject copyWith({
    String? id,
    String? farmId,
    String? name,
    String? description,
    AtlasInvestmentCategory? category,
    double? initialInvestment,
    double? workingCapital,
    double? annualRevenue,
    double? annualOperatingCost,
    double? residualValue,
    int? horizonYears,
    double? strategicAlignment,
    double? operationalCapacity,
    double? riskScore,
    bool? mandatory,
    DateTime? createdAt,
  }) {
    return AtlasInvestmentProject(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      initialInvestment: initialInvestment ?? this.initialInvestment,
      workingCapital: workingCapital ?? this.workingCapital,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      annualOperatingCost: annualOperatingCost ?? this.annualOperatingCost,
      residualValue: residualValue ?? this.residualValue,
      horizonYears: horizonYears ?? this.horizonYears,
      strategicAlignment: strategicAlignment ?? this.strategicAlignment,
      operationalCapacity: operationalCapacity ?? this.operationalCapacity,
      riskScore: riskScore ?? this.riskScore,
      mandatory: mandatory ?? this.mandatory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'farmId': farmId,
    'name': name,
    'description': description,
    'category': category.name,
    'initialInvestment': initialInvestment,
    'workingCapital': workingCapital,
    'annualRevenue': annualRevenue,
    'annualOperatingCost': annualOperatingCost,
    'residualValue': residualValue,
    'horizonYears': horizonYears,
    'strategicAlignment': strategicAlignment,
    'operationalCapacity': operationalCapacity,
    'riskScore': riskScore,
    'mandatory': mandatory,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AtlasInvestmentProject.fromJson(Map<String, dynamic> json) {
    return AtlasInvestmentProject(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: AtlasInvestmentCategory.values.firstWhere(
        (item) => item.name == json['category'],
        orElse: () => AtlasInvestmentCategory.other,
      ),
      initialInvestment: (json['initialInvestment'] as num?)?.toDouble() ?? 0,
      workingCapital: (json['workingCapital'] as num?)?.toDouble() ?? 0,
      annualRevenue: (json['annualRevenue'] as num?)?.toDouble() ?? 0,
      annualOperatingCost:
          (json['annualOperatingCost'] as num?)?.toDouble() ?? 0,
      residualValue: (json['residualValue'] as num?)?.toDouble() ?? 0,
      horizonYears: (json['horizonYears'] as num?)?.toInt() ?? 5,
      strategicAlignment:
          (json['strategicAlignment'] as num?)?.toDouble() ?? 50,
      operationalCapacity:
          (json['operationalCapacity'] as num?)?.toDouble() ?? 50,
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 50,
      mandatory: json['mandatory'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
