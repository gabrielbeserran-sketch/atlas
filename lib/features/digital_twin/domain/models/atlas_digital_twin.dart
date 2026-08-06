class AtlasDigitalTwin {
  const AtlasDigitalTwin({
    required this.farmId,
    required this.farmName,
    required this.createdAt,
    required this.updatedAt,
    required this.overallScore,
    required this.trend,
    required this.health,
    required this.risks,
    required this.timeline,
    required this.totalProcessedEvents,
    required this.lastEventId,
  });

  final String farmId;
  final String farmName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double overallScore;
  final AtlasDigitalTwinTrend trend;
  final AtlasFarmHealth health;
  final List<AtlasFarmRisk> risks;
  final List<AtlasFarmTimelineEvent> timeline;
  final int totalProcessedEvents;
  final String? lastEventId;

  factory AtlasDigitalTwin.initial({
    required String farmId,
    required String farmName,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    return AtlasDigitalTwin(
      farmId: farmId,
      farmName: farmName,
      createdAt: current,
      updatedAt: current,
      overallScore: 75,
      trend: AtlasDigitalTwinTrend.stable,
      health: const AtlasFarmHealth(
        animal: 75,
        sanitary: 75,
        reproductive: 75,
        financial: 75,
        inventory: 75,
        operational: 75,
      ),
      risks: const <AtlasFarmRisk>[],
      timeline: const <AtlasFarmTimelineEvent>[],
      totalProcessedEvents: 0,
      lastEventId: null,
    );
  }

  AtlasDigitalTwin copyWith({
    String? farmId,
    String? farmName,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? overallScore,
    AtlasDigitalTwinTrend? trend,
    AtlasFarmHealth? health,
    List<AtlasFarmRisk>? risks,
    List<AtlasFarmTimelineEvent>? timeline,
    int? totalProcessedEvents,
    String? lastEventId,
  }) {
    return AtlasDigitalTwin(
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      overallScore: overallScore ?? this.overallScore,
      trend: trend ?? this.trend,
      health: health ?? this.health,
      risks: risks ?? this.risks,
      timeline: timeline ?? this.timeline,
      totalProcessedEvents:
          totalProcessedEvents ?? this.totalProcessedEvents,
      lastEventId: lastEventId ?? this.lastEventId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'farmId': farmId,
      'farmName': farmName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'overallScore': overallScore,
      'trend': trend.name,
      'health': health.toJson(),
      'risks': risks.map((item) => item.toJson()).toList(),
      'timeline': timeline.map((item) => item.toJson()).toList(),
      'totalProcessedEvents': totalProcessedEvents,
      'lastEventId': lastEventId,
    };
  }

  factory AtlasDigitalTwin.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasDigitalTwin(
      farmId: json['farmId'] as String? ?? 'global',
      farmName: json['farmName'] as String? ?? 'Operação',
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
            json['updatedAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      overallScore:
          (json['overallScore'] as num?)?.toDouble() ?? 75,
      trend: AtlasDigitalTwinTrend.values.firstWhere(
        (item) => item.name == json['trend'],
        orElse: () => AtlasDigitalTwinTrend.stable,
      ),
      health: AtlasFarmHealth.fromJson(
        Map<String, dynamic>.from(
          json['health'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      risks: (json['risks'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => AtlasFarmRisk.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      timeline: (json['timeline'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => AtlasFarmTimelineEvent.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      totalProcessedEvents:
          json['totalProcessedEvents'] as int? ?? 0,
      lastEventId: json['lastEventId'] as String?,
    );
  }
}

class AtlasFarmHealth {
  const AtlasFarmHealth({
    required this.animal,
    required this.sanitary,
    required this.reproductive,
    required this.financial,
    required this.inventory,
    required this.operational,
  });

  final double animal;
  final double sanitary;
  final double reproductive;
  final double financial;
  final double inventory;
  final double operational;

  AtlasFarmHealth copyWith({
    double? animal,
    double? sanitary,
    double? reproductive,
    double? financial,
    double? inventory,
    double? operational,
  }) {
    return AtlasFarmHealth(
      animal: animal ?? this.animal,
      sanitary: sanitary ?? this.sanitary,
      reproductive: reproductive ?? this.reproductive,
      financial: financial ?? this.financial,
      inventory: inventory ?? this.inventory,
      operational: operational ?? this.operational,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'animal': animal,
      'sanitary': sanitary,
      'reproductive': reproductive,
      'financial': financial,
      'inventory': inventory,
      'operational': operational,
    };
  }

  factory AtlasFarmHealth.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasFarmHealth(
      animal: (json['animal'] as num?)?.toDouble() ?? 75,
      sanitary: (json['sanitary'] as num?)?.toDouble() ?? 75,
      reproductive:
          (json['reproductive'] as num?)?.toDouble() ?? 75,
      financial:
          (json['financial'] as num?)?.toDouble() ?? 75,
      inventory:
          (json['inventory'] as num?)?.toDouble() ?? 75,
      operational:
          (json['operational'] as num?)?.toDouble() ?? 75,
    );
  }
}

class AtlasFarmRisk {
  const AtlasFarmRisk({
    required this.id,
    required this.area,
    required this.title,
    required this.description,
    required this.score,
    required this.level,
    required this.updatedAt,
    required this.sourceEventType,
  });

  final String id;
  final AtlasDigitalTwinArea area;
  final String title;
  final String description;
  final double score;
  final AtlasFarmRiskLevel level;
  final DateTime updatedAt;
  final String sourceEventType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'area': area.name,
      'title': title,
      'description': description,
      'score': score,
      'level': level.name,
      'updatedAt': updatedAt.toIso8601String(),
      'sourceEventType': sourceEventType,
    };
  }

  factory AtlasFarmRisk.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasFarmRisk(
      id: json['id'] as String? ?? 'risk_unknown',
      area: AtlasDigitalTwinArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasDigitalTwinArea.operational,
      ),
      title: json['title'] as String? ?? 'Risco',
      description: json['description'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      level: AtlasFarmRiskLevel.values.firstWhere(
        (item) => item.name == json['level'],
        orElse: () => AtlasFarmRiskLevel.low,
      ),
      updatedAt: DateTime.tryParse(
            json['updatedAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      sourceEventType:
          json['sourceEventType'] as String? ?? 'unknown',
    );
  }
}

class AtlasFarmTimelineEvent {
  const AtlasFarmTimelineEvent({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.area,
    required this.impact,
    required this.occurredAt,
    required this.scoreBefore,
    required this.scoreAfter,
  });

  final String id;
  final String eventId;
  final String title;
  final String description;
  final AtlasDigitalTwinArea area;
  final AtlasDigitalTwinImpact impact;
  final DateTime occurredAt;
  final double scoreBefore;
  final double scoreAfter;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'area': area.name,
      'impact': impact.name,
      'occurredAt': occurredAt.toIso8601String(),
      'scoreBefore': scoreBefore,
      'scoreAfter': scoreAfter,
    };
  }

  factory AtlasFarmTimelineEvent.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasFarmTimelineEvent(
      id: json['id'] as String? ?? 'timeline_unknown',
      eventId: json['eventId'] as String? ?? 'event_unknown',
      title: json['title'] as String? ?? 'Evento',
      description: json['description'] as String? ?? '',
      area: AtlasDigitalTwinArea.values.firstWhere(
        (item) => item.name == json['area'],
        orElse: () => AtlasDigitalTwinArea.operational,
      ),
      impact: AtlasDigitalTwinImpact.values.firstWhere(
        (item) => item.name == json['impact'],
        orElse: () => AtlasDigitalTwinImpact.neutral,
      ),
      occurredAt: DateTime.tryParse(
            json['occurredAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      scoreBefore:
          (json['scoreBefore'] as num?)?.toDouble() ?? 0,
      scoreAfter:
          (json['scoreAfter'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum AtlasDigitalTwinArea {
  animal,
  sanitary,
  reproductive,
  financial,
  inventory,
  operational,
}

enum AtlasDigitalTwinTrend {
  improving,
  stable,
  worsening,
}

enum AtlasDigitalTwinImpact {
  positive,
  neutral,
  negative,
  critical,
}

enum AtlasFarmRiskLevel {
  low,
  moderate,
  high,
  critical,
}

String atlasDigitalTwinAreaLabel(
  AtlasDigitalTwinArea area,
) {
  switch (area) {
    case AtlasDigitalTwinArea.animal:
      return 'Desempenho animal';
    case AtlasDigitalTwinArea.sanitary:
      return 'Sanidade';
    case AtlasDigitalTwinArea.reproductive:
      return 'Reprodução';
    case AtlasDigitalTwinArea.financial:
      return 'Financeiro';
    case AtlasDigitalTwinArea.inventory:
      return 'Estoque';
    case AtlasDigitalTwinArea.operational:
      return 'Operacional';
  }
}

String atlasDigitalTwinTrendLabel(
  AtlasDigitalTwinTrend trend,
) {
  switch (trend) {
    case AtlasDigitalTwinTrend.improving:
      return 'Melhorando';
    case AtlasDigitalTwinTrend.stable:
      return 'Estável';
    case AtlasDigitalTwinTrend.worsening:
      return 'Piorando';
  }
}

String atlasFarmRiskLevelLabel(
  AtlasFarmRiskLevel level,
) {
  switch (level) {
    case AtlasFarmRiskLevel.low:
      return 'Baixo';
    case AtlasFarmRiskLevel.moderate:
      return 'Moderado';
    case AtlasFarmRiskLevel.high:
      return 'Alto';
    case AtlasFarmRiskLevel.critical:
      return 'Crítico';
  }
}
