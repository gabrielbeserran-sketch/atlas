class AtlasAiRecommendation {
  const AtlasAiRecommendation({
    required this.id,
    required this.area,
    required this.title,
    required this.description,
    required this.priority,
    required this.confidence,
    required this.action,
    required this.evidence,
    required this.limitations,
  });

  final String id;
  final String area;
  final String title;
  final String description;
  final String priority;
  final double confidence;
  final String action;
  final List<String> evidence;
  final List<String> limitations;

  factory AtlasAiRecommendation.fromMap(Map<String, dynamic> map) {
    List<String> strings(Object? value) => value is List
        ? value.map((item) => item.toString()).toList(growable: false)
        : const [];
    return AtlasAiRecommendation(
      id: map['id']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Recomendação',
      description: map['description']?.toString() ?? '',
      priority: map['priority']?.toString() ?? 'normal',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      action: map['recommended_action']?.toString() ?? '',
      evidence: strings(map['evidence']),
      limitations: strings(map['limitations']),
    );
  }
}

class AtlasAiSimulation {
  const AtlasAiSimulation({
    required this.projectedVariation,
    required this.confidence,
    this.roiPercent,
  });
  final double projectedVariation;
  final double? roiPercent;
  final double confidence;

  factory AtlasAiSimulation.fromMap(Map<String, dynamic> map) =>
      AtlasAiSimulation(
        projectedVariation:
            (map['projected_variation'] as num?)?.toDouble() ?? 0,
        roiPercent: (map['roi_percent'] as num?)?.toDouble(),
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      );
}
