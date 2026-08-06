import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_score_engine.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class DecisionPriorityEngine {
  const DecisionPriorityEngine();

  List<ExecutivePriorityAction> buildPriorityActions({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
    int maxItems = 20,
  }) {
    final candidates = <_PriorityCandidate>[];

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      final score = scoresByActionId[action.id];

      if (score == null) {
        continue;
      }

      final decisionScore = _calculateDecisionScore(
        action: action,
        score: score,
      );

      final adjustedImpact = _calculateAdjustedImpact(
        action: action,
        score: score,
        decisionScore: decisionScore,
      );

      final urgencyIndex = _calculateUrgencyIndex(action: action, score: score);

      final executionReadiness = _calculateExecutionReadiness(
        action: action,
        score: score,
      );

      final finalScore = _calculateFinalPriorityScore(
        decisionScore: decisionScore,
        adjustedImpact: adjustedImpact,
        urgencyIndex: urgencyIndex,
        executionReadiness: executionReadiness,
      );

      candidates.add(
        _PriorityCandidate(
          action: action,
          score: score,
          finalScore: finalScore,
          decisionScore: decisionScore,
          adjustedImpact: adjustedImpact,
          urgencyIndex: urgencyIndex,
          executionReadiness: executionReadiness,
        ),
      );
    }

    candidates.sort((first, second) {
      final finalComparison = second.finalScore.compareTo(first.finalScore);

      if (finalComparison != 0) {
        return finalComparison;
      }

      final riskComparison = second.score.riskScore.compareTo(
        first.score.riskScore,
      );

      if (riskComparison != 0) {
        return riskComparison;
      }

      return second.score.estimatedImpact.compareTo(
        first.score.estimatedImpact,
      );
    });

    final limited = candidates.take(maxItems < 0 ? 0 : maxItems);

    var position = 1;

    return limited.map((candidate) {
      final action = candidate.action;
      final score = candidate.score;

      final reasons = _buildPriorityReasons(candidate);

      return ExecutivePriorityAction(
        position: position++,
        actionId: action.id,
        title: action.title,
        description: action.action,
        farmName: action.farmName.trim().isEmpty
            ? 'Todas as fazendas'
            : action.farmName.trim(),
        responsible: action.responsible.trim().isEmpty
            ? 'Não definido'
            : action.responsible.trim(),
        deadline: action.deadline.trim().isEmpty
            ? 'Sem prazo'
            : action.deadline.trim(),
        category: decisionActionCategory(action),
        status: action.status,
        priorityScore: candidate.finalScore,
        riskScore: score.riskScore,
        opportunityScore: score.opportunityScore,
        delayProbability: score.delayProbability,
        estimatedImpact: candidate.adjustedImpact,
        priorityLevel: decisionLevelFromScore(candidate.finalScore),
        reasons: reasons,
        recommendedAction: _buildRecommendedAction(candidate),
      );
    }).toList();
  }

  List<ExecutivePriorityAction> buildTodayPriorities({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
    int maxItems = 5,
  }) {
    final all = buildPriorityActions(
      actions: actions,
      scoresByActionId: scoresByActionId,
      maxItems: actions.length,
    );

    final critical = all.where((item) {
      return item.priorityLevel == ExecutiveDecisionLevel.critical;
    }).toList();

    final attention = all.where((item) {
      return item.priorityLevel == ExecutiveDecisionLevel.attention;
    }).toList();

    final selected = <ExecutivePriorityAction>[];

    selected.addAll(critical.take(maxItems));

    if (selected.length < maxItems) {
      selected.addAll(attention.take(maxItems - selected.length));
    }

    if (selected.length < maxItems) {
      final remaining = all.where((item) {
        return !selected.any(
          (selectedItem) => selectedItem.actionId == item.actionId,
        );
      });

      selected.addAll(remaining.take(maxItems - selected.length));
    }

    return List.generate(selected.length, (index) {
      final item = selected[index];

      return ExecutivePriorityAction(
        position: index + 1,
        actionId: item.actionId,
        title: item.title,
        description: item.description,
        farmName: item.farmName,
        responsible: item.responsible,
        deadline: item.deadline,
        category: item.category,
        status: item.status,
        priorityScore: item.priorityScore,
        riskScore: item.riskScore,
        opportunityScore: item.opportunityScore,
        delayProbability: item.delayProbability,
        estimatedImpact: item.estimatedImpact,
        priorityLevel: item.priorityLevel,
        reasons: item.reasons,
        recommendedAction: item.recommendedAction,
      );
    });
  }

  DecisionPrioritySummary buildSummary({
    required List<ExecutivePriorityAction> priorityActions,
  }) {
    if (priorityActions.isEmpty) {
      return const DecisionPrioritySummary(
        totalActions: 0,
        criticalCount: 0,
        attentionCount: 0,
        averagePriorityScore: 0,
        averageRiskScore: 0,
        averageOpportunityScore: 0,
        totalEstimatedImpact: 0,
        topFarm: 'Não definido',
        topCategory: 'Não definida',
        topResponsible: 'Não definido',
        estimatedPerformanceGain: 0,
      );
    }

    final criticalCount = priorityActions.where((item) {
      return item.priorityLevel == ExecutiveDecisionLevel.critical;
    }).length;

    final attentionCount = priorityActions.where((item) {
      return item.priorityLevel == ExecutiveDecisionLevel.attention;
    }).length;

    final averagePriorityScore = _average(
      priorityActions.map((item) {
        return item.priorityScore;
      }),
    );

    final averageRiskScore = _average(
      priorityActions.map((item) {
        return item.riskScore;
      }),
    );

    final averageOpportunityScore = _average(
      priorityActions.map((item) {
        return item.opportunityScore;
      }),
    );

    final totalEstimatedImpact = priorityActions.fold<double>(
      0,
      (sum, item) => sum + item.estimatedImpact,
    );

    final topFarm = _topLabel(
      priorityActions.map((item) {
        return item.farmName;
      }),
    );

    final topCategory = _topLabel(
      priorityActions.map((item) {
        return item.category;
      }),
    );

    final topResponsible = _topLabel(
      priorityActions
          .map((item) {
            return item.responsible;
          })
          .where((value) {
            return value != 'Não definido';
          }),
    );

    final topFiveImpact = priorityActions
        .take(5)
        .fold<double>(0, (sum, item) => sum + item.estimatedImpact);

    final estimatedPerformanceGain = (topFiveImpact / 100 * 8).clamp(0.0, 12.0);

    return DecisionPrioritySummary(
      totalActions: priorityActions.length,
      criticalCount: criticalCount,
      attentionCount: attentionCount,
      averagePriorityScore: averagePriorityScore,
      averageRiskScore: averageRiskScore,
      averageOpportunityScore: averageOpportunityScore,
      totalEstimatedImpact: totalEstimatedImpact,
      topFarm: topFarm,
      topCategory: topCategory,
      topResponsible: topResponsible,
      estimatedPerformanceGain: estimatedPerformanceGain,
    );
  }

  double _calculateDecisionScore({
    required ReportActionItemData action,
    required DecisionActionScore score,
  }) {
    var result =
        score.priorityScore * 0.36 +
        score.riskScore * 0.26 +
        score.opportunityScore * 0.18 +
        score.delayProbability * 100 * 0.20;

    if (action.isOverdue) {
      result += 9;
    }

    if (action.isUrgent) {
      result += 7;
    }

    if (action.responsible.trim().isEmpty) {
      result += 5;
    }

    if (action.isPending) {
      result += 3;
    }

    return clampDecisionScore(result);
  }

  double _calculateAdjustedImpact({
    required ReportActionItemData action,
    required DecisionActionScore score,
    required double decisionScore,
  }) {
    var result =
        score.estimatedImpact * 0.55 +
        decisionScore * 0.25 +
        score.opportunityScore * 0.20;

    if (action.isUrgent) {
      result += 4;
    }

    if (action.isOverdue) {
      result += 5;
    }

    if (score.delayProbability >= 0.75) {
      result += 4;
    }

    return clampDecisionScore(result);
  }

  double _calculateUrgencyIndex({
    required ReportActionItemData action,
    required DecisionActionScore score,
  }) {
    var result =
        score.delayProbability * 100 * 0.45 +
        score.riskScore * 0.30 +
        score.priorityScore * 0.25;

    if (action.isOverdue) {
      result += 15;
    }

    if (action.isUrgent) {
      result += 10;
    }

    if (action.deadline.trim().isEmpty) {
      result += 5;
    }

    return clampDecisionScore(result);
  }

  double _calculateExecutionReadiness({
    required ReportActionItemData action,
    required DecisionActionScore score,
  }) {
    var result = 100.0;

    if (action.responsible.trim().isEmpty) {
      result -= 38;
    }

    if (action.deadline.trim().isEmpty) {
      result -= 20;
    }

    if (action.action.trim().isEmpty) {
      result -= 20;
    }

    if (action.isPending) {
      result -= 8;
    }

    if (score.delayProbability >= 0.80) {
      result -= 10;
    }

    return clampDecisionScore(result);
  }

  double _calculateFinalPriorityScore({
    required double decisionScore,
    required double adjustedImpact,
    required double urgencyIndex,
    required double executionReadiness,
  }) {
    final readinessOpportunity = 100 - executionReadiness;

    final result =
        decisionScore * 0.42 +
        adjustedImpact * 0.25 +
        urgencyIndex * 0.23 +
        readinessOpportunity * 0.10;

    return clampDecisionScore(result);
  }

  List<String> _buildPriorityReasons(_PriorityCandidate candidate) {
    final action = candidate.action;
    final score = candidate.score;

    final reasons = <String>[...score.reasons];

    if (candidate.finalScore >= 85) {
      reasons.insert(
        0,
        'A ação está entre as prioridades críticas da operação.',
      );
    }

    if (candidate.adjustedImpact >= 75) {
      reasons.add('A execução possui impacto estimado elevado.');
    }

    if (candidate.urgencyIndex >= 75) {
      reasons.add('O índice de urgência está alto.');
    }

    if (candidate.executionReadiness < 50) {
      reasons.add('A ação ainda apresenta baixa prontidão para execução.');
    }

    if (action.isPending && score.opportunityScore >= 70) {
      reasons.add(
        'A ação ainda não foi iniciada e possui boa oportunidade de ganho.',
      );
    }

    return _removeDuplicateReasons(reasons).take(6).toList();
  }

  String _buildRecommendedAction(_PriorityCandidate candidate) {
    final action = candidate.action;
    final score = candidate.score;

    if (action.responsible.trim().isEmpty) {
      return 'Definir o responsável imediatamente, confirmar o prazo e iniciar o acompanhamento.';
    }

    if (action.isOverdue && candidate.finalScore >= 85) {
      return 'Tratar como prioridade imediata, identificar o impedimento e definir um plano de recuperação ainda hoje.';
    }

    if (score.delayProbability >= 0.80) {
      return 'Antecipar recursos e remover impedimentos antes que a ação ultrapasse o prazo.';
    }

    if (candidate.adjustedImpact >= 80) {
      return 'Executar entre as primeiras ações do dia devido ao alto impacto esperado.';
    }

    if (candidate.executionReadiness < 50) {
      return 'Preparar os recursos necessários, esclarecer a atividade e confirmar o responsável antes da execução.';
    }

    if (action.isUrgent) {
      return 'Confirmar a execução com o responsável e acompanhar até a conclusão.';
    }

    return score.recommendation;
  }

  Iterable<String> _removeDuplicateReasons(List<String> reasons) sync* {
    final normalized = <String>{};

    for (final reason in reasons) {
      final key = reason.trim().toLowerCase();

      if (key.isEmpty || normalized.contains(key)) {
        continue;
      }

      normalized.add(key);
      yield reason;
    }
  }

  double _average(Iterable<double> values) {
    final list = values.toList();

    if (list.isEmpty) {
      return 0;
    }

    return list.reduce((first, second) => first + second) / list.length;
  }

  String _topLabel(Iterable<String> values) {
    final counts = <String, int>{};

    for (final value in values) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        continue;
      }

      counts.update(normalized, (count) => count + 1, ifAbsent: () => 1);
    }

    if (counts.isEmpty) {
      return 'Não definido';
    }

    final entries = counts.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    return entries.first.key;
  }
}

