import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';

class AtlasFarmAudit {
  const AtlasFarmAudit({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.overallIndex,
    required this.classification,
    required this.diagnosis,
    required this.areaResults,
    required this.problems,
    required this.opportunities,
    required this.digitalTwinScore,
    required this.trend,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final double overallIndex;
  final AtlasFarmAuditClassification classification;
  final String diagnosis;
  final List<AtlasFarmAuditAreaResult> areaResults;
  final List<AtlasFarmAuditProblem> problems;
  final List<AtlasFarmAuditOpportunity> opportunities;
  final double digitalTwinScore;
  final AtlasDigitalTwinTrend trend;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'farmId': farmId,
      'farmName': farmName,
      'generatedAt': generatedAt.toIso8601String(),
      'overallIndex': overallIndex,
      'classification': classification.name,
      'diagnosis': diagnosis,
      'areaResults': areaResults.map((item) => item.toJson()).toList(),
      'problems': problems.map((item) => item.toJson()).toList(),
      'opportunities': opportunities.map((item) => item.toJson()).toList(),
      'digitalTwinScore': digitalTwinScore,
      'trend': trend.name,
    };
  }

  factory AtlasFarmAudit.fromJson(Map<String, dynamic> json) {
    return AtlasFarmAudit(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Fazenda',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      overallIndex: (json['overallIndex'] as num?)?.toDouble() ?? 0,
      classification: AtlasFarmAuditClassification.values.firstWhere(
        (item) => item.name == json['classification'],
        orElse: () => AtlasFarmAuditClassification.attention,
      ),
      diagnosis: json['diagnosis'] as String? ?? '',
      areaResults: (json['areaResults'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => AtlasFarmAuditAreaResult.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      problems: (json['problems'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) =>
                AtlasFarmAuditProblem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      opportunities: (json['opportunities'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => AtlasFarmAuditOpportunity.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      digitalTwinScore: (json['digitalTwinScore'] as num?)?.toDouble() ?? 0,
      trend: AtlasDigitalTwinTrend.values.firstWhere(
        (item) => item.name == json['trend'],
        orElse: () => AtlasDigitalTwinTrend.stable,
      ),
    );
  }
}

class AtlasFarmAuditAreaResult {
  const AtlasFarmAuditAreaResult({
    required this.area,
    required this.score,
    required this.weight,
    required this.status,
    required this.summary,
  });

  final AtlasFarmAuditArea area;
  final double score;
  final double weight;
  final AtlasFarmAuditAreaStatus status;
  final String summary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'area': area.name,
      'score': score,
      'weight': weight,
      'status': status.name,
      'summary': summary,
    };
  }

  factory AtlasFarmAuditAreaResult.fromJson(Map<String, dynamic> json) {
    return AtlasFarmAuditAreaResult(
      area: AtlasFarmAuditArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasFarmAuditArea.operational,
      ),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
      status: AtlasFarmAuditAreaStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => AtlasFarmAuditAreaStatus.attention,
      ),
      summary: json['summary'] as String? ?? '',
    );
  }
}

class AtlasFarmAuditProblem {
  const AtlasFarmAuditProblem({
    required this.id,
    required this.area,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedAnnualImpact,
    required this.recommendedDeadlineDays,
  });

  final String id;
  final AtlasFarmAuditArea area;
  final String title;
  final String description;
  final AtlasFarmAuditPriority priority;
  final double estimatedAnnualImpact;
  final int recommendedDeadlineDays;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'area': area.name,
      'title': title,
      'description': description,
      'priority': priority.name,
      'estimatedAnnualImpact': estimatedAnnualImpact,
      'recommendedDeadlineDays': recommendedDeadlineDays,
    };
  }

  factory AtlasFarmAuditProblem.fromJson(Map<String, dynamic> json) {
    return AtlasFarmAuditProblem(
      id: json['id'] as String? ?? '',
      area: AtlasFarmAuditArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasFarmAuditArea.operational,
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: AtlasFarmAuditPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => AtlasFarmAuditPriority.moderate,
      ),
      estimatedAnnualImpact:
          (json['estimatedAnnualImpact'] as num?)?.toDouble() ?? 0,
      recommendedDeadlineDays: json['recommendedDeadlineDays'] as int? ?? 30,
    );
  }
}

