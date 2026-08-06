import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_outcome.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_executive_intelligence.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';

class AtlasExecutiveIntelligenceService {
  const AtlasExecutiveIntelligenceService();

  AtlasExecutiveIntelligenceSnapshot build({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasOperationalGoal> goals,
    required List<AtlasActionOutcome> outcomes,
  }) {
    final total = actions.length;
    final completed = actions.where((action) => action.isCompleted).length;
    final overdue = actions.where((action) => action.isOverdue).length;
    final withResponsible = actions
        .where((action) => action.hasResponsible)
        .length;

    final completionRate = total == 0 ? 0.0 : completed / total * 100;
    final averageProgress = total == 0
        ? 0.0
        : actions
                  .map((action) => action.progressPercent)
                  .fold<int>(0, (a, b) => a + b) /
              total;
    final deadlineHealth = total == 0 ? 100.0 : (1 - overdue / total) * 100;
    final responsibilityCoverage = total == 0
        ? 0.0
        : withResponsible / total * 100;
    final goalProgress = goals.isEmpty
        ? 0.0
        : goals
                  .map((goal) => goal.progressPercent)
                  .fold<double>(0, (a, b) => a + b) /
              goals.length;

    final expectedImpact = actions.fold<double>(
      0,
      (total, action) => total + action.expectedFinancialImpact,
    );
    final netResult = outcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.netFinancialResult,
    );
    final totalCost = outcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.executionCost,
    );
    final roi = totalCost <= 0
        ? (netResult > 0 ? 100.0 : 0.0)
        : netResult / totalCost * 100;

    final operational =
        (completionRate * 0.35 +
                averageProgress * 0.30 +
                deadlineHealth * 0.20 +
                responsibilityCoverage * 0.15)
            .clamp(0.0, 100.0);

    final economic =
        (_normalizeFinancial(netResult) * 0.50 +
                _normalizeRoi(roi) * 0.35 +
                (expectedImpact == 0
                    ? 50
                    : _normalizeFinancial(netResult - expectedImpact) * 0.15))
            .clamp(0.0, 100.0);

    final zootechnical = _areaScore(
      actions: actions,
      goals: goals,
      keywords: const <String>['rebanho', 'herd', 'animal', 'repro', 'nutri'],
      fallback: averageProgress,
    );

    final sanitary = _areaScore(
      actions: actions,
      goals: goals,
      keywords: const <String>['san', 'health', 'vacina', 'medic'],
      fallback: deadlineHealth,
    );

    final overall =
        (operational * 0.35 +
                economic * 0.30 +
                zootechnical * 0.20 +
                sanitary * 0.15)
            .clamp(0.0, 100.0);

    final scores = AtlasExecutiveScoreSet(
      overall: overall,
      operational: operational,
      economic: economic,
      zootechnical: zootechnical,
      sanitary: sanitary,
      status: _status(overall),
    );

    return AtlasExecutiveIntelligenceSnapshot(
      generatedAt: DateTime.now(),
      kpis: <AtlasExecutiveKpi>[
        AtlasExecutiveKpi(
          title: 'Score geral',
          value: overall,
          unit: 'pontos',
          status: _status(overall),
          description: 'Visão consolidada da fazenda.',
        ),
        AtlasExecutiveKpi(
          title: 'Conclusão',
          value: completionRate,
          unit: '%',
          status: _status(completionRate),
          description: '$completed de $total ações concluídas.',
        ),
        AtlasExecutiveKpi(
          title: 'Saúde de prazos',
          value: deadlineHealth,
          unit: '%',
          status: _status(deadlineHealth),
          description: '$overdue ação(ões) atrasada(s).',
        ),
        AtlasExecutiveKpi(
          title: 'Resultado líquido',
          value: netResult,
          unit: 'R\$',
          status: netResult >= 0 ? 'Positivo' : 'Negativo',
          description: 'Resultado financeiro consolidado.',
        ),
        AtlasExecutiveKpi(
          title: 'ROI',
          value: roi,
          unit: '%',
          status: roi >= 0 ? 'Positivo' : 'Negativo',
          description: 'Retorno sobre o investimento.',
        ),
        AtlasExecutiveKpi(
          title: 'Metas',
          value: goalProgress,
          unit: '%',
          status: _status(goalProgress),
          description: '${goals.length} meta(s) monitorada(s).',
        ),
      ],
      scores: scores,
      bottlenecks: _buildBottlenecks(
        actions: actions,
        goals: goals,
        outcomes: outcomes,
      ),
      goalProjections: _buildGoalProjections(goals),
      scenarios: _buildScenarios(baseScore: overall, netResult: netResult),
      strategicPriorities: _buildPriorities(
        actions: actions,
        goals: goals,
        scores: scores,
      ),
    );
  }

  List<AtlasExecutiveBottleneck> _buildBottlenecks({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasOperationalGoal> goals,
    required List<AtlasActionOutcome> outcomes,
  }) {
    final result = <AtlasExecutiveBottleneck>[];
    final overdue = actions.where((action) => action.isOverdue).length;
    final withoutResponsible = actions
        .where((action) => action.isOpen && !action.hasResponsible)
        .length;
    final withoutOutcome = actions
        .where((action) => action.isCompleted)
        .where(
          (action) => !outcomes.any((outcome) => outcome.actionId == action.id),
        )
        .length;
    final delayedGoals = goals.where((goal) => goal.isOverdue).length;

    if (overdue > 0) {
      result.add(
        AtlasExecutiveBottleneck(
          id: 'overdue_actions',
          title: 'Ações atrasadas',
          area: AtlasOperationalArea.general,
          severity: 'Crítica',
          impactScore: (overdue * 15).clamp(0, 100).toDouble(),
          description: '$overdue ação(ões) ultrapassou(aram) o prazo.',
          recommendation: 'Replanejar prazos e priorizar responsáveis.',
        ),
      );
    }

    if (withoutResponsible > 0) {
      result.add(
        AtlasExecutiveBottleneck(
          id: 'without_responsible',
          title: 'Falta de responsáveis',
          area: AtlasOperationalArea.general,
          severity: 'Alta',
          impactScore: (withoutResponsible * 12).clamp(0, 100).toDouble(),
          description:
              '$withoutResponsible ação(ões) aberta(s) sem responsável.',
          recommendation:
              'Definir responsáveis e equilibrar a carga da equipe.',
        ),
      );
    }

    if (withoutOutcome > 0) {
      result.add(
        AtlasExecutiveBottleneck(
          id: 'without_outcome',
          title: 'Resultados não registrados',
          area: AtlasOperationalArea.finance,
          severity: 'Média',
          impactScore: (withoutOutcome * 10).clamp(0, 100).toDouble(),
          description: '$withoutOutcome ação(ões) concluída(s) sem resultado.',
          recommendation: 'Registrar resultados técnicos e financeiros.',
        ),
      );
    }

    if (delayedGoals > 0) {
      result.add(
        AtlasExecutiveBottleneck(
          id: 'delayed_goals',
          title: 'Metas atrasadas',
          area: AtlasOperationalArea.general,
          severity: 'Alta',
          impactScore: (delayedGoals * 18).clamp(0, 100).toDouble(),
          description: '$delayedGoals meta(s) ultrapassou(aram) o prazo.',
          recommendation: 'Revisar valor-alvo, ações vinculadas e cronograma.',
        ),
      );
    }

    if (result.isEmpty) {
      result.add(
        const AtlasExecutiveBottleneck(
          id: 'stable_operation',
          title: 'Operação estável',
          area: AtlasOperationalArea.general,
          severity: 'Informativa',
          impactScore: 0,
          description: 'Nenhum gargalo crítico foi identificado.',
          recommendation: 'Manter o acompanhamento e a disciplina de execução.',
        ),
      );
    }

    result.sort((a, b) => b.impactScore.compareTo(a.impactScore));
    return result;
  }

  List<AtlasSmartGoalProjection> _buildGoalProjections(
    List<AtlasOperationalGoal> goals,
  ) {
    final now = DateTime.now();

    return goals
        .where((goal) => goal.active)
        .map((goal) {
          final totalDays = goal.endAt
              .difference(goal.startAt)
              .inDays
              .clamp(1, 100000);
          final elapsedDays = now
              .difference(goal.startAt)
              .inDays
              .clamp(0, totalDays);
          final daysRemaining = goal.endAt.difference(now).inDays;
          final elapsedRate = elapsedDays / totalDays * 100;
          final onTrack = goal.progressPercent + 5 >= elapsedRate;
          final projected = elapsedDays == 0
              ? goal.progressPercent
              : (goal.progressPercent / elapsedDays * totalDays).clamp(
                  0.0,
                  150.0,
                );

          return AtlasSmartGoalProjection(
            goalId: goal.id,
            goalTitle: goal.title,
            currentProgressPercent: goal.progressPercent,
            projectedProgressPercent: projected,
            daysRemaining: daysRemaining,
            onTrack: onTrack,
            recommendation: onTrack
                ? 'Manter o ritmo atual e acompanhar semanalmente.'
                : 'Aumentar o ritmo das ações vinculadas ou replanejar a meta.',
          );
        })
        .toList(growable: false);
  }

  List<AtlasWhatIfScenario> _buildScenarios({
    required double baseScore,
    required double netResult,
  }) {
    return <AtlasWhatIfScenario>[
      AtlasWhatIfScenario(
        id: 'scenario_execution',
        title: 'Elevar conclusão em 15%',
        description: 'Simula maior disciplina operacional.',
        baseScore: baseScore,
        projectedScore: (baseScore + 7.5).clamp(0.0, 100.0),
        projectedFinancialImpact: netResult + netResult.abs() * 0.10,
        confidencePercent: 82,
        impacts: const <AtlasDecisionImpactNode>[
          AtlasDecisionImpactNode(
            area: AtlasOperationalArea.general,
            impactPercent: 15,
            direction: 'Positivo',
            explanation: 'Mais ações concluídas elevam o score operacional.',
          ),
          AtlasDecisionImpactNode(
            area: AtlasOperationalArea.finance,
            impactPercent: 10,
            direction: 'Positivo',
            explanation:
                'Maior execução tende a converter impactos esperados em realizados.',
          ),
        ],
      ),
      AtlasWhatIfScenario(
        id: 'scenario_cost',
        title: 'Reduzir custos em 8%',
        description: 'Simula redução do custo das ações.',
        baseScore: baseScore,
        projectedScore: (baseScore + 4).clamp(0.0, 100.0),
        projectedFinancialImpact: netResult + netResult.abs() * 0.08 + 1000,
        confidencePercent: 76,
        impacts: const <AtlasDecisionImpactNode>[
          AtlasDecisionImpactNode(
            area: AtlasOperationalArea.finance,
            impactPercent: 8,
            direction: 'Positivo',
            explanation: 'Redução de custos melhora margem e ROI.',
          ),
          AtlasDecisionImpactNode(
            area: AtlasOperationalArea.nutrition,
            impactPercent: -2,
            direction: 'Atenção',
            explanation:
                'Cortes mal planejados podem reduzir desempenho nutricional.',
          ),
        ],
      ),
      AtlasWhatIfScenario(
        id: 'scenario_reproduction',
        title: 'Elevar desempenho reprodutivo',
        description: 'Simula melhoria de 10% nos indicadores reprodutivos.',
        baseScore: baseScore,
        projectedScore: (baseScore + 5.5).clamp(0.0, 100.0),
        projectedFinancialImpact: netResult + 5000,
        confidencePercent: 70,
        impacts: const <AtlasDecisionImpactNode>[
          AtlasDecisionImpactNode(
            area: AtlasOperationalArea.reproduction,
            impactPercent: 10,
            direction: 'Positivo',
            explanation:
                'Melhora o potencial produtivo e a eficiência do rebanho.',
          ),
          AtlasDecisionImpactNode(
            area: AtlasOperationalArea.finance,
            impactPercent: 6,
            direction: 'Positivo',
            explanation:
                'Maior eficiência reprodutiva tende a elevar a receita futura.',
          ),
        ],
      ),
    ];
  }

  List<String> _buildPriorities({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasOperationalGoal> goals,
    required AtlasExecutiveScoreSet scores,
  }) {
    final priorities = <String>[];

    if (actions.any((action) => action.isOverdue)) {
      priorities.add(
        'Eliminar ações atrasadas antes de iniciar novas frentes.',
      );
    }
    if (actions.any((action) => action.isOpen && !action.hasResponsible)) {
      priorities.add('Definir responsáveis para todas as ações abertas.');
    }
    if (goals.any((goal) => goal.isOverdue)) {
      priorities.add('Replanejar metas vencidas e reforçar ações vinculadas.');
    }
    if (scores.economic < 60) {
      priorities.add('Priorizar ações com impacto financeiro mensurável.');
    }
    if (scores.sanitary < 60) {
      priorities.add('Reforçar prevenção e acompanhamento sanitário.');
    }

    if (priorities.isEmpty) {
      priorities.add('Manter a cadência semanal de gestão e resultados.');
      priorities.add(
        'Expandir as metas com maior retorno técnico e financeiro.',
      );
    }

    return priorities.take(6).toList(growable: false);
  }

  double _areaScore({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasOperationalGoal> goals,
    required List<String> keywords,
    required double fallback,
  }) {
    final areaActions = actions.where((action) {
      final source = action.sourceModule.toLowerCase();
      final text = '${action.title} ${action.description}'.toLowerCase();

      return keywords.any(
        (keyword) => source.contains(keyword) || text.contains(keyword),
      );
    }).toList();

    final areaGoals = goals.where((goal) {
      final text = '${goal.title} ${goal.description}'.toLowerCase();

      return keywords.any(text.contains);
    }).toList();

    if (areaActions.isEmpty && areaGoals.isEmpty) {
      return fallback.clamp(0.0, 100.0);
    }

    final actionProgress = areaActions.isEmpty
        ? fallback
        : areaActions
                  .map((action) => action.progressPercent)
                  .fold<int>(0, (a, b) => a + b) /
              areaActions.length;
    final goalProgress = areaGoals.isEmpty
        ? actionProgress
        : areaGoals
                  .map((goal) => goal.progressPercent)
                  .fold<double>(0, (a, b) => a + b) /
              areaGoals.length;

    return (actionProgress * 0.65 + goalProgress * 0.35).clamp(0.0, 100.0);
  }

  double _normalizeFinancial(double value) {
    return (50 + value / 200).clamp(0.0, 100.0);
  }

  double _normalizeRoi(double value) {
    return ((value + 100) / 3).clamp(0.0, 100.0);
  }

  String _status(double score) {
    if (score >= 85) {
      return 'Excelente';
    }
    if (score >= 70) {
      return 'Bom';
    }
    if (score >= 50) {
      return 'Atenção';
    }

    return 'Crítico';
  }
}
