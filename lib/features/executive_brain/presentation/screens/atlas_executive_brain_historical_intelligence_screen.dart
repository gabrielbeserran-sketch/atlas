import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_analytics_data.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_analytics_service.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_service.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';

class AtlasExecutiveBrainHistoricalIntelligenceScreen extends StatefulWidget {
  const AtlasExecutiveBrainHistoricalIntelligenceScreen({
    required this.brainData,
    super.key,
  });

  final AtlasExecutiveBrainData brainData;

  @override
  State<AtlasExecutiveBrainHistoricalIntelligenceScreen> createState() {
    return _AtlasExecutiveBrainHistoricalIntelligenceScreenState();
  }
}

class _AtlasExecutiveBrainHistoricalIntelligenceScreenState
    extends State<AtlasExecutiveBrainHistoricalIntelligenceScreen> {
  final AtlasEventAnalyticsService analyticsService =
      const AtlasEventAnalyticsService();

  bool isLoading = true;
  AtlasEventAnalyticsData? analytics;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
    });

    await AtlasEventLogService.instance.load();

    final result = analyticsService.build(
      entries: AtlasEventLogService.instance.entries,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      analytics = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = analytics;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Inteligência histórica',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : current == null || !current.hasData
          ? const _EmptyHistoricalView()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _HistoricalHero(
                        brainData: widget.brainData,
                        analytics: current,
                      ),
                      const SizedBox(height: 20),
                      _EvidenceMetricGrid(analytics: current),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Influência no Executive Brain',
                        subtitle:
                            'Como o histórico altera score, confiança e classificação.',
                      ),
                      const SizedBox(height: 12),
                      _BrainInfluenceCard(
                        brainData: widget.brainData,
                        analytics: current,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Padrões recorrentes utilizados',
                        subtitle:
                            'Ocorrências repetidas que formam memória executiva.',
                      ),
                      const SizedBox(height: 12),
                      _RecurringPatternList(
                        items: current.recurringCriticalEvents,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Memórias históricas no cérebro',
                        subtitle:
                            'Aprendizados, riscos e padrões presentes na análise atual.',
                      ),
                      const SizedBox(height: 12),
                      _HistoricalMemoryList(
                        items: widget.brainData.memoryInsights
                            .where(
                              (item) =>
                                  item.type ==
                                      AtlasExecutiveMemoryInsightType
                                          .recurringPattern ||
                                  item.type ==
                                      AtlasExecutiveMemoryInsightType
                                          .historicalRisk ||
                                  item.type ==
                                      AtlasExecutiveMemoryInsightType
                                          .decisionLesson,
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Recomendações do histórico',
                        subtitle:
                            'Ações sugeridas a partir das ocorrências acumuladas.',
                      ),
                      const SizedBox(height: 12),
                      _RecommendationList(items: current.recommendations),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _HistoricalHero extends StatelessWidget {
  const _HistoricalHero({required this.brainData, required this.analytics});

  final AtlasExecutiveBrainData brainData;
  final AtlasEventAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF18364B), Color(0xFF245D72)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_edu_outlined,
            color: Color(0xFFB3E5FC),
            size: 39,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Memória histórica aplicada à decisão',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${analytics.totalEvents} eventos sustentam a análise atual, '
                  'com ${analytics.recurringCriticalEvents.length} padrões '
                  'recorrentes e ${brainData.memoryInsights.length} memórias executivas.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceMetricGrid extends StatelessWidget {
  const _EvidenceMetricGrid({required this.analytics});

  final AtlasEventAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        label: 'Eventos analisados',
        value: analytics.totalEvents.toString(),
        icon: Icons.event_note_outlined,
      ),
      _MetricData(
        label: 'Últimos 30 dias',
        value: analytics.last30DaysEvents.toString(),
        icon: Icons.calendar_month_outlined,
      ),
      _MetricData(
        label: 'Alta prioridade',
        value: analytics.highPriorityEvents.toString(),
        icon: Icons.warning_amber_outlined,
      ),
      _MetricData(
        label: 'Críticos',
        value: analytics.criticalEvents.toString(),
        icon: Icons.error_outline,
      ),
      _MetricData(
        label: 'Padrões recorrentes',
        value: analytics.recurringCriticalEvents.length.toString(),
        icon: Icons.repeat,
      ),
      _MetricData(
        label: 'Recomendações',
        value: analytics.recommendations.length.toString(),
        icon: Icons.lightbulb_outline,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;

        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(child: Icon(item.icon)),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.label,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
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

class _BrainInfluenceCard extends StatelessWidget {
  const _BrainInfluenceCard({required this.brainData, required this.analytics});

  final AtlasExecutiveBrainData brainData;
  final AtlasEventAnalyticsData analytics;

  double get riskPenalty {
    return (analytics.criticalEvents * 1.8 +
            analytics.highPriorityEvents * 0.45 +
            analytics.recurringCriticalEvents.length * 1.4)
        .clamp(0.0, 22.0)
        .toDouble();
  }

  double get evidenceBonus {
    if (analytics.totalEvents < 5) {
      return 0;
    }

    final volumeBonus = analytics.totalEvents >= 100
        ? 7.0
        : analytics.totalEvents >= 30
        ? 5.0
        : 3.0;

    return (volumeBonus + (analytics.last30DaysEvents > 0 ? 2.0 : 0.0))
        .clamp(0.0, 9.0)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            _InfluenceItem(
              title: 'Score atual',
              value: brainData.brainScore.toStringAsFixed(1),
              description: 'Resultado após aplicar o risco histórico.',
              icon: Icons.speed_outlined,
            ),
            _InfluenceItem(
              title: 'Penalidade histórica',
              value: '-${riskPenalty.toStringAsFixed(1)}',
              description: 'Redução provocada por riscos e recorrências.',
              icon: Icons.trending_down,
            ),
            _InfluenceItem(
              title: 'Confiança atual',
              value: '${brainData.confidencePercent.toStringAsFixed(1)}%',
              description: 'Confiança após considerar as evidências.',
              icon: Icons.verified_outlined,
            ),
            _InfluenceItem(
              title: 'Bônus de evidência',
              value: '+${evidenceBonus.toStringAsFixed(1)}',
              description: 'Aumento baseado em volume e atualidade.',
              icon: Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfluenceItem extends StatelessWidget {
  const _InfluenceItem({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
  });

  final String title;
  final String value;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 235,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringPatternList extends StatelessWidget {
  const _RecurringPatternList({required this.items});

  final List<AtlasEventAnalyticsCriticalPattern> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection(
        message: 'Nenhum padrão crítico recorrente foi encontrado.',
      );
    }

    return Column(
      children: items.map((item) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFC62828).withValues(alpha: 0.12),
              child: const Icon(Icons.repeat, color: Color(0xFFC62828)),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.sourceModule} · ${item.farmName}\n'
              '${item.count} ocorrências · última em '
              '${_formatDate(item.lastOccurrence)}',
            ),
            isThreeLine: true,
            trailing: Text(
              '#${item.position}',
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HistoricalMemoryList extends StatelessWidget {
  const _HistoricalMemoryList({required this.items});

  final List<AtlasExecutiveMemoryInsight> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection(
        message: 'Nenhuma memória histórica foi adicionada ao cérebro.',
      );
    }

    return Column(
      children: items.map((item) {
        return Card(
          child: ExpansionTile(
            leading: Icon(
              _memoryIcon(item.type),
              color: _memoryColor(item.type),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasExecutiveMemoryInsightTypeLabel(item.type)} · '
              '${item.relevanceScore.toStringAsFixed(0)} pontos',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.description,
                  style: const TextStyle(height: 1.4),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recomendação: ${item.recommendation}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({required this.items});

  final List<AtlasEventAnalyticsRecommendation> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = _priorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                item.position.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${item.description}\n${item.reason}'),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
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
  const _EmptySection({this.message = 'Nenhum item disponível.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Text(message, style: const TextStyle(color: Colors.black54)),
        ),
      ),
    );
  }
}

class _EmptyHistoricalView extends StatelessWidget {
  const _EmptyHistoricalView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ainda não existem eventos suficientes para formar inteligência histórica.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}

Color _priorityColor(AtlasEventPriority priority) {
  switch (priority) {
    case AtlasEventPriority.low:
      return const Color(0xFF2E7D32);
    case AtlasEventPriority.normal:
      return const Color(0xFF1565C0);
    case AtlasEventPriority.high:
      return const Color(0xFFEF6C00);
    case AtlasEventPriority.critical:
      return const Color(0xFFC62828);
  }
}

Color _memoryColor(AtlasExecutiveMemoryInsightType type) {
  switch (type) {
    case AtlasExecutiveMemoryInsightType.recurringPattern:
      return const Color(0xFFEF6C00);
    case AtlasExecutiveMemoryInsightType.historicalRisk:
      return const Color(0xFFC62828);
    case AtlasExecutiveMemoryInsightType.repeatedOpportunity:
      return const Color(0xFF2E7D32);
    case AtlasExecutiveMemoryInsightType.decisionLesson:
      return const Color(0xFF1565C0);
    case AtlasExecutiveMemoryInsightType.missionLesson:
      return const Color(0xFF6A1B9A);
  }
}

IconData _memoryIcon(AtlasExecutiveMemoryInsightType type) {
  switch (type) {
    case AtlasExecutiveMemoryInsightType.recurringPattern:
      return Icons.repeat;
    case AtlasExecutiveMemoryInsightType.historicalRisk:
      return Icons.warning_amber_outlined;
    case AtlasExecutiveMemoryInsightType.repeatedOpportunity:
      return Icons.trending_up;
    case AtlasExecutiveMemoryInsightType.decisionLesson:
      return Icons.psychology_outlined;
    case AtlasExecutiveMemoryInsightType.missionLesson:
      return Icons.flag_outlined;
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}
