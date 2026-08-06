import 'dart:math' as math;

import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/predictive/domain/models/atlas_predictive_scenario.dart';

class AtlasPredictiveService {
  const AtlasPredictiveService();

  AtlasPredictiveScenarioResult simulate({
    required AtlasDiagnosticData diagnostic,
    required AtlasFarmIntelligenceData farm,
    required AtlasPredictiveScenarioRequest request,
    DateTime? now,
  }) {
    final normalizedChange = request.changePercent.clamp(0.0, 100.0);

    final area = _scenarioArea(request.type);

    final areaScore = _findAreaScore(diagnostic: diagnostic, area: area);

    final coefficients = _coefficients(
      type: request.type,
      diagnostic: diagnostic,
      farm: farm,
      changePercent: normalizedChange,
      areaScore: areaScore,
    );

    final probableScoreGain = coefficients.scoreGain.clamp(0.0, 35.0);

    final probableScore = (diagnostic.score + probableScoreGain).clamp(
      0.0,
      100.0,
    );

    final financialImpact = _buildFinancialImpact(
      farm: farm,
      request: request,
      coefficients: coefficients,
    );

    final riskReduction = coefficients.riskReduction.clamp(0.0, 100.0);

    final confidence = _confidence(
      type: request.type,
      farm: farm,
      diagnostic: diagnostic,
      changePercent: normalizedChange,
    );

    final effort = _effort(
      type: request.type,
      changePercent: normalizedChange,
      investmentValue: request.investmentValue,
      executionDays: request.executionDays,
    );

    final projections = _buildProjections(
      currentScore: diagnostic.score,
      probableScoreGain: probableScoreGain,
      financialImpact: financialImpact,
      riskReduction: riskReduction,
      confidence: confidence,
    );

    final actions = _buildActions(request: request, area: area, farm: farm);

    return AtlasPredictiveScenarioResult(
      generatedAt: now ?? DateTime.now(),
      scopeLabel: diagnostic.scopeLabel,
      request: request,
      currentScore: diagnostic.score,
      projectedScore: probableScore,
      scoreVariation: probableScore - diagnostic.score,
      currentLevel: diagnostic.level,
      projectedLevel: _levelFromScore(probableScore),
      financialImpact: financialImpact,
      riskReductionPercent: riskReduction,
      confidence: confidence,
      effort: effort,
      recommendation: _recommendation(
        request: request,
        probableScoreGain: probableScoreGain,
        financialImpact: financialImpact,
        riskReduction: riskReduction,
        confidence: confidence,
        effort: effort,
      ),
      mainEvidence: _mainEvidence(
        request: request,
        farm: farm,
        diagnostic: diagnostic,
        areaScore: areaScore,
      ),
      projections: projections,
      actions: actions,
    );
  }

  AtlasPredictiveScenarioRanking compareScenarios({
    required AtlasDiagnosticData diagnostic,
    required AtlasFarmIntelligenceData farm,
    required List<AtlasPredictiveScenarioRequest> requests,
    DateTime? now,
  }) {
    final results =
        requests.map((request) {
          return simulate(
            diagnostic: diagnostic,
            farm: farm,
            request: request,
            now: now,
          );
        }).toList()..sort(
          (first, second) =>
              second.impactEffortScore.compareTo(first.impactEffortScore),
        );

    final best = results.isEmpty ? null : results.first;

    return AtlasPredictiveScenarioRanking(
      generatedAt: now ?? DateTime.now(),
      scopeLabel: diagnostic.scopeLabel,
      results: results,
      bestScenario: best,
      summary: best == null
          ? 'Nenhum cenário foi informado para comparação.'
          : 'O cenário com melhor relação entre impacto, risco e esforço é '
                '"${best.request.title}", com projeção de '
                '${best.scoreVariation.toStringAsFixed(1)} pontos no score e '
                '${best.riskReductionPercent.toStringAsFixed(0)}% de redução potencial de risco.',
    );
  }

