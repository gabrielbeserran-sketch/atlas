import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_benchmark.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/services/atlas_bi_benchmark_service.dart';

class AtlasBiBenchmarkScreen extends StatefulWidget {
  const AtlasBiBenchmarkScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasBiBenchmarkData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasBiBenchmarkScreen> createState() {
    return _AtlasBiBenchmarkScreenState();
  }
}

class _AtlasBiBenchmarkScreenState extends State<AtlasBiBenchmarkScreen> {
  final AtlasBiBenchmarkService service = const AtlasBiBenchmarkService();

  String? selectedFarm;
  AtlasBiCategory? selectedCategory;

  AtlasBiBenchmarkData get data {
    return widget.data;
  }

  List<AtlasBiBenchmarkOpportunity> get opportunities {
    return service.buildOpportunities(benchmark: data);
  }

  List<AtlasBiBenchmarkIndicator> get filteredIndicators {
    return data.indicators.where((item) {
      if (selectedCategory != null && item.category != selectedCategory) {
        return false;
      }

      if (selectedFarm != null &&
          !item.farmResults.any((result) => result.farmName == selectedFarm)) {
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
          'Benchmarking Atlas BI',
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
                      _BenchmarkHero(data: data),
                      const SizedBox(height: 22),
                      _BenchmarkFilters(
                        farms: data.farms.map((item) => item.farmName).toList(),
                        selectedFarm: selectedFarm,
                        selectedCategory: selectedCategory,
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
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Ranking comparativo',
                        subtitle:
                            'Posição, score e distância em relação à fazenda líder.',
                      ),
                      const SizedBox(height: 13),
                      _FarmRanking(
                        farms: data.farms,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Comparação por indicador',
                        subtitle:
                            'Referência interna, média e resultados de cada fazenda.',
                      ),
                      const SizedBox(height: 13),
                      if (filteredIndicators.isEmpty)
                        const _EmptySection()
                      else
                        ...filteredIndicators.map((indicator) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _IndicatorBenchmarkCard(
                              indicator: indicator,
                            ),
                          );
                        }),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Oportunidades de melhoria',
                        subtitle:
                            'Maiores distâncias em relação às referências internas.',
                      ),
                      const SizedBox(height: 13),
                      _OpportunityList(
                        opportunities: opportunities,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyBenchmarkView(),
          ),
        ),
      ),
    );
  }
}

class _BenchmarkHero extends StatelessWidget {
  const _BenchmarkHero({required this.data});

  final AtlasBiBenchmarkData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102027), Color(0xFF234E52), Color(0xFF3A7378)],
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
                    Icons.leaderboard_outlined,
                    color: Color(0xFFB2DFDB),
                    size: 31,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Benchmarking Interno',
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
                  _HeroMetric(label: 'Fazendas', value: data.farms.length),
                  _HeroMetric(
                    label: 'Indicadores',
                    value: data.indicators.length,
                  ),
                  _HeroMetric(label: 'Média', value: data.averageScore.round()),
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
                const Text(
                  'Líder',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  data.leadingFarmName ?? '—',
                  style: const TextStyle(
                    color: Color(0xFFB2DFDB),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${data.averageScore.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Média geral',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
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

class _BenchmarkFilters extends StatelessWidget {
  const _BenchmarkFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedCategory,
    required this.onFarmChanged,
    required this.onCategoryChanged,
  });

  final List<String> farms;
  final String? selectedFarm;
  final AtlasBiCategory? selectedCategory;

  final ValueChanged<String?> onFarmChanged;

  final ValueChanged<AtlasBiCategory?> onCategoryChanged;

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
          ],
        ),
      ),
    );
  }
}

class _FarmRanking extends StatelessWidget {
  const _FarmRanking({required this.farms, required this.onOpenFarm});

  final List<AtlasBiBenchmarkFarm> farms;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: farms.map((farm) {
        final color = _statusColor(farm.status);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                '${farm.position}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              farm.farmName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              farm.isLeader
                  ? 'Referência interna'
                  : '${farm.distanceFromLeader.toStringAsFixed(1)} pontos da líder',
            ),
            trailing: Text(
              farm.score.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onOpenFarm == null
                ? null
                : () {
                    onOpenFarm!(farm.farmName);
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _IndicatorBenchmarkCard extends StatelessWidget {
  const _IndicatorBenchmarkCard({required this.indicator});

  final AtlasBiBenchmarkIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.compare_arrows_outlined,
                  color: Color(0xFF234E52),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    indicator.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  atlasBiCategoryLabel(indicator.category),
                  style: const TextStyle(
                    color: Color(0xFF234E52),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Referência: ${indicator.bestFarmName ?? '—'} · '
              '${_formatValue(indicator.referenceValue, indicator.unit)}',
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Média: ${_formatValue(indicator.averageValue, indicator.unit)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 13),
            ...indicator.farmResults.map((result) {
              final color = _statusColor(result.status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.farmName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _formatValue(result.currentValue, indicator.unit),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 95,
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: result.targetAchievementPercent / 120,
                        backgroundColor: color.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OpportunityList extends StatelessWidget {
  const _OpportunityList({
    required this.opportunities,
    required this.onOpenFarm,
  });

  final List<AtlasBiBenchmarkOpportunity> opportunities;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: opportunities.map((item) {
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.trending_up_outlined,
              color: Color(0xFFEF6C00),
            ),
            title: Text(
              item.indicatorTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.farmName} · distância de '
              '${item.gapPercent.toStringAsFixed(1)} pontos da referência\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              _formatValue(item.referenceValue, item.unit),
              style: const TextStyle(
                color: Color(0xFF1B5E20),
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
            'Nenhum dado encontrado com os filtros atuais.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _EmptyBenchmarkView extends StatelessWidget {
  const _EmptyBenchmarkView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined, size: 58, color: Colors.black38),
            SizedBox(height: 14),
            Text(
              'Benchmarking indisponível',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'Cadastre indicadores em mais fazendas para gerar comparações.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
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
