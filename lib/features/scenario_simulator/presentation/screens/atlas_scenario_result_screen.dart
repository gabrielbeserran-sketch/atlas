import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation_result.dart';

class AtlasScenarioResultScreen extends StatelessWidget {
  const AtlasScenarioResultScreen({required this.result, super.key});

  final AtlasSimulationResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          result.simulation.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _ResultHero(result: result),
                const SizedBox(height: 20),
                _FinancialGrid(result: result),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Comparação estratégica',
                  subtitle:
                      'Estado atual da fazenda comparado ao cenário simulado.',
                ),
                const SizedBox(height: 12),
                _ComparisonTable(result: result),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Recomendação executiva',
                  subtitle: 'Leitura consolidada do impacto esperado.',
                ),
                const SizedBox(height: 12),
                _RecommendationCard(result: result),
                const SizedBox(height: 24),
                _StrengthsAndAttention(result: result),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.result});

  final AtlasSimulationResult result;

  @override
  Widget build(BuildContext context) {
    final favorable = result.isFavorable;
    final variation = result.scoreVariation;
    final sign = variation > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF17384D), Color(0xFF236075)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            favorable ? Icons.trending_up : Icons.analytics_outlined,
            color: favorable
                ? const Color(0xFF69F0AE)
                : const Color(0xFFFFCC80),
            size: 48,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorable ? 'Cenário favorável' : 'Cenário exige avaliação',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${result.currentTwin.overallScore.toStringAsFixed(1)} '
                  '→ '
                  '${result.simulatedTwin.overallScore.toStringAsFixed(1)} '
                  '($sign${variation.toStringAsFixed(1)} pontos)',
                  style: const TextStyle(color: Colors.white70, fontSize: 17),
                ),
                const SizedBox(height: 6),
                Text(
                  'Horizonte: ${result.simulation.horizonMonths} meses · '
                  'Risco ${atlasSimulationRiskLevelLabel(result.riskLevel)}',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialGrid extends StatelessWidget {
  const _FinancialGrid({required this.result});

  final AtlasSimulationResult result;

  @override
  Widget build(BuildContext context) {
    final items = <_MetricData>[
      _MetricData(
        label: 'Receita projetada',
        value: _formatCurrency(result.projectedRevenueChange),
        icon: Icons.trending_up,
      ),
      _MetricData(
        label: 'Custos e investimento',
        value: _formatCurrency(result.projectedCostChange),
        icon: Icons.payments_outlined,
      ),
      _MetricData(
        label: 'Resultado líquido',
        value: _formatCurrency(result.projectedNetResult),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _MetricData(
        label: 'ROI projetado',
        value: '${result.roiPercent.toStringAsFixed(1)}%',
        icon: Icons.percent,
      ),
      _MetricData(
        label: 'Payback',
        value: result.paybackMonths == null
            ? 'Não calculado'
            : '${result.paybackMonths!.toStringAsFixed(1)} meses',
        icon: Icons.schedule,
      ),
      _MetricData(
        label: 'Alteração do rebanho',
        value:
            '${result.simulation.changes.herdSizeChange >= 0 ? '+' : ''}'
            '${result.simulation.changes.herdSizeChange}',
        icon: Icons.pets_outlined,
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
                                fontSize: 19,
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

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.result});

  final AtlasSimulationResult result;

  @override
  Widget build(BuildContext context) {
    final current = result.currentTwin;
    final simulated = result.simulatedTwin;

    final rows = <_ComparisonRowData>[
      _ComparisonRowData(
        label: 'Atlas Farm Index',
        current: current.overallScore,
        simulated: simulated.overallScore,
      ),
      _ComparisonRowData(
        label: 'Desempenho animal',
        current: current.health.animal,
        simulated: simulated.health.animal,
      ),
      _ComparisonRowData(
        label: 'Sanidade',
        current: current.health.sanitary,
        simulated: simulated.health.sanitary,
      ),
      _ComparisonRowData(
        label: 'Reprodução',
        current: current.health.reproductive,
        simulated: simulated.health.reproductive,
      ),
      _ComparisonRowData(
        label: 'Financeiro',
        current: current.health.financial,
        simulated: simulated.health.financial,
      ),
      _ComparisonRowData(
        label: 'Estoque',
        current: current.health.inventory,
        simulated: simulated.health.inventory,
      ),
      _ComparisonRowData(
        label: 'Operacional',
        current: current.health.operational,
        simulated: simulated.health.operational,
      ),
    ];

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Indicador')),
            DataColumn(numeric: true, label: Text('Atual')),
            DataColumn(numeric: true, label: Text('Cenário')),
            DataColumn(numeric: true, label: Text('Variação')),
          ],
          rows: rows.map((row) {
            final variation = row.simulated - row.current;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    row.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(row.current.toStringAsFixed(1))),
                DataCell(Text(row.simulated.toStringAsFixed(1))),
                DataCell(
                  Text(
                    '${variation > 0 ? '+' : ''}'
                    '${variation.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: variation > 0
                          ? const Color(0xFF2E7D32)
                          : variation < 0
                          ? const Color(0xFFC62828)
                          : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.result});

  final AtlasSimulationResult result;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(result.riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.psychology_outlined, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                result.recommendation,
                style: const TextStyle(
                  height: 1.5,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthsAndAttention extends StatelessWidget {
  const _StrengthsAndAttention({required this.result});

  final AtlasSimulationResult result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;

        final strengths = _PointListCard(
          title: 'Pontos fortes',
          icon: Icons.check_circle_outline,
          items: result.strengths,
        );

        final attention = _PointListCard(
          title: 'Pontos de atenção',
          icon: Icons.warning_amber_outlined,
          items: result.attentionPoints,
        );

        if (!wide) {
          return Column(
            children: [strengths, const SizedBox(height: 12), attention],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: strengths),
            const SizedBox(width: 12),
            Expanded(child: attention),
          ],
        );
      },
    );
  }
}

class _PointListCard extends StatelessWidget {
  const _PointListCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(item, style: const TextStyle(height: 1.35)),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _ComparisonRowData {
  const _ComparisonRowData({
    required this.label,
    required this.current,
    required this.simulated,
  });

  final String label;
  final double current;
  final double simulated;
}

String _formatCurrency(double value) {
  final negative = value < 0;
  final absoluteValue = value.abs();

  final fixed = absoluteValue.toStringAsFixed(2);
  final parts = fixed.split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();

  for (var index = 0; index < integerPart.length; index++) {
    final remaining = integerPart.length - index;

    buffer.write(integerPart[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  final prefix = negative ? '-R\$ ' : 'R\$ ';

  return '$prefix${buffer.toString()},$decimalPart';
}

Color _riskColor(AtlasSimulationRiskLevel level) {
  switch (level) {
    case AtlasSimulationRiskLevel.low:
      return const Color(0xFF2E7D32);
    case AtlasSimulationRiskLevel.moderate:
      return const Color(0xFF1565C0);
    case AtlasSimulationRiskLevel.high:
      return const Color(0xFFEF6C00);
    case AtlasSimulationRiskLevel.critical:
      return const Color(0xFFC62828);
  }
}
