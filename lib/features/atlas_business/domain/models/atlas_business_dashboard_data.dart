class AtlasBusinessDashboardData {
  const AtlasBusinessDashboardData({required this.commercial, required this.consulting, required this.enterprise, required this.bi, required this.product, required this.generatedAt});
  final Map<String, dynamic> commercial;
  final Map<String, dynamic> consulting;
  final Map<String, dynamic> enterprise;
  final Map<String, dynamic> bi;
  final Map<String, dynamic> product;
  final DateTime generatedAt;
  factory AtlasBusinessDashboardData.fromJson(Map<String, dynamic> json) => AtlasBusinessDashboardData(
    commercial: Map<String, dynamic>.from(json['commercial'] as Map? ?? const {}),
    consulting: Map<String, dynamic>.from(json['consulting'] as Map? ?? const {}),
    enterprise: Map<String, dynamic>.from(json['enterprise'] as Map? ?? const {}),
    bi: Map<String, dynamic>.from(json['bi'] as Map? ?? const {}),
    product: Map<String, dynamic>.from(json['product'] as Map? ?? const {}),
    generatedAt: DateTime.tryParse('${json['generated_at'] ?? ''}') ?? DateTime.now(),
  );
}
