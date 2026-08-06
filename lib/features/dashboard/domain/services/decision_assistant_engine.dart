import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_priority_engine.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/decision_score_engine.dart';

class DecisionAssistantEngine {
  const DecisionAssistantEngine();

  ExecutiveAssistantMessage buildMessage({
    required List<ExecutivePriorityAction> priorityActions,
    required List<ExecutiveDecisionRankingItem> farmRiskRanking,
    required List<ExecutiveDecisionRankingItem> responsibleRiskRanking,
    required List<ExecutiveDecisionRankingItem> categoryRiskRanking,
    required List<ExecutivePredictionData> predictions,
    required DecisionPrioritySummary prioritySummary,
    String consultantName = 'Gabriel',
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();

    final greeting = _buildGreeting(
      consultantName: consultantName,
      now: referenceDate,
    );

    final criticalActions = priorityActions.where((item) {
      return item.priorityLevel == ExecutiveDecisionLevel.critical;
    }).toList();

    final highDelayActions = priorityActions.where((item) {
      return item.delayProbability >= 0.70;
    }).toList();

    final topFarm = farmRiskRanking.isEmpty ? null : farmRiskRanking.first;

    final topResponsible = responsibleRiskRanking.isEmpty
        ? null
        : responsibleRiskRanking.first;

    final topCategory = categoryRiskRanking.isEmpty
        ? null
        : categoryRiskRanking.first;

    final mainPriority = priorityActions.isEmpty ? null : priorityActions.first;

    final secondaryPriority = priorityActions.length < 2
        ? null
        : priorityActions[1];

    final headline = _buildHeadline(
      criticalCount: criticalActions.length,
      attentionCount: prioritySummary.attentionCount,
      predictedDelayCount: highDelayActions.length,
      topFarm: topFarm,
    );

    final message = _buildMainMessage(
      criticalActions: criticalActions,
      highDelayActions: highDelayActions,
      topFarm: topFarm,
      topResponsible: topResponsible,
      topCategory: topCategory,
      predictions: predictions,
      prioritySummary: prioritySummary,
    );

    final mainPriorityText = _buildPriorityText(
      priority: mainPriority,
      prefix: 'Prioridade principal',
    );

    final secondaryPriorityText = _buildPriorityText(
      priority: secondaryPriority,
      prefix: 'Prioridade secundária',
    );

    final callToAction = _buildCallToAction(
      mainPriority: mainPriority,
      criticalCount: criticalActions.length,
      predictedDelayCount: highDelayActions.length,
      topFarm: topFarm,
    );

    return ExecutiveAssistantMessage(
      greeting: greeting,
      headline: headline,
      message: message,
      mainPriority: mainPriorityText,
      secondaryPriority: secondaryPriorityText,
      estimatedGain: prioritySummary.estimatedPerformanceGain,
      callToAction: callToAction,
    );
  }

  String _buildGreeting({
    required String consultantName,
    required DateTime now,
  }) {
    final name = consultantName.trim().isEmpty
        ? 'consultor'
        : consultantName.trim();

    if (now.hour < 12) {
      return 'Bom dia, $name.';
    }

    if (now.hour < 18) {
      return 'Boa tarde, $name.';
    }

    return 'Boa noite, $name.';
  }

  String _buildHeadline({
    required int criticalCount,
    required int attentionCount,
    required int predictedDelayCount,
    required ExecutiveDecisionRankingItem? topFarm,
  }) {
    if (criticalCount > 0) {
      return 'Existem $criticalCount '
          '${criticalCount == 1 ? 'prioridade crítica' : 'prioridades críticas'} '
          'que exigem ação imediata.';
    }

    if (predictedDelayCount > 0) {
      return '$predictedDelayCount '
          '${predictedDelayCount == 1 ? 'ação apresenta' : 'ações apresentam'} '
          'alta chance de atraso.';
    }

    if (attentionCount > 0) {
      return 'A operação possui $attentionCount '
          '${attentionCount == 1 ? 'ponto de atenção' : 'pontos de atenção'} '
          'que devem ser acompanhados.';
    }

    if (topFarm != null && topFarm.level == ExecutiveDecisionLevel.attention) {
      return '${topFarm.label} concentra o maior nível de atenção da operação.';
    }

    return 'A operação está estável e sem prioridades críticas no momento.';
  }

  String _buildMainMessage({
    required List<ExecutivePriorityAction> criticalActions,
    required List<ExecutivePriorityAction> highDelayActions,
    required ExecutiveDecisionRankingItem? topFarm,
    required ExecutiveDecisionRankingItem? topResponsible,
    required ExecutiveDecisionRankingItem? topCategory,
    required List<ExecutivePredictionData> predictions,
    required DecisionPrioritySummary prioritySummary,
  }) {
    final buffer = StringBuffer();

    if (criticalActions.isNotEmpty) {
      buffer.write(
        'Foram identificadas '
        '${criticalActions.length} '
        '${criticalActions.length == 1 ? 'ação crítica' : 'ações críticas'} '
        'na fila de decisão. ',
      );
    }

    if (highDelayActions.isNotEmpty) {
      buffer.write(
        '${highDelayActions.length} '
        '${highDelayActions.length == 1 ? 'ação possui' : 'ações possuem'} '
        'probabilidade elevada de atraso. ',
      );
    }

    if (topFarm != null) {
      buffer.write(
        '${topFarm.label} apresenta o maior risco entre as fazendas, '
        'com score de '
        '${topFarm.riskScore.toStringAsFixed(1).replaceAll('.', ',')} pontos. ',
      );
    }

    if (topResponsible != null && topResponsible.openCount > 0) {
      buffer.write(
        '${topResponsible.label} concentra '
        '${topResponsible.openCount} '
        '${topResponsible.openCount == 1 ? 'ação aberta' : 'ações abertas'}',
      );

      if (topResponsible.overdueCount > 0) {
        buffer.write(
          ', sendo ${topResponsible.overdueCount} '
          '${topResponsible.overdueCount == 1 ? 'atrasada' : 'atrasadas'}',
        );
      }

      buffer.write('. ');
    }

    if (topCategory != null) {
      buffer.write(
        'A categoria ${topCategory.label} é a mais sensível no momento. ',
      );
    }

    final criticalPredictions = predictions.where((item) {
      return item.level == ExecutiveDecisionLevel.critical;
    }).length;

    if (criticalPredictions > 0) {
      buffer.write(
        'O motor preditivo identificou '
        '$criticalPredictions '
        '${criticalPredictions == 1 ? 'previsão crítica' : 'previsões críticas'} '
        'para os próximos dias. ',
      );
    }

    if (prioritySummary.estimatedPerformanceGain > 0) {
      buffer.write(
        'A execução das cinco principais decisões pode elevar o índice geral em aproximadamente '
        '${prioritySummary.estimatedPerformanceGain.toStringAsFixed(1).replaceAll('.', ',')} pontos.',
      );
    }

    if (buffer.isEmpty) {
      buffer.write(
        'Nenhum risco relevante foi identificado. '
        'Mantenha a revisão semanal das ações, responsáveis e prazos.',
      );
    }

    return buffer.toString().trim();
  }

  String _buildPriorityText({
    required ExecutivePriorityAction? priority,
    required String prefix,
  }) {
    if (priority == null) {
      return '$prefix: nenhuma ação prioritária identificada.';
    }

    final buffer = StringBuffer();

    buffer.write('$prefix: ${priority.title}');

    if (priority.farmName.isNotEmpty) {
      buffer.write(' — ${priority.farmName}');
    }

    buffer.write(
      '. Score de prioridade: '
      '${priority.priorityScore.toStringAsFixed(1).replaceAll('.', ',')} pontos',
    );

    if (priority.delayProbability >= 0.70) {
      buffer.write(
        ', com '
        '${formatDecisionPercentage(priority.delayProbability)} '
        'de probabilidade de atraso',
      );
    }

    buffer.write('.');

    return buffer.toString();
  }

  String _buildCallToAction({
    required ExecutivePriorityAction? mainPriority,
    required int criticalCount,
    required int predictedDelayCount,
    required ExecutiveDecisionRankingItem? topFarm,
  }) {
    if (mainPriority == null) {
      return 'Revise o plano semanalmente e mantenha os registros atualizados.';
    }

    if (criticalCount > 0) {
      return 'Inicie pela ação "${mainPriority.title}", confirme o responsável e acompanhe a execução ainda hoje.';
    }

    if (predictedDelayCount > 0) {
      return 'Antecipe o acompanhamento das ações com maior risco de atraso e remova impedimentos antes do prazo.';
    }

    if (topFarm != null && topFarm.level == ExecutiveDecisionLevel.attention) {
      return 'Priorize uma revisão das ações da ${topFarm.label} e confirme os próximos vencimentos.';
    }

    return 'Comece pela ação "${mainPriority.title}" e atualize o progresso ao final do dia.';
  }
}

class DecisionAssistantBrief {
  const DecisionAssistantBrief({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.level,
  });

  final String title;
  final String message;
  final String actionLabel;
  final ExecutiveDecisionLevel level;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'actionLabel': actionLabel,
      'level': level.name,
    };
  }
}

DecisionAssistantBrief buildDecisionAssistantBrief({
  required ExecutiveAssistantMessage message,
  required List<ExecutivePriorityAction> priorities,
}) {
  final main = priorities.isEmpty ? null : priorities.first;

  if (main == null) {
    return DecisionAssistantBrief(
      title: message.headline,
      message: message.message,
      actionLabel: 'Revisar plano de ação',
      level: ExecutiveDecisionLevel.good,
    );
  }

  return DecisionAssistantBrief(
    title: message.headline,
    message: message.message,
    actionLabel: 'Abrir ${main.title}',
    level: main.priorityLevel,
  );
}
