import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_core/domain/models/atlas_executive_core_data.dart';

class AtlasExecutiveCoreScreen
    extends StatelessWidget {
  const AtlasExecutiveCoreScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasExecutiveCoreData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Executive Core',
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
                      _ExecutiveCoreHero(
                        data: data,
                      ),
                      const SizedBox(height: 24),
                      _IndexGrid(data: data),
                      if (data.bestDecisionOfWeek !=
                          null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title:
                              'Melhor decisão da semana',
                          subtitle:
                              'Decisão consolidada com maior impacto e confiança.',
                        ),
                        const SizedBox(height: 12),
                        _BestDecisionCard(
                          item:
                              data.bestDecisionOfWeek!,
                          onOpenFarm:
                              onOpenFarm,
                        ),
                      ],
                      if (data.nextMission !=
                          null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title:
                              'Próxima missão recomendada',
                          subtitle:
                              'Missão executiva gerada a partir da principal decisão.',
                        ),
                        const SizedBox(height: 12),
                        _MissionCard(
                          item: data.nextMission!,
                          onOpenFarm:
                              onOpenFarm,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Prioridades globais',
                        subtitle:
                            'Ranking consolidado de toda a operação.',
                      ),
                      const SizedBox(height: 12),
                      _PriorityList(
                        items: data.priorities,
                        onOpenFarm:
                            onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Principais riscos',
                        subtitle:
                            'Riscos ordenados por severidade e probabilidade.',
                      ),
                      const SizedBox(height: 12),
                      _RiskList(
                        items: data.risks,
                        onOpenFarm:
                            onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Oportunidades',
                        subtitle:
                            'Potenciais de retorno priorizados pelo Executive Core.',
                      ),
                      const SizedBox(height: 12),
                      _OpportunityList(
                        items:
                            data.opportunities,
                        onOpenFarm:
                            onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Memória executiva',
                        subtitle:
                            'Registros iniciais de padrões, decisões, riscos e missões.',
                      ),
                      const SizedBox(height: 12),
                      _MemoryList(
                        items:
                            data.memoryRecords,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyExecutiveCoreView(),
          ),
        ),
      ),
    );
  }
}

