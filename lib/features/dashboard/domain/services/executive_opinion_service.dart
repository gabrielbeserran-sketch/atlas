import 'package:projeto_atlas/features/dashboard/domain/models/executive_dashboard_data.dart';

class ExecutiveOpinionService {
  const ExecutiveOpinionService();

  ExecutiveOpinionData buildOpinion({
    required ExecutiveDashboardData dashboard,
  }) {
    final totalActions =
        dashboard.findKpi('total_actions')?.numericValue.round() ?? 0;

    final openActions =
        dashboard.findKpi('open_actions')?.numericValue.round() ?? 0;

    final completedActions =
        dashboard.findKpi('completed_actions')?.numericValue.round() ?? 0;

    final overdueActions =
        dashboard.findKpi('overdue_actions')?.numericValue.round() ?? 0;

    final urgentActions =
        dashboard.findKpi('urgent_actions')?.numericValue.round() ?? 0;

    final completionRate =
        dashboard.findKpi('completion_rate')?.numericValue ?? 0;

    final overdueRate = dashboard.findKpi('overdue_rate')?.numericValue ?? 0;

    final performanceIndex = dashboard.generalPerformanceIndex;

    final strengths = _buildStrengths(
      dashboard: dashboard,
      completionRate: completionRate,
      overdueRate: overdueRate,
      completedActions: completedActions,
    );

    final bottlenecks = _buildBottlenecks(
      dashboard: dashboard,
      openActions: openActions,
      overdueActions: overdueActions,
      urgentActions: urgentActions,
      overdueRate: overdueRate,
    );

    final risks = _buildRisks(
      dashboard: dashboard,
      overdueActions: overdueActions,
      urgentActions: urgentActions,
      completionRate: completionRate,
    );

    final opportunities = _buildOpportunities(
      dashboard: dashboard,
      completionRate: completionRate,
      openActions: openActions,
    );

    final priorities = _buildPriorities(
      dashboard: dashboard,
      overdueActions: overdueActions,
      urgentActions: urgentActions,
      openActions: openActions,
    );

    final recommendations = _buildRecommendations(
      dashboard: dashboard,
      completionRate: completionRate,
      overdueRate: overdueRate,
      openActions: openActions,
      overdueActions: overdueActions,
    );

    final classification = _classifyPerformance(performanceIndex);

    final confidence = _calculateConfidence(
      totalActions: totalActions,
      alertCount: dashboard.alerts.length,
      recommendationCount: dashboard.recommendations.length,
      monthlyPointCount: dashboard.monthlyEvolution.length,
      weeklyPointCount: dashboard.weeklyEvolution.length,
    );

    final diagnosis = _buildDiagnosis(
      dashboard: dashboard,
      totalActions: totalActions,
      openActions: openActions,
      completedActions: completedActions,
      overdueActions: overdueActions,
      urgentActions: urgentActions,
      completionRate: completionRate,
      overdueRate: overdueRate,
      performanceIndex: performanceIndex,
      classification: classification,
    );

    final executiveSummary = _buildExecutiveSummary(
      dashboard: dashboard,
      diagnosis: diagnosis,
      priorities: priorities,
      recommendations: recommendations,
      classification: classification,
    );

    return ExecutiveOpinionData(
      generatedAt: dashboard.generatedAt,
      scopeLabel: dashboard.scopeLabel,
      classification: classification,
      performanceIndex: performanceIndex,
      confidence: confidence,
      diagnosis: diagnosis,
      executiveSummary: executiveSummary,
      strengths: strengths,
      bottlenecks: bottlenecks,
      risks: risks,
      opportunities: opportunities,
      priorities: priorities,
      recommendations: recommendations,
    );
  }

