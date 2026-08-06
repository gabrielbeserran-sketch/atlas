import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';

class AtlasExecutiveBrainHistoryEntry {
  const AtlasExecutiveBrainHistoryEntry({
    required this.id,
    required this.recordedAt,
    required this.changeType,
    required this.previousDecisionId,
    required this.currentDecisionId,
    required this.previousDecisionTitle,
    required this.currentDecisionTitle,
    required this.previousScore,
    required this.currentScore,
    required this.previousConfidencePercent,
    required this.currentConfidencePercent,
    required this.currentStatus,
    required this.reason,
  });

  final String id;
  final DateTime recordedAt;
  final AtlasExecutiveBrainChangeType changeType;
  final String? previousDecisionId;
  final String? currentDecisionId;
  final String? previousDecisionTitle;
  final String? currentDecisionTitle;
  final double? previousScore;
  final double currentScore;
  final double? previousConfidencePercent;
  final double currentConfidencePercent;
  final AtlasExecutiveBrainStatus currentStatus;
  final String reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'recordedAt': recordedAt.toIso8601String(),
      'changeType': changeType.name,
      'previousDecisionId': previousDecisionId,
      'currentDecisionId': currentDecisionId,
      'previousDecisionTitle': previousDecisionTitle,
      'currentDecisionTitle': currentDecisionTitle,
      'previousScore': previousScore,
      'currentScore': currentScore,
      'previousConfidencePercent': previousConfidencePercent,
      'currentConfidencePercent': currentConfidencePercent,
      'currentStatus': currentStatus.name,
      'reason': reason,
    };
  }

  factory AtlasExecutiveBrainHistoryEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasExecutiveBrainHistoryEntry(
      id: json['id'] as String? ?? 'brain_history_unknown',
      recordedAt: DateTime.tryParse(
            json['recordedAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      changeType: AtlasExecutiveBrainChangeType.values.firstWhere(
        (item) => item.name == json['changeType'],
        orElse: () => AtlasExecutiveBrainChangeType.scoreChanged,
      ),
      previousDecisionId: json['previousDecisionId'] as String?,
      currentDecisionId: json['currentDecisionId'] as String?,
      previousDecisionTitle: json['previousDecisionTitle'] as String?,
      currentDecisionTitle: json['currentDecisionTitle'] as String?,
      previousScore: (json['previousScore'] as num?)?.toDouble(),
      currentScore: (json['currentScore'] as num?)?.toDouble() ?? 0,
      previousConfidencePercent:
          (json['previousConfidencePercent'] as num?)?.toDouble(),
      currentConfidencePercent:
          (json['currentConfidencePercent'] as num?)?.toDouble() ?? 0,
      currentStatus: AtlasExecutiveBrainStatus.values.firstWhere(
        (item) => item.name == json['currentStatus'],
        orElse: () => AtlasExecutiveBrainStatus.attention,
      ),
      reason: json['reason'] as String? ??
          'Mudança executiva registrada.',
    );
  }
}

enum AtlasExecutiveBrainChangeType {
  initialized,
  decisionChanged,
  decisionRemoved,
  priorityChanged,
  scoreChanged,
  strategyChanged,
}

String atlasExecutiveBrainChangeTypeLabel(
  AtlasExecutiveBrainChangeType type,
) {
  switch (type) {
    case AtlasExecutiveBrainChangeType.initialized:
      return 'Inicialização';
    case AtlasExecutiveBrainChangeType.decisionChanged:
      return 'Decisão alterada';
    case AtlasExecutiveBrainChangeType.decisionRemoved:
      return 'Decisão removida';
    case AtlasExecutiveBrainChangeType.priorityChanged:
      return 'Prioridade alterada';
    case AtlasExecutiveBrainChangeType.scoreChanged:
      return 'Score alterado';
    case AtlasExecutiveBrainChangeType.strategyChanged:
      return 'Estratégia alterada';
  }
}
