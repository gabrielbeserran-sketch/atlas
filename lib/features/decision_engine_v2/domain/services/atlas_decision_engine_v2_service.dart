import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/decision_engine/domain/models/atlas_decision_engine_data.dart';
import 'package:projeto_atlas/features/decision_engine_v2/domain/models/atlas_decision_engine_v2_data.dart';
import 'package:projeto_atlas/features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/models/atlas_workflow_data.dart';

class AtlasDecisionEngineV2Service {
  const AtlasDecisionEngineV2Service();

  AtlasDecisionEngineV2Data build({
    required AtlasDecisionEngineData decisionEngine,
    required AtlasPredictiveAnalyticsData predictive,
    required AtlasWorkflowData workflow,
    DateTime? now,
  }) {
    final candidates = <_DecisionV2Candidate>[
      ..._fromDecisionEngine(decisionEngine),
      ..._fromPredictive(predictive),
    ];

    final actions = _rankActions(
      candidates: candidates,
      workflow: workflow,
    );

    final dailyPlan = actions.where((item) {
      return item.horizon ==
          AtlasDecisionV2Horizon.today;
    }).take(5).toList();

    final weeklyPlan = actions.where((item) {
      return item.horizon ==
          AtlasDecisionV2Horizon.week;
    }).take(8).toList();

    final monthlyPlan = actions.where((item) {
      return item.horizon ==
          AtlasDecisionV2Horizon.month;
    }).take(10).toList();

    final simulations = _buildSimulations(
      actions.take(8).toList(),
    );

    final score = _buildScore(actions);

    final confidence =
        _buildConfidence(actions);

    final status = _statusFromScore(score);

    return AtlasDecisionEngineV2Data(
      generatedAt: now ?? DateTime.now(),
      summary: _buildSummary(
        actions: actions,
        dailyPlan: dailyPlan,
        weeklyPlan: weeklyPlan,
        monthlyPlan: monthlyPlan,
        score: score,
        confidence: confidence,
        status: status,
      ),
      score: score,
      confidencePercent: confidence,
      status: status,
      bestActionToday:
          dailyPlan.isEmpty ? null : dailyPlan.first,
      dailyPlan: dailyPlan,
      weeklyPlan: weeklyPlan,
      monthlyPlan: monthlyPlan,
      rankedActions: actions,
      simulations: simulations,
    );
  }

  List<_DecisionV2Candidate> _fromDecisionEngine(
    AtlasDecisionEngineData data,
  ) {
    return data.decisions.map((item) {
      return _DecisionV2Candidate(
        id: 'decision_${item.id}',
        farmName: item.farmName,
        title: item.title,
        description: item.description,
        category: item.category,
        baseScore:
            _priorityWeight(item.priority) * 18 +
                _urgencyWeight(item.urgency) * 13 +
                _riskWeight(item.risk) * 9 +
                item.confidencePercent * 0.30,
        confidencePercent:
            item.confidencePercent,
        expectedFinancialImpact:
            item.expectedFinancialImpact,
        investmentValue:
            item.investmentValue,
        expectedReturnValue:
            item.expectedReturnValue,
        roiPercent: item.roiPercent,
        deadlineDays: item.deadlineDays,
        risk: _riskFromDecision(item.risk),
        effort: _effortFromDecision(item),
        expectedResult:
            item.expectedResult,
        reasoning:
            item.reasoningSummary,
        dependencies:
            item.executionPlan
                .skip(1)
                .map((step) => step.title)
                .toList(),
      );
    }).toList();
  }

  List<_DecisionV2Candidate> _fromPredictive(
    AtlasPredictiveAnalyticsData data,
  ) {
    final candidates =
        <_DecisionV2Candidate>[];

    for (final item in data.recommendations) {
      final relatedRisk =
          data.risks.cast<AtlasPredictiveRisk?>().firstWhere(
                (risk) =>
                    risk?.farmName == item.farmName &&
                    risk?.category == item.category,
                orElse: () => null,
              );

      final relatedScenario =
          data.scenarios.cast<AtlasPredictiveScenario?>().firstWhere(
                (scenario) =>
                    scenario?.farmName == item.farmName &&
                    scenario?.category == item.category &&
                    scenario?.type ==
                        AtlasPredictiveScenarioType.whatIf,
                orElse: () => null,
              );

      final financialImpact =
          relatedScenario?.projectedFinancialImpact ??
              relatedRisk?.financialImpactValue ??
              0;

      candidates.add(
        _DecisionV2Candidate(
          id: 'predictive_${item.id}',
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          baseScore:
              _predictivePriorityWeight(item.priority) * 18 +
                  item.confidencePercent * 0.35 +
                  (relatedRisk?.probabilityPercent ?? 0) *
                      0.25,
          confidencePercent:
              item.confidencePercent,
          expectedFinancialImpact:
              financialImpact,
          investmentValue: 0,
          expectedReturnValue:
              financialImpact,
          roiPercent: 0,
          deadlineDays:
              item.priority ==
                      AtlasPredictiveAnalyticsPriority.critical
                  ? 7
                  : item.priority ==
                          AtlasPredictiveAnalyticsPriority.high
                      ? 14
                      : 30,
          risk:
              _riskFromPredictive(
            relatedRisk?.level,
          ),
          effort:
              AtlasDecisionV2Effort.medium,
          expectedResult:
              item.expectedImpact,
          reasoning:
              'A ação foi recomendada pelo Predictive Analytics com base em risco futuro e impacto projetado.',
          dependencies: const [],
        ),
      );
    }

    return candidates;
  }

