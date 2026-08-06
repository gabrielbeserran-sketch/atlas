import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class DecisionScoreEngine {
  const DecisionScoreEngine();

  DecisionActionScore calculate({
    required ReportActionItemData action,
    required List<ReportActionHistoryData> history,
    required DecisionScoreContext context,
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();

    final priorityBase = _priorityBase(action.priority);

    final deadlineData = _buildDeadlineData(action: action, now: referenceDate);

    final responsibleData = _buildResponsibleData(
      action: action,
      context: context,
    );

    final farmData = _buildFarmData(action: action, context: context);

    final categoryData = _buildCategoryData(action: action, context: context);

    final historyData = _buildHistoryData(
      action: action,
      history: history,
      now: referenceDate,
    );

    final executionData = _buildExecutionData(action);

    final priorityScore = _calculatePriorityScore(
      priorityBase: priorityBase,
      deadlineData: deadlineData,
      responsibleData: responsibleData,
      farmData: farmData,
      categoryData: categoryData,
      historyData: historyData,
      executionData: executionData,
    );

    final riskScore = _calculateRiskScore(
      priorityBase: priorityBase,
      deadlineData: deadlineData,
      responsibleData: responsibleData,
      farmData: farmData,
      categoryData: categoryData,
      historyData: historyData,
      executionData: executionData,
    );

    final opportunityScore = _calculateOpportunityScore(
      priorityBase: priorityBase,
      deadlineData: deadlineData,
      responsibleData: responsibleData,
      farmData: farmData,
      categoryData: categoryData,
      historyData: historyData,
      executionData: executionData,
    );

    final delayProbability = _calculateDelayProbability(
      deadlineData: deadlineData,
      responsibleData: responsibleData,
      farmData: farmData,
      categoryData: categoryData,
      historyData: historyData,
      executionData: executionData,
    );

    final estimatedImpact = _calculateEstimatedImpact(
      priorityScore: priorityScore,
      riskScore: riskScore,
      opportunityScore: opportunityScore,
      action: action,
    );

    final level = decisionLevelFromScore(priorityScore);

    final reasons = _buildReasons(
      action: action,
      deadlineData: deadlineData,
      responsibleData: responsibleData,
      farmData: farmData,
      categoryData: categoryData,
      historyData: historyData,
      executionData: executionData,
      priorityScore: priorityScore,
      riskScore: riskScore,
      opportunityScore: opportunityScore,
      delayProbability: delayProbability,
    );

    final recommendation = _buildRecommendation(
      action: action,
      deadlineData: deadlineData,
      responsibleData: responsibleData,
      priorityScore: priorityScore,
      riskScore: riskScore,
      opportunityScore: opportunityScore,
      delayProbability: delayProbability,
    );

    return DecisionActionScore(
      actionId: action.id,
      priorityScore: priorityScore,
      riskScore: riskScore,
      opportunityScore: opportunityScore,
      delayProbability: delayProbability,
      estimatedImpact: estimatedImpact,
      level: level,
      reasons: reasons,
      recommendation: recommendation,
      components: [
        DecisionScoreComponent(
          id: 'declared_priority',
          title: 'Prioridade declarada',
          value: priorityBase,
          weight: 0.22,
          weightedValue: priorityBase * 0.22,
          explanation: 'Importância informada no cadastro da ação.',
        ),
        DecisionScoreComponent(
          id: 'deadline',
          title: 'Prazo',
          value: deadlineData.score,
          weight: 0.24,
          weightedValue: deadlineData.score * 0.24,
          explanation: deadlineData.explanation,
        ),
        DecisionScoreComponent(
          id: 'responsible',
          title: 'Responsável',
          value: responsibleData.score,
          weight: 0.14,
          weightedValue: responsibleData.score * 0.14,
          explanation: responsibleData.explanation,
        ),
        DecisionScoreComponent(
          id: 'farm',
          title: 'Fazenda',
          value: farmData.score,
          weight: 0.12,
          weightedValue: farmData.score * 0.12,
          explanation: farmData.explanation,
        ),
        DecisionScoreComponent(
          id: 'category',
          title: 'Categoria',
          value: categoryData.score,
          weight: 0.10,
          weightedValue: categoryData.score * 0.10,
          explanation: categoryData.explanation,
        ),
        DecisionScoreComponent(
          id: 'history',
          title: 'Histórico',
          value: historyData.score,
          weight: 0.10,
          weightedValue: historyData.score * 0.10,
          explanation: historyData.explanation,
        ),
        DecisionScoreComponent(
          id: 'execution',
          title: 'Execução',
          value: executionData.score,
          weight: 0.08,
          weightedValue: executionData.score * 0.08,
          explanation: executionData.explanation,
        ),
      ],
    );
  }

  double _calculatePriorityScore({
    required double priorityBase,
    required _DecisionFactorData deadlineData,
    required _DecisionFactorData responsibleData,
    required _DecisionFactorData farmData,
    required _DecisionFactorData categoryData,
    required _DecisionFactorData historyData,
    required _DecisionFactorData executionData,
  }) {
    final result =
        priorityBase * 0.22 +
        deadlineData.score * 0.24 +
        responsibleData.score * 0.14 +
        farmData.score * 0.12 +
        categoryData.score * 0.10 +
        historyData.score * 0.10 +
        executionData.score * 0.08;

    return clampDecisionScore(result);
  }

  double _calculateRiskScore({
    required double priorityBase,
    required _DecisionFactorData deadlineData,
    required _DecisionFactorData responsibleData,
    required _DecisionFactorData farmData,
    required _DecisionFactorData categoryData,
    required _DecisionFactorData historyData,
    required _DecisionFactorData executionData,
  }) {
    final result =
        deadlineData.score * 0.30 +
        responsibleData.score * 0.18 +
        farmData.score * 0.16 +
        categoryData.score * 0.10 +
        historyData.score * 0.14 +
        executionData.score * 0.08 +
        priorityBase * 0.04;

    return clampDecisionScore(result);
  }

  double _calculateOpportunityScore({
    required double priorityBase,
    required _DecisionFactorData deadlineData,
    required _DecisionFactorData responsibleData,
    required _DecisionFactorData farmData,
    required _DecisionFactorData categoryData,
    required _DecisionFactorData historyData,
    required _DecisionFactorData executionData,
  }) {
    final urgencyOpportunity = 100 - deadlineData.score;

    final executionOpportunity = 100 - executionData.score;

    final result =
        priorityBase * 0.28 +
        urgencyOpportunity * 0.14 +
        executionOpportunity * 0.18 +
        farmData.score * 0.12 +
        categoryData.score * 0.14 +
        historyData.score * 0.08 +
        responsibleData.score * 0.06;

    return clampDecisionScore(result);
  }

  double _calculateDelayProbability({
    required _DecisionFactorData deadlineData,
    required _DecisionFactorData responsibleData,
    required _DecisionFactorData farmData,
    required _DecisionFactorData categoryData,
    required _DecisionFactorData historyData,
    required _DecisionFactorData executionData,
  }) {
    final score =
        deadlineData.score * 0.34 +
        responsibleData.score * 0.22 +
        historyData.score * 0.18 +
        farmData.score * 0.10 +
        categoryData.score * 0.08 +
        executionData.score * 0.08;

    return (score / 100).clamp(0.0, 1.0);
  }

  double _calculateEstimatedImpact({
    required double priorityScore,
    required double riskScore,
    required double opportunityScore,
    required ReportActionItemData action,
  }) {
    var result =
        priorityScore * 0.40 + riskScore * 0.35 + opportunityScore * 0.25;

    if (action.isUrgent) {
      result += 6;
    }

    if (action.isOverdue) {
      result += 8;
    }

    if (action.responsible.trim().isEmpty) {
      result += 4;
    }

    return clampDecisionScore(result);
  }

  _DecisionFactorData _buildDeadlineData({
    required ReportActionItemData action,
    required DateTime now,
  }) {
    if (action.isCompleted || action.isCancelled) {
      return const _DecisionFactorData(
        score: 0,
        explanation: 'A ação não está aberta.',
      );
    }

    if (action.deadline.trim().isEmpty) {
      return const _DecisionFactorData(
        score: 58,
        explanation: 'A ação não possui prazo definido.',
      );
    }

    final deadline = tryParseDecisionDate(action.deadline);

    if (deadline == null) {
      return const _DecisionFactorData(
        score: 52,
        explanation: 'O prazo informado não pôde ser interpretado.',
      );
    }

    final today = DateTime(now.year, now.month, now.day);

    final difference = deadline.difference(today).inDays;

    if (difference < 0) {
      final overdueDays = difference.abs();

      return _DecisionFactorData(
        score: clampDecisionScore(82 + overdueDays * 2.2),
        explanation:
            'A ação está atrasada há $overdueDays '
            '${overdueDays == 1 ? 'dia' : 'dias'}.',
      );
    }

    if (difference == 0) {
      return const _DecisionFactorData(
        score: 88,
        explanation: 'A ação vence hoje.',
      );
    }

    if (difference == 1) {
      return const _DecisionFactorData(
        score: 80,
        explanation: 'A ação vence amanhã.',
      );
    }

    if (difference <= 3) {
      return _DecisionFactorData(
        score: 72,
        explanation: 'A ação vence em $difference dias.',
      );
    }

    if (difference <= 7) {
      return _DecisionFactorData(
        score: 58,
        explanation: 'A ação vence dentro de uma semana.',
      );
    }

    if (difference <= 15) {
      return const _DecisionFactorData(
        score: 38,
        explanation: 'A ação possui prazo moderado.',
      );
    }

    return const _DecisionFactorData(
      score: 20,
      explanation: 'A ação possui prazo confortável.',
    );
  }

  _DecisionFactorData _buildResponsibleData({
    required ReportActionItemData action,
    required DecisionScoreContext context,
  }) {
    final responsible = action.responsible.trim();

    if (!action.isOpen) {
      return const _DecisionFactorData(
        score: 0,
        explanation: 'A ação não está aberta.',
      );
    }

    if (responsible.isEmpty) {
      return const _DecisionFactorData(
        score: 82,
        explanation: 'A ação está sem responsável definido.',
      );
    }

    final stats = context.responsibleStats[responsible];

    if (stats == null) {
      return const _DecisionFactorData(
        score: 25,
        explanation: 'Não há histórico suficiente do responsável.',
      );
    }

    final loadScore = stats.openCount == 0
        ? 0.0
        : (stats.openCount / 8 * 100).clamp(0.0, 100.0);

    final overdueRate = stats.openCount == 0
        ? 0.0
        : stats.overdueCount / stats.openCount;

    final result = loadScore * 0.55 + overdueRate * 100 * 0.45;

    return _DecisionFactorData(
      score: clampDecisionScore(result),
      explanation:
          '$responsible possui ${stats.openCount} ações abertas '
          'e ${stats.overdueCount} atrasadas.',
    );
  }

  _DecisionFactorData _buildFarmData({
    required ReportActionItemData action,
    required DecisionScoreContext context,
  }) {
    final farm = action.farmName.trim().isEmpty
        ? 'Todas as fazendas'
        : action.farmName.trim();

    final stats = context.farmStats[farm];

    if (stats == null) {
      return const _DecisionFactorData(
        score: 20,
        explanation: 'Não há histórico suficiente da fazenda.',
      );
    }

    final overdueRate = stats.openCount == 0
        ? 0.0
        : stats.overdueCount / stats.openCount;

    final urgentRate = stats.openCount == 0
        ? 0.0
        : stats.urgentCount / stats.openCount;

    final volumeScore = (stats.openCount / 10 * 100).clamp(0.0, 100.0);

    final result =
        overdueRate * 100 * 0.45 + urgentRate * 100 * 0.30 + volumeScore * 0.25;

    return _DecisionFactorData(
      score: clampDecisionScore(result),
      explanation:
          '$farm concentra ${stats.openCount} ações abertas, '
          '${stats.overdueCount} atrasadas e '
          '${stats.urgentCount} urgentes.',
    );
  }

  _DecisionFactorData _buildCategoryData({
    required ReportActionItemData action,
    required DecisionScoreContext context,
  }) {
    final category = decisionActionCategory(action);

    final stats = context.categoryStats[category];

    if (stats == null) {
      return _DecisionFactorData(
        score: 20,
        explanation: 'A categoria $category possui poucos dados.',
      );
    }

    final overdueRate = stats.openCount == 0
        ? 0.0
        : stats.overdueCount / stats.openCount;

    final recurrenceScore = (stats.totalCount / 10 * 100).clamp(0.0, 100.0);

    final result = overdueRate * 100 * 0.55 + recurrenceScore * 0.45;

    return _DecisionFactorData(
      score: clampDecisionScore(result),
      explanation:
          'A categoria $category possui '
          '${stats.totalCount} registros e '
          '${stats.overdueCount} atrasos.',
    );
  }

  _DecisionFactorData _buildHistoryData({
    required ReportActionItemData action,
    required List<ReportActionHistoryData> history,
    required DateTime now,
  }) {
    if (history.isEmpty) {
      return const _DecisionFactorData(
        score: 22,
        explanation: 'A ação possui pouco histórico registrado.',
      );
    }

    var statusChanges = 0;
    var deadlineChanges = 0;
    var responsibleChanges = 0;
    var priorityChanges = 0;

    for (final item in history) {
      if (item.isStatusChange || item.isCompletion || item.isCancellation) {
        statusChanges++;
      }

      if (item.isDeadlineChange) {
        deadlineChanges++;
      }

      if (item.isResponsibleChange) {
        responsibleChanges++;
      }

      if (item.isPriorityChange) {
        priorityChanges++;
      }
    }

    final createdDate = tryParseDecisionDate(action.createdAt);

    final ageDays = createdDate == null
        ? 0
        : now.difference(createdDate).inDays.abs();

    final changeScore =
        statusChanges * 5 +
        deadlineChanges * 12 +
        responsibleChanges * 8 +
        priorityChanges * 6;

    final ageScore = action.isOpen
        ? (ageDays / 45 * 100).clamp(0.0, 100.0)
        : 0.0;

    final result = changeScore * 0.65 + ageScore * 0.35;

    return _DecisionFactorData(
      score: clampDecisionScore(result),
      explanation:
          'A ação possui ${history.length} movimentações, '
          '$deadlineChanges alterações de prazo e '
          '$responsibleChanges trocas de responsável.',
    );
  }

  _DecisionFactorData _buildExecutionData(ReportActionItemData action) {
    if (action.isCompleted) {
      return const _DecisionFactorData(
        score: 0,
        explanation: 'A ação já foi concluída.',
      );
    }

    if (action.isCancelled) {
      return const _DecisionFactorData(
        score: 0,
        explanation: 'A ação foi cancelada.',
      );
    }

    if (action.isOverdue) {
      return const _DecisionFactorData(
        score: 92,
        explanation: 'A execução está atrasada.',
      );
    }

    if (action.isPending) {
      return const _DecisionFactorData(
        score: 64,
        explanation: 'A ação ainda não foi iniciada.',
      );
    }

    if (action.isInProgress) {
      return const _DecisionFactorData(
        score: 36,
        explanation: 'A ação está em andamento.',
      );
    }

    return const _DecisionFactorData(
      score: 45,
      explanation: 'A execução possui status intermediário.',
    );
  }

  List<String> _buildReasons({
    required ReportActionItemData action,
    required _DecisionFactorData deadlineData,
    required _DecisionFactorData responsibleData,
    required _DecisionFactorData farmData,
    required _DecisionFactorData categoryData,
    required _DecisionFactorData historyData,
    required _DecisionFactorData executionData,
    required double priorityScore,
    required double riskScore,
    required double opportunityScore,
    required double delayProbability,
  }) {
    final reasons = <String>[];

    if (action.isOverdue) {
      reasons.add('A ação está fora do prazo.');
    }

    if (action.isUrgent) {
      reasons.add('A prioridade declarada é urgente.');
    }

    if (action.responsible.trim().isEmpty) {
      reasons.add('Não há responsável definido.');
    }

    if (deadlineData.score >= 70) {
      reasons.add(deadlineData.explanation);
    }

    if (responsibleData.score >= 65) {
      reasons.add(responsibleData.explanation);
    }

    if (farmData.score >= 65) {
      reasons.add(farmData.explanation);
    }

    if (categoryData.score >= 65) {
      reasons.add(categoryData.explanation);
    }

    if (historyData.score >= 65) {
      reasons.add(historyData.explanation);
    }

    if (executionData.score >= 70) {
      reasons.add(executionData.explanation);
    }

    if (delayProbability >= 0.70) {
      reasons.add(
        'A probabilidade estimada de atraso é de '
        '${formatDecisionPercentage(delayProbability)}.',
      );
    }

    if (opportunityScore >= 75) {
      reasons.add('A conclusão pode gerar ganho operacional relevante.');
    }

    if (priorityScore >= 85 && riskScore >= 75) {
      reasons.add(
        'A ação combina prioridade elevada e risco operacional alto.',
      );
    }

    if (reasons.isEmpty) {
      reasons.add('A ação apresenta prioridade operacional moderada.');
    }

    return reasons;
  }

  String _buildRecommendation({
    required ReportActionItemData action,
    required _DecisionFactorData deadlineData,
    required _DecisionFactorData responsibleData,
    required double priorityScore,
    required double riskScore,
    required double opportunityScore,
    required double delayProbability,
  }) {
    if (!action.isOpen) {
      return 'Nenhuma ação imediata é necessária.';
    }

    if (action.responsible.trim().isEmpty) {
      return 'Definir um responsável e confirmar o prazo antes de iniciar a execução.';
    }

    if (action.isOverdue) {
      return 'Revisar imediatamente o impedimento, negociar novo prazo e registrar um plano de recuperação.';
    }

    if (delayProbability >= 0.75) {
      return 'Antecipar o acompanhamento, confirmar recursos e remover impedimentos antes do prazo.';
    }

    if (priorityScore >= 80 && riskScore >= 70) {
      return 'Executar como prioridade do dia e acompanhar até a conclusão.';
    }

    if (opportunityScore >= 75) {
      return 'Priorizar a execução, pois a ação possui bom potencial de ganho operacional.';
    }

    if (deadlineData.score >= 70) {
      return 'Confirmar a execução nas próximas 48 horas.';
    }

    if (responsibleData.score >= 65) {
      return 'Avaliar redistribuição de carga ou apoio ao responsável atual.';
    }

    return 'Manter no plano semanal e atualizar o progresso regularmente.';
  }

  double _priorityBase(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'muito alta':
      case 'urgente':
        return 100;

      case 'alta':
        return 82;

      case 'média':
      case 'media':
      case 'normal':
        return 58;

      case 'baixa':
        return 30;

      case 'muito baixa':
        return 15;

      default:
        return 45;
    }
  }
}