class AtlasFarmAuditOpportunity {
  const AtlasFarmAuditOpportunity({
    required this.id,
    required this.area,
    required this.title,
    required this.description,
    required this.estimatedInvestment,
    required this.estimatedReturn,
    required this.roiPercent,
    required this.priority,
  });

  final String id;
  final AtlasFarmAuditArea area;
  final String title;
  final String description;
  final double estimatedInvestment;
  final double estimatedReturn;
  final double roiPercent;
  final AtlasFarmAuditPriority priority;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'area': area.name,
      'title': title,
      'description': description,
      'estimatedInvestment': estimatedInvestment,
      'estimatedReturn': estimatedReturn,
      'roiPercent': roiPercent,
      'priority': priority.name,
    };
  }

  factory AtlasFarmAuditOpportunity.fromJson(Map<String, dynamic> json) {
    return AtlasFarmAuditOpportunity(
      id: json['id'] as String? ?? '',
      area: AtlasFarmAuditArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasFarmAuditArea.operational,
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      estimatedInvestment:
          (json['estimatedInvestment'] as num?)?.toDouble() ?? 0,
      estimatedReturn: (json['estimatedReturn'] as num?)?.toDouble() ?? 0,
      roiPercent: (json['roiPercent'] as num?)?.toDouble() ?? 0,
      priority: AtlasFarmAuditPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => AtlasFarmAuditPriority.moderate,
      ),
    );
  }
}

enum AtlasFarmAuditArea {
  nutrition,
  sanitary,
  reproduction,
  animalWelfare,
  genetics,
  pastures,
  financial,
  inventory,
  operational,
  people,
  biosecurity,
  sustainability,
}

enum AtlasFarmAuditClassification { excellent, good, attention, critical }

enum AtlasFarmAuditAreaStatus { excellent, good, attention, critical }

enum AtlasFarmAuditPriority { low, moderate, high, critical }

String atlasFarmAuditAreaLabel(AtlasFarmAuditArea area) {
  switch (area) {
    case AtlasFarmAuditArea.nutrition:
      return 'Nutrição';
    case AtlasFarmAuditArea.sanitary:
      return 'Sanidade';
    case AtlasFarmAuditArea.reproduction:
      return 'Reprodução';
    case AtlasFarmAuditArea.animalWelfare:
      return 'Bem-estar animal';
    case AtlasFarmAuditArea.genetics:
      return 'Genética';
    case AtlasFarmAuditArea.pastures:
      return 'Pastagens';
    case AtlasFarmAuditArea.financial:
      return 'Financeiro';
    case AtlasFarmAuditArea.inventory:
      return 'Estoque';
    case AtlasFarmAuditArea.operational:
      return 'Operacional';
    case AtlasFarmAuditArea.people:
      return 'Pessoas';
    case AtlasFarmAuditArea.biosecurity:
      return 'Biossegurança';
    case AtlasFarmAuditArea.sustainability:
      return 'Sustentabilidade';
  }
}

String atlasFarmAuditClassificationLabel(
  AtlasFarmAuditClassification classification,
) {
  switch (classification) {
    case AtlasFarmAuditClassification.excellent:
      return 'Excelente';
    case AtlasFarmAuditClassification.good:
      return 'Bom';
    case AtlasFarmAuditClassification.attention:
      return 'Atenção';
    case AtlasFarmAuditClassification.critical:
      return 'Crítico';
  }
}

String atlasFarmAuditAreaStatusLabel(AtlasFarmAuditAreaStatus status) {
  switch (status) {
    case AtlasFarmAuditAreaStatus.excellent:
      return 'Excelente';
    case AtlasFarmAuditAreaStatus.good:
      return 'Bom';
    case AtlasFarmAuditAreaStatus.attention:
      return 'Atenção';
    case AtlasFarmAuditAreaStatus.critical:
      return 'Crítico';
  }
}

String atlasFarmAuditPriorityLabel(AtlasFarmAuditPriority priority) {
  switch (priority) {
    case AtlasFarmAuditPriority.low:
      return 'Baixa';
    case AtlasFarmAuditPriority.moderate:
      return 'Moderada';
    case AtlasFarmAuditPriority.high:
      return 'Alta';
    case AtlasFarmAuditPriority.critical:
      return 'Crítica';
  }
}
