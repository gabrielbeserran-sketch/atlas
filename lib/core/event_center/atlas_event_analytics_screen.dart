import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_analytics_data.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_analytics_service.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_service.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventAnalyticsScreen extends StatefulWidget {
  const AtlasEventAnalyticsScreen({super.key});

  @override
  State<AtlasEventAnalyticsScreen> createState() {
    return _AtlasEventAnalyticsScreenState();
  }
}

class _AtlasEventAnalyticsScreenState extends State<AtlasEventAnalyticsScreen> {
  final AtlasEventAnalyticsService service = const AtlasEventAnalyticsService();

  bool isLoading = true;
  AtlasEventAnalyticsData? data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AtlasEventLogService.instance.load();

    final result = service.build(
      entries: AtlasEventLogService.instance.entries,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      data = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = data;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Event Analytics',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar análise',
            onPressed: isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : current == null || !current.hasData
          ? const _EmptyAnalyticsView()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _AnalyticsHero(data: current),
                      const SizedBox(height: 20),
                      _MetricGrid(data: current),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Tendência dos últimos 30 dias',
                        subtitle: 'Evolução diária dos eventos registrados.',
                      ),
                      const SizedBox(height: 12),
                      _TrendChart(items: current.dailyTrend),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Módulos mais ativos',
                        subtitle: 'Distribuição das ocorrências por módulo.',
                      ),
                      const SizedBox(height: 12),
                      _RankingList(
                        items: current.moduleDistribution.take(10).toList(),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Fazendas com mais ocorrências',
                        subtitle: 'Ranking por volume de eventos.',
                      ),
                      const SizedBox(height: 12),
                      _RankingList(
                        items: current.farmDistribution.take(10).toList(),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Tipos mais frequentes',
                        subtitle: 'Eventos que mais se repetem no histórico.',
                      ),
                      const SizedBox(height: 12),
                      _TypeRankingList(
                        items: current.typeDistribution.take(10).toList(),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Padrões críticos recorrentes',
                        subtitle:
                            'Ocorrências de alta prioridade que se repetiram.',
                      ),
                      const SizedBox(height: 12),
                      _CriticalPatternList(
                        items: current.recurringCriticalEvents,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Recomendações',
                        subtitle: 'Ações sugeridas com base no histórico.',
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

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({required this.data});

  final AtlasEventAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF14334A), Color(0xFF1F5A73)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: Color(0xFFB3E5FC),
            size: 38,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inteligência do histórico de eventos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${data.totalEvents} eventos analisados, '
                  '${data.criticalEvents} críticos e '
                  '${data.highPriorityEvents} de alta prioridade.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.data});

  final AtlasEventAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', data.totalEvents, Icons.event_note_outlined),
      ('Últimos 7 dias', data.last7DaysEvents, Icons.date_range_outlined),
      ('Últimos 30 dias', data.last30DaysEvents, Icons.calendar_month_outlined),
      ('Críticos', data.criticalEvents, Icons.error_outline),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 600
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

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
                      Icon(item.$3, color: const Color(0xFF1565C0)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.$1,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
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

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.items});

  final List<AtlasEventAnalyticsDailyPoint> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<int>(
      1,
      (current, item) => item.total > current ? item.total : current,
    );

    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items.map((item) {
              final height = item.total / maxValue * 150;

              return Expanded(
                child: Tooltip(
                  message:
                      '${item.date.day}/${item.date.month}: '
                      '${item.total} eventos',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: height < 4 ? 4 : height,
                      decoration: BoxDecoration(
                        color: item.critical > 0
                            ? const Color(0xFFC62828)
                            : item.high > 0
                            ? const Color(0xFFEF6C00)
                            : const Color(0xFF1565C0),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.items});

  final List<AtlasEventAnalyticsRankingItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Card(
      child: Column(
        children: items.map((item) {
          return ListTile(
            leading: CircleAvatar(child: Text(item.position.toString())),
            title: Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: LinearProgressIndicator(
              value: item.percent / 100,
              minHeight: 7,
            ),
            trailing: Text(
              '${item.count} · '
              '${item.percent.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TypeRankingList extends StatelessWidget {
  const _TypeRankingList({required this.items});

  final List<AtlasEventAnalyticsTypeItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Card(
      child: Column(
        children: items.map((item) {
          return ListTile(
            leading: CircleAvatar(child: Text(item.position.toString())),
            title: Text(
              atlasEventTypeLabel(item.type),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '${item.count} · '
              '${item.percent.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CriticalPatternList extends StatelessWidget {
  const _CriticalPatternList({required this.items});

  final List<AtlasEventAnalyticsCriticalPattern> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection(
        message: 'Nenhum padrão crítico recorrente identificado.',
      );
    }

    return Column(
      children: items.map((item) {
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.warning_amber_outlined,
              color: Color(0xFFC62828),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.sourceModule} · '
              '${item.farmName} · '
              '${item.count} ocorrências',
            ),
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
            subtitle: Text(
              '${item.description}\n'
              '${item.reason}',
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
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

class _EmptyAnalyticsView extends StatelessWidget {
  const _EmptyAnalyticsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Ainda não existem eventos suficientes para análise.',
        style: TextStyle(color: Colors.black54),
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
