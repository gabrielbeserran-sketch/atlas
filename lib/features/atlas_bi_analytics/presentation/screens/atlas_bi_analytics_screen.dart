import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi_analytics/domain/models/atlas_bi_analytics_data.dart';

class AtlasBiAnalyticsScreen extends StatefulWidget {
  const AtlasBiAnalyticsScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasBiAnalyticsData data;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasBiAnalyticsScreen> createState() {
    return _AtlasBiAnalyticsScreenState();
  }
}

class _AtlasBiAnalyticsScreenState extends State<AtlasBiAnalyticsScreen> {
  String? selectedFarm;
  AtlasBiCategory? selectedCategory;

  AtlasBiAnalyticsData get data {
    return widget.data;
  }

  List<String> get farms {
    final values = <String>{
      ...data.bottlenecks.map((item) => item.farmName),
      ...data.investments.map((item) => item.farmName),
      ...data.scenarios.map((item) => item.farmName),
    }.toList()..sort();

    return values;
  }

  bool _matches(String farmName, AtlasBiCategory category) {
    if (selectedFarm != null && farmName != selectedFarm) {
      return false;
    }

    if (selectedCategory != null && category != selectedCategory) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bottlenecks = data.bottlenecks.where((item) {
      return _matches(item.farmName, item.category);
    }).toList();

    final investments = data.investments.where((item) {
      return _matches(item.farmName, item.category);
    }).toList();

    final scenarios = data.scenarios.where((item) {
      return _matches(item.farmName, item.category);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas BI Analytics',
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
                      _AnalyticsHero(data: data),
                      const SizedBox(height: 22),
                      _AnalyticsFilters(
                        farms: farms,
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
                        title: 'Gargalos prioritários',
                        subtitle:
                            'Indicadores que mais limitam o desempenho da operação.',
                      ),
                      const SizedBox(height: 13),
                      _BottleneckList(
                        items: bottlenecks,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Ranking de investimentos',
                        subtitle:
                            'Oportunidades ordenadas por impacto, ROI e confiança.',
                      ),
                      const SizedBox(height: 13),
                      _InvestmentList(
                        items: investments,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Relações entre indicadores',
                        subtitle:
                            'Correlações relevantes identificadas no histórico.',
                      ),
                      const SizedBox(height: 13),
                      _CorrelationList(items: data.correlations),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Cenários simulados',
                        subtitle:
                            'Impacto financeiro e redução de risco em intervenções possíveis.',
                      ),
                      const SizedBox(height: 13),
                      _ScenarioList(
                        items: scenarios,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyAnalyticsView(),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({required this.data});

  final AtlasBiAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1033), Color(0xFF3A245E), Color(0xFF5B3B82)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insights_outlined,
            color: Color(0xFFE1BEE7),
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analytics Avançado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.summary,
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                data.score.toStringAsFixed(0),
                style: const TextStyle(
                  color: Color(0xFFE1BEE7),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Score', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsFilters extends StatelessWidget {
  const _AnalyticsFilters({
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

class _BottleneckList extends StatelessWidget {
  const _BottleneckList({required this.items, required this.onOpenFarm});

  final List<AtlasBiBottleneck> items;
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
            leading: Icon(Icons.warning_amber_outlined, color: color),
            title: Text(
              item.indicatorTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.farmName} · lacuna de '
              '${item.performanceGapPercent.toStringAsFixed(1)}%\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              'R\$ ${item.financialImpactValue.toStringAsFixed(2)}',
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

class _InvestmentList extends StatelessWidget {
  const _InvestmentList({required this.items, required this.onOpenFarm});

  final List<AtlasBiInvestmentOpportunity> items;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.currency_exchange_outlined,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${item.roiPercent.toStringAsFixed(1)}% ROI',
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Text(
                  'Investimento: R\$ ${item.investmentValue.toStringAsFixed(2)} · '
                  'Retorno esperado: R\$ ${item.expectedReturnValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  item.paybackDays == null
                      ? 'Payback indisponível'
                      : 'Payback estimado: ${item.paybackDays} dias',
                  style: const TextStyle(color: Colors.black54),
                ),
                if (onOpenFarm != null) ...[
                  const SizedBox(height: 10),
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
      }).toList(),
    );
  }
}

class _CorrelationList extends StatelessWidget {
  const _CorrelationList({required this.items});

  final List<AtlasBiCorrelation> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = item.direction == AtlasBiCorrelationDirection.positive
            ? const Color(0xFF1B5E20)
            : const Color(0xFFC62828);

        return Card(
          child: ListTile(
            leading: Icon(Icons.hub_outlined, color: color),
            title: Text(
              '${item.firstIndicatorTitle} × '
              '${item.secondIndicatorTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.explanation),
            trailing: Text(
              item.coefficient.toStringAsFixed(2),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScenarioList extends StatelessWidget {
  const _ScenarioList({required this.items, required this.onOpenFarm});

  final List<AtlasBiScenarioAnalysis> items;
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
              Icons.science_outlined,
              color: Color(0xFF6A1B9A),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${item.changePercent.toStringAsFixed(1)}% de mudança · '
              '${item.riskReductionPercent.toStringAsFixed(1)}% de redução de risco',
            ),
            trailing: Text(
              'R\$ ${item.projectedFinancialImpact.toStringAsFixed(2)}',
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

class _EmptyAnalyticsView extends StatelessWidget {
  const _EmptyAnalyticsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma análise avançada disponível.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

Color _severityColor(AtlasBiAnalyticsSeverity severity) {
  switch (severity) {
    case AtlasBiAnalyticsSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasBiAnalyticsSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasBiAnalyticsSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasBiAnalyticsSeverity.critical:
      return const Color(0xFFC62828);
  }
}
