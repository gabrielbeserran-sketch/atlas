import 'dart:math' as math;

import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';
import 'package:projeto_atlas/features/executive_brain/domain/services/atlas_executive_brain_event_service.dart';
import 'package:projeto_atlas/features/executive_core/domain/models/atlas_executive_core_data.dart';

class AtlasExecutiveBrainService {
  const AtlasExecutiveBrainService();

  AtlasExecutiveBrainData build({
    required AtlasExecutiveCoreData executiveCore,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final crossImpacts = _buildCrossImpacts(
      executiveCore,
    );

    final conflicts = _buildConflicts(
      executiveCore,
    );

    final officialDecision = _buildOfficialDecision(
      executiveCore: executiveCore,
      conflicts: conflicts,
      crossImpacts: crossImpacts,
    );

    final strategy = _buildStrategy(
      executiveCore: executiveCore,
      officialDecision: officialDecision,
      crossImpacts: crossImpacts,
      conflicts: conflicts,
    );

    final plans = _buildPlans(
      executiveCore,
    );

    final memoryInsights = _buildMemoryInsights(
      executiveCore,
    );

    final scoreDimensions = _buildScoreDimensions(executiveCore);
    final radarItems = _buildRadarItems(executiveCore);

    final score = _brainScore(
      executiveCore: executiveCore,
      crossImpacts: crossImpacts,
      conflicts: conflicts,
    );

    final confidence = _confidence(
      executiveCore: executiveCore,
      officialDecision: officialDecision,
      crossImpacts: crossImpacts,
    );

    final status = _status(
      score,
    );

    final result = AtlasExecutiveBrainData(
      generatedAt: currentTime,
      summary: _summary(
        executiveCore: executiveCore,
        score: score,
        confidence: confidence,
        officialDecision: officialDecision,
        strategy: strategy,
        crossImpacts: crossImpacts,
        conflicts: conflicts,
        dailyPlan: plans.daily,
        weeklyPlan: plans.weekly,
        monthlyPlan: plans.monthly,
      ),
      brainScore: score,
      confidencePercent: confidence,
      status: status,
      officialDecision: officialDecision,
      strategy: strategy,
      crossImpacts: crossImpacts,
      conflicts: conflicts,
      dailyPlan: plans.daily,
      weeklyPlan: plans.weekly,
      monthlyPlan: plans.monthly,
      memoryInsights: memoryInsights,
      scoreDimensions: scoreDimensions,
      radarItems: radarItems,
    );

    AtlasExecutiveBrainEventService.instance
        .publishIfChangedDetached(
      result,
    );

    return result;
  }

  List<AtlasExecutiveCrossImpact>
      _buildCrossImpacts(
    AtlasExecutiveCoreData core,
  ) {
    final result =
        <AtlasExecutiveCrossImpact>[];

    if (core.operationalIndex < 60 &&
        core.financialIndex >= 65) {
      result.add(
        AtlasExecutiveCrossImpact(
          id:
              'operational_to_financial',
          title:
              'Execução pode limitar o resultado financeiro',
          description:
              'O índice financeiro é favorável, mas o índice operacional está abaixo do nível necessário.',
          sourceArea: 'Operacional',
          affectedArea: 'Financeiro',
          direction:
              AtlasExecutiveImpactDirection.negative,
          impactScore:
              (100 - core.operationalIndex)
                  .clamp(0.0, 100.0)
                  .toDouble(),
          probabilityPercent: 86,
          financialImpact:
              core.opportunities.fold<double>(
            0,
            (sum, item) =>
                sum +
                item.expectedReturn * 0.25,
          ),
          recommendation:
              'Priorizar execução e remover gargalos antes de ampliar investimentos.',
        ),
      );
    }

    if (core.predictiveIndex < 60 &&
        core.strategicIndex >= 70) {
      result.add(
        AtlasExecutiveCrossImpact(
          id:
              'predictive_to_strategy',
          title:
              'Baixa previsibilidade pode comprometer a estratégia',
          description:
              'A estratégia está estruturada, porém a confiança preditiva permanece limitada.',
          sourceArea: 'Preditivo',
          affectedArea: 'Estratégico',
          direction:
              AtlasExecutiveImpactDirection.negative,
          impactScore:
              (100 - core.predictiveIndex)
                  .clamp(0.0, 100.0)
                  .toDouble(),
          probabilityPercent: 78,
          financialImpact: 0,
          recommendation:
              'Atualizar dados e revisar premissas antes de comprometer recursos de longo prazo.',
        ),
      );
    }

    if (core.financialIndex >= 70 &&
        core.operationalIndex >= 70) {
      result.add(
        AtlasExecutiveCrossImpact(
          id:
              'operations_finance_opportunity',
          title:
              'Execução e finanças alinhadas',
          description:
              'A combinação de boa capacidade operacional e oportunidade financeira favorece expansão controlada.',
          sourceArea: 'Operacional',
          affectedArea: 'Financeiro',
          direction:
              AtlasExecutiveImpactDirection.positive,
          impactScore:
              ((core.financialIndex +
                          core.operationalIndex) /
                      2)
                  .clamp(0.0, 100.0)
                  .toDouble(),
          probabilityPercent: 82,
          financialImpact:
              core.opportunities.fold<double>(
            0,
            (sum, item) =>
                sum + item.expectedReturn,
          ),
          recommendation:
              'Priorizar oportunidades de maior ROI e validar capacidade de execução.',
        ),
      );
    }

    if (core.healthIndex < 55) {
      result.add(
        AtlasExecutiveCrossImpact(
          id: 'health_global_impact',
          title:
              'Saúde geral afeta toda a operação',
          description:
              'O baixo índice de saúde geral aumenta o risco de efeitos simultâneos em execução, estratégia e finanças.',
          sourceArea: 'Saúde geral',
          affectedArea: 'Toda a operação',
          direction:
              AtlasExecutiveImpactDirection.mixed,
          impactScore:
              (100 - core.healthIndex)
                  .clamp(0.0, 100.0)
                  .toDouble(),
          probabilityPercent: 90,
          financialImpact:
              core.risks.fold<double>(
            0,
            (sum, item) =>
                sum +
                item.expectedFinancialImpact,
          ),
          recommendation:
              'Criar plano de estabilização antes de ampliar metas.',
        ),
      );
    }

    result.sort(
      (first, second) =>
          second.impactScore.compareTo(
        first.impactScore,
      ),
    );

    return result;
  }

  List<AtlasExecutiveConflict> _buildConflicts(
    AtlasExecutiveCoreData core,
  ) {
    final result =
        <AtlasExecutiveConflict>[];

    final urgentPriorities =
        core.priorities.where((item) {
      return item.deadlineHours <= 24;
    }).toList();

    if (urgentPriorities.length >= 5) {
      result.add(
        AtlasExecutiveConflict(
          id:
              'too_many_urgent_priorities',
          title:
              'Excesso de prioridades urgentes',
          description:
              '${urgentPriorities.length} prioridades possuem prazo inferior ou igual a 24 horas.',
          type:
              AtlasExecutiveConflictType.priority,
          severity:
              urgentPriorities.length >= 8
                  ? AtlasExecutiveBrainSeverity
                      .critical
                  : AtlasExecutiveBrainSeverity.high,
          relatedEntityIds:
              urgentPriorities
                  .map((item) => item.id)
                  .toList(),
          recommendation:
              'Reduzir o número de prioridades simultâneas e escolher as três ações mais críticas.',
        ),
      );
    }

    final highInvestmentOpportunities =
        core.opportunities.where((item) {
      return item.investmentValue >= 50000;
    }).toList();

    if (highInvestmentOpportunities.length >= 2) {
      result.add(
        AtlasExecutiveConflict(
          id:
              'investment_resource_conflict',
          title:
              'Disputa por recursos financeiros',
          description:
              'Existem múltiplas oportunidades que exigem investimento elevado ao mesmo tempo.',
          type:
              AtlasExecutiveConflictType.resource,
          severity:
              AtlasExecutiveBrainSeverity.high,
          relatedEntityIds:
              highInvestmentOpportunities
                  .map((item) => item.id)
                  .toList(),
          recommendation:
              'Comparar ROI, risco e prazo antes de aprovar os investimentos.',
        ),
      );
    }

    if (core.operationalIndex < 55 &&
        core.priorities.length >= 10) {
      result.add(
        AtlasExecutiveConflict(
          id:
              'execution_capacity_conflict',
          title:
              'Capacidade de execução abaixo da demanda',
          description:
              'O volume de prioridades supera a capacidade operacional indicada pelo sistema.',
          type:
              AtlasExecutiveConflictType.execution,
          severity:
              AtlasExecutiveBrainSeverity.critical,
          relatedEntityIds:
              core.priorities
                  .take(10)
                  .map((item) => item.id)
                  .toList(),
          recommendation:
              'Suspender ações de baixo impacto e concentrar recursos nas prioridades críticas.',
        ),
      );
    }

    if (core.strategicIndex >= 75 &&
        core.healthIndex < 55) {
      result.add(
        AtlasExecutiveConflict(
          id:
              'strategy_health_conflict',
          title:
              'Estratégia incompatível com a saúde atual',
          description:
              'As metas estratégicas estão avançadas em relação à condição atual da operação.',
          type:
              AtlasExecutiveConflictType.strategy,
          severity:
              AtlasExecutiveBrainSeverity.high,
          relatedEntityIds: const [],
          recommendation:
              'Recalibrar metas e executar uma fase de estabilização.',
        ),
      );
    }

    return result;
  }

  AtlasExecutiveBrainDecision?
      _buildOfficialDecision({
    required AtlasExecutiveCoreData executiveCore,
    required List<AtlasExecutiveConflict> conflicts,
    required List<AtlasExecutiveCrossImpact>
        crossImpacts,
  }) {
    final baseDecision =
        executiveCore.bestDecisionOfWeek;

    if (baseDecision == null) {
      return null;
    }

    final criticalConflicts =
        conflicts.where((item) {
      return item.severity ==
          AtlasExecutiveBrainSeverity.critical;
    }).length;

    final negativeImpacts =
        crossImpacts.where((item) {
      return item.direction ==
          AtlasExecutiveImpactDirection.negative;
    }).length;

    final adjustedScore =
        (baseDecision.score -
                criticalConflicts * 8 -
                negativeImpacts * 3)
            .clamp(0.0, 100.0)
            .toDouble();

    final priority =
        _priorityFromScore(
      adjustedScore,
    );

    final conflictReason = conflicts.isEmpty
        ? ''
        : ' Foram identificados '
            '${conflicts.length} conflitos que devem ser controlados.';

    return AtlasExecutiveBrainDecision(
      id:
          'official_${baseDecision.id}',
      title: baseDecision.title,
      description:
          baseDecision.description,
      farmName:
          baseDecision.farmName,
      priority: priority,
      score: adjustedScore,
      confidencePercent:
          baseDecision.confidencePercent,
      expectedFinancialImpact:
          baseDecision.expectedFinancialImpact,
      deadlineHours:
          baseDecision.deadlineHours,
      reasoning:
          '${baseDecision.reasoning}$conflictReason',
      actions:
          baseDecision.actions,
      expectedResult:
          baseDecision.expectedFinancialImpact > 0
              ? 'Capturar impacto esperado de '
                  'R\$ ${baseDecision.expectedFinancialImpact.toStringAsFixed(2)}.'
              : 'Reduzir risco e elevar a capacidade de execução.',
    );
  }

  AtlasExecutiveBrainStrategy? _buildStrategy({
    required AtlasExecutiveCoreData executiveCore,
    required AtlasExecutiveBrainDecision?
        officialDecision,
    required List<AtlasExecutiveCrossImpact>
        crossImpacts,
    required List<AtlasExecutiveConflict> conflicts,
  }) {
    if (officialDecision == null) {
      return null;
    }

    final financialWeight =
        executiveCore.financialIndex < 60
            ? 30.0
            : 20.0;

    final operationalWeight =
        executiveCore.operationalIndex < 60
            ? 35.0
            : 25.0;

    final strategicWeight =
        executiveCore.strategicIndex < 60
            ? 25.0
            : 20.0;

    final predictiveWeight =
        100 -
            financialWeight -
            operationalWeight -
            strategicWeight;

    final totalImpact =
        officialDecision.expectedFinancialImpact +
            crossImpacts.fold<double>(
              0,
              (sum, item) =>
                  sum +
                  math.max(
                    item.financialImpact,
                    0,
                  ),
            );

    return AtlasExecutiveBrainStrategy(
      id:
          'strategy_${officialDecision.id}',
      title:
          'Estratégia executiva integrada',
      summary:
          'Concentrar a operação na decisão oficial, remover conflitos e capturar impactos cruzados.',
      objective:
          'Transformar prioridades dispersas em uma única sequência coordenada de execução.',
      horizonDays: 30,
      successProbabilityPercent:
          (officialDecision.confidencePercent -
                  conflicts.length * 3)
              .clamp(35.0, 95.0)
              .toDouble(),
      expectedFinancialImpact:
          totalImpact,
      pillars: [
        AtlasExecutiveStrategyPillar(
          position: 1,
          title: 'Financeiro',
          description:
              'Proteger caixa, priorizar ROI e reduzir exposição.',
          weightPercent:
              financialWeight,
          target:
              'Elevar o índice financeiro acima de 70.',
        ),
        AtlasExecutiveStrategyPillar(
          position: 2,
          title: 'Operacional',
          description:
              'Remover gargalos e aumentar a capacidade de execução.',
          weightPercent:
              operationalWeight,
          target:
              'Elevar execução e reduzir atrasos.',
        ),
        AtlasExecutiveStrategyPillar(
          position: 3,
          title: 'Estratégico',
          description:
              'Alinhar metas, prioridades e recursos.',
          weightPercent:
              strategicWeight,
          target:
              'Manter metas compatíveis com a realidade.',
        ),
        AtlasExecutiveStrategyPillar(
          position: 4,
          title: 'Preditivo',
          description:
              'Atualizar dados e antecipar riscos.',
          weightPercent:
              predictiveWeight,
          target:
              'Elevar confiança preditiva acima de 75%.',
        ),
      ],
    );
  }

  _ExecutivePlans _buildPlans(
    AtlasExecutiveCoreData core,
  ) {
    final daily =
        <AtlasExecutiveBrainAction>[];
    final weekly =
        <AtlasExecutiveBrainAction>[];
    final monthly =
        <AtlasExecutiveBrainAction>[];

    for (final item in core.priorities) {
      final horizon = item.deadlineHours <= 24
          ? AtlasExecutiveBrainHorizon.today
          : item.deadlineHours <= 168
              ? AtlasExecutiveBrainHorizon.week
              : AtlasExecutiveBrainHorizon.month;

      final action =
          AtlasExecutiveBrainAction(
        position: 0,
        id: item.id,
        title: item.title,
        description:
            item.description,
        farmName: item.farmName,
        horizon: horizon,
        priority:
            _priorityFromCore(
          item.priority,
        ),
        confidencePercent:
            item.confidencePercent,
        expectedFinancialImpact:
            item.expectedFinancialImpact,
        deadlineHours:
            item.deadlineHours,
        source: item.source,
        completed: false,
      );

      switch (horizon) {
        case AtlasExecutiveBrainHorizon.today:
          daily.add(action);

        case AtlasExecutiveBrainHorizon.week:
          weekly.add(action);

        case AtlasExecutiveBrainHorizon.month:
          monthly.add(action);
      }
    }

    List<AtlasExecutiveBrainAction> rank(
      List<AtlasExecutiveBrainAction> items,
      int limit,
    ) {
      final selected =
          items.take(limit).toList();

      return List.generate(
        selected.length,
        (index) {
          final item = selected[index];

          return AtlasExecutiveBrainAction(
            position: index + 1,
            id: item.id,
            title: item.title,
            description:
                item.description,
            farmName:
                item.farmName,
            horizon: item.horizon,
            priority:
                item.priority,
            confidencePercent:
                item.confidencePercent,
            expectedFinancialImpact:
                item.expectedFinancialImpact,
            deadlineHours:
                item.deadlineHours,
            source: item.source,
            completed:
                item.completed,
          );
        },
      );
    }

    return _ExecutivePlans(
      daily: rank(daily, 5),
      weekly: rank(weekly, 8),
      monthly: rank(monthly, 10),
    );
  }

  List<AtlasExecutiveMemoryInsight>
      _buildMemoryInsights(
    AtlasExecutiveCoreData core,
  ) {
    final result =
        <AtlasExecutiveMemoryInsight>[];

    for (final item
        in core.memoryRecords.take(20)) {
      final type = switch (item.type) {
        AtlasExecutiveMemoryType.pattern =>
          AtlasExecutiveMemoryInsightType
              .recurringPattern,
        AtlasExecutiveMemoryType.risk =>
          AtlasExecutiveMemoryInsightType
              .historicalRisk,
        AtlasExecutiveMemoryType.opportunity =>
          AtlasExecutiveMemoryInsightType
              .repeatedOpportunity,
        AtlasExecutiveMemoryType.decision =>
          AtlasExecutiveMemoryInsightType
              .decisionLesson,
        AtlasExecutiveMemoryType.mission =>
          AtlasExecutiveMemoryInsightType
              .missionLesson,
      };

      result.add(
        AtlasExecutiveMemoryInsight(
          id:
              'insight_${item.id}',
          title: item.title,
          description:
              item.description,
          type: type,
          farmName: item.farmName,
          relevanceScore:
              item.relevanceScore,
          recommendation:
              _memoryRecommendation(type),
        ),
      );
    }

    return result;
  }

  double _brainScore({
    required AtlasExecutiveCoreData executiveCore,
    required List<AtlasExecutiveCrossImpact>
        crossImpacts,
    required List<AtlasExecutiveConflict> conflicts,
  }) {
    final negativeImpactPenalty =
        crossImpacts.where((item) {
      return item.direction ==
          AtlasExecutiveImpactDirection.negative;
    }).fold<double>(
      0,
      (sum, item) =>
          sum +
          item.impactScore * 0.04,
    );

    final conflictPenalty =
        conflicts.fold<double>(
      0,
      (sum, item) =>
          sum +
          _severityWeight(item.severity) *
              2.5,
    );

    return (executiveCore.executiveScore -
            negativeImpactPenalty -
            conflictPenalty)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _confidence({
    required AtlasExecutiveCoreData executiveCore,
    required AtlasExecutiveBrainDecision?
        officialDecision,
    required List<AtlasExecutiveCrossImpact>
        crossImpacts,
  }) {
    final values = <double>[
      executiveCore.confidencePercent,
      if (officialDecision != null)
        officialDecision.confidencePercent,
      ...crossImpacts.map(
        (item) =>
            item.probabilityPercent,
      ),
    ];

    return (values.fold<double>(
              0,
              (sum, value) => sum + value,
            ) /
            values.length)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  AtlasExecutiveBrainStatus _status(
    double score,
  ) {
    if (score >= 80) {
      return AtlasExecutiveBrainStatus.excellent;
    }

    if (score >= 65) {
      return AtlasExecutiveBrainStatus.adequate;
    }

    if (score >= 45) {
      return AtlasExecutiveBrainStatus.attention;
    }

    return AtlasExecutiveBrainStatus.critical;
  }

  AtlasExecutiveBrainPriority
      _priorityFromScore(
    double score,
  ) {
    if (score >= 85) {
      return AtlasExecutiveBrainPriority.critical;
    }

    if (score >= 70) {
      return AtlasExecutiveBrainPriority.high;
    }

    if (score >= 50) {
      return AtlasExecutiveBrainPriority.medium;
    }

    return AtlasExecutiveBrainPriority.low;
  }

  AtlasExecutiveBrainPriority
      _priorityFromCore(
    AtlasExecutiveCorePriorityLevel priority,
  ) {
    switch (priority) {
      case AtlasExecutiveCorePriorityLevel.low:
        return AtlasExecutiveBrainPriority.low;

      case AtlasExecutiveCorePriorityLevel.medium:
        return AtlasExecutiveBrainPriority.medium;

      case AtlasExecutiveCorePriorityLevel.high:
        return AtlasExecutiveBrainPriority.high;

      case AtlasExecutiveCorePriorityLevel.critical:
        return AtlasExecutiveBrainPriority.critical;
    }
  }

  int _severityWeight(
    AtlasExecutiveBrainSeverity severity,
  ) {
    switch (severity) {
      case AtlasExecutiveBrainSeverity.low:
        return 1;

      case AtlasExecutiveBrainSeverity.medium:
        return 2;

      case AtlasExecutiveBrainSeverity.high:
        return 3;

      case AtlasExecutiveBrainSeverity.critical:
        return 4;
    }
  }

  String _memoryRecommendation(
    AtlasExecutiveMemoryInsightType type,
  ) {
    switch (type) {
      case AtlasExecutiveMemoryInsightType
          .recurringPattern:
        return 'Verificar recorrência e confirmar a causa comum.';

      case AtlasExecutiveMemoryInsightType
          .historicalRisk:
        return 'Criar ação preventiva antes da repetição do risco.';

      case AtlasExecutiveMemoryInsightType
          .repeatedOpportunity:
        return 'Comparar resultados anteriores e avaliar expansão.';

      case AtlasExecutiveMemoryInsightType
          .decisionLesson:
        return 'Usar o aprendizado para melhorar decisões futuras.';

      case AtlasExecutiveMemoryInsightType
          .missionLesson:
        return 'Reaplicar as etapas que produziram melhor resultado.';
    }
  }

  String _summary({
    required AtlasExecutiveCoreData executiveCore,
    required double score,
    required double confidence,
    required AtlasExecutiveBrainDecision?
        officialDecision,
    required AtlasExecutiveBrainStrategy? strategy,
    required List<AtlasExecutiveCrossImpact>
        crossImpacts,
    required List<AtlasExecutiveConflict> conflicts,
    required List<AtlasExecutiveBrainAction> dailyPlan,
    required List<AtlasExecutiveBrainAction> weeklyPlan,
    required List<AtlasExecutiveBrainAction> monthlyPlan,
  }) {
    final decisionTitle =
        officialDecision?.title ??
            'nenhuma decisão oficial';

    final strategyTitle =
        strategy?.title ??
            'nenhuma estratégia central';

    return 'O Executive Brain consolidou o Executive Core, '
        'gerou score de ${score.toStringAsFixed(0)}/100, '
        '${confidence.toStringAsFixed(0)}% de confiança, '
        '${crossImpacts.length} impactos cruzados, '
        '${conflicts.length} conflitos, '
        '${dailyPlan.length} ações para hoje, '
        '${weeklyPlan.length} para a semana, '
        '${monthlyPlan.length} para o mês, '
        '$decisionTitle como decisão oficial '
        'e $strategyTitle como estratégia central.';
  }

  List<AtlasExecutiveScoreDimension> _buildScoreDimensions(AtlasExecutiveCoreData core) {
    return [
      AtlasExecutiveScoreDimension(title: 'Financeiro', score: core.financialIndex, weightPercent: 25, explanation: 'Liquidez, retorno, margem e capacidade de investimento.'),
      AtlasExecutiveScoreDimension(title: 'Operacional', score: core.operationalIndex, weightPercent: 20, explanation: 'Execução, recursos, prazos e eficiência operacional.'),
      AtlasExecutiveScoreDimension(title: 'Estratégico', score: core.strategicIndex, weightPercent: 20, explanation: 'Metas, prioridades, alinhamento e geração de valor.'),
      AtlasExecutiveScoreDimension(title: 'Preditivo', score: core.predictiveIndex, weightPercent: 15, explanation: 'Qualidade das previsões, cenários e confiança dos dados.'),
      AtlasExecutiveScoreDimension(title: 'Saúde geral', score: core.healthIndex, weightPercent: 20, explanation: 'Visão consolidada da saúde técnica e gerencial da fazenda.'),
    ];
  }

  List<AtlasExecutiveRadarItem> _buildRadarItems(AtlasExecutiveCoreData core) {
    final items = <AtlasExecutiveRadarItem>[];
    for (final risk in core.risks.take(4)) {
      items.add(AtlasExecutiveRadarItem(
        id: 'risk_${risk.id}', title: risk.title, description: risk.description,
        type: AtlasExecutiveRadarType.risk,
        priority: risk.severity == AtlasExecutiveCoreSeverity.critical
            ? AtlasExecutiveBrainPriority.critical
            : risk.severity == AtlasExecutiveCoreSeverity.high
                ? AtlasExecutiveBrainPriority.high
                : AtlasExecutiveBrainPriority.medium,
        expectedFinancialImpact: risk.expectedFinancialImpact,
        confidencePercent: risk.probabilityPercent,
        recommendedAction: risk.recommendation,
      ));
    }
    for (final opportunity in core.opportunities.take(4)) {
      final quickWin = opportunity.investmentValue <= 20000 && opportunity.roiPercent >= 20;
      items.add(AtlasExecutiveRadarItem(
        id: 'opportunity_${opportunity.id}', title: opportunity.title, description: opportunity.description,
        type: quickWin ? AtlasExecutiveRadarType.quickWin : AtlasExecutiveRadarType.opportunity,
        priority: opportunity.roiPercent >= 30 ? AtlasExecutiveBrainPriority.high : AtlasExecutiveBrainPriority.medium,
        expectedFinancialImpact: opportunity.expectedReturn,
        confidencePercent: opportunity.confidencePercent,
        recommendedAction: opportunity.recommendation,
      ));
    }
    for (final priority in core.priorities.take(3)) {
      if (priority.deadlineHours <= 48) {
        items.add(AtlasExecutiveRadarItem(
          id: 'critical_${priority.id}', title: priority.title, description: priority.description,
          type: AtlasExecutiveRadarType.criticalActivity,
          priority: priority.priority == AtlasExecutiveCorePriorityLevel.critical
              ? AtlasExecutiveBrainPriority.critical : AtlasExecutiveBrainPriority.high,
          expectedFinancialImpact: priority.expectedFinancialImpact,
          confidencePercent: priority.confidencePercent,
          recommendedAction: 'Executar em até ${priority.deadlineHours} horas e acompanhar o resultado.',
        ));
      }
    }
    items.sort((a, b) {
      final byPriority = b.priority.index.compareTo(a.priority.index);
      return byPriority != 0 ? byPriority : b.expectedFinancialImpact.abs().compareTo(a.expectedFinancialImpact.abs());
    });
    return items.take(10).toList();
  }

}

class _ExecutivePlans {
  const _ExecutivePlans({
    required this.daily,
    required this.weekly,
    required this.monthly,
  });

  final List<AtlasExecutiveBrainAction> daily;
  final List<AtlasExecutiveBrainAction> weekly;
  final List<AtlasExecutiveBrainAction> monthly;
}