class _ExecutiveCoreHero
    extends StatelessWidget {
  const _ExecutiveCoreHero({
    required this.data,
  });

  final AtlasExecutiveCoreData data;

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF020617),
            Color(0xFF10243A),
            Color(0xFF254B62),
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
                    Icons.account_balance_outlined,
                    color: Color(0xFFB3E5FC),
                    size: 33,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Atlas Executive Core',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
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
                  height: 1.48,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Prioridades',
                    value:
                        data.priorities.length,
                  ),
                  _HeroMetric(
                    label: 'Riscos',
                    value: data.risks.length,
                  ),
                  _HeroMetric(
                    label: 'Oportunidades',
                    value:
                        data.opportunities.length,
                  ),
                  _HeroMetric(
                    label: 'Memórias',
                    value:
                        data.memoryRecords.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 245,
            padding:
                const EdgeInsets.all(18),
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
                  data.executiveScore
                      .toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  atlasExecutiveCoreStatusLabel(
                    data.status,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${data.confidencePercent.toStringAsFixed(0)}% de confiança',
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

class _IndexGrid extends StatelessWidget {
  const _IndexGrid({
    required this.data,
  });

  final AtlasExecutiveCoreData data;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Financeiro',
        data.financialIndex,
        Icons.payments_outlined,
      ),
      (
        'Operacional',
        data.operationalIndex,
        Icons.settings_outlined,
      ),
      (
        'Estratégico',
        data.strategicIndex,
        Icons.flag_outlined,
      ),
      (
        'Preditivo',
        data.predictiveIndex,
        Icons.auto_graph_outlined,
      ),
      (
        'Saúde geral',
        data.healthIndex,
        Icons.monitor_heart_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final width =
            constraints.maxWidth >= 900
                ? (constraints.maxWidth - 28) /
                    3
                : constraints.maxWidth >= 620
                    ? (constraints.maxWidth -
                            14) /
                        2
                    : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: items.map((item) {
            final color =
                _indexColor(item.$2);

            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.$3,
                            color: color,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              item.$1,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            item.$2
                                .toStringAsFixed(0),
                            style: TextStyle(
                              color: color,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      LinearProgressIndicator(
                        minHeight: 8,
                        value: item.$2 / 100,
                        backgroundColor:
                            color.withValues(
                          alpha: 0.10,
                        ),
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BestDecisionCard
    extends StatelessWidget {
  const _BestDecisionCard({
    required this.item,
    required this.onOpenFarm,
  });

  final AtlasExecutiveCoreDecision item;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color =
        _indexColor(item.score);

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
                  Icons.bolt_outlined,
                  color: color,
                  size: 30,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.farmName,
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
                  item.score.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.reasoning,
              style: const TextStyle(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            ...item.actions.map((action) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 5,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(action),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Text(
              'Prazo: ${item.deadlineHours} horas · '
              '${item.confidencePercent.toStringAsFixed(0)}% de confiança · '
              'R\$ ${item.expectedFinancialImpact.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            if (onOpenFarm != null &&
                item.farmName !=
                    'Operação') ...[
              const SizedBox(height: 12),
              ActionChip(
                label: const Text(
                  'Abrir fazenda',
                ),
                onPressed: () {
                  onOpenFarm!(
                    item.farmName,
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

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.item,
    required this.onOpenFarm,
  });

  final AtlasExecutiveCoreMission item;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  color: Color(0xFF6A1B9A),
                  size: 29,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Missão executiva',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.description,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Objetivo: ${item.objective}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...item.steps.map((step) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 5,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_right,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(step),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Text(
              '${item.deadlineDays} dias · '
              '${item.successProbabilityPercent.toStringAsFixed(0)}% de sucesso · '
              '${item.expectedImpact}',
              style: const TextStyle(
                color: Color(0xFF6A1B9A),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onOpenFarm != null &&
                item.farmName !=
                    'Operação') ...[
              const SizedBox(height: 12),
              ActionChip(
                label: const Text(
                  'Abrir fazenda',
                ),
                onPressed: () {
                  onOpenFarm!(
                    item.farmName,
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

class _PriorityList extends StatelessWidget {
  const _PriorityList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveCorePriority> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
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
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.source} · '
              '${item.farmName} · '
              '${item.deadlineHours} horas\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasExecutiveCorePriorityLabel(
                item.priority,
              ),
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null ||
                    item.farmName ==
                        'Operação'
                ? null
                : () {
                    onOpenFarm!(
                      item.farmName,
                    );
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _RiskList extends StatelessWidget {
  const _RiskList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveCoreRisk> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color =
            _severityColor(item.severity);

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.warning_amber_outlined,
              color: color,
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${item.probabilityPercent.toStringAsFixed(0)}% de probabilidade\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasExecutiveCoreSeverityLabel(
                item.severity,
              ),
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null ||
                    item.farmName ==
                        'Operação'
                ? null
                : () {
                    onOpenFarm!(
                      item.farmName,
                    );
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _OpportunityList
    extends StatelessWidget {
  const _OpportunityList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveCoreOpportunity>
      items;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.trending_up_outlined,
              color: Color(0xFF1B5E20),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${item.confidencePercent.toStringAsFixed(0)}% de confiança\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.roiPercent.toStringAsFixed(0)}% ROI',
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null ||
                    item.farmName ==
                        'Operação'
                ? null
                : () {
                    onOpenFarm!(
                      item.farmName,
                    );
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _MemoryList extends StatelessWidget {
  const _MemoryList({
    required this.items,
  });

  final List<AtlasExecutiveMemoryRecord>
      items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.history_edu_outlined,
              color: Color(0xFF455A64),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${atlasExecutiveMemoryTypeLabel(item.type)} · '
              '${item.farmName}\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              item.relevanceScore
                  .toStringAsFixed(0),
              style: const TextStyle(
                color: Color(0xFF455A64),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
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
          fontWeight:
              FontWeight.w600,
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
            'Nenhum item disponível.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyExecutiveCoreView
    extends StatelessWidget {
  const _EmptyExecutiveCoreView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum dado executivo consolidado disponível.',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }
}

Color _statusColor(
  AtlasExecutiveCoreStatus status,
) {
  switch (status) {
    case AtlasExecutiveCoreStatus.excellent:
      return const Color(0xFF80CBC4);

    case AtlasExecutiveCoreStatus.adequate:
      return const Color(0xFFA5D6A7);

    case AtlasExecutiveCoreStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasExecutiveCoreStatus.critical:
      return const Color(0xFFEF9A9A);
  }
}

Color _indexColor(
  double value,
) {
  if (value >= 80) {
    return const Color(0xFF1B5E20);
  }

  if (value >= 65) {
    return const Color(0xFF1565C0);
  }

  if (value >= 45) {
    return const Color(0xFFEF6C00);
  }

  return const Color(0xFFC62828);
}

Color _priorityColor(
  AtlasExecutiveCorePriorityLevel priority,
) {
  switch (priority) {
    case AtlasExecutiveCorePriorityLevel.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveCorePriorityLevel.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveCorePriorityLevel.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveCorePriorityLevel.critical:
      return const Color(0xFFC62828);
  }
}

Color _severityColor(
  AtlasExecutiveCoreSeverity severity,
) {
  switch (severity) {
    case AtlasExecutiveCoreSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveCoreSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveCoreSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveCoreSeverity.critical:
      return const Color(0xFFC62828);
  }
}
