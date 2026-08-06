import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/decision_engine/domain/models/atlas_decision_engine_data.dart';

class AtlasDecisionEngineScreen
    extends StatelessWidget {
  const AtlasDecisionEngineScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasDecisionEngineData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Decision Engine',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1240,
            ),
            child: data.hasData
                ? ListView(
                    padding:
                        const EdgeInsets.all(22),
                    children: [
                      _DecisionHero(data: data),
                      if (data.mainDecision != null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title:
                              'Decisão recomendada',
                          subtitle:
                              'Ação com maior combinação de impacto, urgência e confiança.',
                        ),
                        const SizedBox(height: 12),
                        _MainDecisionCard(
                          decision:
                              data.mainDecision!,
                          onOpenFarm: onOpenFarm,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Ranking de decisões',
                        subtitle:
                            'Recomendações ordenadas por prioridade executiva.',
                      ),
                      const SizedBox(height: 12),
                      _DecisionList(
                        decisions: data.decisions,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyDecisionView(),
          ),
        ),
      ),
    );
  }
}

class _DecisionHero extends StatelessWidget {
  const _DecisionHero({
    required this.data,
  });

  final AtlasDecisionEngineData data;

  @override
  Widget build(BuildContext context) {
    final color =
        _engineStatusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF101820),
            Color(0xFF1E3A5F),
            Color(0xFF345995),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final compact =
              constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    color: Color(0xFFB3E5FC),
                    size: 32,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Motor Executivo de Decisão',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Decisões',
                    value: data.decisions.length,
                  ),
                  _HeroMetric(
                    label: 'Críticas',
                    value: data.decisions
                        .where(
                          (item) =>
                              item.priority ==
                              AtlasDecisionPriority
                                  .critical,
                        )
                        .length,
                  ),
                  _HeroMetric(
                    label: 'Imediatas',
                    value: data.decisions
                        .where(
                          (item) =>
                              item.urgency ==
                              AtlasDecisionUrgency
                                  .immediate,
                        )
                        .length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 225,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  data.engineScore
                      .toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  atlasDecisionEngineStatusLabel(
                    data.status,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child:
                      LinearProgressIndicator(
                    minHeight: 9,
                    value:
                        data.engineScore / 100,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.12,
                    ),
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      color,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Confiança: '
                  '${data.confidencePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                information,
                const SizedBox(height: 20),
                side,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 24),
              side,
            ],
          );
        },
      ),
    );
  }
}

class _MainDecisionCard extends StatelessWidget {
  const _MainDecisionCard({
    required this.decision,
    required this.onOpenFarm,
  });

  final AtlasDecisionRecommendation decision;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color =
        _priorityColor(decision.priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_circle_outlined,
                  color: color,
                  size: 31,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        decision.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        decision.farmName,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  atlasDecisionPriorityLabel(
                    decision.priority,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              decision.description,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label:
                      'Urgência: ${atlasDecisionUrgencyLabel(decision.urgency)}',
                  color: color,
                ),
                _InfoChip(
                  label:
                      'Risco: ${atlasDecisionRiskLabel(decision.risk)}',
                  color:
                      const Color(0xFFC62828),
                ),
                _InfoChip(
                  label:
                      '${decision.confidencePercent.toStringAsFixed(0)}% de confiança',
                  color:
                      const Color(0xFF1565C0),
                ),
                _InfoChip(
                  label:
                      '${decision.deadlineDays} dias',
                  color:
                      const Color(0xFF6A1B9A),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              'Impacto esperado: '
              'R\$ ${decision.expectedFinancialImpact.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (decision.investmentValue > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Investimento: '
                'R\$ ${decision.investmentValue.toStringAsFixed(2)} · '
                'ROI: ${decision.roiPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 13),
            Text(
              decision.reasoningSummary,
              style: const TextStyle(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Plano de execução',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...decision.executionPlan.map(
              (step) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor:
                            color.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          step.position.toString(),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            Text(
                              step.description,
                              style: const TextStyle(
                                color:
                                    Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${step.deadlineDays}d',
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                label:
                    const Text('Abrir fazenda'),
                onPressed: () {
                  onOpenFarm!(
                    decision.farmName,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionList extends StatelessWidget {
  const _DecisionList({
    required this.decisions,
    required this.onOpenFarm,
  });

  final List<AtlasDecisionRecommendation>
      decisions;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (decisions.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: decisions.map((item) {
        final color =
            _priorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  color.withValues(
                alpha: 0.12,
              ),
              child: Text(
                item.position.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${atlasDecisionUrgencyLabel(item.urgency)} · '
              '${item.deadlineDays} dias\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              'R\$ ${item.expectedFinancialImpact.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(item.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'Nenhuma decisão disponível.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDecisionView
    extends StatelessWidget {
  const _EmptyDecisionView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma recomendação de decisão disponível.',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }
}

Color _engineStatusColor(
  AtlasDecisionEngineStatus status,
) {
  switch (status) {
    case AtlasDecisionEngineStatus.excellent:
      return const Color(0xFF80CBC4);

    case AtlasDecisionEngineStatus.adequate:
      return const Color(0xFFA5D6A7);

    case AtlasDecisionEngineStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasDecisionEngineStatus.critical:
      return const Color(0xFFEF9A9A);
  }
}

Color _priorityColor(
  AtlasDecisionPriority priority,
) {
  switch (priority) {
    case AtlasDecisionPriority.low:
      return const Color(0xFF2E7D32);

    case AtlasDecisionPriority.medium:
      return const Color(0xFF1565C0);

    case AtlasDecisionPriority.high:
      return const Color(0xFFEF6C00);

    case AtlasDecisionPriority.critical:
      return const Color(0xFFC62828);
  }
}
