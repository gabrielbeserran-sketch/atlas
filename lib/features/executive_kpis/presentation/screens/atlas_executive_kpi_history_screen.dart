import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi_history.dart';

class AtlasExecutiveKpiHistoryScreen extends StatefulWidget {
  const AtlasExecutiveKpiHistoryScreen({required this.history, super.key});

  final AtlasExecutiveKpiHistorySummary history;

  @override
  State<AtlasExecutiveKpiHistoryScreen> createState() {
    return _AtlasExecutiveKpiHistoryScreenState();
  }
}

class _AtlasExecutiveKpiHistoryScreenState
    extends State<AtlasExecutiveKpiHistoryScreen> {
  String? selectedFarm;
  AtlasExecutiveKpiCategory? selectedCategory;
  _KpiHistoryPeriod selectedPeriod = _KpiHistoryPeriod.all;

  AtlasExecutiveKpiHistorySummary get history => widget.history;

  List<String> get farmNames {
    final names = history.series.map((item) => item.farmName).toSet().toList()
      ..sort();

    return names;
  }

  List<AtlasExecutiveKpiHistorySeries> get filteredSeries {
    final now = DateTime.now();

    return history.series
        .where((series) {
          if (selectedFarm != null && series.farmName != selectedFarm) {
            return false;
          }

          if (selectedCategory != null && series.category != selectedCategory) {
            return false;
          }

          final firstDate = _periodStart(selectedPeriod, now);

          if (firstDate == null) {
            return true;
          }

          return series.points.any((point) {
            return !point.recordedAt.isBefore(firstDate);
          });
        })
        .map((series) {
          final firstDate = _periodStart(selectedPeriod, now);

          if (firstDate == null) {
            return series;
          }

          final points = series.points.where((point) {
            return !point.recordedAt.isBefore(firstDate);
          }).toList();

          if (points.isEmpty) {
            return series;
          }

          final current = points.last;
          final previous = points.length > 1 ? points[points.length - 2] : null;

          final variation = previous == null || previous.value == 0
              ? 0.0
              : (current.value - previous.value) / previous.value.abs() * 100;

          return AtlasExecutiveKpiHistorySeries(
            kpiId: series.kpiId,
            farmName: series.farmName,
            title: series.title,
            category: series.category,
            unit: series.unit,
            points: points,
            currentValue: current.value,
            previousValue: previous?.value,
            variationPercent: variation,
            trend: _trendFromVariation(variation, previous != null),
          );
        })
        .toList()
      ..sort(
        (first, second) => second.variationPercent.abs().compareTo(
          first.variationPercent.abs(),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final series = filteredSeries;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Evolução dos Indicadores',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: history.hasHistory
                ? ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _HistoryHero(history: history),
                      const SizedBox(height: 22),
                      _HistoryFilters(
                        farms: farmNames,
                        selectedFarm: selectedFarm,
                        selectedCategory: selectedCategory,
                        selectedPeriod: selectedPeriod,
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
                        onPeriodChanged: (value) {
                          setState(() {
                            selectedPeriod = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Séries históricas',
                        subtitle:
                            'Evolução dos indicadores ao longo do período selecionado.',
                      ),
                      const SizedBox(height: 12),
                      if (series.isEmpty)
                        const _EmptyFilteredHistory()
                      else
                        ...series.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _HistorySeriesCard(series: item),
                          );
                        }),
                      const SizedBox(height: 30),
                    ],
                  )
                : const _EmptyHistoryView(),
          ),
        ),
      ),
    );
  }

  DateTime? _periodStart(_KpiHistoryPeriod period, DateTime now) {
    switch (period) {
      case _KpiHistoryPeriod.days30:
        return now.subtract(const Duration(days: 30));

      case _KpiHistoryPeriod.days90:
        return now.subtract(const Duration(days: 90));

      case _KpiHistoryPeriod.year:
        return DateTime(now.year, 1, 1);

      case _KpiHistoryPeriod.all:
        return null;
    }
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({required this.history});

  final AtlasExecutiveKpiHistorySummary history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17324D), Color(0xFF244F73), Color(0xFF326C91)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.show_chart_outlined,
                color: Color(0xFFFFD180),
                size: 31,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Histórico de KPIs',
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
            history.summary,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _HeroMetric(label: 'Séries', value: history.series.length),
              _HeroMetric(label: 'Em melhora', value: history.improvingCount),
              _HeroMetric(label: 'Estáveis', value: history.stableCount),
              _HeroMetric(label: 'Em piora', value: history.worseningCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedCategory,
    required this.selectedPeriod,
    required this.onFarmChanged,
    required this.onCategoryChanged,
    required this.onPeriodChanged,
  });

  final List<String> farms;
  final String? selectedFarm;
  final AtlasExecutiveKpiCategory? selectedCategory;
  final _KpiHistoryPeriod selectedPeriod;

  final ValueChanged<String?> onFarmChanged;
  final ValueChanged<AtlasExecutiveKpiCategory?> onCategoryChanged;
  final ValueChanged<_KpiHistoryPeriod> onPeriodChanged;

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
              width: 270,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedFarm,
                decoration: const InputDecoration(
                  labelText: 'Fazenda',
                  prefixIcon: Icon(Icons.agriculture_outlined),
                ),
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
              width: 250,
              child: DropdownButtonFormField<AtlasExecutiveKpiCategory?>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as categorias'),
                  ),
                  ...AtlasExecutiveKpiCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(atlasExecutiveKpiCategoryLabel(category)),
                    );
                  }),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<_KpiHistoryPeriod>(
                initialValue: selectedPeriod,
                decoration: const InputDecoration(
                  labelText: 'Período',
                  prefixIcon: Icon(Icons.date_range_outlined),
                ),
                items: _KpiHistoryPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(_periodLabel(period)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onPeriodChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySeriesCard extends StatelessWidget {
  const _HistorySeriesCard({required this.series});

  final AtlasExecutiveKpiHistorySeries series;

  @override
  Widget build(BuildContext context) {
    final color = _trendColor(series.trend);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_trendIcon(series.trend), color: color),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${series.farmName} · '
                        '${atlasExecutiveKpiCategoryLabel(series.category)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatValue(series.currentValue, series.unit),
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      series.hasHistory
                          ? '${series.variationPercent >= 0 ? '+' : ''}'
                                '${series.variationPercent.toStringAsFixed(1)}%'
                          : 'Sem comparação',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _KpiLineChartPainter(
                  points: series.points,
                  lineColor: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HistoryChip(
                  label: '${series.points.length} registros',
                  color: const Color(0xFF1565C0),
                ),
                _HistoryChip(
                  label: atlasExecutiveKpiTrendLabel(series.trend),
                  color: color,
                ),
                if (series.firstRecordedAt != null)
                  _HistoryChip(
                    label:
                        '${_formatDate(series.firstRecordedAt!)} a '
                        '${_formatDate(series.lastRecordedAt!)}',
                    color: const Color(0xFF6A1B9A),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiLineChartPainter extends CustomPainter {
  const _KpiLineChartPainter({required this.points, required this.lineColor});

  final List<AtlasExecutiveKpiHistoryPoint> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final padding = 14.0;
    final chartWidth = math.max(1.0, size.width - padding * 2);
    final chartHeight = math.max(1.0, size.height - padding * 2);

    for (var index = 0; index <= 4; index++) {
      final y = padding + chartHeight * index / 4;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        axisPaint,
      );
    }

    if (points.isEmpty) {
      return;
    }

    final values = points.map((item) => item.value).toList();

    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);

    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    }

    final path = Path();

    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width / 2
          : padding + chartWidth * index / (points.length - 1);

      final normalized =
          (points[index].value - minValue) / (maxValue - minValue);

      final y = padding + chartHeight * (1 - normalized);

      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    if (points.length > 1) {
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KpiLineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.label, required this.color});

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

class _EmptyFilteredHistory extends StatelessWidget {
  const _EmptyFilteredHistory();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nenhuma série encontrada com os filtros atuais.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_outlined, size: 58, color: Colors.black38),
            SizedBox(height: 14),
            Text(
              'Histórico ainda insuficiente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'É necessário registrar KPIs em pelo menos dois dias para gerar gráficos de evolução.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

enum _KpiHistoryPeriod { days30, days90, year, all }

String _periodLabel(_KpiHistoryPeriod period) {
  switch (period) {
    case _KpiHistoryPeriod.days30:
      return 'Últimos 30 dias';

    case _KpiHistoryPeriod.days90:
      return 'Últimos 90 dias';

    case _KpiHistoryPeriod.year:
      return 'Ano atual';

    case _KpiHistoryPeriod.all:
      return 'Todo o histórico';
  }
}

AtlasExecutiveKpiTrend _trendFromVariation(double variation, bool hasPrevious) {
  if (!hasPrevious) {
    return AtlasExecutiveKpiTrend.unavailable;
  }

  if (variation >= 10) {
    return AtlasExecutiveKpiTrend.strongUp;
  }

  if (variation >= 2) {
    return AtlasExecutiveKpiTrend.up;
  }

  if (variation <= -10) {
    return AtlasExecutiveKpiTrend.strongDown;
  }

  if (variation <= -2) {
    return AtlasExecutiveKpiTrend.down;
  }

  return AtlasExecutiveKpiTrend.stable;
}

Color _trendColor(AtlasExecutiveKpiTrend trend) {
  switch (trend) {
    case AtlasExecutiveKpiTrend.strongUp:
    case AtlasExecutiveKpiTrend.up:
      return const Color(0xFF1B5E20);

    case AtlasExecutiveKpiTrend.stable:
      return const Color(0xFF1565C0);

    case AtlasExecutiveKpiTrend.down:
    case AtlasExecutiveKpiTrend.strongDown:
      return const Color(0xFFC62828);

    case AtlasExecutiveKpiTrend.unavailable:
      return const Color(0xFF616161);
  }
}

IconData _trendIcon(AtlasExecutiveKpiTrend trend) {
  switch (trend) {
    case AtlasExecutiveKpiTrend.strongUp:
    case AtlasExecutiveKpiTrend.up:
      return Icons.trending_up;

    case AtlasExecutiveKpiTrend.stable:
      return Icons.trending_flat;

    case AtlasExecutiveKpiTrend.down:
    case AtlasExecutiveKpiTrend.strongDown:
      return Icons.trending_down;

    case AtlasExecutiveKpiTrend.unavailable:
      return Icons.horizontal_rule;
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
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