class DecisionScoreContext {
  const DecisionScoreContext({
    required this.responsibleStats,
    required this.farmStats,
    required this.categoryStats,
  });

  final Map<String, DecisionGroupStatistics> responsibleStats;

  final Map<String, DecisionGroupStatistics> farmStats;

  final Map<String, DecisionGroupStatistics> categoryStats;

  factory DecisionScoreContext.fromActions(List<ReportActionItemData> actions) {
    final responsibleStats = <String, DecisionGroupStatistics>{};

    final farmStats = <String, DecisionGroupStatistics>{};

    final categoryStats = <String, DecisionGroupStatistics>{};

    for (final action in actions) {
      final responsible = action.responsible.trim();

      if (responsible.isNotEmpty) {
        responsibleStats.update(
          responsible,
          (value) => value.addAction(action),
          ifAbsent: () => DecisionGroupStatistics.fromAction(action),
        );
      }

      final farm = action.farmName.trim().isEmpty
          ? 'Todas as fazendas'
          : action.farmName.trim();

      farmStats.update(
        farm,
        (value) => value.addAction(action),
        ifAbsent: () => DecisionGroupStatistics.fromAction(action),
      );

      final category = decisionActionCategory(action);

      categoryStats.update(
        category,
        (value) => value.addAction(action),
        ifAbsent: () => DecisionGroupStatistics.fromAction(action),
      );
    }

    return DecisionScoreContext(
      responsibleStats: responsibleStats,
      farmStats: farmStats,
      categoryStats: categoryStats,
    );
  }
}

