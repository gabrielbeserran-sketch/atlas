import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/contracts/atlas_decision_contract.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';
import 'package:projeto_atlas/features/executive_brain/domain/services/atlas_executive_brain_service.dart';
import 'package:projeto_atlas/features/executive_core/domain/models/atlas_executive_core_data.dart';

/// Orquestrador canônico do Executive Brain.
///
/// Mantém o cálculo consolidado já existente no [AtlasExecutiveBrainService]
/// e usa as decisões canônicas como fonte oficial para decisão e planos.
/// Nenhuma regra do Decision Engine V2 é repetida neste serviço.
class AtlasExecutiveBrainCanonicalService {
  const AtlasExecutiveBrainCanonicalService({
    this.baseService = const AtlasExecutiveBrainService(),
  });

  final AtlasExecutiveBrainService baseService;

  AtlasExecutiveBrainData build({
    required AtlasExecutiveCoreData executiveCore,
    required List<AtlasDecisionContract> canonicalDecisions,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final base = baseService.build(
      executiveCore: executiveCore,
      now: currentTime,
    );

    if (canonicalDecisions.isEmpty) {
      return base;
    }

    final ranked = [...canonicalDecisions]..sort(_compareDecisions);
    final official = _toOfficialDecision(ranked.first, currentTime);
    final plans = _buildPlans(ranked, currentTime);
    final strategy = _alignStrategy(base.strategy, official);

    return AtlasExecutiveBrainData(
      generatedAt: currentTime,
      summary: _buildSummary(base.summary, official, ranked.length),
      brainScore: base.brainScore,
      confidencePercent: _combinedConfidence(
        base.confidencePercent,
        official.confidencePercent,
      ),
      status: base.status,
      officialDecision: official,
      strategy: strategy,
      crossImpacts: base.crossImpacts,
      conflicts: base.conflicts,
      dailyPlan: plans.daily,
      weeklyPlan: plans.weekly,
      monthlyPlan: plans.monthly,
      memoryInsights: base.memoryInsights,
      scoreDimensions: base.scoreDimensions,
      radarItems: base.radarItems,
    );
  }

  int _compareDecisions(
    AtlasDecisionContract first,
    AtlasDecisionContract second,
  ) {
    final priorityComparison =
        _priorityWeight(second.priority).compareTo(_priorityWeight(first.priority));
    if (priorityComparison != 0) {
      return priorityComparison;
    }

    final scoreComparison = second.decisionScore.compareTo(first.decisionScore);
    if (scoreComparison != 0) {
      return scoreComparison;
    }

    final confidenceComparison =
        second.confidencePercent.compareTo(first.confidencePercent);
    if (confidenceComparison != 0) {
      return confidenceComparison;
    }

    return first.deadline.compareTo(second.deadline);
  }

  AtlasExecutiveBrainDecision _toOfficialDecision(
    AtlasDecisionContract decision,
    DateTime now,
  ) {
    final operationalActions = <String>[
      ...decision.dependencies,
      if (decision.dependencies.isEmpty) ...decision.evidence.take(3),
      if (decision.dependencies.isEmpty && decision.evidence.isEmpty)
        decision.expectedResult,
    ];

    return AtlasExecutiveBrainDecision(
      id: 'canonical_${decision.id}',
      title: decision.title,
      description: decision.description,
      farmName: decision.farmName,
      priority: _priority(decision.priority),
      score: decision.decisionScore.clamp(0.0, 100.0).toDouble(),
      confidencePercent:
          decision.confidencePercent.clamp(0.0, 100.0).toDouble(),
      expectedFinancialImpact: decision.expectedFinancialImpact,
      deadlineHours: _deadlineHours(decision.deadline, now),
      reasoning: decision.reasoning,
      actions: List<String>.unmodifiable(operationalActions),
      expectedResult: decision.expectedResult,
    );
  }

  _CanonicalPlans _buildPlans(
    List<AtlasDecisionContract> decisions,
    DateTime now,
  ) {
    final daily = <AtlasExecutiveBrainAction>[];
    final weekly = <AtlasExecutiveBrainAction>[];
    final monthly = <AtlasExecutiveBrainAction>[];

    for (final decision in decisions) {
      final horizon = _horizon(decision.horizon);
      final action = AtlasExecutiveBrainAction(
        position: 0,
        id: 'canonical_action_${decision.id}',
        title: decision.title,
        description: decision.description,
        farmName: decision.farmName,
        horizon: horizon,
        priority: _priority(decision.priority),
        confidencePercent:
            decision.confidencePercent.clamp(0.0, 100.0).toDouble(),
        expectedFinancialImpact: decision.expectedFinancialImpact,
        deadlineHours: _deadlineHours(decision.deadline, now),
        source: decision.sourceModule,
        completed: false,
      );

      switch (horizon) {
        case AtlasExecutiveBrainHorizon.today:
          daily.add(action);
        case AtlasExecutiveBrainHorizon.week:
          weekly.add(action);
        case AtlasExecutiveBrainHorizon.month:
          monthly.add(action);
      }
    }

    return _CanonicalPlans(
      daily: _rankActions(daily, 5),
      weekly: _rankActions(weekly, 8),
      monthly: _rankActions(monthly, 10),
    );
  }

  List<AtlasExecutiveBrainAction> _rankActions(
    List<AtlasExecutiveBrainAction> actions,
    int limit,
  ) {
    final selected = actions.take(limit).toList(growable: false);

    return List<AtlasExecutiveBrainAction>.generate(
      selected.length,
      (index) {
        final item = selected[index];
        return AtlasExecutiveBrainAction(
          position: index + 1,
          id: item.id,
          title: item.title,
          description: item.description,
          farmName: item.farmName,
          horizon: item.horizon,
          priority: item.priority,
          confidencePercent: item.confidencePercent,
          expectedFinancialImpact: item.expectedFinancialImpact,
          deadlineHours: item.deadlineHours,
          source: item.source,
          completed: item.completed,
        );
      },
      growable: false,
    );
  }

  AtlasExecutiveBrainStrategy _alignStrategy(
    AtlasExecutiveBrainStrategy? base,
    AtlasExecutiveBrainDecision official,
  ) {
    if (base == null) {
      return AtlasExecutiveBrainStrategy(
        id: 'canonical_strategy_${official.id}',
        title: 'Estratégia executiva orientada pela decisão oficial',
        summary: 'Executar a decisão oficial e acompanhar seus efeitos nos módulos integrados.',
        objective: official.expectedResult,
        horizonDays: 30,
        successProbabilityPercent: official.confidencePercent,
        expectedFinancialImpact: official.expectedFinancialImpact,
        pillars: const [],
      );
    }

    return AtlasExecutiveBrainStrategy(
      id: base.id,
      title: base.title,
      summary: base.summary,
      objective: official.expectedResult,
      horizonDays: base.horizonDays,
      successProbabilityPercent:
          _combinedConfidence(base.successProbabilityPercent, official.confidencePercent),
      expectedFinancialImpact: official.expectedFinancialImpact +
          (base.expectedFinancialImpact > 0 ? base.expectedFinancialImpact : 0),
      pillars: base.pillars,
    );
  }

  String _buildSummary(
    String baseSummary,
    AtlasExecutiveBrainDecision official,
    int decisionCount,
  ) {
    return '$baseSummary A decisão oficial foi alinhada ao contrato canônico '
        'do Decision Engine V2, considerando $decisionCount decisão(ões) '
        'ranqueada(s). Prioridade atual: ${official.title}.';
  }

  double _combinedConfidence(double first, double second) {
    return ((first + second) / 2).clamp(0.0, 100.0).toDouble();
  }

  int _deadlineHours(DateTime deadline, DateTime now) {
    if (!deadline.isAfter(now)) {
      return 0;
    }
    return deadline.difference(now).inHours;
  }

  int _priorityWeight(AtlasCanonicalPriority priority) {
    switch (priority) {
      case AtlasCanonicalPriority.low:
        return 1;
      case AtlasCanonicalPriority.medium:
        return 2;
      case AtlasCanonicalPriority.high:
        return 3;
      case AtlasCanonicalPriority.critical:
        return 4;
    }
  }

  AtlasExecutiveBrainPriority _priority(AtlasCanonicalPriority priority) {
    switch (priority) {
      case AtlasCanonicalPriority.low:
        return AtlasExecutiveBrainPriority.low;
      case AtlasCanonicalPriority.medium:
        return AtlasExecutiveBrainPriority.medium;
      case AtlasCanonicalPriority.high:
        return AtlasExecutiveBrainPriority.high;
      case AtlasCanonicalPriority.critical:
        return AtlasExecutiveBrainPriority.critical;
    }
  }

  AtlasExecutiveBrainHorizon _horizon(AtlasCanonicalHorizon horizon) {
    switch (horizon) {
      case AtlasCanonicalHorizon.today:
        return AtlasExecutiveBrainHorizon.today;
      case AtlasCanonicalHorizon.week:
        return AtlasExecutiveBrainHorizon.week;
      case AtlasCanonicalHorizon.month:
      case AtlasCanonicalHorizon.quarter:
      case AtlasCanonicalHorizon.longTerm:
        return AtlasExecutiveBrainHorizon.month;
    }
  }
}

class _CanonicalPlans {
  const _CanonicalPlans({
    required this.daily,
    required this.weekly,
    required this.monthly,
  });

  final List<AtlasExecutiveBrainAction> daily;
  final List<AtlasExecutiveBrainAction> weekly;
  final List<AtlasExecutiveBrainAction> monthly;
}
