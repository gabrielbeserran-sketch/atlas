import 'package:projeto_atlas/features/dashboard/domain/models/executive_decision_data.dart';

class AtlasOperationsIntelligenceService {
  const AtlasOperationsIntelligenceService();

  AtlasIntelligenceBrief buildBrief({
    required ExecutiveDecisionData decisionData,
    String consultantName = 'Gabriel',
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();

    final priorities = decisionData.priorityActions;
    final predictions = decisionData.predictions;
    final farms = decisionData.farmRiskRanking;
    final responsibles = decisionData.responsibleRiskRanking;
    final categories = decisionData.categoryRiskRanking;

    final mainPriority = priorities.isEmpty ? null : priorities.first;

    final topPriorities = priorities.take(5).toList();

    final criticalPredictions = predictions.where((item) {
      return item.level == ExecutiveDecisionLevel.critical;
    }).toList();

    final attentionPredictions = predictions.where((item) {
      return item.level == ExecutiveDecisionLevel.attention;
    }).toList();

    final operationScore = _calculateOperationScore(decisionData);

    final operationLevel = _operationLevelFromScore(operationScore);

    final situation = _buildSituation(
      level: operationLevel,
      score: operationScore,
      decisionData: decisionData,
    );

    final todayGuidance = _buildTodayGuidance(
      mainPriority: mainPriority,
      criticalCount: decisionData.summary.criticalActionCount,
      predictedDelayCount: decisionData.summary.predictedDelayCount,
      topFarm: farms.isEmpty ? null : farms.first,
    );

    final executiveSummary = _buildExecutiveSummary(
      decisionData: decisionData,
      operationScore: operationScore,
      operationLevel: operationLevel,
      mainPriority: mainPriority,
      criticalPredictions: criticalPredictions,
      attentionPredictions: attentionPredictions,
    );

    final risks = _buildRisks(
      decisionData: decisionData,
      criticalPredictions: criticalPredictions,
      attentionPredictions: attentionPredictions,
    );

    final opportunities = _buildOpportunities(
      decisionData: decisionData,
      priorities: priorities,
      farms: farms,
      categories: categories,
    );

    final strengths = _buildStrengths(decisionData);

    final farmAnalyses = _buildFarmAnalyses(farms);

    final responsibleAnalyses = _buildResponsibleAnalyses(responsibles);

    final categoryAnalyses = _buildCategoryAnalyses(categories);

    return AtlasIntelligenceBrief(
      generatedAt: referenceDate,
      consultantName: consultantName,
      greeting: _buildGreeting(consultantName, referenceDate),
      operationScore: operationScore,
      operationLevel: operationLevel,
      situationTitle: situation.title,
      situationDescription: situation.description,
      executiveSummary: executiveSummary,
      todayGuidance: todayGuidance,
      mainPriority: mainPriority,
      topPriorities: topPriorities,
      risks: risks,
      opportunities: opportunities,
      strengths: strengths,
      farmAnalyses: farmAnalyses,
      responsibleAnalyses: responsibleAnalyses,
      categoryAnalyses: categoryAnalyses,
      estimatedGain: decisionData.executiveAssistant.estimatedGain,
    );
  }

  double _calculateOperationScore(ExecutiveDecisionData data) {
    final consultantComponent = data.consultantScore.value * 0.44;

    final riskControlComponent =
        (100 - data.summary.averageRiskScore).clamp(0.0, 100.0) * 0.24;

    final priorityControlComponent =
        (100 - data.summary.averagePriorityScore).clamp(0.0, 100.0) * 0.12;

    final predictionPenalty = (data.summary.predictedDelayCount * 5.5).clamp(
      0.0,
      30.0,
    );

    final criticalPenalty = (data.summary.criticalActionCount * 7.0).clamp(
      0.0,
      35.0,
    );

    final opportunityComponent = data.summary.averageOpportunityScore * 0.20;

    final score =
        consultantComponent +
        riskControlComponent +
        priorityControlComponent +
        opportunityComponent -
        predictionPenalty -
        criticalPenalty;

    return score.clamp(0.0, 100.0);
  }

  AtlasIntelligenceLevel _operationLevelFromScore(double score) {
    if (score >= 85) {
      return AtlasIntelligenceLevel.excellent;
    }

    if (score >= 70) {
      return AtlasIntelligenceLevel.stable;
    }

    if (score >= 50) {
      return AtlasIntelligenceLevel.attention;
    }

    return AtlasIntelligenceLevel.critical;
  }

  _AtlasSituation _buildSituation({
    required AtlasIntelligenceLevel level,
    required double score,
    required ExecutiveDecisionData decisionData,
  }) {
    switch (level) {
      case AtlasIntelligenceLevel.excellent:
        return _AtlasSituation(
          title: 'Operação em excelente condição',
          description:
              'Os principais indicadores estão sob controle. '
              'O foco deve ser manter a disciplina de execução e aproveitar as oportunidades identificadas.',
        );

      case AtlasIntelligenceLevel.stable:
        return _AtlasSituation(
          title: 'Operação estável',
          description:
              'A operação apresenta bom controle geral, mas ainda existem pontos que merecem acompanhamento para evitar perda de desempenho.',
        );

      case AtlasIntelligenceLevel.attention:
        return _AtlasSituation(
          title: 'Operação exige atenção',
          description:
              'Existem riscos operacionais, prioridades elevadas ou atrasos previstos que podem comprometer o resultado caso não sejam tratados.',
        );

      case AtlasIntelligenceLevel.critical:
        return _AtlasSituation(
          title: 'Operação em situação crítica',
          description:
              'A combinação de risco, ações críticas e atrasos previstos exige intervenção imediata e acompanhamento próximo.',
        );
    }
  }

  String _buildTodayGuidance({
    required ExecutivePriorityAction? mainPriority,
    required int criticalCount,
    required int predictedDelayCount,
    required ExecutiveDecisionRankingItem? topFarm,
  }) {
    if (mainPriority == null) {
      return 'Revise os registros, confirme os próximos prazos e mantenha o acompanhamento semanal da operação.';
    }

    final buffer = StringBuffer();

    buffer.write('Comece pela ação "${mainPriority.title}"');

    if (mainPriority.farmName.trim().isNotEmpty) {
      buffer.write(' na ${mainPriority.farmName}');
    }

    buffer.write('. ');

    buffer.write(mainPriority.recommendedAction);

    if (criticalCount > 1) {
      buffer.write(
        ' Depois, organize as outras '
        '${criticalCount - 1} prioridades críticas em ordem de prazo e impacto.',
      );
    }

    if (predictedDelayCount > 0) {
      buffer.write(
        ' Antecipe o contato com os responsáveis pelas ações com risco de atraso.',
      );
    }

    if (topFarm != null && topFarm.level == ExecutiveDecisionLevel.critical) {
      buffer.write(
        ' Reserve um momento específico para revisar a ${topFarm.label}.',
      );
    }

    return buffer.toString();
  }

  String _buildExecutiveSummary({
    required ExecutiveDecisionData decisionData,
    required double operationScore,
    required AtlasIntelligenceLevel operationLevel,
    required ExecutivePriorityAction? mainPriority,
    required List<ExecutivePredictionData> criticalPredictions,
    required List<ExecutivePredictionData> attentionPredictions,
  }) {
    final buffer = StringBuffer();

    buffer.write(
      'A operação recebeu score geral de '
      '${formatAtlasNumber(operationScore)} pontos e está classificada como '
      '${atlasIntelligenceLevelLabel(operationLevel).toLowerCase()}. ',
    );

    final criticalCount = decisionData.summary.criticalActionCount;

    if (criticalCount > 0) {
      buffer.write(
        'Existem $criticalCount '
        '${criticalCount == 1 ? 'ação crítica' : 'ações críticas'} na fila de decisão. ',
      );
    } else {
      buffer.write(
        'Não existem ações classificadas como críticas neste momento. ',
      );
    }

    if (mainPriority != null) {
      buffer.write(
        'A principal prioridade é "${mainPriority.title}", '
        'com score de '
        '${formatAtlasNumber(mainPriority.priorityScore)} pontos. ',
      );
    }

    if (criticalPredictions.isNotEmpty) {
      buffer.write(
        'O motor preditivo encontrou '
        '${criticalPredictions.length} '
        '${criticalPredictions.length == 1 ? 'previsão crítica' : 'previsões críticas'}. ',
      );
    } else if (attentionPredictions.isNotEmpty) {
      buffer.write(
        'Foram encontrados '
        '${attentionPredictions.length} '
        '${attentionPredictions.length == 1 ? 'sinal de atenção' : 'sinais de atenção'} para os próximos dias. ',
      );
    }

    if (decisionData.executiveAssistant.estimatedGain > 0) {
      buffer.write(
        'A execução das principais ações pode elevar o desempenho em aproximadamente '
        '${formatAtlasNumber(decisionData.executiveAssistant.estimatedGain)} pontos.',
      );
    }

    return buffer.toString().trim();
  }

  List<AtlasIntelligenceInsight> _buildRisks({
    required ExecutiveDecisionData decisionData,
    required List<ExecutivePredictionData> criticalPredictions,
    required List<ExecutivePredictionData> attentionPredictions,
  }) {
    final risks = <AtlasIntelligenceInsight>[];

    for (final prediction in criticalPredictions.take(3)) {
      risks.add(
        AtlasIntelligenceInsight(
          id: 'risk_${prediction.id}',
          title: prediction.title,
          description: prediction.description,
          recommendation: prediction.recommendedAction,
          level: AtlasIntelligenceLevel.critical,
          iconType: AtlasInsightIconType.risk,
          targetLabel: prediction.targetLabel,
        ),
      );
    }

    if (risks.length < 4) {
      for (final prediction in attentionPredictions.take(4 - risks.length)) {
        risks.add(
          AtlasIntelligenceInsight(
            id: 'risk_${prediction.id}',
            title: prediction.title,
            description: prediction.description,
            recommendation: prediction.recommendedAction,
            level: AtlasIntelligenceLevel.attention,
            iconType: AtlasInsightIconType.warning,
            targetLabel: prediction.targetLabel,
          ),
        );
      }
    }

    if (decisionData.summary.criticalActionCount > 0 && risks.length < 4) {
      risks.add(
        AtlasIntelligenceInsight(
          id: 'critical_actions',
          title: 'Prioridades críticas abertas',
          description:
              '${decisionData.summary.criticalActionCount} ações exigem atenção imediata.',
          recommendation:
              'Trate primeiro as ações de maior risco, menor prazo e maior impacto.',
          level: AtlasIntelligenceLevel.critical,
          iconType: AtlasInsightIconType.priority,
          targetLabel: 'Ações gerenciais',
        ),
      );
    }

    if (risks.isEmpty) {
      risks.add(
        const AtlasIntelligenceInsight(
          id: 'no_relevant_risk',
          title: 'Nenhum risco crítico identificado',
          description: 'Os dados atuais não indicam um risco crítico imediato.',
          recommendation:
              'Mantenha os registros atualizados e revise os indicadores semanalmente.',
          level: AtlasIntelligenceLevel.stable,
          iconType: AtlasInsightIconType.positive,
          targetLabel: 'Operação geral',
        ),
      );
    }

    return risks;
  }

  List<AtlasIntelligenceInsight> _buildOpportunities({
    required ExecutiveDecisionData decisionData,
    required List<ExecutivePriorityAction> priorities,
    required List<ExecutiveDecisionRankingItem> farms,
    required List<ExecutiveDecisionRankingItem> categories,
  }) {
    final opportunities = <AtlasIntelligenceInsight>[];

    final opportunityActions = priorities
        .where((item) {
          return item.opportunityScore >= 70;
        })
        .take(3);

    for (final action in opportunityActions) {
      opportunities.add(
        AtlasIntelligenceInsight(
          id: 'opportunity_${action.actionId}',
          title: action.title,
          description:
              'Esta ação possui oportunidade estimada de '
              '${formatAtlasNumber(action.opportunityScore)} pontos.',
          recommendation: action.recommendedAction,
          level: AtlasIntelligenceLevel.stable,
          iconType: AtlasInsightIconType.opportunity,
          targetLabel: action.farmName,
        ),
      );
    }

    if (categories.isNotEmpty && opportunities.length < 4) {
      final category = categories.first;

      if (category.opportunityScore >= 55) {
        opportunities.add(
          AtlasIntelligenceInsight(
            id: 'category_opportunity_${category.label}',
            title: 'Oportunidade na categoria ${category.label}',
            description:
                'A categoria possui oportunidade estimada de '
                '${formatAtlasNumber(category.opportunityScore)} pontos.',
            recommendation:
                'Revise as ações da categoria e transforme as causas recorrentes em um plano preventivo.',
            level: AtlasIntelligenceLevel.stable,
            iconType: AtlasInsightIconType.opportunity,
            targetLabel: category.label,
          ),
        );
      }
    }

    if (farms.isNotEmpty && opportunities.length < 4) {
      final farm = farms.first;

      if (farm.opportunityScore >= 55) {
        opportunities.add(
          AtlasIntelligenceInsight(
            id: 'farm_opportunity_${farm.label}',
            title: 'Potencial de melhoria na ${farm.label}',
            description:
                'A propriedade possui oportunidade estimada de '
                '${formatAtlasNumber(farm.opportunityScore)} pontos.',
            recommendation:
                'Concentre as primeiras ações na propriedade e acompanhe a evolução do risco.',
            level: AtlasIntelligenceLevel.stable,
            iconType: AtlasInsightIconType.farm,
            targetLabel: farm.label,
          ),
        );
      }
    }

    if (opportunities.isEmpty) {
      opportunities.add(
        AtlasIntelligenceInsight(
          id: 'general_opportunity',
          title: 'Manutenção do desempenho',
          description:
              'A principal oportunidade está em manter os prazos, responsáveis e registros sob controle.',
          recommendation:
              'Conclua as prioridades atuais e registre os resultados alcançados.',
          level: AtlasIntelligenceLevel.stable,
          iconType: AtlasInsightIconType.opportunity,
          targetLabel: 'Operação geral',
        ),
      );
    }

    return opportunities;
  }

  List<AtlasIntelligenceInsight> _buildStrengths(
    ExecutiveDecisionData decisionData,
  ) {
    final strengths = <AtlasIntelligenceInsight>[];

    if (decisionData.summary.criticalActionCount == 0) {
      strengths.add(
        const AtlasIntelligenceInsight(
          id: 'no_critical_actions',
          title: 'Sem ações críticas',
          description: 'Nenhuma ação está classificada no nível crítico.',
          recommendation: 'Mantenha a rotina de acompanhamento.',
          level: AtlasIntelligenceLevel.excellent,
          iconType: AtlasInsightIconType.positive,
          targetLabel: 'Ações gerenciais',
        ),
      );
    }

    if (decisionData.summary.predictedDelayCount == 0) {
      strengths.add(
        const AtlasIntelligenceInsight(
          id: 'no_predicted_delay',
          title: 'Sem atrasos previstos',
          description:
              'O motor preditivo não encontrou ações com alta probabilidade de atraso.',
          recommendation: 'Continue atualizando o progresso e os impedimentos.',
          level: AtlasIntelligenceLevel.excellent,
          iconType: AtlasInsightIconType.positive,
          targetLabel: 'Prazos',
        ),
      );
    }

    if (decisionData.consultantScore.value >= 70) {
      strengths.add(
        AtlasIntelligenceInsight(
          id: 'good_consultant_score',
          title: 'Bom desempenho do consultor',
          description:
              'O score atual é de '
              '${formatAtlasNumber(decisionData.consultantScore.value)} pontos.',
          recommendation:
              'Preserve a disciplina de registros, prazos e acompanhamento.',
          level: decisionData.consultantScore.value >= 85
              ? AtlasIntelligenceLevel.excellent
              : AtlasIntelligenceLevel.stable,
          iconType: AtlasInsightIconType.positive,
          targetLabel: 'Score do consultor',
        ),
      );
    }

    if (decisionData.summary.highRiskResponsibleCount == 0) {
      strengths.add(
        const AtlasIntelligenceInsight(
          id: 'no_overload',
          title: 'Sem sobrecarga crítica identificada',
          description:
              'Nenhum responsável está classificado com risco elevado.',
          recommendation: 'Mantenha a distribuição equilibrada das ações.',
          level: AtlasIntelligenceLevel.excellent,
          iconType: AtlasInsightIconType.positive,
          targetLabel: 'Responsáveis',
        ),
      );
    }

    if (strengths.isEmpty) {
      strengths.add(
        const AtlasIntelligenceInsight(
          id: 'data_available',
          title: 'Base de dados disponível para decisão',
          description:
              'O Atlas já possui informações suficientes para ordenar prioridades e gerar recomendações.',
          recommendation:
              'Continue alimentando o sistema para aumentar a precisão das análises.',
          level: AtlasIntelligenceLevel.stable,
          iconType: AtlasInsightIconType.positive,
          targetLabel: 'Qualidade dos dados',
        ),
      );
    }

    return strengths;
  }

  List<AtlasGroupAnalysis> _buildFarmAnalyses(
    List<ExecutiveDecisionRankingItem> ranking,
  ) {
    return ranking.take(6).map((item) {
      return AtlasGroupAnalysis(
        position: item.position,
        label: item.label,
        groupType: AtlasGroupType.farm,
        score: item.riskScore,
        opportunityScore: item.opportunityScore,
        openCount: item.openCount,
        overdueCount: item.overdueCount,
        urgentCount: item.urgentCount,
        level: _convertDecisionLevel(item.level),
        analysis: item.explanation,
        recommendation: _farmRecommendation(item),
      );
    }).toList();
  }

  List<AtlasGroupAnalysis> _buildResponsibleAnalyses(
    List<ExecutiveDecisionRankingItem> ranking,
  ) {
    return ranking.take(6).map((item) {
      return AtlasGroupAnalysis(
        position: item.position,
        label: item.label,
        groupType: AtlasGroupType.responsible,
        score: item.riskScore,
        opportunityScore: item.opportunityScore,
        openCount: item.openCount,
        overdueCount: item.overdueCount,
        urgentCount: item.urgentCount,
        level: _convertDecisionLevel(item.level),
        analysis: item.explanation,
        recommendation: _responsibleRecommendation(item),
      );
    }).toList();
  }

  List<AtlasGroupAnalysis> _buildCategoryAnalyses(
    List<ExecutiveDecisionRankingItem> ranking,
  ) {
    return ranking.take(6).map((item) {
      return AtlasGroupAnalysis(
        position: item.position,
        label: item.label,
        groupType: AtlasGroupType.category,
        score: item.riskScore,
        opportunityScore: item.opportunityScore,
        openCount: item.openCount,
        overdueCount: item.overdueCount,
        urgentCount: item.urgentCount,
        level: _convertDecisionLevel(item.level),
        analysis: item.explanation,
        recommendation: _categoryRecommendation(item),
      );
    }).toList();
  }

  String _farmRecommendation(ExecutiveDecisionRankingItem item) {
    if (item.overdueCount > 0) {
      return 'Revise os atrasos da propriedade, confirme os responsáveis e defina um plano de recuperação.';
    }

    if (item.urgentCount > 0) {
      return 'Organize as ações urgentes da propriedade e acompanhe os próximos vencimentos.';
    }

    if (item.openCount >= 5) {
      return 'Reduza o volume de ações abertas antes de criar novas pendências.';
    }

    return 'Mantenha o acompanhamento semanal e atualize os indicadores da propriedade.';
  }

  String _responsibleRecommendation(ExecutiveDecisionRankingItem item) {
    if (item.overdueCount > 0) {
      return 'Converse com o responsável, identifique impedimentos e redistribua tarefas quando necessário.';
    }

    if (item.openCount >= 6) {
      return 'Avalie a carga atual e ofereça apoio nas ações de maior impacto.';
    }

    return 'Confirme o progresso das ações e mantenha os prazos atualizados.';
  }

  String _categoryRecommendation(ExecutiveDecisionRankingItem item) {
    if (item.overdueCount > 0) {
      return 'Investigue a causa comum dos atrasos e crie um plano preventivo para a categoria.';
    }

    if (item.openCount >= 4) {
      return 'Agrupe as ações semelhantes e transforme-as em um plano único de melhoria.';
    }

    return 'Acompanhe a evolução da categoria e registre os resultados das ações.';
  }

  AtlasIntelligenceLevel _convertDecisionLevel(ExecutiveDecisionLevel level) {
    switch (level) {
      case ExecutiveDecisionLevel.excellent:
        return AtlasIntelligenceLevel.excellent;

      case ExecutiveDecisionLevel.good:
        return AtlasIntelligenceLevel.stable;

      case ExecutiveDecisionLevel.normal:
        return AtlasIntelligenceLevel.stable;

      case ExecutiveDecisionLevel.attention:
        return AtlasIntelligenceLevel.attention;

      case ExecutiveDecisionLevel.critical:
        return AtlasIntelligenceLevel.critical;
    }
  }

  String _buildGreeting(String consultantName, DateTime now) {
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
}

class AtlasIntelligenceBrief {
  const AtlasIntelligenceBrief({
    required this.generatedAt,
    required this.consultantName,
    required this.greeting,
    required this.operationScore,
    required this.operationLevel,
    required this.situationTitle,
    required this.situationDescription,
    required this.executiveSummary,
    required this.todayGuidance,
    required this.mainPriority,
    required this.topPriorities,
    required this.risks,
    required this.opportunities,
    required this.strengths,
    required this.farmAnalyses,
    required this.responsibleAnalyses,
    required this.categoryAnalyses,
    required this.estimatedGain,
  });

  final DateTime generatedAt;

  final String consultantName;
  final String greeting;

  final double operationScore;
  final AtlasIntelligenceLevel operationLevel;

  final String situationTitle;
  final String situationDescription;

  final String executiveSummary;
  final String todayGuidance;

  final ExecutivePriorityAction? mainPriority;

  final List<ExecutivePriorityAction> topPriorities;

  final List<AtlasIntelligenceInsight> risks;

  final List<AtlasIntelligenceInsight> opportunities;

  final List<AtlasIntelligenceInsight> strengths;

  final List<AtlasGroupAnalysis> farmAnalyses;

  final List<AtlasGroupAnalysis> responsibleAnalyses;

  final List<AtlasGroupAnalysis> categoryAnalyses;

  final double estimatedGain;

  bool get hasMainPriority {
    return mainPriority != null;
  }

  bool get hasCriticalRisk {
    return risks.any((item) {
      return item.level == AtlasIntelligenceLevel.critical;
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'consultantName': consultantName,
      'greeting': greeting,
      'operationScore': operationScore,
      'operationLevel': operationLevel.name,
      'situationTitle': situationTitle,
      'situationDescription': situationDescription,
      'executiveSummary': executiveSummary,
      'todayGuidance': todayGuidance,
      'mainPriority': mainPriority?.toJson(),
      'topPriorities': topPriorities.map((item) {
        return item.toJson();
      }).toList(),
      'risks': risks.map((item) {
        return item.toJson();
      }).toList(),
      'opportunities': opportunities.map((item) {
        return item.toJson();
      }).toList(),
      'strengths': strengths.map((item) {
        return item.toJson();
      }).toList(),
      'farmAnalyses': farmAnalyses.map((item) {
        return item.toJson();
      }).toList(),
      'responsibleAnalyses': responsibleAnalyses.map((item) {
        return item.toJson();
      }).toList(),
      'categoryAnalyses': categoryAnalyses.map((item) {
        return item.toJson();
      }).toList(),
      'estimatedGain': estimatedGain,
    };
  }
}

class AtlasIntelligenceInsight {
  const AtlasIntelligenceInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.level,
    required this.iconType,
    required this.targetLabel,
  });

  final String id;
  final String title;
  final String description;
  final String recommendation;

  final AtlasIntelligenceLevel level;
  final AtlasInsightIconType iconType;

  final String targetLabel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'level': level.name,
      'iconType': iconType.name,
      'targetLabel': targetLabel,
    };
  }
}

