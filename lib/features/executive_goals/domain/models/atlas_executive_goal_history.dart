import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';

enum AtlasExecutiveGoalHistoryEventType {
  created,
  updated,
  targetChanged,
  deadlineChanged,
  responsibleChanged,
  progressUpdated,
  statusChanged,
  completed,
  reopened,
  cancelled,
  deleted,
}

enum AtlasExecutiveGoalRiskLevel { onTrack, attention, high, completed }

class AtlasExecutiveGoalHistoryEvent {
  const AtlasExecutiveGoalHistoryEvent({
    required this.id,
    required this.goalId,
    required this.farmName,
    required this.kpiTitle,
    required this.type,
    required this.recordedAt,
    required this.description,
    required this.progressPercent,
    required this.currentValue,
    required this.targetValue,
    required this.status,
  });

  final String id;
  final String goalId;
  final String farmName;
  final String kpiTitle;
  final AtlasExecutiveGoalHistoryEventType type;
  final DateTime recordedAt;
  final String description;
  final double progressPercent;
  final double currentValue;
  final double targetValue;
  final AtlasExecutiveGoalStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'goalId': goalId,
    'farmName': farmName,
    'kpiTitle': kpiTitle,
    'type': type.name,
    'recordedAt': recordedAt.toIso8601String(),
    'description': description,
    'progressPercent': progressPercent,
    'currentValue': currentValue,
    'targetValue': targetValue,
    'status': status.name,
  };

  factory AtlasExecutiveGoalHistoryEvent.fromJson(Map<String, dynamic> json) {
    return AtlasExecutiveGoalHistoryEvent(
      id: json['id']?.toString() ?? '',
      goalId: json['goalId']?.toString() ?? '',
      farmName: json['farmName']?.toString() ?? '',
      kpiTitle: json['kpiTitle']?.toString() ?? '',
      type: AtlasExecutiveGoalHistoryEventType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => AtlasExecutiveGoalHistoryEventType.updated,
      ),
      recordedAt:
          DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
      description: json['description']?.toString() ?? '',
      progressPercent: _double(json['progressPercent']),
      currentValue: _double(json['currentValue']),
      targetValue: _double(json['targetValue']),
      status: AtlasExecutiveGoalStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => AtlasExecutiveGoalStatus.active,
      ),
    );
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasExecutiveGoalHistorySeries {
  const AtlasExecutiveGoalHistorySeries({
    required this.goalId,
    required this.farmName,
    required this.kpiTitle,
    required this.events,
    required this.currentStatus,
    required this.currentProgressPercent,
    required this.averageDailyProgress,
    required this.projectedCompletionDate,
    required this.riskLevel,
  });

  final String goalId;
  final String farmName;
  final String kpiTitle;
  final List<AtlasExecutiveGoalHistoryEvent> events;
  final AtlasExecutiveGoalStatus currentStatus;
  final double currentProgressPercent;
  final double averageDailyProgress;
  final DateTime? projectedCompletionDate;
  final AtlasExecutiveGoalRiskLevel riskLevel;
}

class AtlasExecutiveGoalHistorySummary {
  const AtlasExecutiveGoalHistorySummary({
    required this.generatedAt,
    required this.summary,
    required this.series,
    required this.onTrack,
    required this.atRisk,
    required this.highRisk,
    required this.completed,
  });

  final DateTime generatedAt;
  final String summary;
  final List<AtlasExecutiveGoalHistorySeries> series;
  final int onTrack;
  final int atRisk;
  final int highRisk;
  final int completed;

  bool get hasHistory => series.isNotEmpty;
}

String atlasExecutiveGoalRiskLevelLabel(AtlasExecutiveGoalRiskLevel level) {
  switch (level) {
    case AtlasExecutiveGoalRiskLevel.onTrack:
      return 'No ritmo esperado';
    case AtlasExecutiveGoalRiskLevel.attention:
      return 'Atenção';
    case AtlasExecutiveGoalRiskLevel.high:
      return 'Alto risco';
    case AtlasExecutiveGoalRiskLevel.completed:
      return 'Concluída';
  }
}
