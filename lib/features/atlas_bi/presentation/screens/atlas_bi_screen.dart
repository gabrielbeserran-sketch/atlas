import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';

class AtlasBiScreen extends StatefulWidget {
  const AtlasBiScreen({required this.data, this.onOpenFarm, super.key});

  final AtlasBiData data;

  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasBiScreen> createState() {
    return _AtlasBiScreenState();
  }
}

class _AtlasBiScreenState extends State<AtlasBiScreen> {
  String? selectedFarm;

  AtlasBiCategory? selectedCategory;

  AtlasBiStatus? selectedStatus;

  AtlasBiData get data => widget.data;

  List<String> get farms {
    final result = data.indicators.map((item) => item.farmName).toSet().toList()
      ..sort();

    return result;
  }

  List<AtlasBiIndicator> get filteredIndicators {
    return data.indicators.where((item) {
      if (selectedFarm != null && item.farmName != selectedFarm) {
        return false;
      }

      if (selectedCategory != null && item.category != selectedCategory) {
        return false;
      }

      if (selectedStatus != null && item.status != selectedStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas BI',
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
                      _BiHero(data: data),
                      const SizedBox(height: 22),
                      _BiFilters(
                        farms: farms,
                        selectedFarm: selectedFarm,
                        selectedCategory: selectedCategory,
                        selectedStatus: selectedStatus,
                        onFarmChanged: (value) {
                          setState(() {
                            selectedFarm = value;
                          });
                        },
                        onCategoryChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        onStatusChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Ranking das fazendas',
                        subtitle:
                            'Comparação consolidada do desempenho analítico.',
                      ),
                      const SizedBox(height: 13),
                      _RankingList(
                        rankings: data.rankings,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Indicadores analíticos',
                        subtitle: 'Valores, metas, tendências e histórico.',
                      ),
                      const SizedBox(height: 13),
                      _IndicatorList(
                        indicators: filteredIndicators,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Insights automáticos',
                        subtitle:
                            'Riscos, oportunidades e recomendações geradas a partir dos dados.',
                      ),
                      const SizedBox(height: 13),
                      _InsightList(insights: data.insights),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyBiView(),
          ),
        ),
      ),
    );
  }
}

class _BiHero extends StatelessWidget {
  const _BiHero({required this.data});

  final AtlasBiData data;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F33), Color(0xFF123A5A), Color(0xFF1E5F8A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFF80DEEA),
                    size: 31,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Business Intelligence',
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
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    label: 'Indicadores',
                    value: data.indicators.length,
                  ),
                  _HeroChip(label: 'Fazendas', value: data.rankings.length),
                  _HeroChip(
                    label: 'Críticos',
                    value: data.criticalIndicators.length,
                  ),
                  _HeroChip(label: 'Insights', value: data.insights.length),
                ],
              ),
            ],
          );

          final side = Container(
            width: 220,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.score.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  atlasBiStatusLabel(data.status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: data.score / 100,
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
              children: [info, const SizedBox(height: 20), side],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: info),
              const SizedBox(width: 24),
              side,
            ],
          );
        },
      ),
    );
  }
}