class DecisionGroupStatistics {
  const DecisionGroupStatistics({
    required this.totalCount,
    required this.openCount,
    required this.completedCount,
    required this.overdueCount,
    required this.urgentCount,
  });

  factory DecisionGroupStatistics.fromAction(ReportActionItemData action) {
    return DecisionGroupStatistics(
      totalCount: 1,
      openCount: action.isOpen ? 1 : 0,
      completedCount: action.isCompleted ? 1 : 0,
      overdueCount: action.isOverdue ? 1 : 0,
      urgentCount: action.isUrgent && action.isOpen ? 1 : 0,
    );
  }

  final int totalCount;
  final int openCount;
  final int completedCount;
  final int overdueCount;
  final int urgentCount;

  DecisionGroupStatistics addAction(ReportActionItemData action) {
    return DecisionGroupStatistics(
      totalCount: totalCount + 1,
      openCount: openCount + (action.isOpen ? 1 : 0),
      completedCount: completedCount + (action.isCompleted ? 1 : 0),
      overdueCount: overdueCount + (action.isOverdue ? 1 : 0),
      urgentCount: urgentCount + (action.isUrgent && action.isOpen ? 1 : 0),
    );
  }
}

class DecisionActionScore {
  const DecisionActionScore({
    required this.actionId,
    required this.priorityScore,
    required this.riskScore,
    required this.opportunityScore,
    required this.delayProbability,
    required this.estimatedImpact,
    required this.level,
    required this.reasons,
    required this.recommendation,
    required this.components,
  });

