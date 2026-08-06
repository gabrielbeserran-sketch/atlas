import 'dart:math' as math;

import 'package:projeto_atlas/features/autonomous_consultant/domain/models/atlas_consultant_report.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/models/atlas_optimization_request.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/models/atlas_optimization_result.dart';
import 'package:projeto_atlas/features/optimization_engine/domain/services/atlas_optimization_engine.dart';

class AtlasAutonomousConsultantService {
  const AtlasAutonomousConsultantService({
    this.optimizationEngine =
        const AtlasOptimizationEngine(),
  });

  final AtlasOptimizationEngine optimizationEngine;

  AtlasConsultantReport analyze({
    required AtlasDigitalTwin twin,
  }) {
    final objective = _selectObjective(twin);

    final request = AtlasOptimizationRequest(
      id:
          'consultant_optimization_${DateTime.now().microsecondsSinceEpoch}',
      farmId: twin.farmId,
      farmName: twin.farmName,
      objective: objective,
      horizonMonths: 12,
      maxInvestment: _recommendedInvestmentLimit(twin),
      maxRisk:
          AtlasOptimizationRiskTolerance.moderate,
      maxHerdExpansion:
          _recommendedHerdExpansion(twin),
      minimumScore: 50,
      generatedAt: DateTime.now(),
    );

    final optimizationResult =
        optimizationEngine.optimize(
      currentTwin: twin,
      request: request,
    );

    final actions = _buildActions(
      twin: twin,
      optimizationResult: optimizationResult,
    );

    final overallPriority =
        _overallPriority(actions);

    return AtlasConsultantReport(
      id:
          'consultant_report_${DateTime.now().microsecondsSinceEpoch}',
      farmId: twin.farmId,
      farmName: twin.farmName,
      generatedAt: DateTime.now(),
      executiveDiagnosis:
          _buildExecutiveDiagnosis(
        twin: twin,
        actions: actions,
      ),
      overallPriority: overallPriority,
      farmScore: twin.overallScore,
      trend: twin.trend,
      actions: actions,
      optimizationResult: optimizationResult,
      strategicSummary:
          _buildStrategicSummary(
        twin: twin,
        actions: actions,
        bestStrategy:
            optimizationResult.bestCandidate.name,
      ),
    );
  }

  AtlasOptimizationObjective _selectObjective(
    AtlasDigitalTwin twin,
  ) {
    final scores = <AtlasDigitalTwinArea, double>{
      AtlasDigitalTwinArea.animal:
          twin.health.animal,
      AtlasDigitalTwinArea.sanitary:
          twin.health.sanitary,
      AtlasDigitalTwinArea.reproductive:
          twin.health.reproductive,
      AtlasDigitalTwinArea.financial:
          twin.health.financial,
      AtlasDigitalTwinArea.inventory:
          twin.health.inventory,
      AtlasDigitalTwinArea.operational:
          twin.health.operational,
    };

    final weakest = scores.entries.reduce(
      (first, second) =>
          first.value <= second.value
              ? first
              : second,
    );

    switch (weakest.key) {
      case AtlasDigitalTwinArea.sanitary:
        return AtlasOptimizationObjective
            .improveSanitary;
      case AtlasDigitalTwinArea.reproductive:
        return AtlasOptimizationObjective
            .improveReproduction;
      case AtlasDigitalTwinArea.financial:
        return AtlasOptimizationObjective
            .maximizeProfit;
      case AtlasDigitalTwinArea.inventory:
      case AtlasDigitalTwinArea.operational:
        return AtlasOptimizationObjective
            .improveOperations;
      case AtlasDigitalTwinArea.animal:
        return AtlasOptimizationObjective
            .balancedGrowth;
    }
  }

  double _recommendedInvestmentLimit(
    AtlasDigitalTwin twin,
  ) {
    final financial = twin.health.financial;

    if (financial >= 80) {
      return 150000;
    }

    if (financial >= 65) {
      return 100000;
    }

    if (financial >= 50) {
      return 60000;
    }

    return 30000;
  }

  int _recommendedHerdExpansion(
    AtlasDigitalTwin twin,
  ) {
    final capacity = math.min(
      twin.health.inventory,
      twin.health.operational,
    );

    if (capacity >= 85) {
      return 120;
    }

    if (capacity >= 70) {
      return 70;
    }

    if (capacity >= 55) {
      return 30;
    }

    return 0;
  }

