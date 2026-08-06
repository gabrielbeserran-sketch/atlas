import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/predictive_analytics/domain/models/atlas_predictive_analytics_data.dart';

class AtlasPredictiveAnalyticsScreen
    extends StatefulWidget {
  const AtlasPredictiveAnalyticsScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasPredictiveAnalyticsData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasPredictiveAnalyticsScreen>
      createState() {
    return _AtlasPredictiveAnalyticsScreenState();
  }
}

class _AtlasPredictiveAnalyticsScreenState
    extends State<AtlasPredictiveAnalyticsScreen> {
  AtlasBiCategory? selectedCategory;
  AtlasPredictiveForecastKind? selectedKind;
  String? selectedFarm;

  AtlasPredictiveAnalyticsData get data {
    return widget.data;
  }

  List<String> get farms {
    final values = data.forecasts
        .map((item) => item.farmName)
        .toSet()
        .toList()
      ..sort();

    return values;
  }

  List<AtlasPredictiveForecast>
      get filteredForecasts {
    return data.forecasts.where((item) {
      if (selectedFarm != null &&
          item.farmName != selectedFarm) {
        return false;
      }

      if (selectedCategory != null &&
          item.category != selectedCategory) {
        return false;
      }

      if (selectedKind != null &&
          item.kind != selectedKind) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Predictive Analytics',
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
                      _PredictiveHero(data: data),
                      const SizedBox(height: 22),
                      _PredictiveFilters(
                        farms: farms,
                        selectedFarm:
                            selectedFarm,
                        selectedCategory:
                            selectedCategory,
                        selectedKind:
                            selectedKind,
                        onFarmChanged: (value) {
                          setState(() {
                            selectedFarm = value;
                          });
                        },
                        onCategoryChanged:
                            (value) {
                          setState(() {
                            selectedCategory =
                                value;
                          });
                        },
                        onKindChanged: (value) {
                          setState(() {
                            selectedKind = value;
                          });
                        },
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Previsões',
                        subtitle:
                            'Projeções por indicador e horizonte analisado.',
                      ),
                      const SizedBox(height: 13),
                      if (filteredForecasts.isEmpty)
                        const _EmptySection()
                      else
                        ...filteredForecasts.map(
                          (item) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child:
                                  _ForecastCard(
                                item: item,
                                onOpenFarm:
                                    widget.onOpenFarm,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title:
                            'Riscos preditivos',
                        subtitle:
                            'Eventos com maior probabilidade e impacto.',
                      ),
                      const SizedBox(height: 13),
                      _RiskList(
                        items: data.risks,
                        onOpenFarm:
                            widget.onOpenFarm,
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title:
                            'Cenários e simulações',
                        subtitle:
                            'Otimista, esperado, pessimista e E se...?',
                      ),
                      const SizedBox(height: 13),
                      _ScenarioList(
                        items: data.scenarios,
                        onOpenFarm:
                            widget.onOpenFarm,
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title:
                            'Recomendações automáticas',
                        subtitle:
                            'Ações sugeridas a partir das projeções.',
                      ),
                      const SizedBox(height: 13),
                      _RecommendationList(
                        items:
                            data.recommendations,
                        onOpenFarm:
                            widget.onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyPredictiveView(),
          ),
        ),
      ),
    );
  }
}

class _PredictiveHero extends StatelessWidget {
  const _PredictiveHero({
    required this.data,
  });

