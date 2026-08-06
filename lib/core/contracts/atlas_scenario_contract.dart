import 'atlas_canonical_types.dart';

class AtlasScenarioContract {
  const AtlasScenarioContract({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.sourceModule,
    required this.baseScore,
    required this.projectedScore,
    required this.investmentValue,
    required this.projectedFinancialImpact,
    required this.projectedRisk,
    required this.confidencePercent,
    required this.executionDays,
    required this.changes,
    required this.recommendation,
    required this.evidence,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime createdAt;
  final String title;
  final String description;
  final String sourceModule;
  final double baseScore;
  final double projectedScore;
  final double investmentValue;
  final double projectedFinancialImpact;
  final AtlasCanonicalRisk projectedRisk;
  final double confidencePercent;
  final int executionDays;
  final Map<String, double> changes;
  final String recommendation;
  final List<String> evidence;

  double get scoreVariation => projectedScore - baseScore;
}
