import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';

class AtlasCopilotImprovementPlan {
  const AtlasCopilotImprovementPlan({
    required this.generatedAt,
    required this.overallScore,
    required this.overallLevel,
    required this.summary,
    required this.priorities,
    required this.strengths,
    required this.recommendedActions,
  });

  final DateTime generatedAt;

  final double overallScore;
  final AtlasCopilotImprovementLevel overallLevel;

  final String summary;

  final List<AtlasCopilotImprovementPriority>
      priorities;

  final List<AtlasCopilotImprovementStrength>
      strengths;

  final List<String> recommendedActions;

  bool get hasPriorities {
    return priorities.isNotEmpty;
  }
}

class AtlasCopilotImprovementPriority {
  const AtlasCopilotImprovementPriority({
    required this.position,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.level,
    required this.score,
    required this.intent,
    required this.contextLabel,
  });

  final int position;

  final String title;
  final String description;
  final String recommendation;

  final AtlasCopilotImprovementLevel level;

  final double score;

  final AtlasCopilotIntent? intent;
  final String? contextLabel;
}

class AtlasCopilotImprovementStrength {
  const AtlasCopilotImprovementStrength({
    required this.title,
    required this.description,
    required this.score,
  });

  final String title;
  final String description;
  final double score;
}

enum AtlasCopilotImprovementLevel {
  excellent,
  stable,
  attention,
  critical,
}

String atlasCopilotImprovementLevelLabel(
  AtlasCopilotImprovementLevel level,
) {
  switch (level) {
    case AtlasCopilotImprovementLevel.excellent:
      return 'Excelente';

    case AtlasCopilotImprovementLevel.stable:
      return 'Estável';

    case AtlasCopilotImprovementLevel.attention:
      return 'Atenção';

    case AtlasCopilotImprovementLevel.critical:
      return 'Crítico';
  }
}