  List<AtlasDecisionV2Action> _rankActions({
    required List<_DecisionV2Candidate> candidates,
    required AtlasWorkflowData workflow,
  }) {
    final activeTaskTitles = workflow.allTasks
        .where((task) {
          return task.status !=
                  AtlasWorkflowTaskStatus.completed &&
              task.status !=
                  AtlasWorkflowTaskStatus.cancelled;
        })
        .map((task) => task.title.toLowerCase())
        .toSet();

    final merged =
        <String, _DecisionV2Candidate>{};

    for (final item in candidates) {
      final key =
          '${item.farmName}::${item.category.name}::${_normalize(item.title)}';

      final existing = merged[key];

      if (existing == null) {
        merged[key] = item;
        continue;
      }

      merged[key] = existing.copyWith(
        baseScore:
            math.max(existing.baseScore, item.baseScore),
        confidencePercent: math.max(
          existing.confidencePercent,
          item.confidencePercent,
        ),
        expectedFinancialImpact: math.max(
          existing.expectedFinancialImpact,
          item.expectedFinancialImpact,
        ),
        expectedReturnValue: math.max(
          existing.expectedReturnValue,
          item.expectedReturnValue,
        ),
        investmentValue:
            existing.investmentValue > 0
                ? existing.investmentValue
                : item.investmentValue,
        roiPercent:
            math.max(existing.roiPercent, item.roiPercent),
        deadlineDays:
            math.min(existing.deadlineDays, item.deadlineDays),
        risk: _higherRisk(
          existing.risk,
          item.risk,
        ),
        dependencies: {
          ...existing.dependencies,
          ...item.dependencies,
        }.toList(),
        reasoning:
            '${existing.reasoning} ${item.reasoning}',
      );
    }

    final candidatesList =
        merged.values.toList();

    candidatesList.sort(
      (first, second) {
        final firstPenalty = activeTaskTitles.any(
          (title) =>
              title.contains(
                _normalize(first.title),
              ) ||
              _normalize(first.title).contains(title),
        )
            ? 8
            : 0;

        final secondPenalty = activeTaskTitles.any(
          (title) =>
              title.contains(
                _normalize(second.title),
              ) ||
              _normalize(second.title).contains(title),
        )
            ? 8
            : 0;

        return (second.baseScore - secondPenalty)
            .compareTo(
          first.baseScore - firstPenalty,
        );
      },
    );

    return List.generate(
      math.min(candidatesList.length, 20),
      (index) {
        final item = candidatesList[index];

        final score = item.baseScore
            .clamp(0.0, 100.0)
            .toDouble();

        final horizon =
            _horizonFromDeadline(
          item.deadlineDays,
        );

        final priority =
            _priorityFromScore(score);

        final urgency =
            _urgencyFromDeadline(
          item.deadlineDays,
          item.risk,
        );

        final canBePostponed =
            urgency != AtlasDecisionV2Urgency.immediate &&
                item.risk != AtlasDecisionV2Risk.critical;

        return AtlasDecisionV2Action(
          position: index + 1,
          id: item.id,
          farmName: item.farmName,
          title: item.title,
          description: item.description,
          category: item.category,
          horizon: horizon,
          priority: priority,
          urgency: urgency,
          risk: item.risk,
          effort: item.effort,
          confidencePercent:
              item.confidencePercent,
          impactScore:
              _impactScore(item),
          decisionScore: score,
          expectedFinancialImpact:
              item.expectedFinancialImpact,
          investmentValue:
              item.investmentValue,
          expectedReturnValue:
              item.expectedReturnValue,
          roiPercent: item.roiPercent,
          deadlineDays: item.deadlineDays,
          canBePostponed: canBePostponed,
          maximumPostponementDays:
              canBePostponed
                  ? math.max(
                      1,
                      math.min(
                        14,
                        item.deadlineDays ~/ 2,
                      ),
                    )
                  : 0,
          expectedResult:
              item.expectedResult,
          reasoning: item.reasoning,
          dependencies:
              item.dependencies,
        );
      },
    );
  }

