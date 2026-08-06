import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_data.dart';
import 'package:projeto_atlas/features/atlas_bi/domain/models/atlas_bi_management_summary.dart';

class AtlasBiManagementDashboardScreen extends StatelessWidget {
  const AtlasBiManagementDashboardScreen({
    required this.data,
    super.key,
  });

  final AtlasBiManagementSummary data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Business Intelligence 2.0',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                _Hero(data: data),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      label: 'Tendências positivas',
                      value: '${data.positiveTrends}',
                      icon: Icons.trending_up,
                    ),
                    _MetricCard(
                      label: 'Tendências negativas',
                      value: '${data.negativeTrends}',
                      icon: Icons.trending_down,
                    ),
                    _MetricCard(
                      label: 'Indicadores na meta',
                      value: '${data.onTargetIndicators}',
                      icon: Icons.check_circle_outline,
                    ),
                    _MetricCard(
                      label: 'Indicadores fora da meta',
                      value: '${data.offTargetIndicators}',
                      icon: Icons.warning_amber_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Desempenho por área',
                  subtitle:
                      'Comparação do alcance médio das metas em cada dimensão da operação.',
                ),
                const SizedBox(height: 12),
                ...data.categorySummaries.map(_CategoryCard.new),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Prioridades gerenciais',
                  subtitle:
                      'Indicadores que merecem atenção primeiro, ordenados por criticidade.',
                ),
                const SizedBox(height: 12),
                if (data.priorities.isEmpty)
                  const _EmptyPriorities()
                else
                  ...data.priorities.map(_PriorityCard.new),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.data});

  final AtlasBiManagementSummary data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F33), Color(0xFF176B87)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Text(
              data.score.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pulso executivo da operação',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Situação atual: ${data.statusLabel}. O painel reúne metas, tendências e prioridades em uma visão gerencial.',
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(label, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard(this.item);

  final AtlasBiCategorySummary item;

  @override
  Widget build(BuildContext context) {
    final progress = (item.averageAchievement / 100).clamp(0.0, 1.0).toDouble();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    atlasBiCategoryLabel(item.category),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${item.averageAchievement.toStringAsFixed(0)}% da meta',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              '${item.indicatorCount} indicadores • ${item.criticalCount} críticos',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard(this.item);

  final AtlasBiManagementPriority item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(child: Icon(Icons.flag_outlined)),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('${item.description}\nAção: ${item.recommendedAction}'),
        ),
        isThreeLine: true,
        trailing: Text(
          _priorityLabel(item.urgency),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _priorityLabel(AtlasBiPriority priority) {
    switch (priority) {
      case AtlasBiPriority.low:
        return 'Baixa';
      case AtlasBiPriority.medium:
        return 'Média';
      case AtlasBiPriority.high:
        return 'Alta';
      case AtlasBiPriority.critical:
        return 'Crítica';
    }
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
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _EmptyPriorities extends StatelessWidget {
  const _EmptyPriorities();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('Nenhuma prioridade crítica identificada nesta análise.'),
      ),
    );
  }
}