  List<AtlasConsultantAction> _buildActions({
    required AtlasDigitalTwin twin,
    required AtlasOptimizationResult optimizationResult,
  }) {
    final actions = <AtlasConsultantAction>[];

    for (final risk in twin.risks.take(5)) {
      actions.add(
        _actionFromRisk(risk),
      );
    }

    final areaScores =
        <AtlasDigitalTwinArea, double>{
      AtlasDigitalTwinArea.animal:
          twin.health.animal,
      AtlasDigitalTwinArea.sanitary:
          twin.health.sanitary,
      AtlasDigitalTwinArea.reproductive:
          twin.health.reproductive,
      AtlasDigitalTwinArea.financial:
          twin.health.financial,
      AtlasDigitalTwinArea.inventory:
          twin.health.inventory,
      AtlasDigitalTwinArea.operational:
          twin.health.operational,
    };

    final ordered = areaScores.entries.toList()
      ..sort(
        (first, second) =>
            first.value.compareTo(second.value),
      );

    for (final entry in ordered.take(3)) {
      if (entry.value < 72) {
        actions.add(
          _actionFromWeakArea(
            area: entry.key,
            score: entry.value,
          ),
        );
      }
    }

    actions.add(
      AtlasConsultantAction(
        id:
            'strategy_${DateTime.now().microsecondsSinceEpoch}',
        title:
            'Preparar plano piloto da estratégia otimizada',
        description:
            'Transformar a estratégia “${optimizationResult.bestCandidate.name}” em uma execução controlada.',
        justification:
            'O Optimization Engine comparou diferentes alternativas e classificou esta como a melhor combinação entre objetivo, retorno, risco e equilíbrio.',
        area:
            AtlasDigitalTwinArea.operational,
        priority:
            AtlasConsultantPriority.moderate,
        deadlineDays: 30,
        expectedScoreImpact:
            optimizationResult.bestCandidate.result
                .scoreVariation,
        estimatedEconomicImpact:
            optimizationResult.bestCandidate.result
                .projectedNetResult,
        riskOfInaction:
            'Manter a operação sem um plano estruturado pode prolongar gargalos e reduzir o ganho potencial.',
        indicators: const <String>[
          'Atlas Farm Index',
          'Resultado líquido',
          'ROI',
          'Payback',
          'Risco estratégico',
        ],
        steps: const <String>[
          'Validar as premissas com os responsáveis pela fazenda.',
          'Definir um lote, setor ou período para o projeto piloto.',
          'Registrar metas e responsáveis.',
          'Acompanhar os indicadores semanalmente.',
          'Expandir somente após validar o resultado.',
        ],
      ),
    );

    final unique = <String, AtlasConsultantAction>{};

    for (final action in actions) {
      unique[
        '${action.area.name}_${action.title}'
      ] = action;
    }

    final result = unique.values.toList()
      ..sort(
        (first, second) =>
            _priorityWeight(second.priority)
                .compareTo(
          _priorityWeight(first.priority),
        ),
      );

    return result.take(8).toList();
  }

  AtlasConsultantAction _actionFromRisk(
    AtlasFarmRisk risk,
  ) {
    final priority =
        _priorityFromRiskLevel(risk.level);

    return AtlasConsultantAction(
      id: 'risk_action_${risk.id}',
      title: 'Tratar ${risk.title.toLowerCase()}',
      description:
          'Executar uma intervenção direcionada para reduzir o risco identificado pelo Digital Twin.',
      justification:
          '${risk.description} O risco apresenta score ${risk.score.toStringAsFixed(0)} e classificação ${atlasFarmRiskLevelLabel(risk.level)}.',
      area: risk.area,
      priority: priority,
      deadlineDays:
          _deadlineForPriority(priority),
      expectedScoreImpact:
          (risk.score / 12)
              .clamp(2.0, 10.0)
              .toDouble(),
      estimatedEconomicImpact:
          risk.score * 750,
      riskOfInaction:
          _riskOfInactionForArea(risk.area),
      indicators:
          _indicatorsForArea(risk.area),
      steps:
          _stepsForArea(risk.area),
    );
  }

