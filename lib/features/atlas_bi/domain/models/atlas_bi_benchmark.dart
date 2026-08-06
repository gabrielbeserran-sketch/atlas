import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasBiBenchmarkData {
  const AtlasBiBenchmarkData({
    required this.generatedAt,
    required this.summary,
    required this.farms,
    required this.indicators,
    required this.leadingFarmName,
    required this.averageScore,
  });

  final DateTime generatedAt;
  final String summary;

  final List<AtlasBiBenchmarkFarm> farms;
  final List<AtlasBiBenchmarkIndicator> indicators;

  final String? leadingFarmName;
  final double averageScore;

  bool get hasData {
    return farms.isNotEmpty;
  }
}

class AtlasBiBenchmarkFarm {
  const AtlasBiBenchmarkFarm({
    required this.position,
    required this.farmName,
    required this.score,
    required this.distanceFromLeader,
    required this.status,
    required this.strongIndicators,
    required this.attentionIndicators,
    required this.criticalIndicators,
    required this.bestIndicatorTitle,
    required this.mainGapTitle,
  });

  final int position;
  final String farmName;

  final double score;
  final double distanceFromLeader;

  final AtlasBiStatus status;

  final int strongIndicators;
  final int attentionIndicators;
  final int criticalIndicators;

  final String? bestIndicatorTitle;
  final String? mainGapTitle;

  bool get isLeader {
    return position == 1;
  }
}

class AtlasBiBenchmarkIndicator {
  const AtlasBiBenchmarkIndicator({
    required this.indicatorId,
    required this.title,
    required this.category,
    required this.unit,
    required this.referenceValue,
    required this.averageValue,
    required this.bestFarmName,
    required this.worstFarmName,
    required this.farmResults,
  });

  final String indicatorId;
  final String title;

  final AtlasBiCategory category;
  final String unit;

  final double referenceValue;
  final double averageValue;

  final String? bestFarmName;
  final String? worstFarmName;

  final List<AtlasBiBenchmarkFarmResult> farmResults;
}

class AtlasBiBenchmarkFarmResult {
  const AtlasBiBenchmarkFarmResult({
    required this.farmName,
    required this.currentValue,
    required this.targetAchievementPercent,
    required this.distanceFromReferencePercent,
    required this.status,
  });

  final String farmName;

  final double currentValue;
  final double targetAchievementPercent;
  final double distanceFromReferencePercent;

  final AtlasBiStatus status;
}

class AtlasBiBenchmarkOpportunity {
  const AtlasBiBenchmarkOpportunity({
    required this.farmName,
    required this.indicatorTitle,
    required this.category,
    required this.currentValue,
    required this.referenceValue,
    required this.unit,
    required this.gapPercent,
    required this.recommendation,
  });

  final String farmName;
  final String indicatorTitle;

  final AtlasBiCategory category;

  final double currentValue;
  final double referenceValue;

  final String unit;
  final double gapPercent;

  final String recommendation;
}
