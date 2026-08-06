import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasImprovementCycle {
  const AtlasImprovementCycle({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.executionScore,
    required this.auditIndex,
    required this.classification,
    required this.summary,
    required this.decisions,
    required this.nextReviewDate,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final double executionScore;
  final double auditIndex;
  final AtlasImprovementCycleClassification classification;
  final String summary;
  final List<AtlasImprovementDecision> decisions;
  final DateTime nextReviewDate;

  int get criticalDecisions => decisions
      .where(
        (item) =>
            item.priority ==
            AtlasFarmAuditPriority.critical,
      )
      .length;

  int get recalibrationDecisions => decisions
      .where(
        (item) =>
            item.type ==
            AtlasImprovementDecisionType.recalibrate,
      )
      .length;

  int get correctionDecisions => decisions
      .where(
        (item) =>
            item.type ==
            AtlasImprovementDecisionType.correct,
      )
      .length;

  int get maintainDecisions => decisions
      .where(
        (item) =>
            item.type ==
            AtlasImprovementDecisionType.maintain,
      )
      .length;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'farmId': farmId,
      'farmName': farmName,
      'generatedAt': generatedAt.toIso8601String(),
      'executionScore': executionScore,
      'auditIndex': auditIndex,
      'classification': classification.name,
      'summary': summary,
      'decisions':
          decisions.map((item) => item.toJson()).toList(),
      'nextReviewDate': nextReviewDate.toIso8601String(),
    };
  }

  factory AtlasImprovementCycle.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasImprovementCycle(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Fazenda',
      generatedAt: DateTime.tryParse(
            json['generatedAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      executionScore:
          (json['executionScore'] as num?)?.toDouble() ?? 0,
      auditIndex:
          (json['auditIndex'] as num?)?.toDouble() ?? 0,
      classification:
          AtlasImprovementCycleClassification.values
              .firstWhere(
        (item) => item.name == json['classification'],
        orElse: () =>
            AtlasImprovementCycleClassification.attention,
      ),
      summary: json['summary'] as String? ?? '',
      decisions:
          (json['decisions'] as List? ?? const <dynamic>[])
              .whereType<Map>()
              .map(
                (item) => AtlasImprovementDecision.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
      nextReviewDate: DateTime.tryParse(
            json['nextReviewDate'] as String? ?? '',
          ) ??
          DateTime.now().add(const Duration(days: 30)),
    );
  }
}

class AtlasImprovementDecision {
  const AtlasImprovementDecision({
    required this.id,
    required this.area,
    required this.title,
    required this.explanation,
    required this.type,
    required this.priority,
    required this.currentValue,
    required this.targetValue,
    required this.deadlineDays,
    required this.expectedGain,
  });

  final String id;
  final AtlasFarmAuditArea area;
  final String title;
  final String explanation;
  final AtlasImprovementDecisionType type;
  final AtlasFarmAuditPriority priority;
  final double currentValue;
  final double targetValue;
  final int deadlineDays;
  final double expectedGain;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'area': area.name,
      'title': title,
      'explanation': explanation,
      'type': type.name,
      'priority': priority.name,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'deadlineDays': deadlineDays,
      'expectedGain': expectedGain,
    };
  }

  factory AtlasImprovementDecision.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasImprovementDecision(
      id: json['id'] as String? ?? '',
      area: AtlasFarmAuditArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasFarmAuditArea.operational,
      ),
      title: json['title'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      type: AtlasImprovementDecisionType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () =>
            AtlasImprovementDecisionType.monitor,
      ),
      priority: AtlasFarmAuditPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => AtlasFarmAuditPriority.moderate,
      ),
      currentValue:
          (json['currentValue'] as num?)?.toDouble() ?? 0,
      targetValue:
          (json['targetValue'] as num?)?.toDouble() ?? 85,
      deadlineDays:
          (json['deadlineDays'] as num?)?.toInt() ?? 30,
      expectedGain:
          (json['expectedGain'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum AtlasImprovementDecisionType {
  maintain,
  monitor,
  correct,
  recalibrate,
}

enum AtlasImprovementCycleClassification {
  excellent,
  controlled,
  attention,
  critical,
}

String atlasImprovementDecisionTypeLabel(
  AtlasImprovementDecisionType type,
) {
  switch (type) {
    case AtlasImprovementDecisionType.maintain:
      return 'Manter';
    case AtlasImprovementDecisionType.monitor:
      return 'Monitorar';
    case AtlasImprovementDecisionType.correct:
      return 'Corrigir';
    case AtlasImprovementDecisionType.recalibrate:
      return 'Recalibrar';
  }
}

String atlasImprovementCycleClassificationLabel(
  AtlasImprovementCycleClassification classification,
) {
  switch (classification) {
    case AtlasImprovementCycleClassification.excellent:
      return 'Excelente';
    case AtlasImprovementCycleClassification.controlled:
      return 'Controlado';
    case AtlasImprovementCycleClassification.attention:
      return 'Atenção';
    case AtlasImprovementCycleClassification.critical:
      return 'Crítico';
  }
}
