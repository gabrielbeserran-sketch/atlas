class AtlasPlatformRecommendation {
  const AtlasPlatformRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.priority,
    required this.confidencePercent,
    required this.expectedImpact,
    required this.evidence,
    required this.recommendedAction,
    required this.deadlineHours,
  });
  final String id,
      title,
      description,
      area,
      priority,
      expectedImpact,
      recommendedAction;
  final double confidencePercent;
  final List<String> evidence;
  final int deadlineHours;
  factory AtlasPlatformRecommendation.fromMap(Map<String, dynamic> map) =>
      AtlasPlatformRecommendation(
        id: '${map['id'] ?? ''}',
        title: '${map['title'] ?? ''}',
        description: '${map['description'] ?? ''}',
        area: '${map['area'] ?? ''}',
        priority: '${map['priority'] ?? ''}',
        confidencePercent: (map['confidence_percent'] as num?)?.toDouble() ?? 0,
        expectedImpact: '${map['expected_impact'] ?? ''}',
        evidence: ((map['evidence'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
        recommendedAction: '${map['recommended_action'] ?? ''}',
        deadlineHours: (map['deadline_hours'] as num?)?.toInt() ?? 0,
      );
}

class AtlasPlatformDashboardData {
  const AtlasPlatformDashboardData({
    required this.generatedAt,
    required this.farm,
    required this.herd,
    required this.reproduction,
    required this.health,
    required this.nutrition,
    required this.inventory,
    required this.financial,
    required this.dataQuality,
    required this.recommendations,
  });
  final DateTime generatedAt;
  final Map<String, dynamic> farm,
      herd,
      reproduction,
      health,
      nutrition,
      inventory,
      financial,
      dataQuality;
  final List<AtlasPlatformRecommendation> recommendations;
  factory AtlasPlatformDashboardData.fromMap(Map<String, dynamic> map) =>
      AtlasPlatformDashboardData(
        generatedAt:
            DateTime.tryParse('${map['generated_at'] ?? ''}') ?? DateTime.now(),
        farm: Map<String, dynamic>.from((map['farm'] as Map?) ?? const {}),
        herd: Map<String, dynamic>.from((map['herd'] as Map?) ?? const {}),
        reproduction: Map<String, dynamic>.from(
          (map['reproduction'] as Map?) ?? const {},
        ),
        health: Map<String, dynamic>.from((map['health'] as Map?) ?? const {}),
        nutrition: Map<String, dynamic>.from(
          (map['nutrition'] as Map?) ?? const {},
        ),
        inventory: Map<String, dynamic>.from(
          (map['inventory'] as Map?) ?? const {},
        ),
        financial: Map<String, dynamic>.from(
          (map['financial'] as Map?) ?? const {},
        ),
        dataQuality: Map<String, dynamic>.from(
          (map['data_quality'] as Map?) ?? const {},
        ),
        recommendations: ((map['recommendations'] as List?) ?? const [])
            .map(
              (e) => AtlasPlatformRecommendation.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}
