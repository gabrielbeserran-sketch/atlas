import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_intelligence/domain/models/atlas_executive_intelligence_data.dart';

class AtlasExecutiveIntelligenceScreen extends StatelessWidget {
  const AtlasExecutiveIntelligenceScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasExecutiveIntelligenceData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Inteligência Executiva',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: data.hasData
                ? ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _IntelligenceHero(data: data),
                      if (data.mainRootCause != null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Principal causa-raiz',
                          subtitle:
                              'Hipótese mais relevante segundo o cruzamento das análises.',
                        ),
                        const SizedBox(height: 12),
                        _RootCauseCard(
                          item: data.mainRootCause!,
                          onOpenFarm: onOpenFarm,
                        ),
                      ],
                      if (data.topPriority != null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Prioridade executiva',
                          subtitle:
                              'Decisão com maior combinação de impacto e confiança.',
                        ),
                        const SizedBox(height: 12),
                        _PriorityCard(
                          item: data.topPriority!,
                          onOpenFarm: onOpenFarm,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Causas-raiz prováveis',
                        subtitle:
                            'Gargalos e hipóteses consolidadas pelo motor.',
                      ),
                      const SizedBox(height: 12),
                      _RootCauseList(
                        items: data.rootCauses,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Efeitos em cadeia',
                        subtitle:
                            'Relações entre indicadores que podem amplificar resultados.',
                      ),
                      const SizedBox(height: 12),
                      _CascadeList(items: data.cascadeEffects),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Consequências futuras',
                        subtitle:
                            'Riscos e impactos prováveis se a tendência atual continuar.',
                      ),
                      const SizedBox(height: 12),
                      _ConsequenceList(
                        items: data.consequences,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Ranking de prioridades',
                        subtitle:
                            'Ações ordenadas por impacto, urgência e confiança.',
                      ),
                      const SizedBox(height: 12),
                      _PriorityList(
                        items: data.priorities,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Insights consolidados',
                        subtitle:
                            'Síntese das principais descobertas do motor.',
                      ),
                      const SizedBox(height: 12),
                      _InsightList(
                        items: data.insights,
                        onOpenFarm: onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyView(),
          ),
        ),
      ),
    );
  }
}

class _IntelligenceHero extends StatelessWidget {
  const _IntelligenceHero({required this.data});

  final AtlasExecutiveIntelligenceData data;

  @override
  Widget build(BuildContext context) {
    final color = _maturityColor(data.maturity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071A2B), Color(0xFF173F5F), Color(0xFF20639B)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.psychology_alt_outlined,
                    color: Color(0xFFB3E5FC),
                    size: 32,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Executive Intelligence Engine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(label: 'Causas', value: data.rootCauses.length),
                  _HeroMetric(
                    label: 'Efeitos',
                    value: data.cascadeEffects.length,
                  ),
                  _HeroMetric(
                    label: 'Consequências',
                    value: data.consequences.length,
                  ),
                  _HeroMetric(
                    label: 'Prioridades',
                    value: data.priorities.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 225,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.intelligenceScore.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  atlasExecutiveIntelligenceMaturityLabel(data.maturity),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: data.intelligenceScore / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 20), side],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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

class _RootCauseCard extends StatelessWidget {
  const _RootCauseCard({required this.item, required this.onOpenFarm});

  final AtlasExecutiveRootCause item;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(item.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search_outlined, color: color, size: 29),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${item.confidencePercent.toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 10),
            ...item.evidences.map((evidence) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '• $evidence',
                  style: const TextStyle(color: Colors.black54),
                ),
              );
            }),
            const SizedBox(height: 9),
            Text(
              item.recommendation,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                label: const Text('Abrir fazenda'),
                onPressed: () {
                  onOpenFarm!(item.farmName);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.item, required this.onOpenFarm});

  final AtlasExecutivePriority item;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(item.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    '${item.position}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${item.priorityScore.toStringAsFixed(0)}/100',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Impacto esperado: '
              'R\$ ${item.expectedFinancialImpact.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            Text(
              'Prazo recomendado: ${item.deadlineDays} dias · '
              'Confiança: ${item.confidencePercent.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.black54),
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                label: const Text('Abrir fazenda'),
                onPressed: () {
                  onOpenFarm!(item.farmName);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RootCauseList extends StatelessWidget {
  const _RootCauseList({required this.items, required this.onOpenFarm});

  final List<AtlasExecutiveRootCause> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = _severityColor(item.severity);

        return Card(
          child: ListTile(
            leading: Icon(Icons.search_outlined, color: color),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${item.confidencePercent.toStringAsFixed(0)}% de confiança',
            ),
            trailing: Text(
              atlasExecutiveIntelligenceSeverityLabel(item.severity),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

class _CascadeList extends StatelessWidget {
  const _CascadeList({required this.items});

  final List<AtlasExecutiveCascadeEffect> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = item.direction == AtlasExecutiveCascadeDirection.negative
            ? const Color(0xFFC62828)
            : const Color(0xFF1B5E20);

        return Card(
          child: ListTile(
            leading: Icon(Icons.account_tree_outlined, color: color),
            title: Text(
              '${item.sourceTitle} → '
              '${item.targetTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.explanation),
            trailing: Text(
              '${item.strengthPercent.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ConsequenceList extends StatelessWidget {
  const _ConsequenceList({required this.items, required this.onOpenFarm});

  final List<AtlasExecutiveConsequence> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = _severityColor(item.severity);

        return Card(
          child: ListTile(
            leading: Icon(Icons.auto_graph_outlined, color: color),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.farmName} · horizonte de '
              '${item.horizonDays} dias\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.probabilityPercent.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

class _PriorityList extends StatelessWidget {
  const _PriorityList({required this.items, required this.onOpenFarm});

  final List<AtlasExecutivePriority> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = _severityColor(item.severity);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                '${item.position}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.farmName} · ${item.deadlineDays} dias\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              '{item.priorityScore.toStringAsFixed(0)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

class _InsightList extends StatelessWidget {
  const _InsightList({required this.items, required this.onOpenFarm});

  final List<AtlasExecutiveInsight> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = _insightPriorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: Icon(Icons.lightbulb_outline, color: color),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasExecutiveInsightTypeLabel(item.type)} · '
              '${item.farmName}\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.confidencePercent.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            onTap: onOpenFarm == null || item.farmName == 'Operação'
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
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
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
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma inteligência executiva disponível.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

Color _maturityColor(AtlasExecutiveIntelligenceMaturity maturity) {
  switch (maturity) {
    case AtlasExecutiveIntelligenceMaturity.initial:
      return const Color(0xFFEF9A9A);

    case AtlasExecutiveIntelligenceMaturity.developing:
      return const Color(0xFFFFCC80);

    case AtlasExecutiveIntelligenceMaturity.structured:
      return const Color(0xFF90CAF9);

    case AtlasExecutiveIntelligenceMaturity.advanced:
      return const Color(0xFFA5D6A7);

    case AtlasExecutiveIntelligenceMaturity.autonomous:
      return const Color(0xFF80CBC4);
  }
}

Color _severityColor(AtlasExecutiveIntelligenceSeverity severity) {
  switch (severity) {
    case AtlasExecutiveIntelligenceSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveIntelligenceSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveIntelligenceSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveIntelligenceSeverity.critical:
      return const Color(0xFFC62828);
  }
}

Color _insightPriorityColor(AtlasExecutiveInsightPriority priority) {
  switch (priority) {
    case AtlasExecutiveInsightPriority.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveInsightPriority.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveInsightPriority.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveInsightPriority.critical:
      return const Color(0xFFC62828);
  }
}