class DecisionPrioritySummary {
  const DecisionPrioritySummary({
    required this.totalActions,
    required this.criticalCount,
    required this.attentionCount,
    required this.averagePriorityScore,
    required this.averageRiskScore,
    required this.averageOpportunityScore,
    required this.totalEstimatedImpact,
    required this.topFarm,
    required this.topCategory,
    required this.topResponsible,
    required this.estimatedPerformanceGain,
  });

  final int totalActions;
  final int criticalCount;
  final int attentionCount;

  final double averagePriorityScore;
  final double averageRiskScore;
  final double averageOpportunityScore;
  final double totalEstimatedImpact;

  final String topFarm;
  final String topCategory;
  final String topResponsible;

  final double estimatedPerformanceGain;

  bool get hasCriticalActions {
    return criticalCount > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalActions': totalActions,
      'criticalCount': criticalCount,
      'attentionCount': attentionCount,
      'averagePriorityScore': averagePriorityScore,
      'averageRiskScore': averageRiskScore,
      'averageOpportunityScore': averageOpportunityScore,
      'totalEstimatedImpact': totalEstimatedImpact,
      'topFarm': topFarm,
      'topCategory': topCategory,
      'topResponsible': topResponsible,
      'estimatedPerformanceGain': estimatedPerformanceGain,
    };
  }
}

class _PriorityCandidate {
  const _PriorityCandidate({
    required this.action,
    required this.score,
    required this.finalScore,
    required this.decisionScore,
    required this.adjustedImpact,
    required this.urgencyIndex,
    required this.executionReadiness,
  });

  final ReportActionItemData action;
  final DecisionActionScore score;

  final double finalScore;
  final double decisionScore;
  final double adjustedImpact;
  final double urgencyIndex;
  final double executionReadiness;
}
