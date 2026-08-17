import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_farm_context.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_response.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/predictive/domain/models/atlas_predictive_scenario.dart';

class AtlasAiResponseService {
  const AtlasAiResponseService();

  AtlasAiResponse answer({
    required String question,
    required AtlasAiFarmContext context,
    List<AtlasAiTrackedAction> trackedActions = const [],
    DateTime? now,
  }) {
    final normalizedQuestion = _normalize(question);

    final intent = _identifyIntent(normalizedQuestion);

    switch (intent) {
      case AtlasAiIntent.generalSituation:
        return _answerGeneralSituation(
          question: question,
          context: context,
          now: now,
        );

      case AtlasAiIntent.mainProblem:
      case AtlasAiIntent.priority:
        return _answerMainPriority(
          question: question,
          context: context,
          now: now,
        );

      case AtlasAiIntent.risks:
        return _answerRisks(question: question, context: context, now: now);

      case AtlasAiIntent.opportunities:
        return _answerOpportunities(
          question: question,
          context: context,
          now: now,
        );

      case AtlasAiIntent.strengths:
        return _answerStrengths(question: question, context: context, now: now);

      case AtlasAiIntent.finance:
        return _answerArea(
          question: question,
          context: context,
          area: AtlasFarmAnalysisArea.finance,
          intent: intent,
          now: now,
        );

      case AtlasAiIntent.herd:
        return _answerArea(
          question: question,
          context: context,
          area: AtlasFarmAnalysisArea.herd,
          intent: intent,
          now: now,
        );

      case AtlasAiIntent.paddocks:
        return _answerArea(
          question: question,
          context: context,
          area: AtlasFarmAnalysisArea.paddock,
          intent: intent,
          now: now,
        );

      case AtlasAiIntent.inventory:
        return _answerArea(
          question: question,
          context: context,
          area: AtlasFarmAnalysisArea.inventory,
          intent: intent,
          now: now,
        );

      case AtlasAiIntent.agenda:
        return _answerArea(
          question: question,
          context: context,
          area: AtlasFarmAnalysisArea.agenda,
          intent: intent,
          now: now,
        );

      case AtlasAiIntent.shortTermPlan:
        return _answerPlan(
          question: question,
          context: context,
          intent: intent,
          actions: context.shortTermActions,
          horizonLabel: 'próximos 7 dias',
          now: now,
        );

      case AtlasAiIntent.mediumTermPlan:
        return _answerPlan(
          question: question,
          context: context,
          intent: intent,
          actions: context.mediumTermActions,
          horizonLabel: 'próximos 30 dias',
          now: now,
        );

      case AtlasAiIntent.longTermPlan:
        return _answerPlan(
          question: question,
          context: context,
          intent: intent,
          actions: context.longTermActions,
          horizonLabel: 'próximos 90 dias',
          now: now,
        );

      case AtlasAiIntent.predictiveDecision:
        return _answerPredictive(
          question: question,
          context: context,
          now: now,
        );

      case AtlasAiIntent.simpleExplanation:
        return _answerSimpleExplanation(
          question: question,
          context: context,
          now: now,
        );

      case AtlasAiIntent.improveScore:
        return _answerImproveScore(
          question: question,
          context: context,
          now: now,
        );

      case AtlasAiIntent.actionProgress:
        return _answerActionProgress(
          question: question,
          context: context,
          trackedActions: trackedActions,
          now: now,
        );

      case AtlasAiIntent.pendingActions:
        return _answerTrackedActions(
          question: question,
          context: context,
          trackedActions: trackedActions,
          intent: intent,
          status: AtlasAiTrackedActionStatus.pending,
          emptyMessage: 'Não existem ações pendentes no acompanhamento atual.',
          now: now,
        );

      case AtlasAiIntent.overdueActions:
        return _answerOverdueActions(
          question: question,
          context: context,
          trackedActions: trackedActions,
          now: now,
        );

      case AtlasAiIntent.completedActions:
        return _answerTrackedActions(
          question: question,
          context: context,
          trackedActions: trackedActions,
          intent: intent,
          status: AtlasAiTrackedActionStatus.completed,
          emptyMessage: 'Nenhuma ação foi marcada como concluída.',
          now: now,
        );

      case AtlasAiIntent.inProgressActions:
        return _answerTrackedActions(
          question: question,
          context: context,
          trackedActions: trackedActions,
          intent: intent,
          status: AtlasAiTrackedActionStatus.inProgress,
          emptyMessage: 'Não existem ações em andamento.',
          now: now,
        );

      case AtlasAiIntent.unknown:
        return _answerUnknown(question: question, context: context, now: now);
    }
  }

