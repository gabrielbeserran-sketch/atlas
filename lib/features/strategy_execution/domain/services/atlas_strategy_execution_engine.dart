import 'package:projeto_atlas/features/decision_intelligence_lab/domain/models/atlas_decision_scenario.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';

class AtlasStrategyExecutionEngine {
  const AtlasStrategyExecutionEngine();

  AtlasStrategyExecutionPlan create(AtlasDecisionScenarioResult scenario) {
    final now = DateTime.now();
    final totalDays = (scenario.input.horizonMonths * 30).clamp(90, 1080);
    final targetDate = now.add(Duration(days: totalDays));

    final preparationEnd = now.add(Duration(days: (totalDays * 0.15).round()));
    final pilotEnd = now.add(Duration(days: (totalDays * 0.45).round()));
    final scaleEnd = now.add(Duration(days: (totalDays * 0.78).round()));

    final phases = <AtlasStrategyExecutionPhase>[
      _phase(
        id: 'prepare',
        title: 'Fase 1 — Preparação',
        objective: 'Validar premissas, recursos, responsáveis e linha de base.',
        start: now,
        end: preparationEnd,
        budget: scenario.input.investment * 0.15,
        responsible: 'Gestor da fazenda e consultor',
        milestones: <_MilestoneTemplate>[
          const _MilestoneTemplate(
            'Validar escopo e orçamento',
            'Confirmar valores, fornecedores, limites e fontes de recurso.',
            'Orçamento aprovado e responsável definido.',
          ),
          const _MilestoneTemplate(
            'Registrar linha de base',
            'Medir os indicadores atuais antes da intervenção.',
            'Indicadores iniciais documentados no Atlas.',
          ),
          const _MilestoneTemplate(
            'Preparar equipe e estrutura',
            'Treinar responsáveis e verificar recursos necessários.',
            'Equipe apta e recursos disponíveis.',
          ),
        ],
      ),
      _phase(
        id: 'pilot',
        title: 'Fase 2 — Piloto controlado',
        objective:
            'Testar o cenário em menor escala antes de comprometer todo o investimento.',
        start: preparationEnd,
        end: pilotEnd,
        budget: scenario.input.investment * 0.30,
        responsible: 'Responsável técnico e líder operacional',
        milestones: <_MilestoneTemplate>[
          const _MilestoneTemplate(
            'Iniciar lote ou área piloto',
            'Executar a intervenção em escala controlada.',
            'Piloto iniciado dentro do prazo e orçamento.',
          ),
          const _MilestoneTemplate(
            'Avaliar resposta inicial',
            'Comparar desempenho, aderência, custo e problemas.',
            'Primeira avaliação registrada com evidências.',
          ),
          const _MilestoneTemplate(
            'Corrigir falhas do piloto',
            'Aplicar ajustes antes da expansão.',
            'Falhas críticas corrigidas ou controladas.',
          ),
        ],
      ),
      _phase(
        id: 'scale',
        title: 'Fase 3 — Expansão',
        objective:
            'Ampliar a estratégia validada com controle de custo e qualidade.',
        start: pilotEnd,
        end: scaleEnd,
        budget: scenario.input.investment * 0.40,
        responsible: 'Gestor, responsável técnico e equipe',
        milestones: <_MilestoneTemplate>[
          const _MilestoneTemplate(
            'Aprovar expansão',
            'Confirmar que o piloto atingiu os critérios mínimos.',
            'Gate de expansão aprovado.',
          ),
          const _MilestoneTemplate(
            'Executar em escala',
            'Expandir o protocolo para os lotes ou áreas definidos.',
            'Execução ampliada conforme o plano.',
          ),
          const _MilestoneTemplate(
            'Controlar orçamento e qualidade',
            'Comparar realizado com planejado semanalmente.',
            'Desvio financeiro e operacional dentro do limite.',
          ),
        ],
      ),
      _phase(
        id: 'consolidate',
        title: 'Fase 4 — Consolidação',
        objective:
            'Confirmar o retorno, padronizar o processo e registrar aprendizados.',
        start: scaleEnd,
        end: targetDate,
        budget: scenario.input.investment * 0.15,
        responsible: 'Gestor da fazenda',
        milestones: <_MilestoneTemplate>[
          const _MilestoneTemplate(
            'Medir resultado final',
            'Comparar indicadores, custos, receita e impacto.',
            'Resultado final calculado e documentado.',
          ),
          const _MilestoneTemplate(
            'Padronizar protocolo',
            'Transformar a estratégia validada em rotina.',
            'Procedimento e responsáveis formalizados.',
          ),
          const _MilestoneTemplate(
            'Registrar lições aprendidas',
            'Documentar acertos, falhas e recomendações futuras.',
            'Caso enviado à memória técnica do Atlas.',
          ),
        ],
      ),
    ];

    final gates = <AtlasStrategyDecisionGate>[
      AtlasStrategyDecisionGate(
        id: 'gate_${scenario.id}_pilot',
        title: 'Gate 1 — Autorizar piloto',
        reviewDate: preparationEnd,
        criteria: <String>[
          'Orçamento e responsável aprovados.',
          'Linha de base registrada.',
          'Equipe e estrutura prontas.',
        ],
        decision: AtlasStrategyGateDecision.pending,
      ),
      AtlasStrategyDecisionGate(
        id: 'gate_${scenario.id}_scale',
        title: 'Gate 2 — Autorizar expansão',
        reviewDate: pilotEnd,
        criteria: <String>[
          'Piloto executado sem risco crítico.',
          'Indicadores iniciais compatíveis com a meta.',
          'Desvio financeiro aceitável.',
        ],
        decision: AtlasStrategyGateDecision.pending,
      ),
      AtlasStrategyDecisionGate(
        id: 'gate_${scenario.id}_consolidate',
        title: 'Gate 3 — Consolidar estratégia',
        reviewDate: scaleEnd,
        criteria: <String>[
          'Probabilidade de atingir a meta permanece favorável.',
          'Equipe consegue sustentar a execução.',
          'Retorno realizado justifica a continuidade.',
        ],
        decision: AtlasStrategyGateDecision.pending,
      ),
    ];

    return AtlasStrategyExecutionPlan(
      id: 'execution_${scenario.input.id}',
      sourceScenarioId: scenario.input.id,
      farmId: scenario.farmId,
      farmName: scenario.farmName,
      title: scenario.input.title,
      description: scenario.input.description,
      area: scenario.input.area,
      createdAt: now,
      startDate: now,
      targetDate: targetDate,
      budget: scenario.input.investment,
      expectedNetGain: scenario.expectedNetGain,
      expectedRoi: scenario.roiPercent,
      confidence: scenario.confidence,
      risk: scenario.risk,
      owner: 'Gestor da fazenda',
      status: AtlasStrategyExecutionStatus.planned,
      phases: phases,
      gates: gates,
    );
  }

  AtlasStrategyExecutionPhase _phase({
    required String id,
    required String title,
    required String objective,
    required DateTime start,
    required DateTime end,
    required double budget,
    required String responsible,
    required List<_MilestoneTemplate> milestones,
  }) {
    final durationDays = end.difference(start).inDays.clamp(1, 10000);

    final generated = milestones.asMap().entries.map((entry) {
      final fraction = (entry.key + 1) / milestones.length;
      final dueDate = start.add(
        Duration(days: (durationDays * fraction).round()),
      );
      final template = entry.value;

      return AtlasStrategyMilestone(
        id: '${id}_${entry.key + 1}',
        title: template.title,
        description: template.description,
        dueDate: dueDate,
        successCriterion: template.successCriterion,
        status: AtlasStrategyMilestoneStatus.pending,
      );
    }).toList();

    return AtlasStrategyExecutionPhase(
      id: id,
      title: title,
      objective: objective,
      startDate: start,
      endDate: end,
      budget: budget,
      responsible: responsible,
      milestones: generated,
    );
  }
}

class _MilestoneTemplate {
  const _MilestoneTemplate(this.title, this.description, this.successCriterion);

  final String title;
  final String description;
  final String successCriterion;
}
