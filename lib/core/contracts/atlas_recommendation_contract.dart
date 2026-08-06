import 'atlas_canonical_types.dart';

class AtlasRecommendationContract {
  const AtlasRecommendationContract({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.area,
    required this.title,
    required this.diagnosis,
    required this.protocol,
    required this.justification,
    required this.sourceModule,
    required this.priority,
    required this.confidencePercent,
    required this.expectedEconomicGain,
    required this.currentScore,
    required this.targetScore,
    required this.steps,
    required this.risks,
    required this.evidence,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final String area;
  final String title;
  final String diagnosis;
  final String protocol;
  final String justification;
  final String sourceModule;
  final AtlasCanonicalPriority priority;
  final double confidencePercent;
  final double expectedEconomicGain;
  final double currentScore;
  final double targetScore;
  final List<String> steps;
  final List<String> risks;
  final List<String> evidence;

  double get expectedScoreGain {
    return (targetScore - currentScore).clamp(0.0, 100.0).toDouble();
  }
}