  final String actionId;

  final double priorityScore;
  final double riskScore;
  final double opportunityScore;
  final double delayProbability;
  final double estimatedImpact;

  final ExecutiveDecisionLevel level;

  final List<String> reasons;
  final String recommendation;

  final List<DecisionScoreComponent> components;

  bool get isCritical {
    return level == ExecutiveDecisionLevel.critical;
  }

  bool get isHighPriority {
    return priorityScore >= 70;
  }

  bool get hasHighDelayRisk {
    return delayProbability >= 0.70;
  }

  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'priorityScore': priorityScore,
      'riskScore': riskScore,
      'opportunityScore': opportunityScore,
      'delayProbability': delayProbability,
      'estimatedImpact': estimatedImpact,
      'level': level.name,
      'reasons': reasons,
      'recommendation': recommendation,
      'components': components.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class DecisionScoreComponent {
  const DecisionScoreComponent({
    required this.id,
    required this.title,
    required this.value,
    required this.weight,
    required this.weightedValue,
    required this.explanation,
  });

  final String id;
  final String title;
  final double value;
  final double weight;
  final double weightedValue;
  final String explanation;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'weight': weight,
      'weightedValue': weightedValue,
      'explanation': explanation,
    };
  }
}

class _DecisionFactorData {
  const _DecisionFactorData({required this.score, required this.explanation});

