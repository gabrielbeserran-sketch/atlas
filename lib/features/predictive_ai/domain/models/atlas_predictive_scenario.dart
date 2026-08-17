enum AtlasPredictionArea { reproduction, production, financial, operational }

enum AtlasRiskLevel { low, moderate, high, critical }

class AtlasPredictiveScenario {
  const AtlasPredictiveScenario({
    required this.id,
    required this.farmId,
    required this.title,
    required this.description,
    required this.area,
    required this.createdAt,
    required this.investment,
    required this.currentRevenue,
    required this.currentCost,
    required this.productivityChange,
    required this.costChange,
    required this.revenueChange,
    required this.capacityChange,
    required this.horizonMonths,
  });

  final String id;
  final String farmId;
  final String title;
  final String description;
  final AtlasPredictionArea area;
  final DateTime createdAt;
  final double investment;
  final double currentRevenue;
  final double currentCost;
  final double productivityChange;
  final double costChange;
  final double revenueChange;
  final double capacityChange;
  final int horizonMonths;

  AtlasPredictiveScenario copyWith({
    String? id,
    String? farmId,
    String? title,
    String? description,
    AtlasPredictionArea? area,
    DateTime? createdAt,
    double? investment,
    double? currentRevenue,
    double? currentCost,
    double? productivityChange,
    double? costChange,
    double? revenueChange,
    double? capacityChange,
    int? horizonMonths,
  }) => AtlasPredictiveScenario(
    id: id ?? this.id,
    farmId: farmId ?? this.farmId,
    title: title ?? this.title,
    description: description ?? this.description,
    area: area ?? this.area,
    createdAt: createdAt ?? this.createdAt,
    investment: investment ?? this.investment,
    currentRevenue: currentRevenue ?? this.currentRevenue,
    currentCost: currentCost ?? this.currentCost,
    productivityChange: productivityChange ?? this.productivityChange,
    costChange: costChange ?? this.costChange,
    revenueChange: revenueChange ?? this.revenueChange,
    capacityChange: capacityChange ?? this.capacityChange,
    horizonMonths: horizonMonths ?? this.horizonMonths,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'farmId': farmId,
    'title': title,
    'description': description,
    'area': area.name,
    'createdAt': createdAt.toIso8601String(),
    'investment': investment,
    'currentRevenue': currentRevenue,
    'currentCost': currentCost,
    'productivityChange': productivityChange,
    'costChange': costChange,
    'revenueChange': revenueChange,
    'capacityChange': capacityChange,
    'horizonMonths': horizonMonths,
  };

  factory AtlasPredictiveScenario.fromJson(Map<String, dynamic> json) =>
      AtlasPredictiveScenario(
        id: json['id'] as String,
        farmId: (json['farmId'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        area: AtlasPredictionArea.values.byName(
          (json['area'] as String?) ?? 'production',
        ),
        createdAt:
            DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.now(),
        investment: (json['investment'] as num?)?.toDouble() ?? 0,
        currentRevenue: (json['currentRevenue'] as num?)?.toDouble() ?? 0,
        currentCost: (json['currentCost'] as num?)?.toDouble() ?? 0,
        productivityChange:
            (json['productivityChange'] as num?)?.toDouble() ?? 0,
        costChange: (json['costChange'] as num?)?.toDouble() ?? 0,
        revenueChange: (json['revenueChange'] as num?)?.toDouble() ?? 0,
        capacityChange: (json['capacityChange'] as num?)?.toDouble() ?? 0,
        horizonMonths: (json['horizonMonths'] as num?)?.toInt() ?? 12,
      );
}

class AtlasPredictionResult {
  const AtlasPredictionResult({
    required this.scenario,
    required this.projectedRevenue,
    required this.projectedCost,
    required this.projectedProfit,
    required this.roi,
    required this.paybackMonths,
    required this.confidence,
    required this.riskLevel,
    required this.riskProbability,
    required this.recommendation,
    required this.drivers,
  });

  final AtlasPredictiveScenario scenario;
  final double projectedRevenue;
  final double projectedCost;
  final double projectedProfit;
  final double roi;
  final double paybackMonths;
  final double confidence;
  final AtlasRiskLevel riskLevel;
  final double riskProbability;
  final String recommendation;
  final List<String> drivers;
}