  AtlasConsultantAction _actionFromWeakArea({
    required AtlasDigitalTwinArea area,
    required double score,
  }) {
    final priority = score < 45
        ? AtlasConsultantPriority.critical
        : score < 60
            ? AtlasConsultantPriority.high
            : AtlasConsultantPriority.moderate;

    return AtlasConsultantAction(
      id:
          'weak_area_${area.name}_${DateTime.now().microsecondsSinceEpoch}',
      title:
          'Recuperar ${atlasDigitalTwinAreaLabel(area).toLowerCase()}',
      description:
          'Criar um plano específico para elevar o indicador atualmente em ${score.toStringAsFixed(1)} pontos.',
      justification:
          'Este é um dos menores scores do Digital Twin e limita o desempenho consolidado da fazenda.',
      area: area,
      priority: priority,
      deadlineDays:
          _deadlineForPriority(priority),
      expectedScoreImpact:
          (75 - score)
              .clamp(3.0, 15.0)
              .toDouble(),
      estimatedEconomicImpact:
          (75 - score)
              .clamp(0.0, 40.0)
              .toDouble() *
          2500,
      riskOfInaction:
          _riskOfInactionForArea(area),
      indicators:
          _indicatorsForArea(area),
      steps: _stepsForArea(area),
    );
  }

  AtlasConsultantPriority _overallPriority(
    List<AtlasConsultantAction> actions,
  ) {
    if (actions.any(
      (item) =>
          item.priority ==
          AtlasConsultantPriority.critical,
    )) {
      return AtlasConsultantPriority.critical;
    }

    if (actions.any(
      (item) =>
          item.priority ==
          AtlasConsultantPriority.high,
    )) {
      return AtlasConsultantPriority.high;
    }

    if (actions.any(
      (item) =>
          item.priority ==
          AtlasConsultantPriority.moderate,
    )) {
      return AtlasConsultantPriority.moderate;
    }

    return AtlasConsultantPriority.low;
  }

  AtlasConsultantPriority _priorityFromRiskLevel(
    AtlasFarmRiskLevel level,
  ) {
    switch (level) {
      case AtlasFarmRiskLevel.low:
        return AtlasConsultantPriority.low;
      case AtlasFarmRiskLevel.moderate:
        return AtlasConsultantPriority.moderate;
      case AtlasFarmRiskLevel.high:
        return AtlasConsultantPriority.high;
      case AtlasFarmRiskLevel.critical:
        return AtlasConsultantPriority.critical;
    }
  }

  int _priorityWeight(
    AtlasConsultantPriority priority,
  ) {
    switch (priority) {
      case AtlasConsultantPriority.low:
        return 1;
      case AtlasConsultantPriority.moderate:
        return 2;
      case AtlasConsultantPriority.high:
        return 3;
      case AtlasConsultantPriority.critical:
        return 4;
    }
  }

  int _deadlineForPriority(
    AtlasConsultantPriority priority,
  ) {
    switch (priority) {
      case AtlasConsultantPriority.critical:
        return 3;
      case AtlasConsultantPriority.high:
        return 7;
      case AtlasConsultantPriority.moderate:
        return 30;
      case AtlasConsultantPriority.low:
        return 60;
    }
  }

  String _riskOfInactionForArea(
    AtlasDigitalTwinArea area,
  ) {
    switch (area) {
      case AtlasDigitalTwinArea.animal:
        return 'Perda de desempenho, pior conversão e redução do valor produzido por animal.';
      case AtlasDigitalTwinArea.sanitary:
        return 'Aumento de doenças, tratamentos, mortalidade e perdas produtivas.';
      case AtlasDigitalTwinArea.reproductive:
        return 'Maior intervalo entre partos, menor produção de bezerros e receita futura reduzida.';
      case AtlasDigitalTwinArea.financial:
        return 'Pressão sobre o caixa, redução da capacidade de investimento e risco de endividamento.';
      case AtlasDigitalTwinArea.inventory:
        return 'Falta de insumos críticos, compras emergenciais e interrupção de atividades.';
      case AtlasDigitalTwinArea.operational:
        return 'Atrasos, retrabalho, falhas de execução e perda de eficiência da equipe.';
    }
  }

  List<String> _indicatorsForArea(
    AtlasDigitalTwinArea area,
  ) {
    switch (area) {
      case AtlasDigitalTwinArea.animal:
        return const <String>[
          'Peso médio',
          'Ganho médio diário',
          'Taxa de descarte',
          'Atlas Farm Index',
        ];
      case AtlasDigitalTwinArea.sanitary:
        return const <String>[
          'Incidência de doenças',
          'Mortalidade',
          'Tratamentos',
          'Score sanitário',
        ];
      case AtlasDigitalTwinArea.reproductive:
        return const <String>[
          'Taxa de prenhez',
          'Taxa de concepção',
          'Intervalo entre partos',
          'Score reprodutivo',
        ];
      case AtlasDigitalTwinArea.financial:
        return const <String>[
          'Fluxo de caixa',
          'Margem operacional',
          'Custo por animal',
          'Score financeiro',
        ];
      case AtlasDigitalTwinArea.inventory:
        return const <String>[
          'Rupturas de estoque',
          'Cobertura em dias',
          'Compras emergenciais',
          'Score de estoque',
        ];
      case AtlasDigitalTwinArea.operational:
        return const <String>[
          'Tarefas atrasadas',
          'Workflows concluídos',
          'Tempo de execução',
          'Score operacional',
        ];
    }
  }

