import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/atlas_operational_intelligence_data.dart';

class ExecutiveIndicatorsCard extends StatelessWidget {
  const ExecutiveIndicatorsCard({
    required this.data,
    required this.farmName,
    super.key,
  });

  final AtlasOperationalIntelligenceData? data;
  final String farmName;

  String _currency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final value = data;
    if (value == null) return const SizedBox.shrink();

    final items = <_ExecutiveMetric>[
      _ExecutiveMetric(
        icon: Icons.favorite_outline,
        label: 'Prenhez',
        value: '${value.pregnancyRatePercent.toStringAsFixed(1)}%',
        detail: '${value.pregnantFemales}/${value.eligibleFemales} fêmeas',
      ),
      _ExecutiveMetric(
        icon: Icons.monitor_weight_outlined,
        label: 'Peso médio',
        value: '${value.averageWeightKg.toStringAsFixed(0)} kg',
        detail: 'animais ativos pesados',
      ),
      _ExecutiveMetric(
        icon: Icons.trending_up,
        label: 'GMD médio',
        value: '${value.averageGmdKgDay.toStringAsFixed(3)} kg/d',
        detail: 'últimas pesagens válidas',
      ),
      _ExecutiveMetric(
        icon: Icons.payments_outlined,
        label: 'Custo / animal',
        value: _currency(value.costPerActiveAnimal),
        detail: 'despesas acumuladas',
      ),
      _ExecutiveMetric(
        icon: Icons.inventory_2_outlined,
        label: 'Estoque crítico',
        value: '${value.criticalStockItems}',
        detail: 'itens no/abaixo do mínimo',
      ),
      _ExecutiveMetric(
        icon: Icons.event_busy_outlined,
        label: 'Tarefas atrasadas',
        value: '${value.overdueTasks}',
        detail: '${value.openTasks} tarefas abertas',
      ),
      _ExecutiveMetric(
        icon: Icons.restaurant_outlined,
        label: 'Nutrição / mês',
        value: _currency(value.nutritionMonthlyCost),
        detail: 'projeção dos planos ativos',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.query_stats_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Indicadores executivos · $farmName',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Indicadores cruzados de rebanho, reprodução, nutrição, '
              'estoque, financeiro e agenda.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .map((item) => _MetricTile(item: item))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final _ExecutiveMetric item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8E2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecutiveMetric {
  const _ExecutiveMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
}
