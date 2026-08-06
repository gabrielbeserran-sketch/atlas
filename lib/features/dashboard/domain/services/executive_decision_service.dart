import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_assistant_engine.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_heatmap_engine.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_prediction_engine.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_priority_engine.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_score_engine.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class ExecutiveDecisionService {
  const ExecutiveDecisionService({
    this.scoreEngine = const DecisionScoreEngine(),
    this.predictionEngine = const DecisionPredictionEngine(),
    this.heatMapEngine = const DecisionHeatMapEngine(),
    this.priorityEngine = const DecisionPriorityEngine(),
    this.assistantEngine = const DecisionAssistantEngine(),
  });

  final DecisionScoreEngine scoreEngine;
  final DecisionPredictionEngine predictionEngine;
  final DecisionHeatMapEngine heatMapEngine;
  final DecisionPriorityEngine priorityEngine;
  final DecisionAssistantEngine assistantEngine;

  ExecutiveDecisionData buildDecisionCenter({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    String scopeLabel = 'Visão consolidada',
    String consultantName = 'Gabriel',
    DateTime? generatedAt,
    int maxPriorityActions = 20,
  }) {
    final now = generatedAt ?? DateTime.now();

    final orderedActions = List<ReportActionItemData>.from(actions)
      ..sort(compareReportActions);

    final context = DecisionScoreContext.fromActions(orderedActions);

    final scoresByActionId = <String, DecisionActionScore>{};

    for (final action in orderedActions) {
      final history = historyByActionId[action.id] ?? const [];

      scoresByActionId[action.id] = scoreEngine.calculate(
        action: action,
        history: history,
        context: context,
        now: now,
      );
    }

    final priorityActions = priorityEngine.buildPriorityActions(
      actions: orderedActions,
      scoresByActionId: scoresByActionId,
      maxItems: maxPriorityActions,
    );

    final todayPriorities = priorityEngine.buildTodayPriorities(
      actions: orderedActions,
      scoresByActionId: scoresByActionId,
      maxItems: 5,
    );

    final prioritySummary = priorityEngine.buildSummary(
      priorityActions: priorityActions,
    );

    final predictions = predictionEngine.buildPredictions(
      actions: orderedActions,
      scoresByActionId: scoresByActionId,
      historyByActionId: historyByActionId,
      now: now,
    );

    final heatMapItems = heatMapEngine.buildHeatMap(
      actions: orderedActions,
      scoresByActionId: scoresByActionId,
    );

    final farmRiskRanking = heatMapEngine.buildFarmRiskRanking(
      actions: orderedActions,
      scoresByActionId: scoresByActionId,
    );

    final responsibleRiskRanking = heatMapEngine.buildResponsibleRiskRanking(
      actions: orderedActions,
      scoresByActionId: scoresByActionId,
    );

    final categoryRiskRanking = heatMapEngine.buildCategoryRiskRanking(
      actions: orderedActions,
      scoresByActionId: scoresByActionId,
    );

    final consultantScore = _buildConsultantScore(
      actions: orderedActions,
      historyByActionId: historyByActionId,
      priorityActions: priorityActions,
      predictions: predictions,
      now: now,
    );

    final assistantMessage = assistantEngine.buildMessage(
      priorityActions: todayPriorities,
      farmRiskRanking: farmRiskRanking,
      responsibleRiskRanking: responsibleRiskRanking,
      categoryRiskRanking: categoryRiskRanking,
      predictions: predictions,
      prioritySummary: prioritySummary,
      consultantName: consultantName,
      now: now,
    );

    final summary = _buildSummary(
      priorityActions: priorityActions,
      farmRiskRanking: farmRiskRanking,
      responsibleRiskRanking: responsibleRiskRanking,
      predictions: predictions,
      prioritySummary: prioritySummary,
    );

    return ExecutiveDecisionData(
      generatedAt: formatExecutiveDecisionDateTime(now),
      scopeLabel: scopeLabel,
      consultantScore: consultantScore,
      priorityActions: priorityActions,
      farmRiskRanking: farmRiskRanking,
      responsibleRiskRanking: responsibleRiskRanking,
      categoryRiskRanking: categoryRiskRanking,
      predictions: predictions,
      heatMapItems: heatMapItems,
      executiveAssistant: assistantMessage,
      summary: summary,
    );
  }

  ExecutiveDecisionScore _buildConsultantScore({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    required List<ExecutivePriorityAction> priorityActions,
    required List<ExecutivePredictionData> predictions,
    required DateTime now,
  }) {
    final openActions = actions.where((action) {
      return action.isOpen;
    }).toList();

    final completedActions = actions.where((action) {
      return action.isCompleted;
    }).toList();

    final overdueActions = actions.where((action) {
      return action.isOverdue;
    }).toList();

    final withoutResponsible = openActions.where((action) {
      return action.responsible.trim().isEmpty;
    }).length;

    final considered = actions.where((action) {
      return !action.isCancelled;
    }).length;

    final completionRate = considered == 0
        ? 0.0
        : completedActions.length / considered;

    final overdueRate = considered == 0
        ? 0.0
        : overdueActions.length / considered;

    final responsibilityRate = openActions.isEmpty
        ? 1.0
        : 1 - withoutResponsible / openActions.length;

    final historyCoverage = actions.isEmpty
        ? 0.0
        : actions.where((action) {
                return (historyByActionId[action.id] ?? const []).isNotEmpty;
              }).length /
              actions.length;

    final averageResponseScore = _calculateResponseTimeScore(
      actions: actions,
      historyByActionId: historyByActionId,
      now: now,
    );

    final predictionControlScore = _calculatePredictionControlScore(
      predictions,
    );

    final priorityExecutionScore = _calculatePriorityExecutionScore(
      priorityActions,
    );

    final completionComponent = ExecutiveScoreComponent(
      id: 'completion_rate',
      title: 'Taxa de conclusão',
      value: completionRate * 100,
      weight: 0.30,
      weightedValue: completionRate * 100 * 0.30,
      description: 'Capacidade de concluir as ações planejadas.',
    );

    final deadlineComponent = ExecutiveScoreComponent(
      id: 'deadline_control',
      title: 'Controle de prazos',
      value: (1 - overdueRate).clamp(0.0, 1.0) * 100,
      weight: 0.22,
      weightedValue: (1 - overdueRate).clamp(0.0, 1.0) * 100 * 0.22,
      description: 'Proporção de ações sem atraso.',
    );

    final responsibilityComponent = ExecutiveScoreComponent(
      id: 'responsibility_definition',
      title: 'Definição de responsáveis',
      value: responsibilityRate.clamp(0.0, 1.0) * 100,
      weight: 0.14,
      weightedValue: responsibilityRate.clamp(0.0, 1.0) * 100 * 0.14,
      description: 'Clareza na atribuição das responsabilidades.',
    );

    final historyComponent = ExecutiveScoreComponent(
      id: 'history_quality',
      title: 'Qualidade do histórico',
      value: historyCoverage * 100,
      weight: 0.10,
      weightedValue: historyCoverage * 100 * 0.10,
      description: 'Cobertura de movimentações registradas.',
    );

    final responseComponent = ExecutiveScoreComponent(
      id: 'response_time',
      title: 'Tempo de resposta',
      value: averageResponseScore,
      weight: 0.10,
      weightedValue: averageResponseScore * 0.10,
      description: 'Agilidade entre criação, atualização e conclusão.',
    );

    final predictionComponent = ExecutiveScoreComponent(
      id: 'prediction_control',
      title: 'Controle preditivo',
      value: predictionControlScore,
      weight: 0.08,
      weightedValue: predictionControlScore * 0.08,
      description: 'Controle sobre riscos previstos de atraso e sobrecarga.',
    );

    final priorityComponent = ExecutiveScoreComponent(
      id: 'priority_execution',
      title: 'Execução das prioridades',
      value: priorityExecutionScore,
      weight: 0.06,
      weightedValue: priorityExecutionScore * 0.06,
      description: 'Capacidade de manter sob controle as ações mais críticas.',
    );

    final components = [
      completionComponent,
      deadlineComponent,
      responsibilityComponent,
      historyComponent,
      responseComponent,
      predictionComponent,
      priorityComponent,
    ];

    final value = components
        .fold<double>(0, (sum, item) => sum + item.weightedValue)
        .clamp(0.0, 100.0);

    final level = consultantLevelFromScore(value);

    return ExecutiveDecisionScore(
      value: value,
      label: consultantScoreLabel(level),
      level: level,
      explanation: _buildConsultantExplanation(
        score: value,
        level: level,
        completionRate: completionRate,
        overdueRate: overdueRate,
        responsibilityRate: responsibilityRate,
        historyCoverage: historyCoverage,
      ),
      components: components,
    );
  }

  double _calculateResponseTimeScore({
    required List<ReportActionItemData> actions,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    required DateTime now,
  }) {
    final responseDays = <int>[];

    for (final action in actions) {
      final created = tryParseDecisionDate(action.createdAt);

      if (created == null) {
        continue;
      }

      final history = historyByActionId[action.id] ?? const [];

      DateTime? firstMovement;

      for (final item in history) {
        final date = tryParseReportActionHistoryDateTime(item.createdAt);

        if (date == null) {
          continue;
        }

        if (firstMovement == null || date.isBefore(firstMovement)) {
          firstMovement = date;
        }
      }

      if (firstMovement != null) {
        responseDays.add(firstMovement.difference(created).inDays.abs());
        continue;
      }

      if (action.isCompleted) {
        final completed = tryParseDecisionDate(action.completedAt);

        if (completed != null) {
          responseDays.add(completed.difference(created).inDays.abs());
        }
      } else {
        responseDays.add(now.difference(created).inDays.abs());
      }
    }

    if (responseDays.isEmpty) {
      return 50;
    }

    final average =
        responseDays.reduce((first, second) => first + second) /
        responseDays.length;

    if (average <= 1) {
      return 100;
    }

    if (average <= 3) {
      return 88;
    }

    if (average <= 7) {
      return 72;
    }

    if (average <= 14) {
      return 55;
    }

    if (average <= 30) {
      return 35;
    }

    return 20;
  }

  double _calculatePredictionControlScore(
    List<ExecutivePredictionData> predictions,
  ) {
    if (predictions.isEmpty) {
      return 100;
    }

    final criticalCount = predictions.where((item) {
      return item.level == ExecutiveDecisionLevel.critical;
    }).length;

    final attentionCount = predictions.where((item) {
      return item.level == ExecutiveDecisionLevel.attention;
    }).length;

    final penalty =
        criticalCount * 16 + attentionCount * 7 + predictions.length * 1.5;

    return (100 - penalty).clamp(0.0, 100.0);
  }

  double _calculatePriorityExecutionScore(
    List<ExecutivePriorityAction> priorityActions,
  ) {
    if (priorityActions.isEmpty) {
      return 100;
    }

    final criticalCount = priorityActions.where((item) {
      return item.priorityLevel == ExecutiveDecisionLevel.critical;
    }).length;

    final highDelayCount = priorityActions.where((item) {
      return item.delayProbability >= 0.70;
    }).length;

    final averagePriority =
        priorityActions
            .map((item) => item.priorityScore)
            .reduce((first, second) => first + second) /
        priorityActions.length;

    final penalty =
        criticalCount * 10 + highDelayCount * 5 + averagePriority * 0.20;

    return (100 - penalty).clamp(0.0, 100.0);
  }

  ExecutiveDecisionSummary _buildSummary({
    required List<ExecutivePriorityAction> priorityActions,
    required List<ExecutiveDecisionRankingItem> farmRiskRanking,
    required List<ExecutiveDecisionRankingItem> responsibleRiskRanking,
    required List<ExecutivePredictionData> predictions,
    required DecisionPrioritySummary prioritySummary,
  }) {
    final criticalActionCount = priorityActions.where((item) {
      return item.priorityLevel == ExecutiveDecisionLevel.critical;
    }).length;

    final highRiskFarmCount = farmRiskRanking.where((item) {
      return item.level == ExecutiveDecisionLevel.critical ||
          item.level == ExecutiveDecisionLevel.attention;
    }).length;

    final highRiskResponsibleCount = responsibleRiskRanking.where((item) {
      return item.level == ExecutiveDecisionLevel.critical ||
          item.level == ExecutiveDecisionLevel.attention;
    }).length;

    final predictedDelayCount = predictions.where((item) {
      return item.targetType == ExecutivePredictionTargetType.action &&
          item.probability >= 0.70;
    }).length;

    return ExecutiveDecisionSummary(
      criticalActionCount: criticalActionCount,
      highRiskFarmCount: highRiskFarmCount,
      highRiskResponsibleCount: highRiskResponsibleCount,
      predictedDelayCount: predictedDelayCount,
      totalEstimatedImpact: prioritySummary.totalEstimatedImpact,
      averagePriorityScore: prioritySummary.averagePriorityScore,
      averageRiskScore: prioritySummary.averageRiskScore,
      averageOpportunityScore: prioritySummary.averageOpportunityScore,
    );
  }

  String _buildConsultantExplanation({
    required double score,
    required ExecutiveDecisionLevel level,
    required double completionRate,
    required double overdueRate,
    required double responsibilityRate,
    required double historyCoverage,
  }) {
    final buffer = StringBuffer();

    buffer.write(
      'O score do consultor é de '
      '${score.toStringAsFixed(1).replaceAll('.', ',')} pontos, '
      'classificado como '
      '${consultantScoreLabel(level).toLowerCase()}. ',
    );

    buffer.write(
      'A taxa de conclusão é de '
      '${formatDecisionPercentage(completionRate)}, ',
    );

    buffer.write(
      'o controle de prazos é de '
      '${formatDecisionPercentage(1 - overdueRate)}, ',
    );

    buffer.write(
      'a definição de responsáveis alcança '
      '${formatDecisionPercentage(responsibilityRate)} ',
    );

    buffer.write(
      'e a cobertura de histórico é de '
      '${formatDecisionPercentage(historyCoverage)}.',
    );

    return buffer.toString();
  }
}

ExecutiveDecisionLevel consultantLevelFromScore(double score) {
  if (score >= 85) {
    return ExecutiveDecisionLevel.excellent;
  }

  if (score >= 70) {
    return ExecutiveDecisionLevel.good;
  }

  if (score >= 50) {
    return ExecutiveDecisionLevel.normal;
  }

  if (score >= 30) {
    return ExecutiveDecisionLevel.attention;
  }

  return ExecutiveDecisionLevel.critical;
}

String consultantScoreLabel(ExecutiveDecisionLevel level) {
  switch (level) {
    case ExecutiveDecisionLevel.excellent:
      return 'Excelente';

    case ExecutiveDecisionLevel.good:
      return 'Bom';

    case ExecutiveDecisionLevel.normal:
      return 'Regular';

    case ExecutiveDecisionLevel.attention:
      return 'Atenção';

    case ExecutiveDecisionLevel.critical:
      return 'Crítico';
  }
}

String formatExecutiveDecisionDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/${date.year} '
      '$hour:$minute';
}