  List<ExecutiveOpinionItem> _buildStrengths({
    required ExecutiveDashboardData dashboard,
    required double completionRate,
    required double overdueRate,
    required int completedActions,
  }) {
    final items = <ExecutiveOpinionItem>[];

    if (completionRate >= 0.75) {
      items.add(
        ExecutiveOpinionItem(
          title: 'Boa taxa de conclusão',
          description:
              'A operação apresenta '
              '${formatOpinionPercentage(completionRate)} '
              'de conclusão das ações consideradas.',
          impact: ExecutiveOpinionImpact.high,
          category: 'Execução',
        ),
      );
    }

    if (overdueRate == 0) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Controle de prazos',
          description: 'Não existem ações abertas fora do prazo.',
          impact: ExecutiveOpinionImpact.high,
          category: 'Prazo',
        ),
      );
    }

    if (completedActions > 0) {
      items.add(
        ExecutiveOpinionItem(
          title: 'Capacidade de entrega',
          description:
              '$completedActions '
              '${completedActions == 1 ? 'ação foi concluída' : 'ações foram concluídas'} '
              'e registradas no sistema.',
          impact: ExecutiveOpinionImpact.medium,
          category: 'Desempenho',
        ),
      );
    }

    if (dashboard.productivityTrend.isIncreasing) {
      items.add(
        ExecutiveOpinionItem(
          title: 'Produtividade em crescimento',
          description: dashboard.productivityTrend.interpretation,
          impact: ExecutiveOpinionImpact.medium,
          category: 'Tendência',
        ),
      );
    }

    if (dashboard.delayTrend.isDecreasing) {
      items.add(
        ExecutiveOpinionItem(
          title: 'Redução dos atrasos',
          description: dashboard.delayTrend.interpretation,
          impact: ExecutiveOpinionImpact.medium,
          category: 'Tendência',
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Base de acompanhamento estruturada',
          description:
              'As ações estão organizadas em um fluxo de acompanhamento, permitindo evolução contínua da gestão.',
          impact: ExecutiveOpinionImpact.low,
          category: 'Gestão',
        ),
      );
    }

    return items;
  }

  List<ExecutiveOpinionItem> _buildBottlenecks({
    required ExecutiveDashboardData dashboard,
    required int openActions,
    required int overdueActions,
    required int urgentActions,
    required double overdueRate,
  }) {
    final items = <ExecutiveOpinionItem>[];

    if (overdueActions > 0) {
      items.add(
        ExecutiveOpinionItem(
          title: 'Ações fora do prazo',
          description:
              '$overdueActions '
              '${overdueActions == 1 ? 'ação está' : 'ações estão'} '
              'atrasadas, representando '
              '${formatOpinionPercentage(overdueRate)} '
              'das ações consideradas.',
          impact: overdueRate >= 0.25
              ? ExecutiveOpinionImpact.critical
              : ExecutiveOpinionImpact.high,
          category: 'Prazo',
        ),
      );
    }

    if (urgentActions > 0) {
      items.add(
        ExecutiveOpinionItem(
          title: 'Concentração de urgências',
          description:
              '$urgentActions '
              '${urgentActions == 1 ? 'ação urgente permanece aberta' : 'ações urgentes permanecem abertas'}.',
          impact: ExecutiveOpinionImpact.high,
          category: 'Prioridade',
        ),
      );
    }

    for (final alert in dashboard.alerts) {
      if (alert.id == 'without_responsible') {
        items.add(
          ExecutiveOpinionItem(
            title: 'Responsabilidades indefinidas',
            description: alert.message,
            impact: ExecutiveOpinionImpact.high,
            category: 'Responsabilidade',
          ),
        );
      }

      if (alert.id == 'responsible_overload') {
        items.add(
          ExecutiveOpinionItem(
            title: 'Possível sobrecarga operacional',
            description: alert.message,
            impact: ExecutiveOpinionImpact.medium,
            category: 'Equipe',
          ),
        );
      }
    }

    if (openActions > 0 && dashboard.responsibleRanking.isEmpty) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Ausência de distribuição por responsável',
          description:
              'Existem ações abertas, mas não há responsáveis suficientes definidos para avaliação de desempenho.',
          impact: ExecutiveOpinionImpact.high,
          category: 'Responsabilidade',
        ),
      );
    }

    return items;
  }

  List<ExecutiveOpinionItem> _buildRisks({
    required ExecutiveDashboardData dashboard,
    required int overdueActions,
    required int urgentActions,
    required double completionRate,
  }) {
    final items = <ExecutiveOpinionItem>[];

    if (overdueActions > 0 && urgentActions > 0) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Acúmulo de criticidade',
          description:
              'A presença simultânea de ações urgentes e atrasadas aumenta o risco de perda de controle operacional.',
          impact: ExecutiveOpinionImpact.critical,
          category: 'Operação',
        ),
      );
    }

    if (completionRate < 0.40) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Baixo ritmo de conclusão',
          description:
              'A taxa de conclusão abaixo de 40% pode indicar dificuldade de execução ou excesso de ações abertas.',
          impact: ExecutiveOpinionImpact.high,
          category: 'Execução',
        ),
      );
    }

    if (dashboard.delayTrend.isIncreasing) {
      items.add(
        ExecutiveOpinionItem(
          title: 'Tendência de aumento dos atrasos',
          description: dashboard.delayTrend.interpretation,
          impact: ExecutiveOpinionImpact.high,
          category: 'Tendência',
        ),
      );
    }

    if (dashboard.productivityTrend.isDecreasing) {
      items.add(
        ExecutiveOpinionItem(
          title: 'Queda de produtividade',
          description: dashboard.productivityTrend.interpretation,
          impact: ExecutiveOpinionImpact.medium,
          category: 'Tendência',
        ),
      );
    }

    return items;
  }

  List<ExecutiveOpinionItem> _buildOpportunities({
    required ExecutiveDashboardData dashboard,
    required double completionRate,
    required int openActions,
  }) {
    final items = <ExecutiveOpinionItem>[];

    if (openActions > 0) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Priorização por impacto',
          description:
              'A organização das ações abertas por impacto, urgência e prazo pode acelerar os resultados.',
          impact: ExecutiveOpinionImpact.high,
          category: 'Planejamento',
        ),
      );
    }

    if (completionRate >= 0.40 && completionRate < 0.75) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Elevar o ritmo de execução',
          description:
              'A operação já apresenta evolução e pode avançar com revisões semanais mais objetivas.',
          impact: ExecutiveOpinionImpact.medium,
          category: 'Execução',
        ),
      );
    }

    if (dashboard.farmRanking.length > 1) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Comparação entre propriedades',
          description:
              'O ranking por fazenda permite identificar práticas de execução que podem ser replicadas nas propriedades com menor desempenho.',
          impact: ExecutiveOpinionImpact.medium,
          category: 'Benchmarking',
        ),
      );
    }

    if (dashboard.responsibleRanking.length > 1) {
      items.add(
        const ExecutiveOpinionItem(
          title: 'Redistribuição baseada em desempenho',
          description:
              'O ranking por responsável pode apoiar uma distribuição mais equilibrada das atividades.',
          impact: ExecutiveOpinionImpact.medium,
          category: 'Equipe',
        ),
      );
    }

    return items;
  }

  List<ExecutiveOpinionPriorityItem> _buildPriorities({
    required ExecutiveDashboardData dashboard,
    required int overdueActions,
    required int urgentActions,
    required int openActions,
  }) {
    final items = <ExecutiveOpinionPriorityItem>[];

    var position = 1;

    if (overdueActions > 0) {
      items.add(
        ExecutiveOpinionPriorityItem(
          position: position++,
          title: 'Tratar ações atrasadas',
          description:
              'Revisar imediatamente as ações vencidas, responsáveis e novos prazos.',
          deadline: 'Imediato',
          expectedResult:
              'Redução do risco operacional e retomada do controle dos prazos.',
        ),
      );
    }

    if (urgentActions > 0) {
      items.add(
        ExecutiveOpinionPriorityItem(
          position: position++,
          title: 'Executar prioridades urgentes',
          description:
              'Confirmar responsáveis e remover impedimentos das ações urgentes.',
          deadline: 'Até 48 horas',
          expectedResult: 'Redução do acúmulo de criticidade.',
        ),
      );
    }

    for (final alert in dashboard.alerts) {
      if (alert.id == 'without_responsible') {
        items.add(
          ExecutiveOpinionPriorityItem(
            position: position++,
            title: 'Definir responsáveis',
            description:
                'Atribuir um responsável para cada ação aberta sem definição.',
            deadline: 'Até 3 dias',
            expectedResult: 'Maior clareza de responsabilidade e cobrança.',
          ),
        );
      }
    }

    if (openActions > 0) {
      items.add(
        ExecutiveOpinionPriorityItem(
          position: position++,
          title: 'Revisar o plano semanalmente',
          description:
              'Atualizar status, prazo, responsável e evidências de conclusão.',
          deadline: 'Semanal',
          expectedResult: 'Melhoria contínua da taxa de conclusão.',
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const ExecutiveOpinionPriorityItem(
          position: 1,
          title: 'Manter o acompanhamento',
          description:
              'Continuar registrando resultados e revisando os indicadores.',
          deadline: 'Semanal',
          expectedResult: 'Preservação do bom desempenho operacional.',
        ),
      );
    }

    return items;
  }

  List<ExecutiveOpinionRecommendation> _buildRecommendations({
    required ExecutiveDashboardData dashboard,
    required double completionRate,
    required double overdueRate,
    required int openActions,
    required int overdueActions,
  }) {
    final items = <ExecutiveOpinionRecommendation>[];

    for (final recommendation in dashboard.recommendations) {
      items.add(
        ExecutiveOpinionRecommendation(
          title: recommendation.title,
          explanation: recommendation.message,
          action: recommendation.recommendedAction,
          priority: recommendation.priority.name,
          confidence: recommendation.confidence,
        ),
      );
    }

    if (overdueRate >= 0.25) {
      items.add(
        const ExecutiveOpinionRecommendation(
          title: 'Criar rotina de cobrança de prazos',
          explanation:
              'A taxa de atraso indica necessidade de maior frequência de acompanhamento.',
          action:
              'Realizar uma reunião curta semanal com foco exclusivo nas ações vencidas e próximas do prazo.',
          priority: 'critical',
          confidence: 0.96,
        ),
      );
    }

    if (completionRate < 0.40 && openActions >= 5) {
      items.add(
        const ExecutiveOpinionRecommendation(
          title: 'Reduzir o trabalho em andamento',
          explanation:
              'Muitas ações abertas simultaneamente podem reduzir a capacidade de conclusão.',
          action:
              'Limitar a quantidade de ações em andamento e finalizar as mais importantes antes de iniciar novas.',
          priority: 'high',
          confidence: 0.90,
        ),
      );
    }

    if (overdueActions == 0 && completionRate >= 0.75) {
      items.add(
        const ExecutiveOpinionRecommendation(
          title: 'Registrar resultados obtidos',
          explanation:
              'O bom nível de execução deve ser acompanhado por evidências dos resultados.',
          action:
              'Documentar ganhos financeiros, produtivos e operacionais gerados pelas ações concluídas.',
          priority: 'medium',
          confidence: 0.88,
        ),
      );
    }

    return _removeDuplicateRecommendations(items);
  }

  ExecutiveOperationClassification _classifyPerformance(double score) {
    if (score >= 85) {
      return ExecutiveOperationClassification.excellent;
    }

    if (score >= 70) {
      return ExecutiveOperationClassification.good;
    }

    if (score >= 50) {
      return ExecutiveOperationClassification.attention;
    }

    if (score >= 30) {
      return ExecutiveOperationClassification.critical;
    }

    return ExecutiveOperationClassification.severe;
  }

  double _calculateConfidence({
    required int totalActions,
    required int alertCount,
    required int recommendationCount,
    required int monthlyPointCount,
    required int weeklyPointCount,
  }) {
    var score = 0.40;

    if (totalActions >= 5) {
      score += 0.15;
    }

    if (totalActions >= 15) {
      score += 0.10;
    }

    if (alertCount > 0) {
      score += 0.08;
    }

    if (recommendationCount > 0) {
      score += 0.07;
    }

    if (monthlyPointCount >= 6) {
      score += 0.10;
    }

    if (weeklyPointCount >= 4) {
      score += 0.10;
    }

    return score.clamp(0.0, 1.0);
  }

  String _buildDiagnosis({
    required ExecutiveDashboardData dashboard,
    required int totalActions,
    required int openActions,
    required int completedActions,
    required int overdueActions,
    required int urgentActions,
    required double completionRate,
    required double overdueRate,
    required double performanceIndex,
    required ExecutiveOperationClassification classification,
  }) {
    if (totalActions == 0) {
      return 'Não existem ações suficientes para produzir um diagnóstico operacional completo. '
          'O primeiro passo é cadastrar as principais ações gerenciais da propriedade.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A operação foi classificada como '
      '${executiveClassificationLabel(classification).toLowerCase()}, '
      'com índice geral de desempenho de '
      '${performanceIndex.toStringAsFixed(0)} pontos em 100. ',
    );

    buffer.write(
      'Foram analisadas $totalActions ações, '
      'das quais $completedActions estão concluídas e '
      '$openActions permanecem abertas. ',
    );

    buffer.write(
      'A taxa de conclusão é de '
      '${formatOpinionPercentage(completionRate)}',
    );

    if (overdueActions > 0) {
      buffer.write(
        ', enquanto $overdueActions '
        '${overdueActions == 1 ? 'ação está atrasada' : 'ações estão atrasadas'}, '
        'equivalendo a '
        '${formatOpinionPercentage(overdueRate)} '
        'das ações consideradas',
      );
    } else {
      buffer.write(' e não existem ações atrasadas');
    }

    buffer.write('. ');

    if (urgentActions > 0) {
      buffer.write(
        'Também foram identificadas $urgentActions '
        '${urgentActions == 1 ? 'prioridade urgente aberta' : 'prioridades urgentes abertas'}. ',
      );
    }

    if (dashboard.productivityTrend.isIncreasing) {
      buffer.write('A produtividade apresenta tendência de crescimento. ');
    } else if (dashboard.productivityTrend.isDecreasing) {
      buffer.write('A produtividade apresenta tendência de redução. ');
    }

    if (dashboard.delayTrend.isIncreasing) {
      buffer.write(
        'Os atrasos apresentam tendência de aumento e exigem atenção.',
      );
    } else if (dashboard.delayTrend.isDecreasing) {
      buffer.write('Os atrasos apresentam tendência de redução.');
    }

    return buffer.toString().trim();
  }

  String _buildExecutiveSummary({
    required ExecutiveDashboardData dashboard,
    required String diagnosis,
    required List<ExecutiveOpinionPriorityItem> priorities,
    required List<ExecutiveOpinionRecommendation> recommendations,
    required ExecutiveOperationClassification classification,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('PARECER EXECUTIVO — ${dashboard.scopeLabel.toUpperCase()}');

    buffer.writeln();

    buffer.writeln(diagnosis);

    buffer.writeln();

    buffer.writeln('Prioridades recomendadas:');

    for (final priority in priorities.take(4)) {
      buffer.writeln(
        '${priority.position}. ${priority.title} — ${priority.description}',
      );
    }

    buffer.writeln();

    if (recommendations.isNotEmpty) {
      buffer.writeln('Recomendação principal:');

      final main = recommendations.first;

      buffer.writeln('${main.title}: ${main.action}');

      buffer.writeln();
    }

    buffer.write(
      'Conclusão: a operação se encontra em nível '
      '${executiveClassificationLabel(classification).toLowerCase()}. '
      'O acompanhamento contínuo das ações, prazos e responsáveis será determinante para elevar o índice geral de desempenho.',
    );

    return buffer.toString();
  }

  List<ExecutiveOpinionRecommendation> _removeDuplicateRecommendations(
    List<ExecutiveOpinionRecommendation> items,
  ) {
    final result = <ExecutiveOpinionRecommendation>[];

    final titles = <String>{};

    for (final item in items) {
      final key = item.title.trim().toLowerCase();

      if (titles.contains(key)) {
        continue;
      }

      titles.add(key);
      result.add(item);
    }

    result.sort((first, second) {
      return executiveOpinionPriorityWeight(
        second.priority,
      ).compareTo(executiveOpinionPriorityWeight(first.priority));
    });

    return result;
  }
}

class ExecutiveOpinionData {
  const ExecutiveOpinionData({
    required this.generatedAt,
    required this.scopeLabel,
    required this.classification,
    required this.performanceIndex,
    required this.confidence,
    required this.diagnosis,
    required this.executiveSummary,
    required this.strengths,
    required this.bottlenecks,
    required this.risks,
    required this.opportunities,
    required this.priorities,
    required this.recommendations,
  });

  final String generatedAt;
  final String scopeLabel;

  final ExecutiveOperationClassification classification;

  final double performanceIndex;
  final double confidence;

  final String diagnosis;
  final String executiveSummary;

  final List<ExecutiveOpinionItem> strengths;
  final List<ExecutiveOpinionItem> bottlenecks;
  final List<ExecutiveOpinionItem> risks;
  final List<ExecutiveOpinionItem> opportunities;

  final List<ExecutiveOpinionPriorityItem> priorities;

  final List<ExecutiveOpinionRecommendation> recommendations;

  bool get hasCriticalRisks {
    return risks.any((item) {
      return item.impact == ExecutiveOpinionImpact.critical;
    });
  }

  bool get hasBottlenecks {
    return bottlenecks.isNotEmpty;
  }

  bool get hasOpportunities {
    return opportunities.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt,
      'scopeLabel': scopeLabel,
      'classification': classification.name,
      'performanceIndex': performanceIndex,
      'confidence': confidence,
      'diagnosis': diagnosis,
      'executiveSummary': executiveSummary,
      'strengths': strengths.map((item) {
        return item.toJson();
      }).toList(),
      'bottlenecks': bottlenecks.map((item) {
        return item.toJson();
      }).toList(),
      'risks': risks.map((item) {
        return item.toJson();
      }).toList(),
      'opportunities': opportunities.map((item) {
        return item.toJson();
      }).toList(),
      'priorities': priorities.map((item) {
        return item.toJson();
      }).toList(),
      'recommendations': recommendations.map((item) {
        return item.toJson();
      }).toList(),
    };
  }
}

