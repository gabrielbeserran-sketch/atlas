class AtlasRecommendationEffectiveness {
  const AtlasRecommendationEffectiveness({
    required this.sourceModule,
    required this.actionCount,
    required this.completedCount,
    required this.outcomeCount,
    required this.averageProgressPercent,
    required this.averageRoiPercent,
    required this.totalNetFinancialResult,
    required this.effectivenessScore,
  });

  final String sourceModule;
  final int actionCount;
  final int completedCount;
  final int outcomeCount;
  final double averageProgressPercent;
  final double averageRoiPercent;
  final double totalNetFinancialResult;
  final double effectivenessScore;
}