  List<AtlasDecisionV2Simulation>
      _buildSimulations(
    List<AtlasDecisionV2Action> actions,
  ) {
    final simulations =
        <AtlasDecisionV2Simulation>[];

    for (final action in actions) {
      final baseImpact =
          action.expectedFinancialImpact.abs();

      final baseInvestment =
          action.investmentValue;

      simulations.addAll([
        AtlasDecisionV2Simulation(
          id: '${action.id}_now',
          actionId: action.id,
          farmName: action.farmName,
          title:
              '${action.title} — executar agora',
          type:
              AtlasDecisionV2SimulationType.executeNow,
          delayDays: 0,
          investmentValue:
              baseInvestment,
          projectedFinancialImpact:
              baseImpact,
          projectedRiskPercent:
              _simulationRisk(action.risk, 0),
          projectedConfidencePercent:
              action.confidencePercent,
          recommendation:
              'Executar imediatamente para preservar o impacto esperado e reduzir a exposição ao risco.',
        ),
        AtlasDecisionV2Simulation(
          id: '${action.id}_wait',
          actionId: action.id,
          farmName: action.farmName,
          title:
              '${action.title} — esperar 7 dias',
          type:
              AtlasDecisionV2SimulationType.waitSevenDays,
          delayDays: 7,
          investmentValue:
              baseInvestment,
          projectedFinancialImpact:
              baseImpact * 0.88,
          projectedRiskPercent:
              _simulationRisk(action.risk, 7),
          projectedConfidencePercent:
              (action.confidencePercent - 5)
                  .clamp(30.0, 95.0)
                  .toDouble(),
          recommendation:
              action.canBePostponed
                  ? 'O adiamento é possível, mas reduz o impacto esperado e aumenta o risco.'
                  : 'O adiamento não é recomendado para esta ação.',
        ),
        AtlasDecisionV2Simulation(
          id:
              '${action.id}_increase_investment',
          actionId: action.id,
          farmName: action.farmName,
          title:
              '${action.title} — aumentar investimento',
          type:
              AtlasDecisionV2SimulationType.increaseInvestment,
          delayDays: 0,
          investmentValue:
              baseInvestment > 0
                  ? baseInvestment * 1.25
                  : 12500,
          projectedFinancialImpact:
              baseImpact * 1.18,
          projectedRiskPercent:
              (_simulationRisk(action.risk, 0) - 8)
                  .clamp(0.0, 100.0)
                  .toDouble(),
          projectedConfidencePercent:
              (action.confidencePercent + 4)
                  .clamp(0.0, 98.0)
                  .toDouble(),
          recommendation:
              'Aumentar recursos pode acelerar a execução, desde que o gargalo seja realmente financeiro.',
        ),
      ]);
    }

    return simulations;
  }

