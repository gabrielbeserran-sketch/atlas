import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_feedback_analytics.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_improvement_plan.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';

class AtlasCopilotImprovementService {
  const AtlasCopilotImprovementService();

  AtlasCopilotImprovementPlan buildPlan({
    required AtlasCopilotFeedbackAnalytics analytics,
    DateTime? now,
  }) {
    final priorities = <AtlasCopilotImprovementPriority>[];

    for (final metric in analytics.intentMetrics) {
      if (metric.total < 2) {
        continue;
      }

      final level = _levelFromRate(metric.approvalRate);

      if (level == AtlasCopilotImprovementLevel.excellent ||
          level == AtlasCopilotImprovementLevel.stable) {
        continue;
      }

      priorities.add(
        AtlasCopilotImprovementPriority(
          position: 0,
          title:
              'Revisar respostas sobre ${atlasCopilotIntentLabel(metric.intent)}',
          description:
              'O assunto possui ${metric.total} avaliações e taxa de aprovação de '
              '${metric.approvalRate.toStringAsFixed(0)}%.',
          recommendation: _intentRecommendation(
            metric.intent,
            metric.approvalRate,
          ),
          level: level,
          score: _priorityScore(
            approvalRate: metric.approvalRate,
            total: metric.total,
          ),
          intent: metric.intent,
          contextLabel: null,
        ),
      );
    }

    for (final metric in analytics.contextMetrics) {
      if (metric.total < 2 || metric.approvalRate >= 70) {
        continue;
      }

      priorities.add(
        AtlasCopilotImprovementPriority(
          position: 0,
          title: 'Melhorar respostas em ${metric.contextLabel}',
          description:
              'Este contexto possui ${metric.total} avaliações e taxa de aprovação de '
              '${metric.approvalRate.toStringAsFixed(0)}%.',
          recommendation:
              'Revise se os dados desse contexto estão completos e se as respostas estão usando os indicadores corretos.',
          level: _levelFromRate(metric.approvalRate),
          score: _priorityScore(
            approvalRate: metric.approvalRate,
            total: metric.total,
          ),
          intent: null,
          contextLabel: metric.contextLabel,
        ),
      );
    }

    priorities.sort((first, second) => second.score.compareTo(first.score));

    final orderedPriorities = List.generate(priorities.length, (index) {
      final item = priorities[index];

      return AtlasCopilotImprovementPriority(
        position: index + 1,
        title: item.title,
        description: item.description,
        recommendation: item.recommendation,
        level: item.level,
        score: item.score,
        intent: item.intent,
        contextLabel: item.contextLabel,
      );
    });

    final strengths = _buildStrengths(analytics);

    final overallLevel = _levelFromRate(analytics.approvalRate);

    return AtlasCopilotImprovementPlan(
      generatedAt: now ?? DateTime.now(),
      overallScore: analytics.approvalRate,
      overallLevel: overallLevel,
      summary: _buildSummary(analytics, orderedPriorities),
      priorities: orderedPriorities,
      strengths: strengths,
      recommendedActions: _buildRecommendedActions(
        analytics,
        orderedPriorities,
      ),
    );
  }

  AtlasCopilotImprovementLevel _levelFromRate(double rate) {
    if (rate >= 85) {
      return AtlasCopilotImprovementLevel.excellent;
    }

    if (rate >= 70) {
      return AtlasCopilotImprovementLevel.stable;
    }

    if (rate >= 50) {
      return AtlasCopilotImprovementLevel.attention;
    }

    return AtlasCopilotImprovementLevel.critical;
  }

  double _priorityScore({required double approvalRate, required int total}) {
    final dissatisfaction = 100 - approvalRate;

    final volumeWeight = (total * 3).clamp(0, 30);

    return (dissatisfaction * 0.75 + volumeWeight).clamp(0.0, 100.0);
  }

