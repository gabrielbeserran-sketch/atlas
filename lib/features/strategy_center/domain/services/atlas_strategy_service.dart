import 'package:projeto_atlas/features/strategy_center/domain/models/atlas_strategy_data.dart';

class AtlasStrategyService {
  const AtlasStrategyService();

  AtlasStrategyData build({required AtlasStrategyInput input, DateTime? now}) {
    final score = _score(input);

    return AtlasStrategyData(
      generatedAt: now ?? DateTime.now(),
      title: input.title,
      mission: input.mission,
      summary: _summary(input, score),
      score: score,
      status: _status(score),
      objectives: _objectives(input.objectives),
      priorities: _priorities(input.priorities),
      initiatives: _initiatives(input.initiatives),
      risks: _risks(input.risks),
      opportunities: _opportunities(input.opportunities),
    );
  }

  double _score(AtlasStrategyInput input) {
    final objectiveScore = _average(
      input.objectives.map((item) => item.progressPercent).toList(),
    );

    final priorityScore = _average(
      input.priorities.map((item) => item.progressPercent).toList(),
    );

    final initiativeScore = _average(
      input.initiatives.map((item) => item.progressPercent).toList(),
    );

    final criticalRisks = input.risks
        .where(
          (item) =>
              item.probability == AtlasStrategyRiskLevel.critical ||
              item.impact == AtlasStrategyRiskLevel.critical,
        )
        .length;

    final highRisks = input.risks
        .where(
          (item) =>
              item.probability == AtlasStrategyRiskLevel.high ||
              item.impact == AtlasStrategyRiskLevel.high,
        )
        .length;

    final opportunityBonus =
        input.opportunities
            .where((item) => item.confidencePercent >= 70)
            .length *
        2;

    final value =
        objectiveScore * 0.40 +
        priorityScore * 0.25 +
        initiativeScore * 0.35 +
        opportunityBonus -
        criticalRisks * 12 -
        highRisks * 6;

    return value.clamp(0.0, 100.0).toDouble();
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;

    return (values.fold<double>(0, (sum, value) => sum + value) / values.length)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasStrategyStatus _status(double score) {
    if (score >= 85) {
      return AtlasStrategyStatus.excellent;
    }
    if (score >= 70) {
      return AtlasStrategyStatus.adequate;
    }
    if (score >= 50) {
      return AtlasStrategyStatus.attention;
    }
    return AtlasStrategyStatus.critical;
  }

  List<AtlasStrategyObjective> _objectives(
    List<AtlasStrategyObjective> values,
  ) {
    final result = [...values]
      ..sort((a, b) => a.progressPercent.compareTo(b.progressPercent));
    return result;
  }

  List<AtlasStrategyPriority> _priorities(List<AtlasStrategyPriority> values) {
    final result = [...values]
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    return result;
  }

  List<AtlasStrategyInitiative> _initiatives(
    List<AtlasStrategyInitiative> values,
  ) {
    final result = [...values]
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    return result;
  }

  List<AtlasStrategyRisk> _risks(List<AtlasStrategyRisk> values) {
    final result = [...values]
      ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return result;
  }

  List<AtlasStrategyOpportunity> _opportunities(
    List<AtlasStrategyOpportunity> values,
  ) {
    final result = [...values]
      ..sort((a, b) => b.confidencePercent.compareTo(a.confidencePercent));
    return result;
  }

  String _summary(AtlasStrategyInput input, double score) {
    final criticalRisks = input.risks
        .where(
          (item) =>
              item.impact == AtlasStrategyRiskLevel.critical ||
              item.probability == AtlasStrategyRiskLevel.critical,
        )
        .length;

    return 'A estratégia possui score de '
        '${score.toStringAsFixed(0)}/100, '
        '${input.objectives.length} objetivos, '
        '${input.priorities.length} prioridades, '
        '${input.initiatives.length} iniciativas, '
        '$criticalRisks riscos críticos e '
        '${input.opportunities.length} oportunidades.';
  }
}