  List<AtlasPredictiveScenarioRequest> buildRecommendedScenarios({
    required AtlasDiagnosticData diagnostic,
    required AtlasFarmIntelligenceData farm,
  }) {
    final scenarios = <AtlasPredictiveScenarioRequest>[];

    if (farm.finance.totalExpenses > 0) {
      scenarios.add(
        const AtlasPredictiveScenarioRequest(
          type: AtlasPredictiveScenarioType.reduceCosts,
          title: 'Reduzir custos em 8%',
          description:
              'Simula o impacto da redução de desperdícios e despesas evitáveis.',
          changePercent: 8,
          executionDays: 60,
        ),
      );
    }

    if (farm.finance.totalIncome > 0) {
      scenarios.add(
        const AtlasPredictiveScenarioRequest(
          type: AtlasPredictiveScenarioType.increaseRevenue,
          title: 'Aumentar receitas em 6%',
          description:
              'Simula o efeito de ganho comercial ou produtivo sobre o resultado.',
          changePercent: 6,
          executionDays: 90,
        ),
      );
    }

    if (farm.agenda.overdueCount > 0) {
      scenarios.add(
        const AtlasPredictiveScenarioRequest(
          type: AtlasPredictiveScenarioType.reduceOverdueTasks,
          title: 'Reduzir atrasos em 70%',
          description:
              'Simula a reorganização da agenda, dos responsáveis e dos prazos.',
          changePercent: 70,
          executionDays: 30,
        ),
      );
    }

    if (farm.inventory.expiredCount > 0 ||
        farm.inventory.nearExpirationCount > 0) {
      scenarios.add(
        const AtlasPredictiveScenarioRequest(
          type: AtlasPredictiveScenarioType.reduceInventoryLosses,
          title: 'Reduzir perdas de estoque em 80%',
          description:
              'Simula o efeito de melhorar validade, compras e rotação dos produtos.',
          changePercent: 80,
          executionDays: 45,
        ),
      );
    }

    if (farm.herd.registrationCoverage < 95) {
      scenarios.add(
        AtlasPredictiveScenarioRequest(
          type: AtlasPredictiveScenarioType.improveHerdRecords,
          title: 'Elevar o cadastro do rebanho para 95%',
          description:
              'Simula o impacto de completar identificação, lotes e dados zootécnicos.',
          changePercent: (95 - farm.herd.registrationCoverage).clamp(
            5.0,
            100.0,
          ),
          executionDays: 45,
        ),
      );
    }

    if (farm.paddocks.score < 85) {
      scenarios.add(
        const AtlasPredictiveScenarioRequest(
          type: AtlasPredictiveScenarioType.improvePaddockUse,
          title: 'Melhorar o uso dos piquetes em 20%',
          description:
              'Simula ajustes de ocupação, descanso e distribuição do rebanho.',
          changePercent: 20,
          executionDays: 90,
        ),
      );
    }

    return scenarios;
  }

  _PredictiveCoefficients _coefficients({
    required AtlasPredictiveScenarioType type,
    required AtlasDiagnosticData diagnostic,
    required AtlasFarmIntelligenceData farm,
    required double changePercent,
    required double areaScore,
  }) {
    final improvementFactor = changePercent / 100;

    final scoreGap = (100 - areaScore).clamp(0.0, 100.0);

    switch (type) {
      case AtlasPredictiveScenarioType.reduceCosts:
        return _PredictiveCoefficients(
          scoreGain:
              math.min(14, changePercent * 0.42) * (0.55 + scoreGap / 200),
          riskReduction: math.min(42, changePercent * 2.6),
          financialBase: farm.finance.totalExpenses * improvementFactor,
        );

      case AtlasPredictiveScenarioType.increaseRevenue:
        return _PredictiveCoefficients(
          scoreGain:
              math.min(13, changePercent * 0.38) * (0.55 + scoreGap / 200),
          riskReduction: math.min(30, changePercent * 1.8),
          financialBase: farm.finance.totalIncome * improvementFactor,
        );

      case AtlasPredictiveScenarioType.reduceOverdueTasks:
        return _PredictiveCoefficients(
          scoreGain:
              math.min(18, changePercent * 0.16) * (0.65 + scoreGap / 180),
          riskReduction: math.min(80, changePercent * 0.92),
          financialBase: farm.agenda.overdueCount * changePercent * 8,
        );

      case AtlasPredictiveScenarioType.reduceInventoryLosses:
        final inventoryRiskValue =
            farm.inventory.totalValue * _inventoryRiskRate(farm);

        return _PredictiveCoefficients(
          scoreGain:
              math.min(16, changePercent * 0.14) * (0.65 + scoreGap / 180),
          riskReduction: math.min(85, changePercent * 0.95),
          financialBase: inventoryRiskValue * improvementFactor,
        );

      case AtlasPredictiveScenarioType.improveHerdRecords:
        return _PredictiveCoefficients(
          scoreGain:
              math.min(15, changePercent * 0.18) * (0.60 + scoreGap / 190),
          riskReduction: math.min(55, changePercent * 0.62),
          financialBase: farm.herd.activeAnimals * improvementFactor * 7.5,
        );

      case AtlasPredictiveScenarioType.improvePaddockUse:
        final productiveBase = math.max(
          farm.finance.totalIncome,
          farm.herd.activeAnimals * 120,
        );

        return _PredictiveCoefficients(
          scoreGain:
              math.min(17, changePercent * 0.32) * (0.60 + scoreGap / 190),
          riskReduction: math.min(50, changePercent * 1.65),
          financialBase: productiveBase * improvementFactor * 0.18,
        );

      case AtlasPredictiveScenarioType.custom:
        return _PredictiveCoefficients(
          scoreGain:
              math.min(12, changePercent * 0.20) * (0.55 + scoreGap / 200),
          riskReduction: math.min(40, changePercent * 0.55),
          financialBase:
              math.max(farm.finance.totalIncome, farm.finance.totalExpenses) *
              improvementFactor *
              0.08,
        );
    }
  }