  String _intentRecommendation(AtlasCopilotIntent intent, double approvalRate) {
    switch (intent) {
      case AtlasCopilotIntent.finance:
        return 'Aumente a explicação sobre receitas, despesas, saldo, margem e causa provável do resultado. Sempre apresente números e uma ação prática.';

      case AtlasCopilotIntent.herd:
        return 'Inclua quantidade de animais, lotação, peso médio, cobertura cadastral e destaque dados ausentes antes de recomendar ações.';

      case AtlasCopilotIntent.inventory:
        return 'Priorize vencimentos, estoque mínimo, quantidade disponível e ordem de reposição. Evite respostas genéricas.';

      case AtlasCopilotIntent.agenda:
        return 'Informe tarefas atrasadas, urgentes, responsáveis e prazos. Termine com a primeira ação que deve ser executada.';

      case AtlasCopilotIntent.priority:
        return 'Explique por que a ação é prioritária, qual risco ela reduz e o que pode acontecer se for adiada.';

      case AtlasCopilotIntent.risk:
        return 'Apresente o risco principal, sua causa, impacto, urgência e recomendação de mitigação.';

      case AtlasCopilotIntent.opportunity:
        return 'Relacione a oportunidade com ganho operacional, impacto esperado e ação necessária para capturá-la.';

      case AtlasCopilotIntent.paddock:
        return 'Use área, ocupação, descanso e lotação para justificar a recomendação sobre piquetes.';

      case AtlasCopilotIntent.responsible:
        return 'Mostre carga de trabalho, atrasos, urgências e possíveis impedimentos antes de recomendar redistribuição.';

      case AtlasCopilotIntent.category:
        return 'Explique quais ações compõem a categoria, qual padrão foi identificado e qual plano preventivo é recomendado.';

      case AtlasCopilotIntent.generalSituation:
      case AtlasCopilotIntent.summary:
        return 'Organize a resposta em situação atual, principal risco, prioridade número 1 e ação recomendada.';

      case AtlasCopilotIntent.strength:
        return 'Explique por que o ponto é positivo e como preservá-lo no dia a dia.';

      case AtlasCopilotIntent.unknown:
        return 'Melhore a identificação da intenção e ofereça perguntas alternativas mais próximas do texto do usuário.';
    }
  }

  List<AtlasCopilotImprovementStrength> _buildStrengths(
    AtlasCopilotFeedbackAnalytics analytics,
  ) {
    final strengths = <AtlasCopilotImprovementStrength>[];

    for (final metric in analytics.intentMetrics) {
      if (metric.total >= 2 && metric.approvalRate >= 80) {
        strengths.add(
          AtlasCopilotImprovementStrength(
            title:
                'Bom desempenho em ${atlasCopilotIntentLabel(metric.intent)}',
            description:
                '${metric.useful} de ${metric.total} respostas foram avaliadas como úteis.',
            score: metric.approvalRate,
          ),
        );
      }
    }

    strengths.sort((first, second) => second.score.compareTo(first.score));

    if (strengths.isEmpty && analytics.approvalRate >= 70) {
      strengths.add(
        AtlasCopilotImprovementStrength(
          title: 'Boa aceitação geral',
          description:
              'A taxa geral de aprovação é de '
              '${analytics.approvalRate.toStringAsFixed(0)}%.',
          score: analytics.approvalRate,
        ),
      );
    }

    return strengths.take(6).toList();
  }

  String _buildSummary(
    AtlasCopilotFeedbackAnalytics analytics,
    List<AtlasCopilotImprovementPriority> priorities,
  ) {
    if (!analytics.hasFeedback) {
      return 'Ainda não existem avaliações suficientes para gerar um plano de melhoria.';
    }

    if (priorities.isEmpty) {
      return 'O Copiloto apresenta boa qualidade geral. Nenhum assunto atingiu nível prioritário de revisão.';
    }

    final first = priorities.first;

    return 'A taxa geral de aprovação é de '
        '${analytics.approvalRate.toStringAsFixed(0)}%. '
        'Foram identificadas ${priorities.length} '
        '${priorities.length == 1 ? 'prioridade de melhoria' : 'prioridades de melhoria'}. '
        'O primeiro ponto a revisar é: ${first.title}.';
  }

  List<String> _buildRecommendedActions(
    AtlasCopilotFeedbackAnalytics analytics,
    List<AtlasCopilotImprovementPriority> priorities,
  ) {
    final actions = <String>[];

    if (priorities.isNotEmpty) {
      actions.add(
        'Revise primeiro as três prioridades com maior score de melhoria.',
      );

      actions.add(
        'Compare as respostas não úteis com os dados disponíveis no contexto.',
      );

      actions.add(
        'Ajuste as regras locais para apresentar números, causa, impacto e ação prática.',
      );
    }

    if (analytics.evaluatedResponses < 10) {
      actions.add(
        'Colete pelo menos 10 avaliações antes de concluir se uma regra precisa ser alterada.',
      );
    }

    if (analytics.notUsefulResponses > 0) {
      actions.add(
        'Use as respostas não úteis como casos de teste para validar as próximas versões.',
      );
    }

    if (actions.isEmpty) {
      actions.add(
        'Mantenha a coleta de feedback e revise o painel semanalmente.',
      );
    }

    return actions;
  }
}