class ExecutiveOpinionItem {
  const ExecutiveOpinionItem({
    required this.title,
    required this.description,
    required this.impact,
    required this.category,
  });

  final String title;
  final String description;
  final ExecutiveOpinionImpact impact;
  final String category;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'impact': impact.name,
      'category': category,
    };
  }
}

class ExecutiveOpinionPriorityItem {
  const ExecutiveOpinionPriorityItem({
    required this.position,
    required this.title,
    required this.description,
    required this.deadline,
    required this.expectedResult,
  });

  final int position;
  final String title;
  final String description;
  final String deadline;
  final String expectedResult;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'title': title,
      'description': description,
      'deadline': deadline,
      'expectedResult': expectedResult,
    };
  }
}

class ExecutiveOpinionRecommendation {
  const ExecutiveOpinionRecommendation({
    required this.title,
    required this.explanation,
    required this.action,
    required this.priority,
    required this.confidence,
  });

  final String title;
  final String explanation;
  final String action;
  final String priority;
  final double confidence;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'explanation': explanation,
      'action': action,
      'priority': priority,
      'confidence': confidence,
    };
  }
}

enum ExecutiveOperationClassification {
  excellent,
  good,
  attention,
  critical,
  severe,
}

enum ExecutiveOpinionImpact { low, medium, high, critical }

String executiveClassificationLabel(
  ExecutiveOperationClassification classification,
) {
  switch (classification) {
    case ExecutiveOperationClassification.excellent:
      return 'Excelente';

    case ExecutiveOperationClassification.good:
      return 'Boa';

    case ExecutiveOperationClassification.attention:
      return 'Atenção';

    case ExecutiveOperationClassification.critical:
      return 'Crítica';

    case ExecutiveOperationClassification.severe:
      return 'Severa';
  }
}

String formatOpinionPercentage(double value) {
  return '${(value * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
}

int executiveOpinionPriorityWeight(String priority) {
  switch (priority) {
    case 'critical':
      return 4;

    case 'high':
      return 3;

    case 'medium':
      return 2;

    case 'low':
      return 1;

    default:
      return 0;
  }
}