  double _impactScore(
    _DecisionV2Candidate item,
  ) {
    final financialComponent =
        item.expectedFinancialImpact.abs() /
            1000;

    final roiComponent =
        item.roiPercent.clamp(0.0, 150.0);

    return (financialComponent * 0.40 +
            roiComponent * 0.25 +
            item.confidencePercent * 0.20 +
            _riskWeightV2(item.risk) * 4)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _buildScore(
    List<AtlasDecisionV2Action> actions,
  ) {
    if (actions.isEmpty) {
      return 0;
    }

    final top = actions.take(
      math.min(actions.length, 8),
    );

    final average = top.fold<double>(
          0,
          (sum, item) =>
              sum + item.decisionScore,
        ) /
        top.length;

    return average
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _buildConfidence(
    List<AtlasDecisionV2Action> actions,
  ) {
    if (actions.isEmpty) {
      return 0;
    }

    final top = actions.take(
      math.min(actions.length, 10),
    );

    final average = top.fold<double>(
          0,
          (sum, item) =>
              sum + item.confidencePercent,
        ) /
        top.length;

    return average
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasDecisionEngineV2Status
      _statusFromScore(
    double score,
  ) {
    if (score >= 85) {
      return AtlasDecisionEngineV2Status.critical;
    }

    if (score >= 65) {
      return AtlasDecisionEngineV2Status.attention;
    }

    if (score >= 45) {
      return AtlasDecisionEngineV2Status.adequate;
    }

    return AtlasDecisionEngineV2Status.excellent;
  }

  AtlasDecisionV2Horizon
      _horizonFromDeadline(
    int deadlineDays,
  ) {
    if (deadlineDays <= 1) {
      return AtlasDecisionV2Horizon.today;
    }

    if (deadlineDays <= 7) {
      return AtlasDecisionV2Horizon.week;
    }

    return AtlasDecisionV2Horizon.month;
  }

  AtlasDecisionV2Priority _priorityFromScore(
    double score,
  ) {
    if (score >= 85) {
      return AtlasDecisionV2Priority.critical;
    }

    if (score >= 70) {
      return AtlasDecisionV2Priority.high;
    }

    if (score >= 50) {
      return AtlasDecisionV2Priority.medium;
    }

    return AtlasDecisionV2Priority.low;
  }

  AtlasDecisionV2Urgency
      _urgencyFromDeadline(
    int deadlineDays,
    AtlasDecisionV2Risk risk,
  ) {
    if (deadlineDays <= 1 ||
        risk == AtlasDecisionV2Risk.critical) {
      return AtlasDecisionV2Urgency.immediate;
    }

    if (deadlineDays <= 7 ||
        risk == AtlasDecisionV2Risk.high) {
      return AtlasDecisionV2Urgency.high;
    }

    if (deadlineDays <= 30) {
      return AtlasDecisionV2Urgency.medium;
    }

    return AtlasDecisionV2Urgency.low;
  }

  AtlasDecisionV2Risk _riskFromDecision(
    AtlasDecisionRisk risk,
  ) {
    switch (risk) {
      case AtlasDecisionRisk.low:
        return AtlasDecisionV2Risk.low;

      case AtlasDecisionRisk.medium:
        return AtlasDecisionV2Risk.medium;

      case AtlasDecisionRisk.high:
        return AtlasDecisionV2Risk.high;

      case AtlasDecisionRisk.critical:
        return AtlasDecisionV2Risk.critical;
    }
  }

  AtlasDecisionV2Risk _riskFromPredictive(
    AtlasPredictiveAnalyticsRiskLevel? risk,
  ) {
    switch (risk) {
      case AtlasPredictiveAnalyticsRiskLevel.low:
        return AtlasDecisionV2Risk.low;

      case AtlasPredictiveAnalyticsRiskLevel.medium:
        return AtlasDecisionV2Risk.medium;

      case AtlasPredictiveAnalyticsRiskLevel.high:
        return AtlasDecisionV2Risk.high;

      case AtlasPredictiveAnalyticsRiskLevel.critical:
        return AtlasDecisionV2Risk.critical;

      case null:
        return AtlasDecisionV2Risk.medium;
    }
  }

  AtlasDecisionV2Effort _effortFromDecision(
    AtlasDecisionRecommendation item,
  ) {
    if (item.investmentValue >= 50000 ||
        item.executionPlan.length >= 5) {
      return AtlasDecisionV2Effort.high;
    }

    if (item.investmentValue >= 10000 ||
        item.executionPlan.length >= 3) {
      return AtlasDecisionV2Effort.medium;
    }

    return AtlasDecisionV2Effort.low;
  }

  AtlasDecisionV2Risk _higherRisk(
    AtlasDecisionV2Risk first,
    AtlasDecisionV2Risk second,
  ) {
    return _riskWeightV2(first) >=
            _riskWeightV2(second)
        ? first
        : second;
  }

  int _priorityWeight(
    AtlasDecisionPriority priority,
  ) {
    switch (priority) {
      case AtlasDecisionPriority.low:
        return 1;

      case AtlasDecisionPriority.medium:
        return 2;

      case AtlasDecisionPriority.high:
        return 3;

      case AtlasDecisionPriority.critical:
        return 4;
    }
  }

  int _urgencyWeight(
    AtlasDecisionUrgency urgency,
  ) {
    switch (urgency) {
      case AtlasDecisionUrgency.low:
        return 1;

      case AtlasDecisionUrgency.medium:
        return 2;

      case AtlasDecisionUrgency.high:
        return 3;

      case AtlasDecisionUrgency.immediate:
        return 4;
    }
  }

  int _riskWeight(
    AtlasDecisionRisk risk,
  ) {
    switch (risk) {
      case AtlasDecisionRisk.low:
        return 1;

      case AtlasDecisionRisk.medium:
        return 2;

      case AtlasDecisionRisk.high:
        return 3;

      case AtlasDecisionRisk.critical:
        return 4;
    }
  }

  int _predictivePriorityWeight(
    AtlasPredictiveAnalyticsPriority priority,
  ) {
    switch (priority) {
      case AtlasPredictiveAnalyticsPriority.low:
        return 1;

      case AtlasPredictiveAnalyticsPriority.medium:
        return 2;

      case AtlasPredictiveAnalyticsPriority.high:
        return 3;

      case AtlasPredictiveAnalyticsPriority.critical:
        return 4;
    }
  }

  int _riskWeightV2(
    AtlasDecisionV2Risk risk,
  ) {
    switch (risk) {
      case AtlasDecisionV2Risk.low:
        return 1;

      case AtlasDecisionV2Risk.medium:
        return 2;

      case AtlasDecisionV2Risk.high:
        return 3;

      case AtlasDecisionV2Risk.critical:
        return 4;
    }
  }

  double _simulationRisk(
    AtlasDecisionV2Risk risk,
    int delayDays,
  ) {
    final base = switch (risk) {
      AtlasDecisionV2Risk.low => 20.0,
      AtlasDecisionV2Risk.medium => 45.0,
      AtlasDecisionV2Risk.high => 70.0,
      AtlasDecisionV2Risk.critical => 90.0,
    };

    return (base + delayDays * 1.5)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  String _normalize(
    String value,
  ) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9áàâãéêíóôõúç ]'),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _buildSummary({
    required List<AtlasDecisionV2Action> actions,
    required List<AtlasDecisionV2Action> dailyPlan,
    required List<AtlasDecisionV2Action> weeklyPlan,
    required List<AtlasDecisionV2Action> monthlyPlan,
    required double score,
    required double confidence,
    required AtlasDecisionEngineV2Status status,
  }) {
    final bestAction = dailyPlan.isEmpty
        ? 'nenhuma ação imediata'
        : dailyPlan.first.title;

    return 'O Decision Engine 2.0 gerou '
        '${actions.length} ações priorizadas, '
        '${dailyPlan.length} para hoje, '
        '${weeklyPlan.length} para a semana, '
        '${monthlyPlan.length} para o mês, '
        'score de ${score.toStringAsFixed(0)}/100, '
        '${confidence.toStringAsFixed(0)}% de confiança, '
        'situação ${atlasDecisionEngineV2StatusLabel(status).toLowerCase()} '
        'e $bestAction como melhor ação atual.';
  }
}

class _DecisionV2Candidate {
  const _DecisionV2Candidate({
    required this.id,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.baseScore,
    required this.confidencePercent,
    required this.expectedFinancialImpact,
    required this.investmentValue,
    required this.expectedReturnValue,
    required this.roiPercent,
    required this.deadlineDays,
    required this.risk,
    required this.effort,
    required this.expectedResult,
    required this.reasoning,
    required this.dependencies,
  });