  AtlasPredictiveFinancialImpact _buildFinancialImpact({
    required AtlasFarmIntelligenceData farm,
    required AtlasPredictiveScenarioRequest request,
    required _PredictiveCoefficients coefficients,
  }) {
    final probable = coefficients.financialBase;

    final conservative = probable * 0.62;
    final optimistic = probable * 1.34;

    final double investment = math.max<double>(0.0, request.investmentValue);

    final netProbable = probable - investment;

    final double roi = investment <= 0
        ? (netProbable > 0 ? 100.0 : 0.0)
        : (netProbable / investment) * 100.0;

    final dailyReturn = probable / math.max(1, request.executionDays);

    final paybackDays = investment > 0 && dailyReturn > 0
        ? (investment / dailyReturn).ceil()
        : null;

    return AtlasPredictiveFinancialImpact(
      conservativeValue: conservative - investment,
      probableValue: netProbable,
      optimisticValue: optimistic - investment,
      investmentValue: investment,
      returnOnInvestmentPercent: roi,
      paybackDays: paybackDays,
    );
  }

  List<AtlasPredictiveProjection> _buildProjections({
    required double currentScore,
    required double probableScoreGain,
    required AtlasPredictiveFinancialImpact financialImpact,
    required double riskReduction,
    required double confidence,
  }) {
    return [
      AtlasPredictiveProjection(
        kind: AtlasPredictiveProjectionKind.conservative,
        label: 'Conservador',
        projectedScore: (currentScore + probableScoreGain * 0.62).clamp(
          0.0,
          100.0,
        ),
        financialImpact: financialImpact.conservativeValue,
        riskReductionPercent: riskReduction * 0.62,
        confidence: (confidence + 8).clamp(0.0, 100.0),
      ),
      AtlasPredictiveProjection(
        kind: AtlasPredictiveProjectionKind.probable,
        label: 'Provável',
        projectedScore: (currentScore + probableScoreGain).clamp(0.0, 100.0),
        financialImpact: financialImpact.probableValue,
        riskReductionPercent: riskReduction,
        confidence: confidence,
      ),
      AtlasPredictiveProjection(
        kind: AtlasPredictiveProjectionKind.optimistic,
        label: 'Otimista',
        projectedScore: (currentScore + probableScoreGain * 1.32).clamp(
          0.0,
          100.0,
        ),
        financialImpact: financialImpact.optimisticValue,
        riskReductionPercent: (riskReduction * 1.18).clamp(0.0, 100.0),
        confidence: (confidence - 12).clamp(0.0, 100.0),
      ),
    ];
  }

