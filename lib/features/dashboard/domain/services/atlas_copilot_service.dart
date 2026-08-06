import 'package:projeto_atlas/features/dashboard/domain/services/atlas_operations_intelligence_service.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasCopilotService {
  const AtlasCopilotService();

  AtlasCopilotResponse answer({
    required String question,
    AtlasIntelligenceBrief? operationBrief,
    AtlasFarmIntelligenceData? farmIntelligence,
    String consultantName = 'Gabriel',
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();
    final normalizedQuestion = _normalizeText(question);

    if (normalizedQuestion.isEmpty) {
      return AtlasCopilotResponse(
        answer: 'Digite uma pergunta sobre a operação ou sobre a fazenda.',
        intent: AtlasCopilotIntent.unknown,
        confidence: 0,
        source: AtlasCopilotAnswerSource.localRules,
        suggestedQuestions: buildSuggestedQuestions(
          operationBrief: operationBrief,
          farmIntelligence: farmIntelligence,
        ),
        actions: const [],
        generatedAt: referenceDate,
      );
    }

    final intent = _detectIntent(normalizedQuestion);

    final response = _buildAnswer(
      intent: intent,
      question: normalizedQuestion,
      operationBrief: operationBrief,
      farmIntelligence: farmIntelligence,
      consultantName: consultantName,
      now: referenceDate,
    );

    return AtlasCopilotResponse(
      answer: response.answer,
      intent: intent,
      confidence: response.confidence,
      source: AtlasCopilotAnswerSource.localRules,
      suggestedQuestions: buildSuggestedQuestions(
        operationBrief: operationBrief,
        farmIntelligence: farmIntelligence,
      ),
      actions: response.actions,
      generatedAt: referenceDate,
    );
  }

  AtlasCopilotIntent _detectIntent(String question) {
    if (_containsAny(question, [
      'maior problema',
      'principal problema',
      'o que esta errado',
      'o que está errado',
      'situacao',
      'situação',
      'como esta',
      'como está',
    ])) {
      return AtlasCopilotIntent.generalSituation;
    }

    if (_containsAny(question, [
      'o que fazer primeiro',
      'prioridade',
      'por onde comecar',
      'por onde começar',
      'o que fazer hoje',
      'primeiro passo',
    ])) {
      return AtlasCopilotIntent.priority;
    }

    if (_containsAny(question, [
      'risco',
      'perigo',
      'critico',
      'crítico',
      'alerta',
      'problema',
    ])) {
      return AtlasCopilotIntent.risk;
    }

    if (_containsAny(question, [
      'financeiro',
      'financeira',
      'receita',
      'despesa',
      'saldo',
      'margem',
      'lucro',
      'prejuizo',
      'prejuízo',
      'custo',
    ])) {
      return AtlasCopilotIntent.finance;
    }

    if (_containsAny(question, [
      'rebanho',
      'animal',
      'animais',
      'peso',
      'lotacao',
      'lotação',
      'lote',
    ])) {
      return AtlasCopilotIntent.herd;
    }

    if (_containsAny(question, [
      'piquete',
      'pasto',
      'pastagem',
      'area',
      'área',
    ])) {
      return AtlasCopilotIntent.paddock;
    }

    if (_containsAny(question, [
      'estoque',
      'produto',
      'medicamento',
      'vencimento',
      'vencido',
      'suplemento',
    ])) {
      return AtlasCopilotIntent.inventory;
    }

    if (_containsAny(question, [
      'agenda',
      'tarefa',
      'tarefas',
      'prazo',
      'atraso',
      'atrasadas',
      'urgente',
    ])) {
      return AtlasCopilotIntent.agenda;
    }

    if (_containsAny(question, [
      'oportunidade',
      'melhorar',
      'melhoria',
      'ganho',
      'aumentar resultado',
      'aumentar margem',
    ])) {
      return AtlasCopilotIntent.opportunity;
    }

    if (_containsAny(question, [
      'ponto positivo',
      'pontos positivos',
      'esta bom',
      'está bom',
      'forte',
      'forca',
      'força',
    ])) {
      return AtlasCopilotIntent.strength;
    }

    if (_containsAny(question, [
      'resumo',
      'resuma',
      'relatorio',
      'relatório',
      'visao geral',
      'visão geral',
    ])) {
      return AtlasCopilotIntent.summary;
    }

    if (_containsAny(question, [
      'responsavel',
      'responsável',
      'sobrecarga',
      'quem',
    ])) {
      return AtlasCopilotIntent.responsible;
    }

    if (_containsAny(question, [
      'categoria',
      'sanidade',
      'nutricao',
      'nutrição',
      'reproducao',
      'reprodução',
      'manejo',
    ])) {
      return AtlasCopilotIntent.category;
    }

    return AtlasCopilotIntent.unknown;
  }

  _AtlasCopilotAnswerData _buildAnswer({
    required AtlasCopilotIntent intent,
    required String question,
    required AtlasIntelligenceBrief? operationBrief,
    required AtlasFarmIntelligenceData? farmIntelligence,
    required String consultantName,
    required DateTime now,
  }) {
    switch (intent) {
      case AtlasCopilotIntent.generalSituation:
        return _answerGeneralSituation(
          operationBrief: operationBrief,
          farmIntelligence: farmIntelligence,
        );

      case AtlasCopilotIntent.priority:
        return _answerPriority(
          operationBrief: operationBrief,
          farmIntelligence: farmIntelligence,
        );

      case AtlasCopilotIntent.risk:
        return _answerRisk(
          operationBrief: operationBrief,
          farmIntelligence: farmIntelligence,
        );

      case AtlasCopilotIntent.finance:
        return _answerFinance(farmIntelligence);

      case AtlasCopilotIntent.herd:
        return _answerHerd(farmIntelligence);

      case AtlasCopilotIntent.paddock:
        return _answerPaddock(farmIntelligence);

      case AtlasCopilotIntent.inventory:
        return _answerInventory(farmIntelligence);

      case AtlasCopilotIntent.agenda:
        return _answerAgenda(farmIntelligence);

      case AtlasCopilotIntent.opportunity:
        return _answerOpportunity(
          operationBrief: operationBrief,
          farmIntelligence: farmIntelligence,
        );

      case AtlasCopilotIntent.strength:
        return _answerStrength(
          operationBrief: operationBrief,
          farmIntelligence: farmIntelligence,
        );

      case AtlasCopilotIntent.summary:
        return _answerSummary(
          operationBrief: operationBrief,
          farmIntelligence: farmIntelligence,
        );

      case AtlasCopilotIntent.responsible:
        return _answerResponsible(operationBrief);

      case AtlasCopilotIntent.category:
        return _answerCategory(operationBrief);

      case AtlasCopilotIntent.unknown:
        return _answerUnknown(
          consultantName: consultantName,
          now: now,
          operationBrief: operationBrief,
          farmIntelligence: farmIntelligence,
        );
    }
  }

  _AtlasCopilotAnswerData _answerGeneralSituation({
    required AtlasIntelligenceBrief? operationBrief,
    required AtlasFarmIntelligenceData? farmIntelligence,
  }) {
    if (farmIntelligence != null) {
      return _AtlasCopilotAnswerData(
        answer:
            '${farmIntelligence.executiveSummary}\n\n'
            '${farmIntelligence.situationDescription}\n\n'
            'Minha recomendação: '
            '${farmIntelligence.generalRecommendation}',
        confidence: 0.96,
        actions: [
          AtlasCopilotAction(
            id: 'open_farm_priority',
            label: 'Ver prioridade da fazenda',
            type: AtlasCopilotActionType.openFarmIntelligence,
          ),
        ],
      );
    }

    if (operationBrief != null) {
      return _AtlasCopilotAnswerData(
        answer:
            '${operationBrief.executiveSummary}\n\n'
            '${operationBrief.situationDescription}\n\n'
            'O que fazer agora: '
            '${operationBrief.todayGuidance}',
        confidence: 0.96,
        actions: [
          AtlasCopilotAction(
            id: 'open_intelligence',
            label: 'Abrir Inteligência Atlas',
            type: AtlasCopilotActionType.openIntelligence,
          ),
        ],
      );
    }

    return _noContextAnswer();
  }

  _AtlasCopilotAnswerData _answerPriority({
    required AtlasIntelligenceBrief? operationBrief,
    required AtlasFarmIntelligenceData? farmIntelligence,
  }) {
    if (farmIntelligence != null) {
      final priority = farmIntelligence.mainPriority;

      return _AtlasCopilotAnswerData(
        answer:
            'A prioridade número 1 da ${farmIntelligence.farmName} é '
            '"${priority.title}".\n\n'
            '${priority.description}\n\n'
            'Ação recomendada: '
            '${priority.recommendation}',
        confidence: 0.98,
        actions: [
          AtlasCopilotAction(
            id: 'open_farm_actions',
            label: 'Abrir fazenda',
            type: AtlasCopilotActionType.openFarm,
          ),
        ],
      );
    }

    final priority = operationBrief?.mainPriority;

    if (priority != null) {
      return _AtlasCopilotAnswerData(
        answer:
            'A prioridade número 1 da operação é '
            '"${priority.title}".\n\n'
            'Fazenda: ${priority.farmName}\n'
            'Responsável: ${priority.responsible}\n'
            'Prazo: ${priority.deadline}\n'
            'Score: ${formatCopilotNumber(priority.priorityScore)} pontos\n\n'
            'Ação recomendada: '
            '${priority.recommendedAction}',
        confidence: 0.98,
        actions: [
          AtlasCopilotAction(
            id: 'open_actions',
            label: 'Abrir Ações Gerenciais',
            type: AtlasCopilotActionType.openActions,
          ),
        ],
      );
    }

    return _AtlasCopilotAnswerData(
      answer:
          'Nenhuma prioridade crítica foi identificada. '
          'Mantenha os registros atualizados e revise os próximos prazos.',
      confidence: 0.78,
      actions: const [],
    );
  }

  _AtlasCopilotAnswerData _answerRisk({
    required AtlasIntelligenceBrief? operationBrief,
    required AtlasFarmIntelligenceData? farmIntelligence,
  }) {
    if (farmIntelligence != null) {
      final risks = farmIntelligence.risks;

      if (risks.isEmpty) {
        return _AtlasCopilotAnswerData(
          answer:
              'Não existem riscos relevantes identificados para esta fazenda.',
          confidence: 0.85,
          actions: const [],
        );
      }

      final topRisk = risks.first;

      return _AtlasCopilotAnswerData(
        answer:
            'O principal risco da ${farmIntelligence.farmName} é '
            '"${topRisk.title}".\n\n'
            '${topRisk.description}\n\n'
            'Recomendação: '
            '${topRisk.recommendation}',
        confidence: 0.96,
        actions: [
          AtlasCopilotAction(
            id: 'open_farm_intelligence',
            label: 'Ver análise da fazenda',
            type: AtlasCopilotActionType.openFarmIntelligence,
          ),
        ],
      );
    }

    if (operationBrief != null && operationBrief.risks.isNotEmpty) {
      final topRisk = operationBrief.risks.first;

      return _AtlasCopilotAnswerData(
        answer:
            'O principal risco da operação é '
            '"${topRisk.title}".\n\n'
            '${topRisk.description}\n\n'
            'Recomendação: '
            '${topRisk.recommendation}',
        confidence: 0.96,
        actions: [
          AtlasCopilotAction(
            id: 'open_intelligence',
            label: 'Abrir Inteligência Atlas',
            type: AtlasCopilotActionType.openIntelligence,
          ),
        ],
      );
    }

    return _noContextAnswer();
  }

  _AtlasCopilotAnswerData _answerFinance(
    AtlasFarmIntelligenceData? farmIntelligence,
  ) {
    if (farmIntelligence == null) {
      return _requiresFarmContext(
        'Para analisar o financeiro, abra primeiro uma fazenda.',
      );
    }

    final finance = farmIntelligence.finance;

    return _AtlasCopilotAnswerData(
      answer:
          '${finance.analysis}\n\n'
          'Receitas: '
          '${formatAtlasFarmCurrency(finance.totalIncome)}\n'
          'Despesas: '
          '${formatAtlasFarmCurrency(finance.totalExpenses)}\n'
          'Resultado: '
          '${formatAtlasFarmCurrency(finance.balance)}\n'
          'Score financeiro: '
          '${formatCopilotNumber(finance.score)} pontos.\n\n'
          '${_financeRecommendation(finance)}',
      confidence: 0.98,
      actions: [
        AtlasCopilotAction(
          id: 'open_finance',
          label: 'Abrir Financeiro',
          type: AtlasCopilotActionType.openFinance,
        ),
      ],
    );
  }

  String _financeRecommendation(AtlasFarmFinanceAnalysis finance) {
    if (finance.balance < 0) {
      return 'Revise a maior categoria de despesa, confirme se todas as receitas foram registradas e defina um plano para recuperar o resultado.';
    }

    if (finance.recordCount == 0) {
      return 'Cadastre receitas e despesas para que o Atlas consiga calcular margem e resultado.';
    }

    return 'O resultado está sob controle. Continue acompanhando despesas por categoria e a evolução da margem.';
  }

  _AtlasCopilotAnswerData _answerHerd(
    AtlasFarmIntelligenceData? farmIntelligence,
  ) {
    if (farmIntelligence == null) {
      return _requiresFarmContext(
        'Para analisar o rebanho, abra primeiro uma fazenda.',
      );
    }

    final herd = farmIntelligence.herd;

    return _AtlasCopilotAnswerData(
      answer:
          '${herd.analysis}\n\n'
          'Animais cadastrados: ${herd.totalAnimals}\n'
          'Animais ativos: ${herd.activeAnimals}\n'
          'Lotes: ${herd.groupCount}\n'
          'Peso médio: ${formatCopilotNumber(herd.averageWeight)} kg\n'
          'Lotação: ${formatCopilotNumber(herd.animalsPerHectare)} animais/ha\n'
          'Cobertura do cadastro: ${formatCopilotNumber(herd.registrationCoverage)}%.',
      confidence: 0.97,
      actions: [
        AtlasCopilotAction(
          id: 'open_herd',
          label: 'Abrir Rebanho',
          type: AtlasCopilotActionType.openHerd,
        ),
      ],
    );
  }

  _AtlasCopilotAnswerData _answerPaddock(
    AtlasFarmIntelligenceData? farmIntelligence,
  ) {
    if (farmIntelligence == null) {
      return _requiresFarmContext(
        'Para analisar piquetes e pastagens, abra primeiro uma fazenda.',
      );
    }

    final paddock = farmIntelligence.paddocks;

    return _AtlasCopilotAnswerData(
      answer:
          '${paddock.analysis}\n\n'
          'Piquetes: ${paddock.paddockCount}\n'
          'Área cadastrada: ${formatCopilotNumber(paddock.totalArea)} ha\n'
          'Em uso: ${paddock.inUseCount}\n'
          'Em descanso: ${paddock.restingCount}\n'
          'Cobertura da área: ${formatCopilotNumber(paddock.areaCoverage)}%.',
      confidence: 0.96,
      actions: [
        AtlasCopilotAction(
          id: 'open_paddocks',
          label: 'Abrir Piquetes',
          type: AtlasCopilotActionType.openPaddocks,
        ),
      ],
    );
  }

  _AtlasCopilotAnswerData _answerInventory(
    AtlasFarmIntelligenceData? farmIntelligence,
  ) {
    if (farmIntelligence == null) {
      return _requiresFarmContext(
        'Para analisar o estoque, abra primeiro uma fazenda.',
      );
    }

    final inventory = farmIntelligence.inventory;

    return _AtlasCopilotAnswerData(
      answer:
          '${inventory.analysis}\n\n'
          'Produtos: ${inventory.itemCount}\n'
          'Valor estimado: ${formatAtlasFarmCurrency(inventory.totalValue)}\n'
          'Estoque baixo: ${inventory.lowStockCount}\n'
          'Vencidos: ${inventory.expiredCount}\n'
          'Próximos do vencimento: ${inventory.nearExpirationCount}\n'
          'Score do estoque: ${formatCopilotNumber(inventory.score)} pontos.',
      confidence: 0.98,
      actions: [
        AtlasCopilotAction(
          id: 'open_inventory',
          label: 'Abrir Estoque',
          type: AtlasCopilotActionType.openInventory,
        ),
      ],
    );
  }

  _AtlasCopilotAnswerData _answerAgenda(
    AtlasFarmIntelligenceData? farmIntelligence,
  ) {
    if (farmIntelligence == null) {
      return _requiresFarmContext(
        'Para analisar tarefas e prazos, abra primeiro uma fazenda.',
      );
    }

    final agenda = farmIntelligence.agenda;

    return _AtlasCopilotAnswerData(
      answer:
          '${agenda.analysis}\n\n'
          'Tarefas abertas: ${agenda.openCount}\n'
          'Concluídas: ${agenda.completedCount}\n'
          'Atrasadas: ${agenda.overdueCount}\n'
          'Urgentes: ${agenda.urgentCount}\n'
          'Sem responsável: ${agenda.withoutResponsibleCount}\n'
          'Taxa de conclusão: ${formatCopilotNumber(agenda.completionRate)}%.',
      confidence: 0.98,
      actions: [
        AtlasCopilotAction(
          id: 'open_agenda',
          label: 'Abrir Agenda',
          type: AtlasCopilotActionType.openAgenda,
        ),
      ],
    );
  }

  _AtlasCopilotAnswerData _answerOpportunity({
    required AtlasIntelligenceBrief? operationBrief,
    required AtlasFarmIntelligenceData? farmIntelligence,
  }) {
    if (farmIntelligence != null && farmIntelligence.opportunities.isNotEmpty) {
      final opportunity = farmIntelligence.opportunities.first;

      return _AtlasCopilotAnswerData(
        answer:
            'A principal oportunidade da ${farmIntelligence.farmName} é '
            '"${opportunity.title}".\n\n'
            '${opportunity.description}\n\n'
            'Ação recomendada: '
            '${opportunity.recommendation}',
        confidence: 0.94,
        actions: [
          AtlasCopilotAction(
            id: 'open_farm_intelligence',
            label: 'Ver oportunidades da fazenda',
            type: AtlasCopilotActionType.openFarmIntelligence,
          ),
        ],
      );
    }

    if (operationBrief != null && operationBrief.opportunities.isNotEmpty) {
      final opportunity = operationBrief.opportunities.first;

      return _AtlasCopilotAnswerData(
        answer:
            'A principal oportunidade da operação é '
            '"${opportunity.title}".\n\n'
            '${opportunity.description}\n\n'
            'Ação recomendada: '
            '${opportunity.recommendation}',
        confidence: 0.94,
        actions: [
          AtlasCopilotAction(
            id: 'open_intelligence',
            label: 'Ver oportunidades',
            type: AtlasCopilotActionType.openIntelligence,
          ),
        ],
      );
    }

    return _noContextAnswer();
  }

  _AtlasCopilotAnswerData _answerStrength({
    required AtlasIntelligenceBrief? operationBrief,
    required AtlasFarmIntelligenceData? farmIntelligence,
  }) {
    if (farmIntelligence != null && farmIntelligence.strengths.isNotEmpty) {
      final strength = farmIntelligence.strengths.first;

      return _AtlasCopilotAnswerData(
        answer:
            'O principal ponto positivo da ${farmIntelligence.farmName} é '
            '"${strength.title}".\n\n'
            '${strength.description}\n\n'
            '${strength.recommendation}',
        confidence: 0.93,
        actions: const [],
      );
    }

    if (operationBrief != null && operationBrief.strengths.isNotEmpty) {
      final strength = operationBrief.strengths.first;

      return _AtlasCopilotAnswerData(
        answer:
            'O principal ponto positivo da operação é '
            '"${strength.title}".\n\n'
            '${strength.description}\n\n'
            '${strength.recommendation}',
        confidence: 0.93,
        actions: const [],
      );
    }

    return _noContextAnswer();
  }

  _AtlasCopilotAnswerData _answerSummary({
    required AtlasIntelligenceBrief? operationBrief,
    required AtlasFarmIntelligenceData? farmIntelligence,
  }) {
    if (farmIntelligence != null) {
      return _AtlasCopilotAnswerData(
        answer:
            '${farmIntelligence.executiveSummary}\n\n'
            'Prioridade principal: '
            '${farmIntelligence.mainPriority.title}.\n\n'
            '${farmIntelligence.generalRecommendation}',
        confidence: 0.98,
        actions: [
          AtlasCopilotAction(
            id: 'open_farm_intelligence',
            label: 'Abrir análise completa',
            type: AtlasCopilotActionType.openFarmIntelligence,
          ),
        ],
      );
    }

    if (operationBrief != null) {
      return _AtlasCopilotAnswerData(
        answer:
            '${operationBrief.executiveSummary}\n\n'
            'Orientação do dia: '
            '${operationBrief.todayGuidance}',
        confidence: 0.98,
        actions: [
          AtlasCopilotAction(
            id: 'open_intelligence',
            label: 'Abrir análise completa',
            type: AtlasCopilotActionType.openIntelligence,
          ),
        ],
      );
    }

    return _noContextAnswer();
  }

  _AtlasCopilotAnswerData _answerResponsible(AtlasIntelligenceBrief? brief) {
    if (brief == null || brief.responsibleAnalyses.isEmpty) {
      return _AtlasCopilotAnswerData(
        answer: 'Não há dados suficientes para avaliar responsáveis.',
        confidence: 0.60,
        actions: const [],
      );
    }

    final responsible = brief.responsibleAnalyses.first;

    return _AtlasCopilotAnswerData(
      answer:
          'O responsável que exige maior atenção é '
          '${responsible.label}.\n\n'
          '${responsible.analysis}\n\n'
          'Recomendação: '
          '${responsible.recommendation}',
      confidence: 0.94,
      actions: [
        AtlasCopilotAction(
          id: 'open_intelligence',
          label: 'Ver responsáveis',
          type: AtlasCopilotActionType.openIntelligence,
        ),
      ],
    );
  }

  _AtlasCopilotAnswerData _answerCategory(AtlasIntelligenceBrief? brief) {
    if (brief == null || brief.categoryAnalyses.isEmpty) {
      return _AtlasCopilotAnswerData(
        answer: 'Não há dados suficientes para avaliar categorias.',
        confidence: 0.60,
        actions: const [],
      );
    }

    final category = brief.categoryAnalyses.first;

    return _AtlasCopilotAnswerData(
      answer:
          'A categoria que exige maior atenção é '
          '${category.label}.\n\n'
          '${category.analysis}\n\n'
          'Recomendação: '
          '${category.recommendation}',
      confidence: 0.94,
      actions: [
        AtlasCopilotAction(
          id: 'open_intelligence',
          label: 'Ver categorias',
          type: AtlasCopilotActionType.openIntelligence,
        ),
      ],
    );
  }

  _AtlasCopilotAnswerData _answerUnknown({
    required String consultantName,
    required DateTime now,
    required AtlasIntelligenceBrief? operationBrief,
    required AtlasFarmIntelligenceData? farmIntelligence,
  }) {
    final greeting = now.hour < 12
        ? 'Bom dia'
        : now.hour < 18
        ? 'Boa tarde'
        : 'Boa noite';

    final contextText = farmIntelligence != null
        ? 'Posso analisar a situação geral, financeiro, rebanho, piquetes, estoque, agenda, riscos e oportunidades da ${farmIntelligence.farmName}.'
        : operationBrief != null
        ? 'Posso analisar prioridades, riscos, oportunidades, responsáveis, categorias e a situação geral da operação.'
        : 'Ainda não recebi dados suficientes da operação.';

    return _AtlasCopilotAnswerData(
      answer:
          '$greeting, $consultantName. '
          'Não consegui identificar exatamente o que você deseja saber.\n\n'
          '$contextText\n\n'
          'Experimente perguntar: '
          '"Qual é a prioridade número 1?" ou '
          '"Qual é o maior risco hoje?".',
      confidence: 0.35,
      actions: const [],
    );
  }

  List<String> buildSuggestedQuestions({
    AtlasIntelligenceBrief? operationBrief,
    AtlasFarmIntelligenceData? farmIntelligence,
  }) {
    if (farmIntelligence != null) {
      return [
        'Qual é o maior problema desta fazenda?',
        'O que devo resolver primeiro?',
        'Como está o resultado financeiro?',
        'Existem produtos vencidos?',
        'Como está a agenda da fazenda?',
        'Qual é a principal oportunidade?',
      ];
    }

    if (operationBrief != null) {
      return [
        'Qual é a prioridade número 1?',
        'Qual é o maior risco hoje?',
        'O que devo fazer primeiro?',
        'Qual fazenda exige mais atenção?',
        'Quem está mais sobrecarregado?',
        'Qual é a principal oportunidade?',
      ];
    }

    return ['O que você consegue analisar?', 'Como funciona o Copiloto Atlas?'];
  }

  _AtlasCopilotAnswerData _requiresFarmContext(String message) {
    return _AtlasCopilotAnswerData(
      answer: message,
      confidence: 0.72,
      actions: [
        AtlasCopilotAction(
          id: 'open_farms',
          label: 'Abrir Fazendas',
          type: AtlasCopilotActionType.openFarms,
        ),
      ],
    );
  }

  _AtlasCopilotAnswerData _noContextAnswer() {
    return const _AtlasCopilotAnswerData(
      answer:
          'Ainda não existem dados suficientes para responder com segurança. '
          'Atualize os cadastros e tente novamente.',
      confidence: 0.45,
      actions: [],
    );
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }

  String _normalizeText(String value) {
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
}

class AtlasCopilotResponse {
  const AtlasCopilotResponse({
    required this.answer,
    required this.intent,
    required this.confidence,
    required this.source,
    required this.suggestedQuestions,
    required this.actions,
    required this.generatedAt,
  });

  final String answer;
  final AtlasCopilotIntent intent;
  final double confidence;

  final AtlasCopilotAnswerSource source;

  final List<String> suggestedQuestions;
  final List<AtlasCopilotAction> actions;

  final DateTime generatedAt;

  bool get hasActions {
    return actions.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'intent': intent.name,
      'confidence': confidence,
      'source': source.name,
      'suggestedQuestions': suggestedQuestions,
      'actions': actions.map((item) {
        return item.toJson();
      }).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class AtlasCopilotAction {
  const AtlasCopilotAction({
    required this.id,
    required this.label,
    required this.type,
  });

  final String id;
  final String label;
  final AtlasCopilotActionType type;

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'type': type.name};
  }
}

class _AtlasCopilotAnswerData {
  const _AtlasCopilotAnswerData({
    required this.answer,
    required this.confidence,
    required this.actions,
  });

  final String answer;
  final double confidence;
  final List<AtlasCopilotAction> actions;
}

enum AtlasCopilotIntent {
  generalSituation,
  priority,
  risk,
  finance,
  herd,
  paddock,
  inventory,
  agenda,
  opportunity,
  strength,
  summary,
  responsible,
  category,
  unknown,
}

enum AtlasCopilotAnswerSource { localRules, externalAi }

enum AtlasCopilotActionType {
  openIntelligence,
  openFarmIntelligence,
  openActions,
  openFarms,
  openFarm,
  openFinance,
  openHerd,
  openPaddocks,
  openInventory,
  openAgenda,
}

String atlasCopilotIntentLabel(AtlasCopilotIntent intent) {
  switch (intent) {
    case AtlasCopilotIntent.generalSituation:
      return 'Situação geral';
    case AtlasCopilotIntent.priority:
      return 'Prioridade';
    case AtlasCopilotIntent.risk:
      return 'Risco';
    case AtlasCopilotIntent.finance:
      return 'Financeiro';
    case AtlasCopilotIntent.herd:
      return 'Rebanho';
    case AtlasCopilotIntent.paddock:
      return 'Piquetes';
    case AtlasCopilotIntent.inventory:
      return 'Estoque';
    case AtlasCopilotIntent.agenda:
      return 'Agenda';
    case AtlasCopilotIntent.opportunity:
      return 'Oportunidade';
    case AtlasCopilotIntent.strength:
      return 'Ponto positivo';
    case AtlasCopilotIntent.summary:
      return 'Resumo';
    case AtlasCopilotIntent.responsible:
      return 'Responsável';
    case AtlasCopilotIntent.category:
      return 'Categoria';
    case AtlasCopilotIntent.unknown:
      return 'Pergunta geral';
  }
}

String formatCopilotNumber(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