class _BiFilters extends StatelessWidget {
  const _BiFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.onFarmChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
  });

  final List<String> farms;

  final String? selectedFarm;
  final AtlasBiCategory? selectedCategory;
  final AtlasBiStatus? selectedStatus;

  final ValueChanged<String?> onFarmChanged;
  final ValueChanged<AtlasBiCategory?> onCategoryChanged;
  final ValueChanged<AtlasBiStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedFarm,
                decoration: const InputDecoration(labelText: 'Fazenda'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as fazendas'),
                  ),
                  ...farms.map((farm) {
                    return DropdownMenuItem(value: farm, child: Text(farm));
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<AtlasBiCategory?>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as categorias'),
                  ),
                  ...AtlasBiCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(atlasBiCategoryLabel(category)),
                    );
                  }),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<AtlasBiStatus?>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Situação'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as situações'),
                  ),
                  ...AtlasBiStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(atlasBiStatusLabel(status)),
                    );
                  }),
                ],
                onChanged: onStatusChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.rankings, required this.onOpenFarm});

  final List<AtlasBiFarmRanking> rankings;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rankings.map((item) {
        final color = _statusColor(item.status);

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
              item.farmName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.positiveIndicators} positivos · '
              '${item.criticalIndicators} críticos',
            ),
            trailing: Text(
              item.score.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontSize: 20,
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

class _IndicatorList extends StatelessWidget {
  const _IndicatorList({required this.indicators, required this.onOpenFarm});

  final List<AtlasBiIndicator> indicators;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (indicators.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: indicators.map((item) {
        final color = _statusColor(item.status);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_trendIcon(item.trend), color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${item.farmName} · '
                            '${atlasBiCategoryLabel(item.category)}',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatValue(item.currentValue, item.unit),
                      style: TextStyle(
                        color: color,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  minHeight: 8,
                  value: item.targetAchievementPercent / 120,
                  backgroundColor: color.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      label: atlasBiTrendLabel(item.trend),
                      color: color,
                    ),
                    _InfoChip(
                      label:
                          '${item.targetAchievementPercent.toStringAsFixed(0)}% da meta',
                      color: const Color(0xFF1565C0),
                    ),
                    _InfoChip(
                      label:
                          '${item.variationPercent >= 0 ? '+' : ''}'
                          '${item.variationPercent.toStringAsFixed(1)}%',
                      color: const Color(0xFF6A1B9A),
                    ),
                    if (onOpenFarm != null)
                      ActionChip(
                        label: const Text('Abrir fazenda'),
                        onPressed: () {
                          onOpenFarm!(item.farmName);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InsightList extends StatelessWidget {
  const _InsightList({required this.insights});

  final List<AtlasBiInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: insights.map((item) {
        final color = _priorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: Icon(_insightIcon(item.type), color: color),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.description}\n'
              'Recomendação: '
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.confidencePercent.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
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
            'Nenhum item encontrado com os filtros atuais.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _EmptyBiView extends StatelessWidget {
  const _EmptyBiView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum dado analítico disponível.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

Color _statusColor(AtlasBiStatus status) {
  switch (status) {
    case AtlasBiStatus.excellent:
      return const Color(0xFF1B5E20);

    case AtlasBiStatus.adequate:
      return const Color(0xFF2E7D32);

    case AtlasBiStatus.attention:
      return const Color(0xFFEF6C00);

    case AtlasBiStatus.critical:
      return const Color(0xFFC62828);
  }
}

Color _priorityColor(AtlasBiPriority priority) {
  switch (priority) {
    case AtlasBiPriority.low:
      return const Color(0xFF2E7D32);

    case AtlasBiPriority.medium:
      return const Color(0xFF1565C0);

    case AtlasBiPriority.high:
      return const Color(0xFFEF6C00);

    case AtlasBiPriority.critical:
      return const Color(0xFFC62828);
  }
}

IconData _trendIcon(AtlasBiTrend trend) {
  switch (trend) {
    case AtlasBiTrend.strongUp:
    case AtlasBiTrend.up:
      return Icons.trending_up;

    case AtlasBiTrend.stable:
      return Icons.trending_flat;

    case AtlasBiTrend.down:
    case AtlasBiTrend.strongDown:
      return Icons.trending_down;

    case AtlasBiTrend.unavailable:
      return Icons.horizontal_rule;
  }
}

IconData _insightIcon(AtlasBiInsightType type) {
  switch (type) {
    case AtlasBiInsightType.opportunity:
      return Icons.trending_up_outlined;

    case AtlasBiInsightType.risk:
      return Icons.warning_amber_outlined;

    case AtlasBiInsightType.anomaly:
      return Icons.error_outline;

    case AtlasBiInsightType.trend:
      return Icons.show_chart_outlined;

    case AtlasBiInsightType.recommendation:
      return Icons.lightbulb_outline;
  }
}

String _formatValue(double value, String unit) {
  final decimals = value == value.roundToDouble() ? 0 : 1;

  if (unit == 'R\$') {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  if (unit.isEmpty) {
    return value.toStringAsFixed(decimals);
  }

  return '${value.toStringAsFixed(decimals)} $unit';
}