class AtlasGroupAnalysis {
  const AtlasGroupAnalysis({
    required this.position,
    required this.label,
    required this.groupType,
    required this.score,
    required this.opportunityScore,
    required this.openCount,
    required this.overdueCount,
    required this.urgentCount,
    required this.level,
    required this.analysis,
    required this.recommendation,
  });

  final int position;
  final String label;

  final AtlasGroupType groupType;

  final double score;
  final double opportunityScore;

  final int openCount;
  final int overdueCount;
  final int urgentCount;

  final AtlasIntelligenceLevel level;

  final String analysis;
  final String recommendation;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'label': label,
      'groupType': groupType.name,
      'score': score,
      'opportunityScore': opportunityScore,
      'openCount': openCount,
      'overdueCount': overdueCount,
      'urgentCount': urgentCount,
      'level': level.name,
      'analysis': analysis,
      'recommendation': recommendation,
    };
  }
}

class _AtlasSituation {
  const _AtlasSituation({required this.title, required this.description});

  final String title;
  final String description;
}

enum AtlasIntelligenceLevel { excellent, stable, attention, critical }

enum AtlasInsightIconType {
  positive,
  warning,
  risk,
  priority,
  opportunity,
  farm,
  responsible,
  category,
}

enum AtlasGroupType { farm, responsible, category }

String atlasIntelligenceLevelLabel(AtlasIntelligenceLevel level) {
  switch (level) {
    case AtlasIntelligenceLevel.excellent:
      return 'Excelente';

    case AtlasIntelligenceLevel.stable:
      return 'Estável';

    case AtlasIntelligenceLevel.attention:
      return 'Atenção';

    case AtlasIntelligenceLevel.critical:
      return 'Crítico';
  }
}

String formatAtlasNumber(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