  double _confidence({
    required AtlasPredictiveScenarioType type,
    required AtlasFarmIntelligenceData farm,
    required AtlasDiagnosticData diagnostic,
    required double changePercent,
  }) {
    var confidence = 72.0;

    if (farm.finance.recordCount > 0) {
      confidence += 5;
    }

    if (farm.herd.activeAnimals > 0) {
      confidence += 4;
    }

    if (farm.agenda.openCount > 0 || farm.agenda.completedCount > 0) {
      confidence += 3;
    }

    if (farm.inventory.itemCount > 0) {
      confidence += 3;
    }

    if (farm.paddocks.paddockCount > 0) {
      confidence += 3;
    }

    if (diagnostic.areas.length >= 5) {
      confidence += 4;
    }

    if (changePercent > 50) {
      confidence -= 8;
    }

    if (changePercent > 80) {
      confidence -= 6;
    }

    if (type == AtlasPredictiveScenarioType.custom) {
      confidence -= 10;
    }

    return confidence.clamp(35.0, 94.0);
  }

  AtlasPredictiveEffort _effort({
    required AtlasPredictiveScenarioType type,
    required double changePercent,
    required double investmentValue,
    required int executionDays,
  }) {
    var points = 0;

    if (changePercent >= 20) {
      points++;
    }

    if (changePercent >= 50) {
      points++;
    }

    if (investmentValue > 0) {
      points++;
    }

    if (executionDays <= 30) {
      points++;
    }

    if (type == AtlasPredictiveScenarioType.improvePaddockUse ||
        type == AtlasPredictiveScenarioType.increaseRevenue) {
      points++;
    }

    if (points >= 4) {
      return AtlasPredictiveEffort.high;
    }

    if (points >= 2) {
      return AtlasPredictiveEffort.medium;
    }

    return AtlasPredictiveEffort.low;
  }

  List<AtlasPredictiveAction> _buildActions({
    required AtlasPredictiveScenarioRequest request,
    required AtlasFarmAnalysisArea area,
    required AtlasFarmIntelligenceData farm,
  }) {
    final descriptions = _actionDescriptions(type: request.type, farm: farm);

    return List.generate(descriptions.length, (index) {
      final item = descriptions[index];

      return AtlasPredictiveAction(
        position: index + 1,
        title: item.title,
        description: item.description,
        expectedResult: item.expectedResult,
        area: area,
        deadlineDays: _actionDeadline(
          executionDays: request.executionDays,
          index: index,
          actionCount: descriptions.length,
        ),
      );
    });
  }

