import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_forecast.dart';

class AtlasBiForecastScreen extends StatefulWidget {
  const AtlasBiForecastScreen({required this.data, this.onOpenFarm, super.key});

  final AtlasBiForecastDashboardData data;

  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasBiForecastScreen> createState() {
    return _AtlasBiForecastScreenState();
  }
}

class _AtlasBiForecastScreenState extends State<AtlasBiForecastScreen> {
  String? selectedFarm;

  AtlasBiCategory? selectedCategory;

  AtlasBiForecastRisk? selectedRisk;

  AtlasBiForecastDashboardData get data {
    return widget.data;
  }

  List<String> get farms {
    final values = data.forecasts.map((item) => item.farmName).toSet().toList()
      ..sort();

    return values;
  }

  List<AtlasBiForecast> get filteredForecasts {
    return data.forecasts.where((item) {
      if (selectedFarm != null && item.farmName != selectedFarm) {
        return false;
      }

      if (selectedCategory != null && item.category != selectedCategory) {
        return false;
      }

      if (selectedRisk != null && item.risk != selectedRisk) {
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
          'Forecast Atlas BI',
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
                      _ForecastHero(data: data),
                      const SizedBox(height: 22),
                      _ForecastFilters(
                        farms: farms,
                        selectedFarm: selectedFarm,
                        selectedCategory: selectedCategory,
                        selectedRisk: selectedRisk,
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
                        onRiskChanged: (value) {
                          setState(() {
                            selectedRisk = value;
                          });
                        },
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Projeções dos indicadores',
                        subtitle:
                            'Tendência, valor projetado, confiança e probabilidade de atingir a meta.',
                      ),
                      const SizedBox(height: 13),
                      if (filteredForecasts.isEmpty)
                        const _EmptyFilteredView()
                      else
                        ...filteredForecasts.map((forecast) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ForecastCard(
                              forecast: forecast,
                              onOpenFarm: widget.onOpenFarm,
                            ),
                          );
                        }),
                      const SizedBox(height: 30),
                    ],
                  )
                : const _EmptyForecastView(),
          ),
        ),
      ),
    );
  }
}

class _ForecastHero extends StatelessWidget {
  const _ForecastHero({required this.data});

  final AtlasBiForecastDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161A30), Color(0xFF31304D), Color(0xFF54507A)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_graph_outlined,
                color: Color(0xFFB2EBF2),
                size: 31,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Inteligência Preditiva',
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
              _HeroMetric(label: 'Positivos', value: data.positiveCount),
              _HeroMetric(label: 'Estáveis', value: data.stableCount),
              _HeroMetric(label: 'Negativos', value: data.negativeCount),
              _HeroMetric(label: 'Alto risco', value: data.highRiskCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForecastFilters extends StatelessWidget {
  const _ForecastFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedCategory,
    required this.selectedRisk,
    required this.onFarmChanged,
    required this.onCategoryChanged,
    required this.onRiskChanged,
  });

  final List<String> farms;

  final String? selectedFarm;
  final AtlasBiCategory? selectedCategory;
  final AtlasBiForecastRisk? selectedRisk;

  final ValueChanged<String?> onFarmChanged;

  final ValueChanged<AtlasBiCategory?> onCategoryChanged;

  final ValueChanged<AtlasBiForecastRisk?> onRiskChanged;

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
              child: DropdownButtonFormField<AtlasBiForecastRisk?>(
                initialValue: selectedRisk,
                decoration: const InputDecoration(labelText: 'Risco'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos os riscos'),
                  ),
                  ...AtlasBiForecastRisk.values.map((risk) {
                    return DropdownMenuItem(
                      value: risk,
                      child: Text(atlasBiForecastRiskLabel(risk)),
                    );
                  }),
                ],
                onChanged: onRiskChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast, required this.onOpenFarm});

  final AtlasBiForecast forecast;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(forecast.risk);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(_trendIcon(forecast.trend), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${forecast.farmName} · '
                        '${atlasBiCategoryLabel(forecast.category)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _RiskBadge(risk: forecast.risk),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              forecast.summary,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label:
                      'Atual: ${_formatValue(forecast.currentValue, forecast.unit)}',
                  color: const Color(0xFF1565C0),
                ),
                _InfoChip(
                  label:
                      'Projetado: ${_formatValue(forecast.projectedValue, forecast.unit)}',
                  color: color,
                ),
                _InfoChip(
                  label:
                      '${forecast.projectedVariationPercent >= 0 ? '+' : ''}'
                      '${forecast.projectedVariationPercent.toStringAsFixed(1)}%',
                  color: const Color(0xFF6A1B9A),
                ),
                _InfoChip(
                  label:
                      '${forecast.targetProbabilityPercent.toStringAsFixed(0)}% de chance da meta',
                  color: const Color(0xFF1B5E20),
                ),
                _InfoChip(
                  label:
                      '${forecast.confidencePercent.toStringAsFixed(0)}% de confiança',
                  color: const Color(0xFF455A64),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                forecast.recommendation,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 12),
              ActionChip(
                avatar: const Icon(Icons.agriculture_outlined, size: 16),
                label: const Text('Abrir fazenda'),
                onPressed: () {
                  onOpenFarm!(forecast.farmName);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk});

  final AtlasBiForecastRisk risk;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(risk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        atlasBiForecastRiskLabel(risk),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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

class _EmptyFilteredView extends StatelessWidget {
  const _EmptyFilteredView();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'Nenhuma projeção encontrada com os filtros atuais.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _EmptyForecastView extends StatelessWidget {
  const _EmptyForecastView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_graph_outlined, size: 58, color: Colors.black38),
            SizedBox(height: 14),
            Text(
              'Histórico insuficiente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'Registre novos valores dos indicadores para gerar projeções mais confiáveis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color _riskColor(AtlasBiForecastRisk risk) {
  switch (risk) {
    case AtlasBiForecastRisk.low:
      return const Color(0xFF1B5E20);

    case AtlasBiForecastRisk.medium:
      return const Color(0xFFEF6C00);

    case AtlasBiForecastRisk.high:
      return const Color(0xFFC62828);

    case AtlasBiForecastRisk.critical:
      return const Color(0xFF8E0000);
  }
}

IconData _trendIcon(AtlasBiForecastTrend trend) {
  switch (trend) {
    case AtlasBiForecastTrend.strongGrowth:
    case AtlasBiForecastTrend.growth:
      return Icons.trending_up;

    case AtlasBiForecastTrend.stable:
      return Icons.trending_flat;

    case AtlasBiForecastTrend.decline:
    case AtlasBiForecastTrend.strongDecline:
      return Icons.trending_down;

    case AtlasBiForecastTrend.unavailable:
      return Icons.horizontal_rule;
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
