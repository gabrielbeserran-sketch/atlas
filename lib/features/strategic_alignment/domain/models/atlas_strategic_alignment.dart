import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';

class AtlasStrategicObjective {
  const AtlasStrategicObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.horizon,
    required this.weightPercent,
    required this.keyResults,
  });

  final String id;
  final String title;
  final String description;
  final AtlasStrategicHorizon horizon;
  final double weightPercent;
  final List<AtlasKeyResult> keyResults;

  double get progressPercent {
    if (keyResults.isEmpty) {
      return 0;
    }

    return keyResults.fold<double>(
          0,
          (sum, item) => sum + item.progressPercent,
        ) /
        keyResults.length;
  }
}

class AtlasKeyResult {
  const AtlasKeyResult({
    required this.id,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
  });

  final String id;
  final String title;
  final double currentValue;
  final double targetValue;
  final String unit;

  double get progressPercent {
    if (targetValue <= 0) {
      return currentValue > 0 ? 100 : 0;
    }

    return (currentValue / targetValue * 100)
        .clamp(0.0, 150.0)
        .toDouble();
  }
}

class AtlasStrategyAlignmentItem {
  const AtlasStrategyAlignmentItem({
    required this.plan,
    required this.objective,
    required this.alignmentScore,
    required this.contributionScore,
    required this.executionConfidence,
    required this.status,
    required this.recommendation,
  });

  final AtlasStrategyExecutionPlan plan;
  final AtlasStrategicObjective? objective;
  final double alignmentScore;
  final double contributionScore;
  final double executionConfidence;
  final AtlasAlignmentStatus status;
  final String recommendation;
}

class AtlasStrategicAlignmentAssessment {
  const AtlasStrategicAlignmentAssessment({
    required this.generatedAt,
    required this.objectives,
    required this.items,
  });

  final DateTime generatedAt;
  final List<AtlasStrategicObjective> objectives;
  final List<AtlasStrategyAlignmentItem> items;

  double get overallAlignment {
    if (items.isEmpty) {
      return 0;
    }

    return items.fold<double>(
          0,
          (sum, item) => sum + item.alignmentScore,
        ) /
        items.length;
  }

  double get objectiveProgress {
    if (objectives.isEmpty) {
      return 0;
    }

    final totalWeight = objectives.fold<double>(
      0,
      (sum, item) => sum + item.weightPercent,
    );

    if (totalWeight <= 0) {
      return 0;
    }

    return objectives.fold<double>(
          0,
          (sum, item) =>
              sum +
              item.progressPercent *
                  item.weightPercent,
        ) /
        totalWeight;
  }

  int get unalignedStrategies {
    return items
        .where(
          (item) =>
              item.status ==
              AtlasAlignmentStatus.unaligned,
        )
        .length;
  }

  int get weakStrategies {
    return items
        .where(
          (item) =>
              item.status ==
              AtlasAlignmentStatus.weak,
        )
        .length;
  }
}

enum AtlasStrategicHorizon {
  shortTerm,
  mediumTerm,
  longTerm,
}

enum AtlasAlignmentStatus {
  strong,
  acceptable,
  weak,
  unaligned,
}

String atlasStrategicHorizonLabel(
  AtlasStrategicHorizon horizon,
) {
  switch (horizon) {
    case AtlasStrategicHorizon.shortTerm:
      return 'Curto prazo';
    case AtlasStrategicHorizon.mediumTerm:
      return 'Médio prazo';
    case AtlasStrategicHorizon.longTerm:
      return 'Longo prazo';
  }
}

String atlasAlignmentStatusLabel(
  AtlasAlignmentStatus status,
) {
  switch (status) {
    case AtlasAlignmentStatus.strong:
      return 'Forte';
    case AtlasAlignmentStatus.acceptable:
      return 'Aceitável';
    case AtlasAlignmentStatus.weak:
      return 'Fraco';
    case AtlasAlignmentStatus.unaligned:
      return 'Sem alinhamento';
  }
}