  List<_ActionDescription> _actionDescriptions({
    required AtlasPredictiveScenarioType type,
    required AtlasFarmIntelligenceData farm,
  }) {
    switch (type) {
      case AtlasPredictiveScenarioType.reduceCosts:
        return const [
          _ActionDescription(
            title: 'Mapear despesas evitáveis',
            description: 'Separe custos essenciais, variáveis e desperdícios.',
            expectedResult:
                'Identificar os primeiros cortes sem comprometer a produção.',
          ),
          _ActionDescription(
            title: 'Definir meta por categoria',
            description:
                'Estabeleça limite mensal para as maiores categorias de despesa.',
            expectedResult: 'Controlar o orçamento e reduzir desvios.',
          ),
          _ActionDescription(
            title: 'Acompanhar economia realizada',
            description:
                'Compare o valor planejado com o valor efetivamente economizado.',
            expectedResult: 'Confirmar o impacto financeiro do cenário.',
          ),
        ];

      case AtlasPredictiveScenarioType.increaseRevenue:
        return const [
          _ActionDescription(
            title: 'Identificar fonte de receita',
            description:
                'Defina qual lote, produto ou serviço poderá gerar o aumento.',
            expectedResult:
                'Transformar a meta em uma oportunidade comercial concreta.',
          ),
          _ActionDescription(
            title: 'Definir meta de produção ou venda',
            description:
                'Estabeleça quantidade, preço e prazo para o ganho projetado.',
            expectedResult: 'Criar um plano mensurável de aumento de receita.',
          ),
          _ActionDescription(
            title: 'Medir margem adicional',
            description:
                'Acompanhe receita nova e custos necessários para obtê-la.',
            expectedResult:
                'Garantir que o crescimento também aumente o resultado.',
          ),
        ];

      case AtlasPredictiveScenarioType.reduceOverdueTasks:
        return const [
          _ActionDescription(
            title: 'Revisar tarefas atrasadas',
            description:
                'Classifique atrasos por risco, urgência e dependência.',
            expectedResult: 'Definir uma ordem objetiva de execução.',
          ),
          _ActionDescription(
            title: 'Atribuir responsáveis',
            description:
                'Garanta que cada atividade tenha uma pessoa responsável.',
            expectedResult:
                'Eliminar tarefas sem dono e reduzir novos atrasos.',
          ),
          _ActionDescription(
            title: 'Criar rotina diária de acompanhamento',
            description:
                'Revise prazos, impedimentos e conclusões todos os dias.',
            expectedResult: 'Elevar a taxa de conclusão da agenda.',
          ),
        ];

      case AtlasPredictiveScenarioType.reduceInventoryLosses:
        return const [
          _ActionDescription(
            title: 'Separar itens por validade',
            description:
                'Organize produtos vencidos, próximos do vencimento e regulares.',
            expectedResult: 'Evitar uso indevido e perdas adicionais.',
          ),
          _ActionDescription(
            title: 'Aplicar saída por vencimento',
            description: 'Priorize o uso dos produtos que vencem primeiro.',
            expectedResult: 'Aumentar o giro e reduzir descarte.',
          ),
          _ActionDescription(
            title: 'Revisar compras e estoque mínimo',
            description: 'Ajuste quantidade comprada ao consumo real.',
            expectedResult: 'Reduzir excesso e falta de produtos.',
          ),
        ];

      case AtlasPredictiveScenarioType.improveHerdRecords:
        return const [
          _ActionDescription(
            title: 'Identificar cadastros incompletos',
            description:
                'Liste animais sem identificação, lote, peso ou categoria.',
            expectedResult:
                'Definir exatamente o trabalho cadastral necessário.',
          ),
          _ActionDescription(
            title: 'Realizar atualização em campo',
            description:
                'Conferir animais e registrar as informações pendentes.',
            expectedResult:
                'Elevar a cobertura e a confiabilidade do cadastro.',
          ),
          _ActionDescription(
            title: 'Criar rotina de manutenção',
            description:
                'Atualize movimentações e pesagens sempre que ocorrerem.',
            expectedResult: 'Evitar nova perda de qualidade dos dados.',
          ),
        ];

      case AtlasPredictiveScenarioType.improvePaddockUse:
        return const [
          _ActionDescription(
            title: 'Revisar ocupação atual',
            description: 'Confira animais, área e condição de cada piquete.',
            expectedResult:
                'Identificar áreas sobrecarregadas ou subutilizadas.',
          ),
          _ActionDescription(
            title: 'Planejar rotação e descanso',
            description:
                'Defina sequência de entrada, saída e recuperação das áreas.',
            expectedResult:
                'Melhorar disponibilidade de forragem e uso da área.',
          ),
          _ActionDescription(
            title: 'Acompanhar lotação',
            description:
                'Compare animais por hectare com a capacidade planejada.',
            expectedResult:
                'Reduzir risco de superlotação e perda de desempenho.',
          ),
        ];

      case AtlasPredictiveScenarioType.custom:
        return const [
          _ActionDescription(
            title: 'Definir indicador principal',
            description:
                'Escolha o indicador que será usado para medir o cenário.',
            expectedResult: 'Criar uma referência objetiva de sucesso.',
          ),
          _ActionDescription(
            title: 'Executar teste controlado',
            description:
                'Aplique a mudança em escala limitada antes de expandir.',
            expectedResult: 'Validar o cenário com menor risco.',
          ),
          _ActionDescription(
            title: 'Comparar resultado',
            description: 'Compare antes e depois usando o mesmo indicador.',
            expectedResult:
                'Decidir se a mudança deve ser mantida ou ampliada.',
          ),
        ];
    }
  }

  String _recommendation({
    required AtlasPredictiveScenarioRequest request,
    required double probableScoreGain,
    required AtlasPredictiveFinancialImpact financialImpact,
    required double riskReduction,
    required double confidence,
    required AtlasPredictiveEffort effort,
  }) {
    if (confidence < 55) {
      return 'Os dados ainda não oferecem confiança suficiente. Complete os registros e execute um teste pequeno antes de adotar o cenário.';
    }

    if (probableScoreGain >= 8 &&
        riskReduction >= 35 &&
        effort != AtlasPredictiveEffort.high) {
      return 'Cenário recomendado. A projeção combina ganho relevante de score, redução de risco e esforço viável.';
    }

    if (financialImpact.probableValue > 0 && probableScoreGain >= 4) {
      return 'Cenário favorável. O impacto financeiro provável é positivo e existe melhoria operacional mensurável.';
    }

    if (effort == AtlasPredictiveEffort.high && probableScoreGain < 5) {
      return 'Cenário de baixa prioridade. O esforço estimado é alto para o ganho operacional projetado.';
    }

    return 'Cenário possível, mas deve ser executado de forma controlada e acompanhado por indicadores.';
  }