  List<String> _stepsForArea(
    AtlasDigitalTwinArea area,
  ) {
    switch (area) {
      case AtlasDigitalTwinArea.animal:
        return const <String>[
          'Separar os animais por categoria e desempenho.',
          'Revisar dieta, suplementação e disponibilidade de água.',
          'Definir meta de ganho médio diário.',
          'Realizar nova pesagem para validar a resposta.',
        ];
      case AtlasDigitalTwinArea.sanitary:
        return const <String>[
          'Revisar os eventos sanitários recentes.',
          'Identificar animais e lotes mais expostos.',
          'Atualizar o calendário preventivo.',
          'Acompanhar novos casos e resposta aos tratamentos.',
        ];
      case AtlasDigitalTwinArea.reproductive:
        return const <String>[
          'Revisar os resultados por categoria e protocolo.',
          'Identificar matrizes vazias ou com repetição de serviço.',
          'Avaliar condição corporal e manejo nutricional.',
          'Definir novo calendário reprodutivo.',
        ];
      case AtlasDigitalTwinArea.financial:
        return const <String>[
          'Revisar receitas, despesas e compromissos futuros.',
          'Separar custos essenciais e adiáveis.',
          'Definir limite semanal de desembolso.',
          'Acompanhar margem e fluxo de caixa.',
        ];
      case AtlasDigitalTwinArea.inventory:
        return const <String>[
          'Fazer conferência física dos itens críticos.',
          'Definir estoque mínimo e ponto de reposição.',
          'Programar compras antes da ruptura.',
          'Acompanhar consumo real por atividade.',
        ];
      case AtlasDigitalTwinArea.operational:
        return const <String>[
          'Listar tarefas atrasadas e atividades críticas.',
          'Definir responsáveis e prazos.',
          'Eliminar gargalos de execução.',
          'Acompanhar conclusão e recorrência de atrasos.',
        ];
    }
  }

  String _buildExecutiveDiagnosis({
    required AtlasDigitalTwin twin,
    required List<AtlasConsultantAction> actions,
  }) {
    final weakest = <MapEntry<String, double>>[
      MapEntry(
        'desempenho animal',
        twin.health.animal,
      ),
      MapEntry(
        'sanidade',
        twin.health.sanitary,
      ),
      MapEntry(
        'reprodução',
        twin.health.reproductive,
      ),
      MapEntry(
        'financeiro',
        twin.health.financial,
      ),
      MapEntry(
        'estoque',
        twin.health.inventory,
      ),
      MapEntry(
        'operacional',
        twin.health.operational,
      ),
    ]..sort(
        (first, second) =>
            first.value.compareTo(second.value),
      );

    final mainArea = weakest.first;

    return 'A fazenda apresenta Atlas Farm Index de '
        '${twin.overallScore.toStringAsFixed(1)}, tendência '
        '${atlasDigitalTwinTrendLabel(twin.trend).toLowerCase()} e '
        '${twin.risks.length} riscos consolidados. O principal ponto de atenção é '
        '${mainArea.key}, com ${mainArea.value.toStringAsFixed(1)} pontos. '
        'O consultor gerou ${actions.length} ações priorizadas.';
  }

  String _buildStrategicSummary({
    required AtlasDigitalTwin twin,
    required List<AtlasConsultantAction> actions,
    required String bestStrategy,
  }) {
    final urgent = actions.where(
      (item) =>
          item.priority ==
              AtlasConsultantPriority.critical ||
          item.priority ==
              AtlasConsultantPriority.high,
    );

    if (urgent.isNotEmpty) {
      return 'Primeiro, execute as ações críticas e de alta prioridade. '
          'Depois, aplique em formato piloto a estratégia “$bestStrategy”. '
          'O Digital Twin deve ser reavaliado após cada ciclo de execução.';
    }

    return 'A operação não apresenta urgências graves. '
        'Recomenda-se iniciar um piloto da estratégia “$bestStrategy” e '
        'acompanhar os indicadores definidos no plano de ação.';
  }
}