  final double score;
  final String explanation;
}

ExecutiveDecisionLevel decisionLevelFromScore(double score) {
  if (score >= 85) {
    return ExecutiveDecisionLevel.critical;
  }

  if (score >= 70) {
    return ExecutiveDecisionLevel.attention;
  }

  if (score >= 50) {
    return ExecutiveDecisionLevel.normal;
  }

  if (score >= 30) {
    return ExecutiveDecisionLevel.good;
  }

  return ExecutiveDecisionLevel.excellent;
}

double clampDecisionScore(double value) {
  return value.clamp(0.0, 100.0);
}

DateTime? tryParseDecisionDate(String value) {
  final normalized = value.trim();

  if (normalized.isEmpty) {
    return null;
  }

  final datePart = normalized.split(' ').first;

  final parts = datePart.split('/');

  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return null;
  }

  final date = DateTime(year, month, day);

  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}

String decisionActionCategory(ReportActionItemData action) {
  final source =
      '${action.title} ${action.action} '
              '${action.notes} ${action.source}'
          .toLowerCase();

  final categories = <String, List<String>>{
    'Reprodução': [
      'reprodução',
      'reproducao',
      'inseminação',
      'inseminacao',
      'prenhez',
      'estro',
      'cio',
      'touros',
      'matrizes',
    ],
    'Sanidade': [
      'sanidade',
      'vacina',
      'vacinação',
      'vacinacao',
      'doença',
      'doenca',
      'parasita',
      'vermífugo',
      'vermifugo',
      'tratamento',
    ],
    'Nutrição': [
      'nutrição',
      'nutricao',
      'alimentação',
      'alimentacao',
      'ração',
      'racao',
      'suplemento',
      'mineral',
      'pastagem',
      'pasto',
    ],
    'Financeiro': [
      'financeiro',
      'custo',
      'receita',
      'despesa',
      'margem',
      'lucro',
      'prejuízo',
      'prejuizo',
    ],
    'Manejo': [
      'manejo',
      'curral',
      'lote',
      'pesagem',
      'identificação',
      'identificacao',
      'brinco',
    ],
    'Gestão': [
      'gestão',
      'gestao',
      'indicador',
      'registro',
      'controle',
      'planejamento',
      'processo',
    ],
  };

  for (final entry in categories.entries) {
    for (final keyword in entry.value) {
      if (source.contains(keyword)) {
        return entry.key;
      }
    }
  }

  return 'Outros';
}

String formatDecisionPercentage(double value) {
  return '${(value * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
}
