import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/benefits_realization/presentation/screens/atlas_benefits_realization_screen.dart';
import 'package:projeto_atlas/features/decision_intelligence_lab/domain/models/atlas_decision_scenario.dart';
import 'package:projeto_atlas/features/farm_audit/domain/models/atlas_farm_audit.dart';
import 'package:projeto_atlas/features/strategy_execution/data/services/atlas_strategy_execution_repository.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';
import 'package:projeto_atlas/features/strategy_execution/domain/services/atlas_strategy_execution_engine.dart';

class AtlasStrategyExecutionScreen extends StatefulWidget {
  const AtlasStrategyExecutionScreen({super.key, this.scenario, this.farmId});

  final AtlasDecisionScenarioResult? scenario;
  final String? farmId;

  @override
  State<AtlasStrategyExecutionScreen> createState() {
    return _AtlasStrategyExecutionScreenState();
  }
}

class _AtlasStrategyExecutionScreenState
    extends State<AtlasStrategyExecutionScreen> {
  bool loading = true;
  List<AtlasStrategyExecutionPlan> plans = <AtlasStrategyExecutionPlan>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scenario = widget.scenario;

    if (scenario != null) {
      final existing = await AtlasStrategyExecutionRepository.instance
          .findByScenario(scenario.input.id);

      if (existing == null) {
        final generated = const AtlasStrategyExecutionEngine().create(scenario);

        await AtlasStrategyExecutionRepository.instance.save(generated);
      }
    }

    final loaded = await AtlasStrategyExecutionRepository.instance.loadAll();

    final filtered = widget.farmId == null
        ? loaded
        : loaded.where((item) => item.farmId == widget.farmId).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      plans = filtered;
      loading = false;
    });
  }

  Future<void> _save(AtlasStrategyExecutionPlan plan) async {
    await AtlasStrategyExecutionRepository.instance.save(plan);
    await _load();
  }

  Future<void> _changeMilestone({
    required AtlasStrategyExecutionPlan plan,
    required String phaseId,
    required String milestoneId,
    required AtlasStrategyMilestoneStatus status,
  }) async {
    final phases = plan.phases.map((phase) {
      if (phase.id != phaseId) {
        return phase;
      }

      final milestones = phase.milestones.map((milestone) {
        if (milestone.id != milestoneId) {
          return milestone;
        }

        return milestone.copyWith(status: status);
      }).toList();

      return phase.copyWith(milestones: milestones);
    }).toList();

    final completed = phases.every(
      (phase) => phase.milestones.every(
        (milestone) =>
            milestone.status == AtlasStrategyMilestoneStatus.completed,
      ),
    );

    await _save(
      plan.copyWith(
        phases: phases,
        status: completed
            ? AtlasStrategyExecutionStatus.completed
            : AtlasStrategyExecutionStatus.active,
      ),
    );
  }

  Future<void> _changeGate({
    required AtlasStrategyExecutionPlan plan,
    required String gateId,
    required AtlasStrategyGateDecision decision,
  }) async {
    final gates = plan.gates.map((gate) {
      if (gate.id != gateId) {
        return gate;
      }

      return gate.copyWith(decision: decision);
    }).toList();

    await _save(plan.copyWith(gates: gates));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Strategy Execution Engine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir realização de benefícios',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasBenefitsRealizationScreen(
                      farmId: widget.farmId,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
          ? const _EmptyView()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _PortfolioHero(plans: plans),
                    const SizedBox(height: 22),
                    const Text(
                      'Portfólio de execução estratégica',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Planos escolhidos no laboratório, agora convertidos em execução controlada.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    ...plans.map(
                      (plan) => _PlanCard(
                        plan: plan,
                        onMilestoneChanged:
                            ({
                              required String phaseId,
                              required String milestoneId,
                              required AtlasStrategyMilestoneStatus status,
                            }) {
                              _changeMilestone(
                                plan: plan,
                                phaseId: phaseId,
                                milestoneId: milestoneId,
                                status: status,
                              );
                            },
                        onGateChanged:
                            ({
                              required String gateId,
                              required AtlasStrategyGateDecision decision,
                            }) {
                              _changeGate(
                                plan: plan,
                                gateId: gateId,
                                decision: decision,
                              );
                            },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PortfolioHero extends StatelessWidget {
  const _PortfolioHero({required this.plans});

  final List<AtlasStrategyExecutionPlan> plans;

  @override
  Widget build(BuildContext context) {
    final active = plans
        .where(
          (item) =>
              item.status == AtlasStrategyExecutionStatus.active ||
              item.status == AtlasStrategyExecutionStatus.planned,
        )
        .length;

    final investment = plans.fold<double>(0, (sum, item) => sum + item.budget);

    final expectedGain = plans.fold<double>(
      0,
      (sum, item) => sum + item.expectedNetGain,
    );

    final averageProgress = plans.isEmpty
        ? 0.0
        : plans.fold<double>(0, (sum, item) => sum + item.progressPercent) /
              plans.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF1B5E20),
            Color(0xFF00838F),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Da decisão para a execução',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          const Text(
            'Portfólio estratégico do Atlas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroMetric(label: 'Planos ativos', value: '$active'),
              _HeroMetric(label: 'Investimento', value: _currency(investment)),
              _HeroMetric(
                label: 'Ganho esperado',
                value: _currency(expectedGain),
              ),
              _HeroMetric(
                label: 'Progresso médio',
                value: '${averageProgress.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onMilestoneChanged,
    required this.onGateChanged,
  });

  final AtlasStrategyExecutionPlan plan;
  final void Function({
    required String phaseId,
    required String milestoneId,
    required AtlasStrategyMilestoneStatus status,
  })
  onMilestoneChanged;
  final void Function({
    required String gateId,
    required AtlasStrategyGateDecision decision,
  })
  onGateChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(
            '${plan.progressPercent.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          plan.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${plan.farmName} · ${atlasFarmAuditAreaLabel(plan.area)} · '
          '${atlasStrategyExecutionStatusLabel(plan.status)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          LinearProgressIndicator(
            value: plan.progressPercent / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(label: 'Orçamento', value: _currency(plan.budget)),
              _Metric(
                label: 'ROI esperado',
                value: '${plan.expectedRoi.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Confiança',
                value: '${plan.confidence.toStringAsFixed(1)}%',
              ),
              _Metric(label: 'Risco', value: atlasDecisionRiskLabel(plan.risk)),
              _Metric(label: 'Prazo', value: _date(plan.targetDate)),
              _Metric(
                label: 'Marcos',
                value: '${plan.completedMilestones}/${plan.totalMilestones}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fases de execução',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...plan.phases.map(
            (phase) => _PhaseCard(
              phase: phase,
              onChanged:
                  ({
                    required String milestoneId,
                    required AtlasStrategyMilestoneStatus status,
                  }) {
                    onMilestoneChanged(
                      phaseId: phase.id,
                      milestoneId: milestoneId,
                      status: status,
                    );
                  },
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gates de decisão',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...plan.gates.map(
            (gate) => _GateCard(
              gate: gate,
              onChanged: (decision) {
                onGateChanged(gateId: gate.id, decision: decision);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phase, required this.onChanged});

  final AtlasStrategyExecutionPhase phase;
  final void Function({
    required String milestoneId,
    required AtlasStrategyMilestoneStatus status,
  })
  onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFAFAFA),
      child: ExpansionTile(
        title: Text(
          phase.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_date(phase.startDate)} a ${_date(phase.endDate)} · '
          '${_currency(phase.budget)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(alignment: Alignment.centerLeft, child: Text(phase.objective)),
          const SizedBox(height: 10),
          ...phase.milestones.map(
            (milestone) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                milestone.status == AtlasStrategyMilestoneStatus.completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
              ),
              title: Text(milestone.title),
              subtitle: Text(
                '${milestone.description}\n'
                'Critério: ${milestone.successCriterion}\n'
                'Prazo: ${_date(milestone.dueDate)}',
              ),
              isThreeLine: true,
              trailing: DropdownButton<AtlasStrategyMilestoneStatus>(
                value: milestone.status,
                items: AtlasStrategyMilestoneStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(atlasStrategyMilestoneStatusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (status) {
                  if (status != null) {
                    onChanged(milestoneId: milestone.id, status: status);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.gate, required this.onChanged});

  final AtlasStrategyDecisionGate gate;
  final ValueChanged<AtlasStrategyGateDecision> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF7F9FC),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.alt_route_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gate.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Revisão: ${_date(gate.reviewDate)}'),
                  const SizedBox(height: 8),
                  ...gate.criteria.map((item) => Text('• $item')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<AtlasStrategyGateDecision>(
              value: gate.decision,
              items: AtlasStrategyGateDecision.values
                  .map(
                    (decision) => DropdownMenuItem(
                      value: decision,
                      child: Text(atlasStrategyGateDecisionLabel(decision)),
                    ),
                  )
                  .toList(),
              onChanged: (decision) {
                if (decision != null) {
                  onChanged(decision);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Nenhum plano estratégico em execução.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Abra o Decision Intelligence Lab e transforme um cenário em plano de execução.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _currency(double value) {
  final negative = value < 0;
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

  return '${negative ? '-' : ''}R\$ '
      '${buffer.toString()},$decimal';
}
