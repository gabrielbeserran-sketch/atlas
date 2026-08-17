import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasComparativeDiagnosticData {
  const AtlasComparativeDiagnosticData({
    required this.generatedAt,
    required this.operationAverageScore,
    required this.operationLevel,
    required this.summary,
    required this.ranking,
    required this.areaComparisons,
    required this.highlights,
    required this.priorities,
  });

  final DateTime generatedAt;

  final double operationAverageScore;
  final AtlasDiagnosticLevel operationLevel;

  final String summary;

  final List<AtlasComparativeFarmRanking> ranking;
  final List<AtlasComparativeAreaData> areaComparisons;
  final List<AtlasComparativeHighlight> highlights;
  final List<AtlasComparativePriority> priorities;

  AtlasComparativeFarmRanking? get bestFarm {
    if (ranking.isEmpty) {
      return null;
    }

    return ranking.first;
  }

  AtlasComparativeFarmRanking? get mostCriticalFarm {
    if (ranking.isEmpty) {
      return null;
    }

    return ranking.last;
  }

  int get farmCount {
    return ranking.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'operationAverageScore': operationAverageScore,
      'operationLevel': operationLevel.name,
      'summary': summary,
      'ranking': ranking.map((item) {
        return item.toJson();
      }).toList(),
      'areaComparisons': areaComparisons.map((item) {
        return item.toJson();
      }).toList(),
      'highlights': highlights.map((item) {
        return item.toJson();
      }).toList(),
      'priorities': priorities.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class AtlasComparativeFarmRanking {
  const AtlasComparativeFarmRanking({
    required this.position,
    required this.farmName,
    required this.score,
    required this.level,
    required this.differenceFromAverage,
    required this.mainPriority,
    required this.criticalRiskCount,
    required this.bottleneckCount,
    required this.opportunityCount,
  });

  final int position;
  final String farmName;

  final double score;
  final AtlasDiagnosticLevel level;
  final double differenceFromAverage;

  final String mainPriority;

  final int criticalRiskCount;
  final int bottleneckCount;
  final int opportunityCount;

  bool get isAboveAverage {
    return differenceFromAverage > 0;
  }

  bool get isBelowAverage {
    return differenceFromAverage < 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'farmName': farmName,
      'score': score,
      'level': level.name,
      'differenceFromAverage': differenceFromAverage,
      'mainPriority': mainPriority,
      'criticalRiskCount': criticalRiskCount,
      'bottleneckCount': bottleneckCount,
      'opportunityCount': opportunityCount,
    };
  }
}

class AtlasComparativeAreaData {
  const AtlasComparativeAreaData({
    required this.area,
    required this.title,
    required this.averageScore,
    required this.bestFarmName,
    required this.bestScore,
    required this.worstFarmName,
    required this.worstScore,
    required this.amplitude,
    required this.level,
  });

  final AtlasFarmAnalysisArea area;
  final String title;

  final double averageScore;

  final String bestFarmName;
  final double bestScore;

  final String worstFarmName;
  final double worstScore;

  final double amplitude;
  final AtlasDiagnosticLevel level;

  Map<String, dynamic> toJson() {
    return {
      'area': area.name,
      'title': title,
      'averageScore': averageScore,
      'bestFarmName': bestFarmName,
      'bestScore': bestScore,
      'worstFarmName': worstFarmName,
      'worstScore': worstScore,
      'amplitude': amplitude,
      'level': level.name,
    };
  }
}

class AtlasComparativeHighlight {
  const AtlasComparativeHighlight({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.type,
    required this.level,
    required this.farmName,
    required this.area,
  });

  final String id;
  final String title;
  final String description;
  final String recommendation;

  final AtlasComparativeHighlightType type;
  final AtlasDiagnosticLevel level;

  final String? farmName;
  final AtlasFarmAnalysisArea? area;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'type': type.name,
      'level': level.name,
      'farmName': farmName,
      'area': area?.name,
    };
  }
}

class AtlasComparativePriority {
  const AtlasComparativePriority({
    required this.position,
    required this.farmName,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.area,
    required this.level,
    required this.priorityScore,
  });

  final int position;
  final String farmName;

  final String title;
  final String description;
  final String recommendation;

  final AtlasFarmAnalysisArea area;
  final AtlasDiagnosticLevel level;

  final double priorityScore;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'farmName': farmName,
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'area': area.name,
      'level': level.name,
      'priorityScore': priorityScore,
    };
  }
}

enum AtlasComparativeHighlightType { leader, warning, opportunity, imbalance }

String atlasComparativeHighlightTypeLabel(AtlasComparativeHighlightType type) {
  switch (type) {
    case AtlasComparativeHighlightType.leader:
      return 'Liderança';

    case AtlasComparativeHighlightType.warning:
      return 'Alerta';

    case AtlasComparativeHighlightType.opportunity:
      return 'Oportunidade';

    case AtlasComparativeHighlightType.imbalance:
      return 'Desequilíbrio';
  }
}
