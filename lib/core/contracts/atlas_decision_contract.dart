import 'atlas_canonical_types.dart';

class AtlasDecisionContract {
  const AtlasDecisionContract({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.title,
    required this.description,
    required this.reasoning,
    required this.expectedResult,
    required this.sourceModule,
    required this.category,
    required this.priority,
    required this.horizon,
    required this.risk,
    required this.confidencePercent,
    required this.decisionScore,
    required this.expectedFinancialImpact,
    required this.deadline,
    required this.dependencies,
    required this.evidence,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final String title;
  final String description;
  final String reasoning;
  final String expectedResult;
  final String sourceModule;
  final String category;
  final AtlasCanonicalPriority priority;
  final AtlasCanonicalHorizon horizon;
  final AtlasCanonicalRisk risk;
  final double confidencePercent;
  final double decisionScore;
  final double expectedFinancialImpact;
  final DateTime deadline;
  final List<String> dependencies;
  final List<String> evidence;

  bool get isOverdue => DateTime.now().isAfter(deadline);

  AtlasDecisionContract copyWith({
    String? id,
    String? farmId,
    String? farmName,
    DateTime? generatedAt,
    String? title,
    String? description,
    String? reasoning,
    String? expectedResult,
    String? sourceModule,
    String? category,
    AtlasCanonicalPriority? priority,
    AtlasCanonicalHorizon? horizon,
    AtlasCanonicalRisk? risk,
    double? confidencePercent,
    double? decisionScore,
    double? expectedFinancialImpact,
    DateTime? deadline,
    List<String>? dependencies,
    List<String>? evidence,
  }) {
    return AtlasDecisionContract(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      generatedAt: generatedAt ?? this.generatedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      reasoning: reasoning ?? this.reasoning,
      expectedResult: expectedResult ?? this.expectedResult,
      sourceModule: sourceModule ?? this.sourceModule,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      horizon: horizon ?? this.horizon,
      risk: risk ?? this.risk,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      decisionScore: decisionScore ?? this.decisionScore,
      expectedFinancialImpact:
          expectedFinancialImpact ?? this.expectedFinancialImpact,
      deadline: deadline ?? this.deadline,
      dependencies: dependencies ?? this.dependencies,
      evidence: evidence ?? this.evidence,
    );
  }
}