  String _mainEvidence({
    required AtlasPredictiveScenarioRequest request,
    required AtlasFarmIntelligenceData farm,
    required AtlasDiagnosticData diagnostic,
    required double areaScore,
  }) {
    switch (request.type) {
      case AtlasPredictiveScenarioType.reduceCosts:
        return 'As despesas atuais somam '
            '${_currency(farm.finance.totalExpenses)} e o score financeiro é '
            '${areaScore.toStringAsFixed(0)} pontos.';

      case AtlasPredictiveScenarioType.increaseRevenue:
        return 'As receitas atuais somam '
            '${_currency(farm.finance.totalIncome)} e o resultado registrado é '
            '${_currency(farm.finance.balance)}.';

      case AtlasPredictiveScenarioType.reduceOverdueTasks:
        return 'A agenda possui ${farm.agenda.overdueCount} tarefas atrasadas, '
            '${farm.agenda.urgentCount} urgentes e '
            '${farm.agenda.withoutResponsibleCount} sem responsável.';

      case AtlasPredictiveScenarioType.reduceInventoryLosses:
        return 'O estoque possui ${farm.inventory.expiredCount} itens vencidos e '
            '${farm.inventory.nearExpirationCount} próximos do vencimento, '
            'com valor total estimado de ${_currency(farm.inventory.totalValue)}.';

      case AtlasPredictiveScenarioType.improveHerdRecords:
        return 'A cobertura atual do cadastro do rebanho é de '
            '${farm.herd.registrationCoverage.toStringAsFixed(1)}%, '
            'com ${farm.herd.activeAnimals} animais ativos.';

      case AtlasPredictiveScenarioType.improvePaddockUse:
        return 'A propriedade possui ${farm.paddocks.paddockCount} piquetes, '
            '${farm.paddocks.totalArea.toStringAsFixed(1)} hectares cadastrados '
            'e score de ${areaScore.toStringAsFixed(0)} pontos na área.';

      case AtlasPredictiveScenarioType.custom:
        return 'O diagnóstico atual da propriedade é de '
            '${diagnostic.score.toStringAsFixed(0)} pontos.';
    }
  }

  double _findAreaScore({
    required AtlasDiagnosticData diagnostic,
    required AtlasFarmAnalysisArea area,
  }) {
    for (final item in diagnostic.areas) {
      if (item.sourceArea == area) {
        return item.score;
      }
    }

    return diagnostic.score;
  }

  AtlasFarmAnalysisArea _scenarioArea(AtlasPredictiveScenarioType type) {
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

  double _inventoryRiskRate(AtlasFarmIntelligenceData farm) {
    if (farm.inventory.itemCount == 0) {
      return 0;
    }

    final exposedItems =
        farm.inventory.expiredCount + farm.inventory.nearExpirationCount;

    return (exposedItems / farm.inventory.itemCount).clamp(0.0, 1.0);
  }

  int _actionDeadline({
    required int executionDays,
    required int index,
    required int actionCount,
  }) {
    if (actionCount <= 0) {
      return executionDays;
    }

    final fraction = (index + 1) / actionCount;

    return math.max(1, (executionDays * fraction).round());
  }

  AtlasDiagnosticLevel _levelFromScore(double score) {
    if (score >= 85) {
      return AtlasDiagnosticLevel.excellent;
    }

    if (score >= 70) {
      return AtlasDiagnosticLevel.stable;
    }

    if (score >= 50) {
      return AtlasDiagnosticLevel.attention;
    }

    return AtlasDiagnosticLevel.critical;
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

class _PredictiveCoefficients {
  const _PredictiveCoefficients({
    required this.scoreGain,
    required this.riskReduction,
    required this.financialBase,
  });

  final double scoreGain;
  final double riskReduction;
  final double financialBase;
}

class _ActionDescription {
  const _ActionDescription({
    required this.title,
    required this.description,
    required this.expectedResult,
  });

  final String title;
  final String description;
  final String expectedResult;
}