  final String id;
  final String farmName;
  final String title;
  final String description;

  final AtlasBiCategory category;

  final double baseScore;
  final double confidencePercent;

  final double expectedFinancialImpact;
  final double investmentValue;
  final double expectedReturnValue;
  final double roiPercent;

  final int deadlineDays;

  final AtlasDecisionV2Risk risk;
  final AtlasDecisionV2Effort effort;

  final String expectedResult;
  final String reasoning;

  final List<String> dependencies;

  _DecisionV2Candidate copyWith({
    double? baseScore,
    double? confidencePercent,
    double? expectedFinancialImpact,
    double? investmentValue,
    double? expectedReturnValue,
    double? roiPercent,
    int? deadlineDays,
    AtlasDecisionV2Risk? risk,
    List<String>? dependencies,
    String? reasoning,
  }) {
    return _DecisionV2Candidate(
      id: id,
      farmName: farmName,
      title: title,
      description: description,
      category: category,
      baseScore:
          baseScore ?? this.baseScore,
      confidencePercent:
          confidencePercent ??
              this.confidencePercent,
      expectedFinancialImpact:
          expectedFinancialImpact ??
              this.expectedFinancialImpact,
      investmentValue:
          investmentValue ??
              this.investmentValue,
      expectedReturnValue:
          expectedReturnValue ??
              this.expectedReturnValue,
      roiPercent:
          roiPercent ?? this.roiPercent,
      deadlineDays:
          deadlineDays ?? this.deadlineDays,
      risk: risk ?? this.risk,
      effort: effort,
      expectedResult: expectedResult,
      reasoning:
          reasoning ?? this.reasoning,
      dependencies:
          dependencies ?? this.dependencies,
    );
  }
}