  AtlasAiResponse _answerGeneralSituation({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    final weakest = _weakestArea(context);

    final evidences = <AtlasAiEvidence>[
      AtlasAiEvidence(
        label: 'Score geral',
        value: '${context.score.toStringAsFixed(0)}/100',
        description: 'Pontuação consolidada do diagnóstico da propriedade.',
        area: AtlasFarmAnalysisArea.general,
        weight: 1,
      ),
      AtlasAiEvidence(
        label: 'Situação',
        value: atlasDiagnosticLevelLabel(context.level),
        description: 'Classificação atual da fazenda.',
        area: AtlasFarmAnalysisArea.general,
        weight: 0.95,
      ),
    ];

    if (weakest != null) {
      evidences.add(
        AtlasAiEvidence(
          label: 'Área mais fraca',
          value: '${weakest.title}: ${weakest.score.toStringAsFixed(0)}/100',
          description: weakest.analysis,
          area: weakest.area,
          weight: 0.9,
        ),
      );
    }

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.generalSituation,
      directAnswer:
          'A ${context.farmName} está em situação '
          '${atlasDiagnosticLevelLabel(context.level).toLowerCase()}, '
          'com ${context.score.toStringAsFixed(0)} pontos de 100.',
      justification: context.executiveSummary,
      evidences: evidences,
      actionPlan: _mapActions(context.shortTermActions.take(3).toList()),
      nextStep:
          'Abra o Diagnóstico Inteligente para revisar as áreas e executar a prioridade principal.',
      confidence: _confidenceFromContext(context),
      level: context.level,
      actions: const [
        AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Abrir diagnóstico',
          type: AtlasAiNavigationActionType.openDiagnostic,
        ),
      ],
    );
  }

  AtlasAiResponse _answerMainPriority({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    final priority = context.mainPriority;

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.priority,
      directAnswer:
          'A prioridade número 1 da ${context.farmName} é: ${priority.title}.',
      justification: '${priority.description} ${priority.recommendation}',
      evidences: [
        AtlasAiEvidence(
          label: 'Score da prioridade',
          value: priority.score.toStringAsFixed(0),
          description:
              'Quanto maior o valor, maior a urgência e o impacto da intervenção.',
          area: priority.area,
          weight: 1,
        ),
        AtlasAiEvidence(
          label: 'Área afetada',
          value: atlasFarmAreaLabel(priority.area),
          description: 'Módulo diretamente relacionado ao problema.',
          area: priority.area,
          weight: 0.9,
        ),
      ],
      actionPlan: _relatedActions(
        context: context,
        area: priority.area,
        maximum: 3,
      ),
      nextStep:
          'Acesse ${atlasFarmAreaLabel(priority.area)} e inicie a primeira ação recomendada.',
      confidence: _confidenceFromContext(context),
      level: priority.level,
      actions: [
        _navigationForArea(priority.area),
        const AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Ver diagnóstico completo',
          type: AtlasAiNavigationActionType.openDiagnostic,
        ),
      ],
    );
  }

  AtlasAiResponse _answerRisks({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    if (context.risks.isEmpty) {
      return AtlasAiResponse(
        generatedAt: now ?? DateTime.now(),
        question: question,
        intent: AtlasAiIntent.risks,
        directAnswer:
            'Nenhum risco relevante foi identificado no diagnóstico atual.',
        justification:
            'Os dados cadastrados não geraram alertas classificados como risco.',
        evidences: const [],
        actionPlan: _mapActions(context.shortTermActions.take(2).toList()),
        nextStep:
            'Mantenha os registros atualizados e revise o diagnóstico periodicamente.',
        confidence: _confidenceFromContext(context),
        level: AtlasDiagnosticLevel.stable,
        actions: const [
          AtlasAiNavigationAction(
            id: 'open_diagnostic',
            label: 'Revisar diagnóstico',
            type: AtlasAiNavigationActionType.openDiagnostic,
          ),
        ],
      );
    }

    final ordered = [
      ...context.risks,
    ]..sort((first, second) => second.impactScore.compareTo(first.impactScore));

    final first = ordered.first;

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.risks,
      directAnswer: 'O risco mais importante é: ${first.title}.',
      justification: '${first.description} ${first.recommendation}',
      evidences: ordered.take(4).map((item) {
        return AtlasAiEvidence(
          label: item.title,
          value: 'Impacto ${item.impactScore.toStringAsFixed(0)}',
          description: item.description,
          area: item.area,
          weight: item.impactScore / 100,
        );
      }).toList(),
      actionPlan: _relatedActions(
        context: context,
        area: first.area,
        maximum: 3,
      ),
      nextStep:
          'Abra ${atlasFarmAreaLabel(first.area)} e execute a recomendação de mitigação.',
      confidence: _confidenceFromContext(context),
      level: first.level,
      actions: [
        _navigationForArea(first.area),
        const AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Ver todos os riscos',
          type: AtlasAiNavigationActionType.openDiagnostic,
        ),
      ],
    );
  }

  AtlasAiResponse _answerOpportunities({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    if (context.opportunities.isEmpty) {
      return AtlasAiResponse(
        generatedAt: now ?? DateTime.now(),
        question: question,
        intent: AtlasAiIntent.opportunities,
        directAnswer:
            'O diagnóstico atual ainda não possui oportunidades destacadas.',
        justification:
            'Isso pode ocorrer quando os dados são insuficientes ou quando as áreas estão focadas em correções prioritárias.',
        evidences: const [],
        actionPlan: _mapActions(context.mediumTermActions.take(3).toList()),
        nextStep:
            'Complete os registros e revise os cenários da Inteligência Preditiva.',
        confidence: _confidenceFromContext(context),
        level: context.level,
        actions: const [
          AtlasAiNavigationAction(
            id: 'open_predictive',
            label: 'Simular decisões',
            type: AtlasAiNavigationActionType.openPredictive,
          ),
        ],
      );
    }

    final ordered = [
      ...context.opportunities,
    ]..sort((first, second) => second.impactScore.compareTo(first.impactScore));

    final first = ordered.first;

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.opportunities,
      directAnswer: 'A principal oportunidade é: ${first.title}.',
      justification: '${first.description} ${first.recommendation}',
      evidences: ordered.take(4).map((item) {
        return AtlasAiEvidence(
          label: item.title,
          value: 'Potencial ${item.impactScore.toStringAsFixed(0)}',
          description: item.description,
          area: item.area,
          weight: item.impactScore / 100,
        );
      }).toList(),
      actionPlan: _relatedActions(
        context: context,
        area: first.area,
        maximum: 3,
      ),
      nextStep: 'Simule o impacto dessa oportunidade antes de executá-la.',
      confidence: _confidenceFromContext(context),
      level: AtlasDiagnosticLevel.stable,
      actions: [
        const AtlasAiNavigationAction(
          id: 'open_predictive',
          label: 'Simular oportunidade',
          type: AtlasAiNavigationActionType.openPredictive,
        ),
        _navigationForArea(first.area),
      ],
    );
  }

  AtlasAiResponse _answerStrengths({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    if (context.strengths.isEmpty) {
      return AtlasAiResponse(
        generatedAt: now ?? DateTime.now(),
        question: question,
        intent: AtlasAiIntent.strengths,
        directAnswer:
            'Ainda não existem pontos fortes suficientes para destacar.',
        justification:
            'O diagnóstico atual está concentrado em riscos, gargalos e ações corretivas.',
        evidences: const [],
        actionPlan: _mapActions(context.longTermActions.take(2).toList()),
        nextStep:
            'Após executar as prioridades, gere um novo diagnóstico para medir os avanços.',
        confidence: _confidenceFromContext(context),
        level: context.level,
        actions: const [
          AtlasAiNavigationAction(
            id: 'open_diagnostic',
            label: 'Abrir diagnóstico',
            type: AtlasAiNavigationActionType.openDiagnostic,
          ),
        ],
      );
    }

    final ordered = [
      ...context.strengths,
    ]..sort((first, second) => second.impactScore.compareTo(first.impactScore));

    final first = ordered.first;

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.strengths,
      directAnswer: 'O principal ponto forte é: ${first.title}.',
      justification: '${first.description} ${first.recommendation}',
      evidences: ordered.take(4).map((item) {
        return AtlasAiEvidence(
          label: item.title,
          value: atlasDiagnosticLevelLabel(item.level),
          description: item.description,
          area: item.area,
          weight: item.impactScore / 100,
        );
      }).toList(),
      actionPlan: _mapActions(context.longTermActions.take(3).toList()),
      nextStep:
          'Documente a prática positiva e avalie se ela pode ser replicada em outras áreas.',
      confidence: _confidenceFromContext(context),
      level: AtlasDiagnosticLevel.excellent,
      actions: const [
        AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Ver pontos fortes',
          type: AtlasAiNavigationActionType.openDiagnostic,
        ),
      ],
    );
  }

  AtlasAiResponse _answerArea({
    required String question,
    required AtlasAiFarmContext context,
    required AtlasFarmAnalysisArea area,
    required AtlasAiIntent intent,
    DateTime? now,
  }) {
    final areaContext = _findArea(context, area);

    if (areaContext == null) {
      return _answerUnknown(question: question, context: context, now: now);
    }

    final relatedInsights = [
      ...context.risks.where((item) {
        return item.area == area;
      }),
      ...context.bottlenecks.where((item) {
        return item.area == area;
      }),
      ...context.opportunities.where((item) {
        return item.area == area;
      }),
    ]..sort((first, second) => second.impactScore.compareTo(first.impactScore));

    final evidences = <AtlasAiEvidence>[
      AtlasAiEvidence(
        label: 'Score da área',
        value: '${areaContext.score.toStringAsFixed(0)}/100',
        description: areaContext.analysis,
        area: area,
        weight: 1,
      ),
      ...relatedInsights.take(3).map((item) {
        return AtlasAiEvidence(
          label: item.title,
          value: 'Impacto ${item.impactScore.toStringAsFixed(0)}',
          description: item.description,
          area: area,
          weight: item.impactScore / 100,
        );
      }),
    ];

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: intent,
      directAnswer:
          '${areaContext.title} está com '
          '${areaContext.score.toStringAsFixed(0)} pontos e nível '
          '${atlasDiagnosticLevelLabel(areaContext.level).toLowerCase()}.',
      justification: '${areaContext.analysis} ${areaContext.recommendation}',
      evidences: evidences,
      actionPlan: _relatedActions(context: context, area: area, maximum: 4),
      nextStep:
          'Abra ${atlasFarmAreaLabel(area)} para conferir os registros e executar a primeira recomendação.',
      confidence: _confidenceFromContext(context),
      level: areaContext.level,
      actions: [
        _navigationForArea(area),
        const AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Ver diagnóstico',
          type: AtlasAiNavigationActionType.openDiagnostic,
        ),
      ],
    );
  }

  AtlasAiResponse _answerPlan({
    required String question,
    required AtlasAiFarmContext context,
    required AtlasAiIntent intent,
    required List<AtlasAiActionContext> actions,
    required String horizonLabel,
    DateTime? now,
  }) {
    if (actions.isEmpty) {
      return AtlasAiResponse(
        generatedAt: now ?? DateTime.now(),
        question: question,
        intent: intent,
        directAnswer: 'Nenhuma ação foi definida para os $horizonLabel.',
        justification:
            'O diagnóstico atual não gerou atividades para esse horizonte.',
        evidences: const [],
        actionPlan: const [],
        nextStep: 'Revise o diagnóstico e atualize os dados da propriedade.',
        confidence: _confidenceFromContext(context),
        level: context.level,
        actions: const [
          AtlasAiNavigationAction(
            id: 'open_diagnostic',
            label: 'Abrir diagnóstico',
            type: AtlasAiNavigationActionType.openDiagnostic,
          ),
        ],
      );
    }

    final first = actions.first;

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: intent,
      directAnswer: 'Para os $horizonLabel, a primeira ação é: ${first.title}.',
      justification:
          '${first.description} O resultado esperado é ${first.expectedResult.toLowerCase()}',
      evidences: [
        AtlasAiEvidence(
          label: 'Quantidade de ações',
          value: actions.length.toString(),
          description: 'Número de atividades previstas para o período.',
          area: AtlasFarmAnalysisArea.general,
          weight: 0.85,
        ),
        AtlasAiEvidence(
          label: 'Primeira área',
          value: atlasFarmAreaLabel(first.area),
          description: 'Área relacionada à primeira ação.',
          area: first.area,
          weight: 1,
        ),
      ],
      actionPlan: _mapActions(actions.take(5).toList()),
      nextStep:
          'Inicie a ação ${first.position} e registre sua execução no módulo correspondente.',
      confidence: _confidenceFromContext(context),
      level: first.level,
      actions: [
        _navigationForArea(first.area),
        const AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Ver plano completo',
          type: AtlasAiNavigationActionType.openDiagnostic,
        ),
      ],
    );
  }

  AtlasAiResponse _answerPredictive({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    if (context.predictiveScenarios.isEmpty) {
      return AtlasAiResponse(
        generatedAt: now ?? DateTime.now(),
        question: question,
        intent: AtlasAiIntent.predictiveDecision,
        directAnswer:
            'Ainda não existem cenários preditivos suficientes para indicar a melhor decisão.',
        justification:
            'A Inteligência Preditiva depende dos dados financeiros, operacionais, zootécnicos, de estoque e de piquetes.',
        evidences: const [],
        actionPlan: _mapActions(context.shortTermActions.take(2).toList()),
        nextStep:
            'Abra a Inteligência Preditiva e gere os cenários recomendados.',
        confidence: 60,
        level: context.level,
        actions: const [
          AtlasAiNavigationAction(
            id: 'open_predictive',
            label: 'Simular decisões',
            type: AtlasAiNavigationActionType.openPredictive,
          ),
        ],
      );
    }

    final ordered = [...context.predictiveScenarios]
      ..sort((first, second) {
        final firstScore = _predictiveScore(first);

        final secondScore = _predictiveScore(second);

        return secondScore.compareTo(firstScore);
      });

    final best = ordered.first;

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.predictiveDecision,
      directAnswer: 'A melhor decisão simulada é: ${best.title}.',
      justification:
          '${best.recommendation} O cenário projeta '
          '${best.scoreVariation >= 0 ? '+' : ''}'
          '${best.scoreVariation.toStringAsFixed(1)} pontos no score, '
          '${best.riskReductionPercent.toStringAsFixed(0)}% de redução de risco '
          'e impacto financeiro provável de ${_currency(best.financialImpact)}.',
      evidences: ordered.take(4).map((item) {
        return AtlasAiEvidence(
          label: item.title,
          value:
              '${item.scoreVariation >= 0 ? '+' : ''}'
              '${item.scoreVariation.toStringAsFixed(1)} pontos',
          description:
              'Confiança ${item.confidence.toStringAsFixed(0)}%, '
              'redução de risco ${item.riskReductionPercent.toStringAsFixed(0)}% '
              'e impacto provável ${_currency(item.financialImpact)}.',
          area: _areaForPredictiveType(item.type),
          weight: item.confidence / 100,
        );
      }).toList(),
      actionPlan: _relatedActions(
        context: context,
        area: _areaForPredictiveType(best.type),
        maximum: 3,
      ),
      nextStep:
          'Abra a Inteligência Preditiva, revise os três cenários e confirme se o esforço é viável.',
      confidence: best.confidence,
      level: best.scoreVariation >= 8
          ? AtlasDiagnosticLevel.excellent
          : AtlasDiagnosticLevel.stable,
      actions: const [
        AtlasAiNavigationAction(
          id: 'open_predictive',
          label: 'Abrir simulação',
          type: AtlasAiNavigationActionType.openPredictive,
        ),
      ],
    );
  }

  AtlasAiResponse _answerSimpleExplanation({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.simpleExplanation,
      directAnswer: context.simpleSummary,
      justification:
          'Essa explicação resume o score, a situação atual e a prioridade principal sem termos técnicos.',
      evidences: [
        AtlasAiEvidence(
          label: 'Score',
          value: '${context.score.toStringAsFixed(0)}/100',
          description: 'Representa a situação geral da fazenda.',
          area: AtlasFarmAnalysisArea.general,
          weight: 1,
        ),
        AtlasAiEvidence(
          label: 'Prioridade',
          value: context.mainPriority.title,
          description: context.mainPriority.description,
          area: context.mainPriority.area,
          weight: 0.95,
        ),
      ],
      actionPlan: _mapActions(context.shortTermActions.take(3).toList()),
      nextStep: 'Comece pela primeira ação do plano de 7 dias.',
      confidence: _confidenceFromContext(context),
      level: context.level,
      actions: const [
        AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Ver diagnóstico',
          type: AtlasAiNavigationActionType.openDiagnostic,
        ),
      ],
    );
  }

  AtlasAiResponse _answerImproveScore({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    final ordered = [...context.areaContexts]
      ..sort((first, second) => first.score.compareTo(second.score));

    if (ordered.isEmpty) {
      return _answerUnknown(question: question, context: context, now: now);
    }

    final weakest = ordered.first;

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.improveScore,
      directAnswer:
          'A forma mais direta de melhorar o score é elevar o desempenho de ${weakest.title.toLowerCase()}.',
      justification:
          'Essa é a área com menor pontuação: '
          '${weakest.score.toStringAsFixed(0)}/100. '
          '${weakest.analysis} ${weakest.recommendation}',
      evidences: ordered.take(3).map((item) {
        return AtlasAiEvidence(
          label: item.title,
          value: '${item.score.toStringAsFixed(0)}/100',
          description: item.analysis,
          area: item.area,
          weight: (100 - item.score) / 100,
        );
      }).toList(),
      actionPlan: _relatedActions(
        context: context,
        area: weakest.area,
        maximum: 4,
      ),
      nextStep:
          'Abra ${atlasFarmAreaLabel(weakest.area)} e corrija primeiro os registros ou processos com maior impacto.',
      confidence: _confidenceFromContext(context),
      level: weakest.level,
      actions: [
        _navigationForArea(weakest.area),
        const AtlasAiNavigationAction(
          id: 'open_predictive',
          label: 'Simular melhoria',
          type: AtlasAiNavigationActionType.openPredictive,
        ),
      ],
    );
  }

  AtlasAiResponse _answerActionProgress({
    required String question,
    required AtlasAiFarmContext context,
    required List<AtlasAiTrackedAction> trackedActions,
    DateTime? now,
  }) {
    final progress = _calculateActionProgress(trackedActions);

    if (!progress.hasActions) {
      return AtlasAiResponse(
        generatedAt: now ?? DateTime.now(),
        question: question,
        intent: AtlasAiIntent.actionProgress,
        directAnswer:
            'Ainda não existem ações acompanhadas para a ${context.farmName}.',
        justification:
            'As ações são criadas automaticamente a partir dos planos sugeridos nas respostas do Atlas IA.',
        evidences: const [],
        actionPlan: _mapActions(context.shortTermActions.take(3).toList()),
        nextStep:
            'Faça uma pergunta sobre prioridades ou plano de 7 dias para gerar ações acompanháveis.',
        confidence: 90,
        level: context.level,
        actions: const [
          AtlasAiNavigationAction(
            id: 'open_diagnostic',
            label: 'Abrir diagnóstico',
            type: AtlasAiNavigationActionType.openDiagnostic,
          ),
        ],
      );
    }

    final nextAction = _nextTrackedAction(trackedActions);

    final evidences = <AtlasAiEvidence>[
      AtlasAiEvidence(
        label: 'Progresso geral',
        value: '${progress.completionPercent.toStringAsFixed(0)}%',
        description:
            '${progress.completed} concluídas de ${progress.validTotal} ações válidas.',
        area: AtlasFarmAnalysisArea.general,
        weight: 1,
      ),
      AtlasAiEvidence(
        label: 'Pendentes',
        value: progress.pending.toString(),
        description: 'Ações que ainda não foram iniciadas.',
        area: AtlasFarmAnalysisArea.general,
        weight: 0.85,
      ),
      AtlasAiEvidence(
        label: 'Em andamento',
        value: progress.inProgress.toString(),
        description: 'Ações cuja execução já começou.',
        area: AtlasFarmAnalysisArea.general,
        weight: 0.9,
      ),
      AtlasAiEvidence(
        label: 'Atrasadas',
        value: progress.overdue.toString(),
        description: 'Ações abertas cujo prazo previsto já terminou.',
        area: AtlasFarmAnalysisArea.general,
        weight: progress.overdue > 0 ? 1 : 0.7,
      ),
    ];

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.actionProgress,
      directAnswer:
          'O progresso das ações da ${context.farmName} é de '
          '${progress.completionPercent.toStringAsFixed(0)}%.',
      justification:
          '${progress.completed} ações foram concluídas, '
          '${progress.inProgress} estão em andamento, '
          '${progress.pending} permanecem pendentes e '
          '${progress.overdue} estão atrasadas.',
      evidences: evidences,
      actionPlan: nextAction == null
          ? const []
          : [_trackedActionStep(action: nextAction, position: 1)],
      nextStep: nextAction == null
          ? 'Revise as ações concluídas e gere um novo plano quando necessário.'
          : 'A próxima ação recomendada é "${nextAction.title}".',
      confidence: 96,
      level: progress.overdue > 0
          ? AtlasDiagnosticLevel.attention
          : progress.completionPercent >= 80
          ? AtlasDiagnosticLevel.excellent
          : AtlasDiagnosticLevel.stable,
      actions: [if (nextAction != null) _navigationForArea(nextAction.area)],
    );
  }

  AtlasAiResponse _answerTrackedActions({
    required String question,
    required AtlasAiFarmContext context,
    required List<AtlasAiTrackedAction> trackedActions,
    required AtlasAiIntent intent,
    required AtlasAiTrackedActionStatus status,
    required String emptyMessage,
    DateTime? now,
  }) {
    final items =
        trackedActions.where((item) {
            return item.status == status;
          }).toList()
          ..sort((first, second) => first.dueDate.compareTo(second.dueDate));

    if (items.isEmpty) {
      return AtlasAiResponse(
        generatedAt: now ?? DateTime.now(),
        question: question,
        intent: intent,
        directAnswer: emptyMessage,
        justification:
            'O acompanhamento considera os status registrados no painel Ações da Consultoria.',
        evidences: const [],
        actionPlan: const [],
        nextStep: 'Abra o painel de ações para revisar ou atualizar os status.',
        confidence: 96,
        level: AtlasDiagnosticLevel.stable,
        actions: const [],
      );
    }

    final first = items.first;
    final label = atlasAiTrackedActionStatusLabel(status).toLowerCase();

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: intent,
      directAnswer:
          'Existem ${items.length} '
          '${items.length == 1 ? 'ação' : 'ações'} $label.',
      justification:
          'A primeira da lista é "${first.title}", '
          'na área ${atlasFarmAreaLabel(first.area)}, '
          'com prazo em ${_formatDate(first.dueDate)}.',
      evidences: items.take(5).map((item) {
        return AtlasAiEvidence(
          label: item.title,
          value:
              '${atlasAiTrackedActionStatusLabel(item.status)} · '
              '${_formatDate(item.dueDate)}',
          description: item.notes.isEmpty
              ? item.description
              : '${item.description} Observação: ${item.notes}',
          area: item.area,
          weight: item.isOverdue ? 1 : 0.85,
        );
      }).toList(),
      actionPlan: List.generate(items.take(5).length, (index) {
        return _trackedActionStep(action: items[index], position: index + 1);
      }),
      nextStep:
          'Atualize o status da ação "${first.title}" após revisar sua execução.',
      confidence: 97,
      level: items.any((item) => item.isOverdue)
          ? AtlasDiagnosticLevel.attention
          : AtlasDiagnosticLevel.stable,
      actions: [_navigationForArea(first.area)],
    );
  }

  AtlasAiResponse _answerOverdueActions({
    required String question,
    required AtlasAiFarmContext context,
    required List<AtlasAiTrackedAction> trackedActions,
    DateTime? now,
  }) {
    final overdue =
        trackedActions.where((item) {
            return item.isOverdue;
          }).toList()
          ..sort((first, second) => first.dueDate.compareTo(second.dueDate));

    if (overdue.isEmpty) {
      return AtlasAiResponse(
        generatedAt: now ?? DateTime.now(),
        question: question,
        intent: AtlasAiIntent.overdueActions,
        directAnswer: 'Não existem ações atrasadas no acompanhamento atual.',
        justification:
            'Todas as ações abertas ainda estão dentro do prazo registrado.',
        evidences: const [],
        actionPlan: const [],
        nextStep:
            'Mantenha os status e observações atualizados para preservar essa condição.',
        confidence: 98,
        level: AtlasDiagnosticLevel.excellent,
        actions: const [],
      );
    }

    final first = overdue.first;

    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.overdueActions,
      directAnswer:
          '${overdue.length} '
          '${overdue.length == 1 ? 'ação está atrasada' : 'ações estão atrasadas'}.',
      justification:
          'A ação mais antiga é "${first.title}", '
          'com prazo encerrado em ${_formatDate(first.dueDate)}.',
      evidences: overdue.take(5).map((item) {
        final delay = DateTime.now().difference(item.dueDate).inDays;

        return AtlasAiEvidence(
          label: item.title,
          value: '$delay ${delay == 1 ? 'dia' : 'dias'} de atraso',
          description: item.notes.isEmpty
              ? item.description
              : '${item.description} Observação: ${item.notes}',
          area: item.area,
          weight: 1,
        );
      }).toList(),
      actionPlan: List.generate(overdue.take(5).length, (index) {
        return _trackedActionStep(action: overdue[index], position: index + 1);
      }),
      nextStep:
          'Revise imediatamente "${first.title}", ajuste o prazo ou atualize seu status.',
      confidence: 99,
      level: AtlasDiagnosticLevel.critical,
      actions: [_navigationForArea(first.area)],
    );
  }

  _ActionProgressData _calculateActionProgress(
    List<AtlasAiTrackedAction> actions,
  ) {
    final pending = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.pending;
    }).length;

    final inProgress = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.inProgress;
    }).length;

    final completed = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.completed;
    }).length;

    final cancelled = actions.where((item) {
      return item.status == AtlasAiTrackedActionStatus.cancelled;
    }).length;

    final overdue = actions.where((item) {
      return item.isOverdue;
    }).length;

    final validTotal = actions.length - cancelled;

    return _ActionProgressData(
      total: actions.length,
      validTotal: validTotal,
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      cancelled: cancelled,
      overdue: overdue,
      completionPercent: validTotal == 0
          ? 0
          : (completed / validTotal * 100).clamp(0.0, 100.0),
    );
  }

  AtlasAiTrackedAction? _nextTrackedAction(List<AtlasAiTrackedAction> actions) {
    final open =
        actions.where((item) {
          return item.isOpen;
        }).toList()..sort((first, second) {
          if (first.isOverdue != second.isOverdue) {
            return first.isOverdue ? -1 : 1;
          }

          if (first.status != second.status) {
            if (first.status == AtlasAiTrackedActionStatus.inProgress) {
              return -1;
            }

            if (second.status == AtlasAiTrackedActionStatus.inProgress) {
              return 1;
            }
          }

          return first.dueDate.compareTo(second.dueDate);
        });

    return open.isEmpty ? null : open.first;
  }

  AtlasAiResponseActionStep _trackedActionStep({
    required AtlasAiTrackedAction action,
    required int position,
  }) {
    final daysRemaining = action.dueDate.difference(DateTime.now()).inDays;

    return AtlasAiResponseActionStep(
      position: position,
      title: action.title,
      description: action.notes.isEmpty
          ? action.description
          : '${action.description} Observação: ${action.notes}',
      expectedResult: action.expectedResult,
      area: action.area,
      deadlineDays: daysRemaining < 0 ? 0 : daysRemaining,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  AtlasAiResponse _answerUnknown({
    required String question,
    required AtlasAiFarmContext context,
    DateTime? now,
  }) {
    return AtlasAiResponse(
      generatedAt: now ?? DateTime.now(),
      question: question,
      intent: AtlasAiIntent.unknown,
      directAnswer:
          'Não consegui identificar com segurança o assunto da pergunta.',
      justification:
          'Posso responder sobre situação geral, prioridade, riscos, oportunidades, financeiro, rebanho, piquetes, estoque, agenda, planos de ação, cenários preditivos e acompanhamento das ações da consultoria.',
      evidences: const [],
      actionPlan: const [],
      nextStep:
          'Escolha uma pergunta sugerida ou reformule usando uma dessas áreas.',
      confidence: 35,
      level: context.level,
      actions: const [
        AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Abrir diagnóstico',
          type: AtlasAiNavigationActionType.openDiagnostic,
        ),
      ],
    );
  }

  AtlasAiIntent _identifyIntent(String question) {
    if (_containsAny(question, [
      'linguagem simples',
      'explique simples',
      'sem termo tecnico',
      'produtor',
      'facil de entender',
    ])) {
      return AtlasAiIntent.simpleExplanation;
    }

    if (_containsAny(question, [
      'melhor decisao',
      'cenario',
      'simulacao',
      'simular',
      'impacto',
      'retorno',
      'preditiv',
    ])) {
      return AtlasAiIntent.predictiveDecision;
    }

    if (_containsAny(question, [
      '7 dias',
      'esta semana',
      'proxima semana',
      'curto prazo',
      'amanha',
    ])) {
      return AtlasAiIntent.shortTermPlan;
    }

    if (_containsAny(question, [
      '30 dias',
      'este mes',
      'proximo mes',
      'medio prazo',
    ])) {
      return AtlasAiIntent.mediumTermPlan;
    }

    if (_containsAny(question, ['90 dias', 'trimestre', 'longo prazo'])) {
      return AtlasAiIntent.longTermPlan;
    }

    if (_containsAny(question, [
      'acao atrasada',
      'acoes atrasadas',
      'o que esta atrasado',
      'atrasadas',
      'atrasada',
      'fora do prazo',
    ])) {
      return AtlasAiIntent.overdueActions;
    }

    if (_containsAny(question, [
      'acoes pendentes',
      'acao pendente',
      'o que esta pendente',
      'ainda precisa fazer',
      'falta fazer',
    ])) {
      return AtlasAiIntent.pendingActions;
    }

    if (_containsAny(question, [
      'acoes concluidas',
      'acao concluida',
      'o que foi concluido',
      'ja foi feito',
      'ja concluiu',
    ])) {
      return AtlasAiIntent.completedActions;
    }

    if (_containsAny(question, [
      'acoes em andamento',
      'acao em andamento',
      'o que esta em andamento',
      'sendo executado',
    ])) {
      return AtlasAiIntent.inProgressActions;
    }

    if (_containsAny(question, [
      'progresso das acoes',
      'progresso da consultoria',
      'andamento das acoes',
      'acompanhamento',
      'percentual concluido',
      'quanto ja foi feito',
      'resuma as acoes',
    ])) {
      return AtlasAiIntent.actionProgress;
    }

    if (_containsAny(question, [
      'melhorar score',
      'aumentar score',
      'subir score',
      'pontuacao',
    ])) {
      return AtlasAiIntent.improveScore;
    }

    if (_containsAny(question, [
      'maior problema',
      'principal problema',
      'problema mais importante',
      'gargalo principal',
    ])) {
      return AtlasAiIntent.mainProblem;
    }

    if (_containsAny(question, [
      'prioridade',
      'priorizar',
      'primeiro',
      'mais urgente',
      'fazer agora',
    ])) {
      return AtlasAiIntent.priority;
    }

    if (_containsAny(question, [
      'risco',
      'perigo',
      'prejuizo',
      'ameaça',
      'alerta',
    ])) {
      return AtlasAiIntent.risks;
    }

    if (_containsAny(question, [
      'oportunidade',
      'ganho',
      'melhorar lucro',
      'economizar',
    ])) {
      return AtlasAiIntent.opportunities;
    }

    if (_containsAny(question, [
      'ponto forte',
      'positivo',
      'funcionando bem',
      'preservar',
    ])) {
      return AtlasAiIntent.strengths;
    }

    if (_containsAny(question, [
      'financeiro',
      'receita',
      'despesa',
      'saldo',
      'lucro',
      'custo',
      'margem',
      'dinheiro',
    ])) {
      return AtlasAiIntent.finance;
    }

    if (_containsAny(question, [
      'rebanho',
      'animal',
      'animais',
      'peso',
      'lote',
      'gado',
    ])) {
      return AtlasAiIntent.herd;
    }

    if (_containsAny(question, [
      'piquete',
      'pasto',
      'pastagem',
      'lotacao',
      'hectare',
      'forragem',
    ])) {
      return AtlasAiIntent.paddocks;
    }

    if (_containsAny(question, [
      'estoque',
      'produto',
      'insumo',
      'medicamento',
      'vencido',
      'validade',
    ])) {
      return AtlasAiIntent.inventory;
    }

    if (_containsAny(question, [
      'agenda',
      'tarefa',
      'atraso',
      'prazo',
      'responsavel',
      'atividade',
    ])) {
      return AtlasAiIntent.agenda;
    }

    if (_containsAny(question, [
      'situacao',
      'resumo',
      'como esta',
      'diagnostico geral',
      'visao geral',
    ])) {
      return AtlasAiIntent.generalSituation;
    }

    return AtlasAiIntent.unknown;
  }

  List<AtlasAiResponseActionStep> _relatedActions({
    required AtlasAiFarmContext context,
    required AtlasFarmAnalysisArea area,
    required int maximum,
  }) {
    final allActions = [
      ...context.shortTermActions,
      ...context.mediumTermActions,
      ...context.longTermActions,
    ];

    final related = allActions
        .where((item) {
          return item.area == area;
        })
        .take(maximum)
        .toList();

    if (related.isNotEmpty) {
      return _mapActions(related);
    }

    return _mapActions(context.shortTermActions.take(maximum).toList());
  }

  List<AtlasAiResponseActionStep> _mapActions(
    List<AtlasAiActionContext> source,
  ) {
    return List.generate(source.length, (index) {
      final item = source[index];

      return AtlasAiResponseActionStep(
        position: index + 1,
        title: item.title,
        description: item.description,
        expectedResult: item.expectedResult,
        area: item.area,
        deadlineDays: _deadlineForHorizon(item.horizon, index),
      );
    });
  }

  int _deadlineForHorizon(AtlasDiagnosticHorizon horizon, int index) {
    switch (horizon) {
      case AtlasDiagnosticHorizon.sevenDays:
        return math.min(7, index + 1);

      case AtlasDiagnosticHorizon.thirtyDays:
        return math.min(30, (index + 1) * 7);

      case AtlasDiagnosticHorizon.ninetyDays:
        return math.min(90, (index + 1) * 30);
    }
  }

  AtlasAiAreaContext? _findArea(
    AtlasAiFarmContext context,
    AtlasFarmAnalysisArea area,
  ) {
    for (final item in context.areaContexts) {
      if (item.area == area) {
        return item;
      }
    }

    return null;
  }

  AtlasAiAreaContext? _weakestArea(AtlasAiFarmContext context) {
    if (context.areaContexts.isEmpty) {
      return null;
    }

    final ordered = [...context.areaContexts]
      ..sort((first, second) => first.score.compareTo(second.score));

    return ordered.first;
  }

  AtlasAiNavigationAction _navigationForArea(AtlasFarmAnalysisArea area) {
    switch (area) {
      case AtlasFarmAnalysisArea.finance:
        return const AtlasAiNavigationAction(
          id: 'open_finance',
          label: 'Abrir Financeiro',
          type: AtlasAiNavigationActionType.openFinance,
        );

      case AtlasFarmAnalysisArea.herd:
        return const AtlasAiNavigationAction(
          id: 'open_herd',
          label: 'Abrir Rebanho',
          type: AtlasAiNavigationActionType.openHerd,
        );

      case AtlasFarmAnalysisArea.paddock:
        return const AtlasAiNavigationAction(
          id: 'open_paddocks',
          label: 'Abrir Piquetes',
          type: AtlasAiNavigationActionType.openPaddocks,
        );

      case AtlasFarmAnalysisArea.inventory:
        return const AtlasAiNavigationAction(
          id: 'open_inventory',
          label: 'Abrir Estoque',
          type: AtlasAiNavigationActionType.openInventory,
        );

      case AtlasFarmAnalysisArea.agenda:
        return const AtlasAiNavigationAction(
          id: 'open_agenda',
          label: 'Abrir Agenda',
          type: AtlasAiNavigationActionType.openAgenda,
        );

      case AtlasFarmAnalysisArea.general:
        return const AtlasAiNavigationAction(
          id: 'open_diagnostic',
          label: 'Abrir Diagnóstico',
          type: AtlasAiNavigationActionType.openDiagnostic,
        );
    }
  }

  AtlasFarmAnalysisArea _areaForPredictiveType(
    AtlasPredictiveScenarioType type,
  ) {
    switch (type) {
      case AtlasPredictiveScenarioType.reduceCosts:
      case AtlasPredictiveScenarioType.increaseRevenue:
        return AtlasFarmAnalysisArea.finance;

      case AtlasPredictiveScenarioType.reduceOverdueTasks:
        return AtlasFarmAnalysisArea.agenda;

      case AtlasPredictiveScenarioType.reduceInventoryLosses:
        return AtlasFarmAnalysisArea.inventory;

      case AtlasPredictiveScenarioType.improveHerdRecords:
        return AtlasFarmAnalysisArea.herd;

      case AtlasPredictiveScenarioType.improvePaddockUse:
        return AtlasFarmAnalysisArea.paddock;

      case AtlasPredictiveScenarioType.custom:
        return AtlasFarmAnalysisArea.general;
    }
  }

  double _predictiveScore(AtlasAiPredictiveContext item) {
    final effortWeight = switch (item.effort) {
      AtlasPredictiveEffort.low => 1.0,
      AtlasPredictiveEffort.medium => 0.78,
      AtlasPredictiveEffort.high => 0.56,
    };

    return (item.scoreVariation * 5 +
            item.riskReductionPercent * 0.45 +
            item.confidence * 0.20) *
        effortWeight;
  }

  double _confidenceFromContext(AtlasAiFarmContext context) {
    var confidence = 68.0;

    if (context.areaContexts.length >= 5) {
      confidence += 10;
    }

    if (context.risks.isNotEmpty || context.bottlenecks.isNotEmpty) {
      confidence += 5;
    }

    if (context.shortTermActions.isNotEmpty) {
      confidence += 5;
    }

    if (context.predictiveScenarios.isNotEmpty) {
      confidence += 5;
    }

    return confidence.clamp(45.0, 93.0);
  }

  bool _containsAny(String value, List<String> terms) {
    for (final term in terms) {
      if (value.contains(term)) {
        return true;
      }
    }

    return false;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  String _currency(double value) {
    final fixed = value.abs().toStringAsFixed(2);

    final parts = fixed.split('.');

    final integer = parts.first;
    final decimal = parts.last;

    final buffer = StringBuffer();

    for (var index = 0; index < integer.length; index++) {
      final remaining = integer.length - index;

      buffer.write(integer[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    final sign = value < 0 ? '-' : '';

    return '${sign}R\$ ${buffer.toString()},$decimal';
  }
}

class _ActionProgressData {
  const _ActionProgressData({
    required this.total,
    required this.validTotal,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.overdue,
    required this.completionPercent,
  });

  final int total;
  final int validTotal;
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int overdue;
  final double completionPercent;

  bool get hasActions {
    return total > 0;
  }
}
