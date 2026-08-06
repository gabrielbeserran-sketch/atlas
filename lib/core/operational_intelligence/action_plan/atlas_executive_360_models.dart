class AtlasExecutive360AreaScore {
  const AtlasExecutive360AreaScore({
    required this.area,
    required this.score,
    required this.status,
  });

  final String area;
  final double score;
  final String status;
}

class AtlasExecutive360Bottleneck {
  const AtlasExecutive360Bottleneck({
    required this.area,
    required this.title,
    required this.description,
    required this.severity,
    required this.recommendedAction,
  });

  final String area;
  final String title;
  final String description;
  final double severity;
  final String recommendedAction;
}

class AtlasExecutive360Snapshot {
  const AtlasExecutive360Snapshot({
    required this.farmName,
    required this.generatedAt,
    required this.overallScore,
    required this.riskScore,
    required this.productivityScore,
    required this.areaScores,
    required this.bottlenecks,
    required this.officialRecommendation,
  });

  final String farmName;
  final DateTime generatedAt;
  final double overallScore;
  final double riskScore;
  final double productivityScore;
  final List<AtlasExecutive360AreaScore> areaScores;
  final List<AtlasExecutive360Bottleneck> bottlenecks;
  final String officialRecommendation;
}
