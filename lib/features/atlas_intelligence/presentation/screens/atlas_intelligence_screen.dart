import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_intelligence/domain/models/atlas_intelligence_data.dart';

class AtlasIntelligenceScreen
    extends StatelessWidget {
  const AtlasIntelligenceScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasIntelligenceData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Intelligence Engine',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 1240,
            ),
            child: data.hasData
                ? ListView(
                    padding:
                        const EdgeInsets.all(22),
                    children: [
                      _IntelligenceHero(
                        data: data,
                      ),
                      if (data.primaryRecommendation !=
                          null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title:
                              'Recomendação central',
                          subtitle:
                              'A principal orientação gerada pelo cérebro do Atlas.',
                        ),
                        const SizedBox(height: 12),
                        _PrimaryRecommendationCard(
                          item: data
                              .primaryRecommendation!,
                          onOpenFarm:
                              onOpenFarm,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Padrões identificados',
                        subtitle:
                            'Relações, gargalos, contradições e oportunidades.',
                      ),
                      const SizedBox(height: 12),
                      _PatternList(
                        items: data.patterns,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Hipóteses',
                        subtitle:
                            'Possíveis relações de causa e efeito que precisam ser validadas.',
                      ),
                      const SizedBox(height: 12),
                      _HypothesisList(
                        items: data.hypotheses,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Recomendações priorizadas',
                        subtitle:
                            'Ações sugeridas com confiança e impacto estimados.',
                      ),
                      const SizedBox(height: 12),
                      _RecommendationList(
                        items:
                            data.recommendations,
                        onOpenFarm:
                            onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title:
                            'Sinais consolidados',
                        subtitle:
                            'Informações relevantes recebidas do Atlas OS.',
                      ),
                      const SizedBox(height: 12),
                      _SignalList(
                        items: data.signals,
                        onOpenFarm:
                            onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyIntelligenceView(),
          ),
        ),
      ),
    );
  }
}

class _IntelligenceHero extends StatelessWidget {
  const _IntelligenceHero({
    required this.data,
  });

  final AtlasIntelligenceData data;

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF030712),
            Color(0xFF111D33),
            Color(0xFF1F3B55),
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
                    Icons.psychology_outlined,
                    color:
                        Color(0xFFB3E5FC),
                    size: 33,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Atlas Intelligence Engine',
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
                    label: 'Sinais',
                    value:
                        data.signals.length,
                  ),
                  _HeroMetric(
                    label: 'Padrões',
                    value:
                        data.patterns.length,
                  ),
                  _HeroMetric(
                    label: 'Hipóteses',
                    value:
                        data.hypotheses.length,
                  ),
                  _HeroMetric(
                    label: 'Recomendações',
                    value: data
                        .recommendations.length,
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
                  data.intelligenceScore
                      .toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  atlasIntelligenceStatusLabel(
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

class _PrimaryRecommendationCard
    extends StatelessWidget {
  const _PrimaryRecommendationCard({
    required this.item,
    required this.onOpenFarm,
  });

  final AtlasIntelligenceRecommendation item;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color =
        _priorityColor(item.priority);

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
                  Icons.auto_awesome_outlined,
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
                  atlasIntelligencePriorityLabel(
                    item.priority,
                  ),
                  style: TextStyle(
                    color: color,
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
            const SizedBox(height: 13),
            ...item.actions.map((action) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 6,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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

class _PatternList extends StatelessWidget {
  const _PatternList({
    required this.items,
  });

  final List<AtlasIntelligencePattern> items;

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
              Icons.hub_outlined,
              color: Color(0xFF6A1B9A),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${atlasIntelligencePatternTypeLabel(item.type)} · '
              '${item.confidencePercent.toStringAsFixed(0)}% de confiança\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              item.strengthScore
                  .toStringAsFixed(0),
              style: const TextStyle(
                color:
                    Color(0xFF6A1B9A),
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

class _HypothesisList
    extends StatelessWidget {
  const _HypothesisList({
    required this.items,
  });

  final List<AtlasIntelligenceHypothesis>
      items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        return Card(
          child: ExpansionTile(
            leading: const Icon(
              Icons.science_outlined,
              color: Color(0xFF1565C0),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.probabilityPercent.toStringAsFixed(0)}% de probabilidade',
            ),
            childrenPadding:
                const EdgeInsets.fromLTRB(
              18,
              0,
              18,
              18,
            ),
            children: [
              Text(
                item.description,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Causa: ${item.cause}',
              ),
              const SizedBox(height: 6),
              Text(
                'Efeito: ${item.effect}',
              ),
              const SizedBox(height: 10),
              ...item.validationSteps
                  .map(
                    (step) => Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 5,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .check_outlined,
                            size: 17,
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          Expanded(
                            child: Text(
                              step,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationList
    extends StatelessWidget {
  const _RecommendationList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasIntelligenceRecommendation>
      items;

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
              '${item.farmName} · '
              '${item.deadlineHours} horas · '
              '${item.confidencePercent.toStringAsFixed(0)}% de confiança\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasIntelligencePriorityLabel(
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

class _SignalList extends StatelessWidget {
  const _SignalList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasIntelligenceSignal> items;
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
              Icons.sensors_outlined,
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
              '${item.source} · '
              '${item.farmName}\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              item.relevanceScore
                  .toStringAsFixed(0),
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

class _EmptyIntelligenceView
    extends StatelessWidget {
  const _EmptyIntelligenceView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma inteligência consolidada disponível.',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }
}

Color _statusColor(
  AtlasIntelligenceStatus status,
) {
  switch (status) {
    case AtlasIntelligenceStatus.stable:
      return const Color(0xFF80CBC4);

    case AtlasIntelligenceStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasIntelligenceStatus.highRisk:
      return const Color(0xFFEF9A9A);

    case AtlasIntelligenceStatus.critical:
      return const Color(0xFFFF8A80);
  }
}

Color _priorityColor(
  AtlasIntelligencePriority priority,
) {
  switch (priority) {
    case AtlasIntelligencePriority.low:
      return const Color(0xFF2E7D32);

    case AtlasIntelligencePriority.medium:
      return const Color(0xFF1565C0);

    case AtlasIntelligencePriority.high:
      return const Color(0xFFEF6C00);

    case AtlasIntelligencePriority.critical:
      return const Color(0xFFC62828);
  }
}

Color _severityColor(
  AtlasIntelligenceSeverity severity,
) {
  switch (severity) {
    case AtlasIntelligenceSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasIntelligenceSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasIntelligenceSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasIntelligenceSeverity.critical:
      return const Color(0xFFC62828);
  }
}
