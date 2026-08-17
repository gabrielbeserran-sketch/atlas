import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';

class AtlasIntelligentRecommendation {
  const AtlasIntelligentRecommendation({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.area,
    required this.title,
    required this.diagnosis,
    required this.recommendedProtocol,
    required this.justification,
    required this.priority,
    required this.confidence,
    required this.similarCases,
    required this.successRate,
    required this.averageResponseDays,
    required this.expectedEconomicGain,
    required this.currentScore,
    required this.targetScore,
    required this.steps,
    required this.risks,
    required this.evidence,
  });

  final String id;
  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final AtlasFarmAuditArea area;
  final String title;
  final String diagnosis;
  final String recommendedProtocol;
  final String justification;
  final AtlasFarmAuditPriority priority;
  final double confidence;
  final int similarCases;
  final double successRate;
  final double averageResponseDays;
  final double expectedEconomicGain;
  final double currentScore;
  final double targetScore;
  final List<String> steps;
  final List<String> risks;
  final List<String> evidence;

  double get expectedScoreGain {
    return (targetScore - currentScore).clamp(0.0, 100.0).toDouble();
  }
}

class AtlasRecommendationPortfolio {
  const AtlasRecommendationPortfolio({
    required this.farmId,
    required this.farmName,
    required this.generatedAt,
    required this.auditIndex,
    required this.recommendations,
  });

  final String farmId;
  final String farmName;
  final DateTime generatedAt;
  final double auditIndex;
  final List<AtlasIntelligentRecommendation> recommendations;

  int get criticalRecommendations {
    return recommendations
        .where((item) => item.priority == AtlasFarmAuditPriority.critical)
        .length;
  }

  double get averageConfidence {
    if (recommendations.isEmpty) {
      return 0;
    }

    return recommendations.fold<double>(
          0,
          (sum, item) => sum + item.confidence,
        ) /
        recommendations.length;
  }

  double get expectedEconomicGain {
    return recommendations.fold<double>(
      0,
      (sum, item) => sum + item.expectedEconomicGain,
    );
  }

  int get evidenceCases {
    return recommendations.fold<int>(0, (sum, item) => sum + item.similarCases);
  }
}
