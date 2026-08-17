import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

enum AtlasKnowledgeSource { manual, executionCycle, predictionFeedback }

enum AtlasKnowledgeStatus { draft, validated, bestPractice, needsReview }

class AtlasKnowledgeCase {
  const AtlasKnowledgeCase({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.createdAt,
    required this.area,
    required this.problem,
    required this.intervention,
    required this.outcome,
    required this.beforeValue,
    required this.afterValue,
    required this.responseDays,
    required this.economicGain,
    required this.success,
    required this.lessons,
    this.predictedValue,
    this.predictedEconomicGain,
    this.source = AtlasKnowledgeSource.manual,
    this.status = AtlasKnowledgeStatus.validated,
    this.recommendationImplemented = true,
    this.notes = '',
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime createdAt;
  final AtlasFarmAuditArea area;
  final String problem;
  final String intervention;
  final String outcome;
  final double beforeValue;
  final double afterValue;
  final int responseDays;
  final double economicGain;
  final bool success;
  final List<String> lessons;
  final double? predictedValue;
  final double? predictedEconomicGain;
  final AtlasKnowledgeSource source;
  final AtlasKnowledgeStatus status;
  final bool recommendationImplemented;
  final String notes;

  double get improvement => afterValue - beforeValue;

  double? get predictionAccuracy {
    if (predictedValue == null) return null;
    final denominator = predictedValue!.abs().clamp(1.0, double.infinity);
    return (100 - ((afterValue - predictedValue!).abs() / denominator * 100))
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasKnowledgeCase copyWith({AtlasKnowledgeStatus? status}) =>
      AtlasKnowledgeCase(
        id: id,
        farmId: farmId,
        farmName: farmName,
        createdAt: createdAt,
        area: area,
        problem: problem,
        intervention: intervention,
        outcome: outcome,
        beforeValue: beforeValue,
        afterValue: afterValue,
        responseDays: responseDays,
        economicGain: economicGain,
        success: success,
        lessons: lessons,
        predictedValue: predictedValue,
        predictedEconomicGain: predictedEconomicGain,
        source: source,
        status: status ?? this.status,
        recommendationImplemented: recommendationImplemented,
        notes: notes,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'farmId': farmId,
    'farmName': farmName,
    'createdAt': createdAt.toIso8601String(),
    'area': area.name,
    'problem': problem,
    'intervention': intervention,
    'outcome': outcome,
    'beforeValue': beforeValue,
    'afterValue': afterValue,
    'responseDays': responseDays,
    'economicGain': economicGain,
    'success': success,
    'lessons': lessons,
    'predictedValue': predictedValue,
    'predictedEconomicGain': predictedEconomicGain,
    'source': source.name,
    'status': status.name,
    'recommendationImplemented': recommendationImplemented,
    'notes': notes,
  };

  factory AtlasKnowledgeCase.fromJson(Map<String, dynamic> json) {
    return AtlasKnowledgeCase(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Fazenda',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      area: AtlasFarmAuditArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasFarmAuditArea.operational,
      ),
      problem: json['problem'] as String? ?? '',
      intervention: json['intervention'] as String? ?? '',
      outcome: json['outcome'] as String? ?? '',
      beforeValue: (json['beforeValue'] as num?)?.toDouble() ?? 0,
      afterValue: (json['afterValue'] as num?)?.toDouble() ?? 0,
      responseDays: (json['responseDays'] as num?)?.toInt() ?? 0,
      economicGain: (json['economicGain'] as num?)?.toDouble() ?? 0,
      success: json['success'] as bool? ?? false,
      lessons: (json['lessons'] as List? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      predictedValue: (json['predictedValue'] as num?)?.toDouble(),
      predictedEconomicGain: (json['predictedEconomicGain'] as num?)
          ?.toDouble(),
      source: AtlasKnowledgeSource.values.firstWhere(
        (item) => item.name == json['source'],
        orElse: () => AtlasKnowledgeSource.manual,
      ),
      status: AtlasKnowledgeStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => AtlasKnowledgeStatus.validated,
      ),
      recommendationImplemented:
          json['recommendationImplemented'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class AtlasKnowledgeProtocol {
  const AtlasKnowledgeProtocol({
    required this.id,
    required this.area,
    required this.title,
    required this.description,
    required this.caseCount,
    required this.successRate,
    required this.averageResponseDays,
    required this.averageEconomicGain,
    required this.confidence,
    required this.lastUpdatedAt,
  });

  final String id;
  final AtlasFarmAuditArea area;
  final String title;
  final String description;
  final int caseCount;
  final double successRate;
  final double averageResponseDays;
  final double averageEconomicGain;
  final double confidence;
  final DateTime lastUpdatedAt;
}

class AtlasKnowledgeOverview {
  const AtlasKnowledgeOverview({required this.cases, required this.protocols});

  final List<AtlasKnowledgeCase> cases;
  final List<AtlasKnowledgeProtocol> protocols;

  int get learnedCases => cases.length;
  int get activeProtocols => protocols.length;
  int get bestPractices => cases
      .where((item) => item.status == AtlasKnowledgeStatus.bestPractice)
      .length;
  int get implementedRecommendations =>
      cases.where((item) => item.recommendationImplemented).length;

  double get successRate => cases.isEmpty
      ? 0
      : cases.where((item) => item.success).length / cases.length * 100;
  double get implementationRate =>
      cases.isEmpty ? 0 : implementedRecommendations / cases.length * 100;
  double get averageResponseDays => cases.isEmpty
      ? 0
      : cases.fold<double>(0, (sum, item) => sum + item.responseDays) /
            cases.length;
  double get averageEconomicGain => cases.isEmpty
      ? 0
      : cases.fold<double>(0, (sum, item) => sum + item.economicGain) /
            cases.length;

  double get averagePredictionAccuracy {
    final values = cases
        .map((item) => item.predictionAccuracy)
        .whereType<double>()
        .toList();
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  }
}
