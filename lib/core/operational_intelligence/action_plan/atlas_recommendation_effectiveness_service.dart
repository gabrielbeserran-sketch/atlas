import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_outcome.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_recommendation_effectiveness.dart';

class AtlasRecommendationEffectivenessService {
  const AtlasRecommendationEffectivenessService();

  List<AtlasRecommendationEffectiveness> build({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasActionOutcome> outcomes,
  }) {
    final outcomesByAction = <String, AtlasActionOutcome>{
      for (final outcome in outcomes) outcome.actionId: outcome,
    };

    final modules = actions.map((action) => action.sourceModule).toSet();

    final ranking =
        modules.map((module) {
          final moduleActions = actions
              .where((action) => action.sourceModule == module)
              .toList();
          final moduleOutcomes = moduleActions
              .map((action) => outcomesByAction[action.id])
              .whereType<AtlasActionOutcome>()
              .toList();

          final completed = moduleActions
              .where((action) => action.isCompleted)
              .length;
          final completionRate = moduleActions.isEmpty
              ? 0.0
              : completed / moduleActions.length * 100;
          final averageProgress = moduleActions.isEmpty
              ? 0.0
              : moduleActions
                        .map((action) => action.progressPercent)
                        .fold<int>(0, (first, second) => first + second) /
                    moduleActions.length;
          final averageRoi = moduleOutcomes.isEmpty
              ? 0.0
              : moduleOutcomes
                        .map((outcome) => outcome.roiPercent)
                        .fold<double>(0, (first, second) => first + second) /
                    moduleOutcomes.length;
          final netResult = moduleOutcomes.fold<double>(
            0,
            (total, outcome) => total + outcome.netFinancialResult,
          );
          final evidenceCoverage = moduleActions.isEmpty
              ? 0.0
              : moduleOutcomes.length / moduleActions.length * 100;
          final normalizedRoi = averageRoi.clamp(-100.0, 200.0);
          final roiScore = ((normalizedRoi + 100) / 3).clamp(0.0, 100.0);

          final score =
              (completionRate * 0.30 +
                      averageProgress * 0.25 +
                      evidenceCoverage * 0.20 +
                      roiScore * 0.25)
                  .clamp(0.0, 100.0);

          return AtlasRecommendationEffectiveness(
            sourceModule: module,
            actionCount: moduleActions.length,
            completedCount: completed,
            outcomeCount: moduleOutcomes.length,
            averageProgressPercent: averageProgress,
            averageRoiPercent: averageRoi,
            totalNetFinancialResult: netResult,
            effectivenessScore: score,
          );
        }).toList()..sort(
          (first, second) =>
              second.effectivenessScore.compareTo(first.effectivenessScore),
        );

    return List<AtlasRecommendationEffectiveness>.unmodifiable(ranking);
  }
}