  final AtlasPredictiveAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final color =
        _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF081C24),
            Color(0xFF123B47),
            Color(0xFF1F6D79),
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
                    Icons.auto_graph_outlined,
                    color: Color(0xFFB2DFDB),
                    size: 32,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Predictive Analytics Engine',
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
                    label: 'Previsões',
                    value:
                        data.forecasts.length,
                  ),
                  _HeroMetric(
                    label: 'Riscos',
                    value: data.risks.length,
                  ),
                  _HeroMetric(
                    label: 'Cenários',
                    value:
                        data.scenarios.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 230,
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
                  data.score.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  atlasPredictiveAnalyticsStatusLabel(
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
                const SizedBox(height: 6),
                Text(
                  '${data.horizonDays} dias',
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

class _PredictiveFilters
    extends StatelessWidget {
  const _PredictiveFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedCategory,
    required this.selectedKind,
    required this.onFarmChanged,
    required this.onCategoryChanged,
    required this.onKindChanged,
  });

  final List<String> farms;
  final String? selectedFarm;
  final AtlasBiCategory?
      selectedCategory;
  final AtlasPredictiveForecastKind?
      selectedKind;

  final ValueChanged<String?>
      onFarmChanged;

  final ValueChanged<AtlasBiCategory?>
      onCategoryChanged;

  final ValueChanged<
          AtlasPredictiveForecastKind?>
      onKindChanged;

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
              width: 250,
              child: DropdownButtonFormField<
                  String?>(
                initialValue: selectedFarm,
                decoration:
                    const InputDecoration(
                  labelText: 'Fazenda',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todas as fazendas',
                    ),
                  ),
                  ...farms.map((farm) {
                    return DropdownMenuItem(
                      value: farm,
                      child: Text(farm),
                    );
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<
                  AtlasBiCategory?>(
                initialValue:
                    selectedCategory,
                decoration:
                    const InputDecoration(
                  labelText: 'Categoria',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todas as categorias',
                    ),
                  ),
                  ...AtlasBiCategory.values
                      .map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        atlasBiCategoryLabel(
                          category,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged:
                    onCategoryChanged,
              ),
            ),
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<
                  AtlasPredictiveForecastKind?>(
                initialValue: selectedKind,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Tipo de previsão',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todos os tipos',
                    ),
                  ),
                  ...AtlasPredictiveForecastKind
                      .values
                      .map((kind) {
                    return DropdownMenuItem(
                      value: kind,
                      child: Text(
                        atlasPredictiveForecastKindLabel(
                          kind,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: onKindChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({
    required this.item,
    required this.onOpenFarm,
  });

  final AtlasPredictiveForecast item;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color =
        _riskColor(item.risk);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart_outlined,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${item.farmName} · '
                        '${atlasPredictiveForecastKindLabel(item.kind)}',
                        style: const TextStyle(
                          color:
                              Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  atlasPredictiveAnalyticsRiskLevelLabel(
                    item.risk,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                _ValueBlock(
                  label: 'Atual',
                  value: _format(
                    item.currentValue,
                    item.unit,
                  ),
                ),
                _ValueBlock(
                  label: 'Projetado',
                  value: _format(
                    item.projectedValue,
                    item.unit,
                  ),
                ),
                _ValueBlock(
                  label: 'Otimista',
                  value: _format(
                    item.optimisticValue,
                    item.unit,
                  ),
                ),
                _ValueBlock(
                  label: 'Pessimista',
                  value: _format(
                    item.pessimisticValue,
                    item.unit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Variação esperada: '
              '${item.expectedVariationPercent.toStringAsFixed(1)}% · '
              'confiança: ${item.confidencePercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.recommendation,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onOpenFarm != null) ...[
              const SizedBox(height: 10),
              ActionChip(
                label:
                    const Text('Abrir fazenda'),
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

class _RiskList extends StatelessWidget {
  const _RiskList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasPredictiveRisk> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color =
            _riskColor(item.level);

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.warning_amber_outlined,
              color: color,
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${item.horizonDays} dias\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.probabilityPercent.toStringAsFixed(0)}%',
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

class _ScenarioList extends StatelessWidget {
  const _ScenarioList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasPredictiveScenario> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.take(20).map((item) {
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.science_outlined,
              color: Color(0xFF6A1B9A),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${atlasPredictiveScenarioTypeLabel(item.type)} · '
              '${item.farmName}\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              'R\$ ${item.projectedFinancialImpact.toStringAsFixed(0)}',
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

class _RecommendationList
    extends StatelessWidget {
  const _RecommendationList({
    required this.items,
    required this.onOpenFarm,
  });

  final List<AtlasPredictiveRecommendation>
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
            leading: Icon(
              Icons.lightbulb_outline,
              color: color,
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item.description}\n'
              '${item.expectedImpact}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasPredictiveAnalyticsPriorityLabel(
                item.priority,
              ),
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

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.04,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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

class _EmptyPredictiveView
    extends StatelessWidget {
  const _EmptyPredictiveView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma análise preditiva disponível.',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }
}

Color _statusColor(
  AtlasPredictiveAnalyticsStatus status,
) {
  switch (status) {
    case AtlasPredictiveAnalyticsStatus.excellent:
      return const Color(0xFF80CBC4);

    case AtlasPredictiveAnalyticsStatus.adequate:
      return const Color(0xFFA5D6A7);

    case AtlasPredictiveAnalyticsStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasPredictiveAnalyticsStatus.critical:
      return const Color(0xFFEF9A9A);
  }
}

Color _riskColor(
  AtlasPredictiveAnalyticsRiskLevel risk,
) {
  switch (risk) {
    case AtlasPredictiveAnalyticsRiskLevel.low:
      return const Color(0xFF2E7D32);

    case AtlasPredictiveAnalyticsRiskLevel.medium:
      return const Color(0xFF1565C0);

    case AtlasPredictiveAnalyticsRiskLevel.high:
      return const Color(0xFFEF6C00);

    case AtlasPredictiveAnalyticsRiskLevel.critical:
      return const Color(0xFFC62828);
  }
}

Color _priorityColor(
  AtlasPredictiveAnalyticsPriority priority,
) {
  switch (priority) {
    case AtlasPredictiveAnalyticsPriority.low:
      return const Color(0xFF2E7D32);

    case AtlasPredictiveAnalyticsPriority.medium:
      return const Color(0xFF1565C0);

    case AtlasPredictiveAnalyticsPriority.high:
      return const Color(0xFFEF6C00);

    case AtlasPredictiveAnalyticsPriority.critical:
      return const Color(0xFFC62828);
  }
}

String _format(
  double value,
  String unit,
) {
  final decimals =
      value == value.roundToDouble()
          ? 0
          : 1;

  if (unit == 'R\$') {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  if (unit.isEmpty) {
    return value.toStringAsFixed(decimals);
  }

  return '${value.toStringAsFixed(decimals)} $unit';
}
