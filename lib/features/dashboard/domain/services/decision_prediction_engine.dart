import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_score_engine.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class DecisionPredictionEngine {
  const DecisionPredictionEngine();

  List<ExecutivePredictionData> buildPredictions({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();

    final predictions = <ExecutivePredictionData>[];

    predictions.addAll(
      _buildActionDelayPredictions(
        actions: actions,
        scoresByActionId: scoresByActionId,
        historyByActionId: historyByActionId,
        now: referenceDate,
      ),
    );

    predictions.addAll(
      _buildFarmPredictions(
        actions: actions,
        scoresByActionId: scoresByActionId,
      ),
    );

    predictions.addAll(
      _buildResponsiblePredictions(
        actions: actions,
        scoresByActionId: scoresByActionId,
      ),
    );

    predictions.addAll(
      _buildCategoryPredictions(
        actions: actions,
        scoresByActionId: scoresByActionId,
      ),
    );

    predictions.addAll(
      _buildIndicatorPredictions(
        actions: actions,
        scoresByActionId: scoresByActionId,
        now: referenceDate,
      ),
    );

    predictions.sort((first, second) {
      final levelComparison = _levelWeight(
        second.level,
      ).compareTo(_levelWeight(first.level));

      if (levelComparison != 0) {
        return levelComparison;
      }

      return second.probability.compareTo(first.probability);
    });

    return predictions;
  }

  List<ExecutivePredictionData> _buildActionDelayPredictions({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
    required Map<String, List<ReportActionHistoryData>> historyByActionId,
    required DateTime now,
  }) {
    final predictions = <ExecutivePredictionData>[];

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      final score = scoresByActionId[action.id];

      if (score == null) {
        continue;
      }

      final evidence = <String>[];

      if (score.delayProbability >= 0.70) {
        evidence.add(
          'Probabilidade de atraso estimada em '
          '${formatDecisionPercentage(score.delayProbability)}.',
        );
      }

      if (action.isOverdue) {
        evidence.add('A ação já está fora do prazo.');
      }

      if (action.isUrgent) {
        evidence.add('A ação possui prioridade urgente.');
      }

      if (action.responsible.trim().isEmpty) {
        evidence.add('Não há responsável definido.');
      }

      final deadline = tryParseDecisionDate(action.deadline);

      if (deadline != null) {
        final today = DateTime(now.year, now.month, now.day);

        final days = deadline.difference(today).inDays;

        if (days >= 0 && days <= 3) {
          evidence.add('O prazo vence em até 3 dias.');
        }
      }

      final history = historyByActionId[action.id] ?? const [];

      final deadlineChanges = history.where((item) {
        return item.isDeadlineChange;
      }).length;

      if (deadlineChanges >= 2) {
        evidence.add(
          'O prazo já foi alterado '
          '$deadlineChanges vezes.',
        );
      }

      final responsibleChanges = history.where((item) {
        return item.isResponsibleChange;
      }).length;

      if (responsibleChanges >= 2) {
        evidence.add(
          'O responsável já foi alterado '
          '$responsibleChanges vezes.',
        );
      }

      final shouldPredict =
          score.delayProbability >= 0.62 ||
          action.isOverdue ||
          evidence.length >= 3;

      if (!shouldPredict) {
        continue;
      }

      final probability = _calculateActionPredictionProbability(
        action: action,
        score: score,
        evidenceCount: evidence.length,
        deadlineChanges: deadlineChanges,
        responsibleChanges: responsibleChanges,
      );

      predictions.add(
        ExecutivePredictionData(
          id: 'action_delay_${action.id}',
          title: 'Risco de atraso da ação',
          description:
              '${action.title} apresenta sinais de atraso ou dificuldade de execução.',
          targetType: ExecutivePredictionTargetType.action,
          targetLabel: action.title,
          probability: probability,
          horizonDays: _predictionHorizonForAction(action: action, now: now),
          level: decisionLevelFromScore(probability * 100),
          recommendedAction: _buildActionPreventiveRecommendation(
            action: action,
            score: score,
          ),
          evidence: evidence,
        ),
      );
    }

    return predictions;
  }

  List<ExecutivePredictionData> _buildFarmPredictions({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    final groups = <String, List<_PredictionActionData>>{};

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      final score = scoresByActionId[action.id];

      if (score == null) {
        continue;
      }

      final farm = action.farmName.trim().isEmpty
          ? 'Todas as fazendas'
          : action.farmName.trim();

      groups
          .putIfAbsent(farm, () => [])
          .add(_PredictionActionData(action: action, score: score));
    }

    final predictions = <ExecutivePredictionData>[];

    for (final entry in groups.entries) {
      final data = entry.value;

      if (data.isEmpty) {
        continue;
      }

      final overdueCount = data.where((item) {
        return item.action.isOverdue;
      }).length;

      final urgentCount = data.where((item) {
        return item.action.isUrgent;
      }).length;

      final highDelayCount = data.where((item) {
        return item.score.delayProbability >= 0.70;
      }).length;

      final averageRisk =
          data.map((item) => item.score.riskScore).reduce((a, b) => a + b) /
          data.length;

      final averageDelay =
          data
              .map((item) => item.score.delayProbability)
              .reduce((a, b) => a + b) /
          data.length;

      final probability = _groupProbability(
        averageRisk: averageRisk,
        averageDelay: averageDelay,
        overdueCount: overdueCount,
        urgentCount: urgentCount,
        totalCount: data.length,
      );

      if (probability < 0.58 && overdueCount == 0 && highDelayCount == 0) {
        continue;
      }

      final evidence = <String>[
        '${data.length} ações abertas na fazenda.',
        '$overdueCount ações atrasadas.',
        '$urgentCount ações urgentes.',
        '$highDelayCount ações com alto risco de atraso.',
        'Risco médio de '
            '${averageRisk.toStringAsFixed(1).replaceAll('.', ',')} pontos.',
      ];

      predictions.add(
        ExecutivePredictionData(
          id: 'farm_risk_${_normalizeId(entry.key)}',
          title: 'Possível agravamento da fazenda',
          description:
              '${entry.key} apresenta concentração de risco operacional e pode exigir maior atenção.',
          targetType: ExecutivePredictionTargetType.farm,
          targetLabel: entry.key,
          probability: probability,
          horizonDays: 14,
          level: decisionLevelFromScore(probability * 100),
          recommendedAction:
              'Revisar as ações abertas da fazenda, priorizar atrasos e confirmar responsáveis.',
          evidence: evidence,
        ),
      );
    }

    return predictions;
  }

  List<ExecutivePredictionData> _buildResponsiblePredictions({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    final groups = <String, List<_PredictionActionData>>{};

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      final responsible = action.responsible.trim();

      if (responsible.isEmpty) {
        continue;
      }

      final score = scoresByActionId[action.id];

      if (score == null) {
        continue;
      }

      groups
          .putIfAbsent(responsible, () => [])
          .add(_PredictionActionData(action: action, score: score));
    }

    final predictions = <ExecutivePredictionData>[];

    for (final entry in groups.entries) {
      final data = entry.value;

      final overdueCount = data.where((item) {
        return item.action.isOverdue;
      }).length;

      final highPriorityCount = data.where((item) {
        return item.score.priorityScore >= 70;
      }).length;

      final highDelayCount = data.where((item) {
        return item.score.delayProbability >= 0.70;
      }).length;

      final averageDelay =
          data
              .map((item) => item.score.delayProbability)
              .reduce((a, b) => a + b) /
          data.length;

      final loadScore = (data.length / 8).clamp(0.0, 1.0);

      final probability =
          (loadScore * 0.35 +
                  averageDelay * 0.35 +
                  (overdueCount / data.length) * 0.20 +
                  (highPriorityCount / data.length) * 0.10)
              .clamp(0.0, 1.0);

      if (probability < 0.60 && data.length < 5 && overdueCount == 0) {
        continue;
      }

      predictions.add(
        ExecutivePredictionData(
          id: 'responsible_overload_${_normalizeId(entry.key)}',
          title: 'Possível sobrecarga do responsável',
          description:
              '${entry.key} concentra uma carga de trabalho que pode comprometer prazos e qualidade de execução.',
          targetType: ExecutivePredictionTargetType.responsible,
          targetLabel: entry.key,
          probability: probability,
          horizonDays: 10,
          level: decisionLevelFromScore(probability * 100),
          recommendedAction:
              'Revisar a distribuição das ações e oferecer apoio nas tarefas mais críticas.',
          evidence: [
            '${data.length} ações abertas sob responsabilidade.',
            '$overdueCount ações atrasadas.',
            '$highPriorityCount ações com prioridade elevada.',
            '$highDelayCount ações com alta chance de atraso.',
          ],
        ),
      );
    }

    return predictions;
  }

  List<ExecutivePredictionData> _buildCategoryPredictions({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
  }) {
    final groups = <String, List<_PredictionActionData>>{};

    for (final action in actions) {
      if (!action.isOpen) {
        continue;
      }

      final score = scoresByActionId[action.id];

      if (score == null) {
        continue;
      }

      final category = decisionActionCategory(action);

      groups
          .putIfAbsent(category, () => [])
          .add(_PredictionActionData(action: action, score: score));
    }

    final predictions = <ExecutivePredictionData>[];

    for (final entry in groups.entries) {
      final data = entry.value;

      if (data.length < 2) {
        continue;
      }

      final overdueCount = data.where((item) {
        return item.action.isOverdue;
      }).length;

      final urgentCount = data.where((item) {
        return item.action.isUrgent;
      }).length;

      final averageRisk =
          data.map((item) => item.score.riskScore).reduce((a, b) => a + b) /
          data.length;

      final averageOpportunity =
          data
              .map((item) => item.score.opportunityScore)
              .reduce((a, b) => a + b) /
          data.length;

      final probability =
          ((data.length / 8).clamp(0.0, 1.0) * 0.25 +
          (overdueCount / data.length) * 0.30 +
          (urgentCount / data.length) * 0.20 +
          (averageRisk / 100) * 0.25);

      if (probability < 0.55 && overdueCount == 0 && urgentCount == 0) {
        continue;
      }

      predictions.add(
        ExecutivePredictionData(
          id: 'category_risk_${_normalizeId(entry.key)}',
          title: 'Recorrência de problemas na categoria',
          description:
              'A categoria ${entry.key} concentra ações abertas e pode se tornar um gargalo operacional.',
          targetType: ExecutivePredictionTargetType.category,
          targetLabel: entry.key,
          probability: probability.clamp(0.0, 1.0),
          horizonDays: 21,
          level: decisionLevelFromScore(probability * 100),
          recommendedAction:
              'Revisar a causa comum das ações da categoria e criar um plano preventivo.',
          evidence: [
            '${data.length} ações abertas na categoria.',
            '$overdueCount ações atrasadas.',
            '$urgentCount ações urgentes.',
            'Risco médio de '
                '${averageRisk.toStringAsFixed(1).replaceAll('.', ',')} pontos.',
            'Oportunidade média de '
                '${averageOpportunity.toStringAsFixed(1).replaceAll('.', ',')} pontos.',
          ],
        ),
      );
    }

    return predictions;
  }

  List<ExecutivePredictionData> _buildIndicatorPredictions({
    required List<ReportActionItemData> actions,
    required Map<String, DecisionActionScore> scoresByActionId,
    required DateTime now,
  }) {
    final openActions = actions.where((action) {
      return action.isOpen;
    }).toList();

    if (openActions.isEmpty) {
      return [];
    }

    final overdueCount = openActions.where((action) {
      return action.isOverdue;
    }).length;

    final noResponsibleCount = openActions.where((action) {
      return action.responsible.trim().isEmpty;
    }).length;

    final highDelayCount = openActions.where((action) {
      final score = scoresByActionId[action.id];

      return score != null && score.delayProbability >= 0.70;
    }).length;

    final dueSoonCount = openActions.where((action) {
      final deadline = tryParseDecisionDate(action.deadline);

      if (deadline == null) {
        return false;
      }

      final today = DateTime(now.year, now.month, now.day);

      final days = deadline.difference(today).inDays;

      return days >= 0 && days <= 7;
    }).length;

    final predictions = <ExecutivePredictionData>[];

    final delayPressure = ((overdueCount + highDelayCount) / openActions.length)
        .clamp(0.0, 1.0);

    if (delayPressure >= 0.30) {
      predictions.add(
        ExecutivePredictionData(
          id: 'indicator_delay_pressure',
          title: 'Pressão crescente sobre os prazos',
          description:
              'O volume de ações atrasadas ou com alta chance de atraso pode elevar a taxa geral de atraso.',
          targetType: ExecutivePredictionTargetType.indicator,
          targetLabel: 'Taxa de atraso',
          probability: (0.55 + delayPressure * 0.40).clamp(0.0, 1.0),
          horizonDays: 14,
          level: delayPressure >= 0.55
              ? ExecutiveDecisionLevel.critical
              : ExecutiveDecisionLevel.attention,
          recommendedAction:
              'Criar uma rotina de revisão dos prazos e acompanhar diariamente as ações críticas.',
          evidence: [
            '$overdueCount ações atrasadas.',
            '$highDelayCount ações com alta chance de atraso.',
            '$dueSoonCount ações vencem nos próximos 7 dias.',
          ],
        ),
      );
    }

    final responsibilityPressure = (noResponsibleCount / openActions.length)
        .clamp(0.0, 1.0);

    if (noResponsibleCount > 0) {
      predictions.add(
        ExecutivePredictionData(
          id: 'indicator_responsibility_gap',
          title: 'Risco de perda de responsabilidade',
          description:
              'Ações sem responsável definido apresentam maior risco de permanecer sem execução.',
          targetType: ExecutivePredictionTargetType.indicator,
          targetLabel: 'Responsabilidade das ações',
          probability: (0.60 + responsibilityPressure * 0.30).clamp(0.0, 1.0),
          horizonDays: 7,
          level: responsibilityPressure >= 0.25
              ? ExecutiveDecisionLevel.critical
              : ExecutiveDecisionLevel.attention,
          recommendedAction:
              'Definir responsáveis para todas as ações abertas e confirmar o aceite das tarefas.',
          evidence: [
            '$noResponsibleCount ações abertas sem responsável.',
            '${formatDecisionPercentage(responsibilityPressure)} das ações abertas estão sem responsável.',
          ],
        ),
      );
    }

    return predictions;
  }

  double _calculateActionPredictionProbability({
    required ReportActionItemData action,
    required DecisionActionScore score,
    required int evidenceCount,
    required int deadlineChanges,
    required int responsibleChanges,
  }) {
    var probability =
        score.delayProbability * 0.70 +
        (score.riskScore / 100) * 0.20 +
        (score.priorityScore / 100) * 0.10;

    if (action.isOverdue) {
      probability += 0.15;
    }

    if (action.responsible.trim().isEmpty) {
      probability += 0.08;
    }

    probability += (deadlineChanges * 0.03).clamp(0.0, 0.12);

    probability += (responsibleChanges * 0.02).clamp(0.0, 0.08);

    probability += (evidenceCount * 0.01).clamp(0.0, 0.05);

    return probability.clamp(0.0, 1.0);
  }

  double _groupProbability({
    required double averageRisk,
    required double averageDelay,
    required int overdueCount,
    required int urgentCount,
    required int totalCount,
  }) {
    if (totalCount == 0) {
      return 0;
    }

    final overdueRate = overdueCount / totalCount;

    final urgentRate = urgentCount / totalCount;

    return ((averageRisk / 100) * 0.30 +
            averageDelay * 0.30 +
            overdueRate * 0.25 +
            urgentRate * 0.15)
        .clamp(0.0, 1.0);
  }

  int _predictionHorizonForAction({
    required ReportActionItemData action,
    required DateTime now,
  }) {
    if (action.isOverdue) {
      return 1;
    }

    final deadline = tryParseDecisionDate(action.deadline);

    if (deadline == null) {
      return 14;
    }

    final today = DateTime(now.year, now.month, now.day);

    final days = deadline.difference(today).inDays;

    if (days <= 0) {
      return 1;
    }

    return days.clamp(1, 30);
  }

  String _buildActionPreventiveRecommendation({
    required ReportActionItemData action,
    required DecisionActionScore score,
  }) {
    if (action.responsible.trim().isEmpty) {
      return 'Definir imediatamente um responsável e confirmar o prazo.';
    }

    if (action.isOverdue) {
      return 'Registrar o motivo do atraso, definir novo prazo e acompanhar diariamente até a conclusão.';
    }

    if (score.delayProbability >= 0.80) {
      return 'Antecipar recursos, remover impedimentos e revisar o progresso nas próximas 24 horas.';
    }

    if (score.priorityScore >= 80) {
      return 'Tratar como prioridade do dia e confirmar a execução com o responsável.';
    }

    return 'Revisar o progresso antes do prazo e registrar qualquer impedimento.';
  }

  int _levelWeight(ExecutiveDecisionLevel level) {
    switch (level) {
      case ExecutiveDecisionLevel.critical:
        return 5;
      case ExecutiveDecisionLevel.attention:
        return 4;
      case ExecutiveDecisionLevel.normal:
        return 3;
      case ExecutiveDecisionLevel.good:
        return 2;
      case ExecutiveDecisionLevel.excellent:
        return 1;
    }
  }

  String _normalizeId(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}

class _PredictionActionData {
  const _PredictionActionData({required this.action, required this.score});

  final ReportActionItemData action;
  final DecisionActionScore score;
}
