import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasBiManagementSummary {
  const AtlasBiManagementSummary({
    required this.generatedAt,
    required this.score,
    required this.statusLabel,
    required this.positiveTrends,
    required this.negativeTrends,
    required this.onTargetIndicators,
    required this.offTargetIndicators,
    required this.categorySummaries,
    required this.priorities,
  });

  final DateTime generatedAt;
  final double score;
  final String statusLabel;
  final int positiveTrends;
  final int negativeTrends;
  final int onTargetIndicators;
  final int offTargetIndicators;
  final List<AtlasBiCategorySummary> categorySummaries;
  final List<AtlasBiManagementPriority> priorities;
}

class AtlasBiCategorySummary {
  const AtlasBiCategorySummary({
    required this.category,
    required this.averageAchievement,
    required this.indicatorCount,
    required this.criticalCount,
  });

  final AtlasBiCategory category;
  final double averageAchievement;
  final int indicatorCount;
  final int criticalCount;
}

class AtlasBiManagementPriority {
  const AtlasBiManagementPriority({
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.recommendedAction,
  });

  final String title;
  final String description;
  final AtlasBiCategory category;
  final AtlasBiPriority urgency;
  final String recommendedAction;
}
