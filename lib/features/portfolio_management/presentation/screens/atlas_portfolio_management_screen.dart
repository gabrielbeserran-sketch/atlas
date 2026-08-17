import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/strategic_capacity/presentation/screens/atlas_strategic_capacity_screen.dart';
import 'package:projeto_atlas/features/benefits_realization/data/services/atlas_benefits_realization_repository.dart';
import 'package:projeto_atlas/features/portfolio_management/domain/models/atlas_portfolio_item.dart';
import 'package:projeto_atlas/features/portfolio_management/domain/services/atlas_portfolio_management_engine.dart';
import 'package:projeto_atlas/features/strategy_execution/data/services/atlas_strategy_execution_repository.dart';
import 'package:projeto_atlas/features/value_governance/data/services/atlas_value_governance_repository.dart';

class AtlasPortfolioManagementScreen extends StatefulWidget {
  const AtlasPortfolioManagementScreen({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasPortfolioManagementScreen> createState() {
    return _AtlasPortfolioManagementScreenState();
  }
}

class _AtlasPortfolioManagementScreenState
    extends State<AtlasPortfolioManagementScreen> {
  bool loading = true;
  AtlasPortfolioSummary summary = AtlasPortfolioSummary(
    items: const <AtlasPortfolioItem>[],
    generatedAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await AtlasStrategyExecutionRepository.instance.loadAll();
    final realizations = await AtlasBenefitsRealizationRepository.instance
        .loadAll();
    final decisions = await AtlasValueGovernanceRepository.instance.loadAll();

    final filteredPlans = widget.farmId == null
        ? plans
        : plans.where((item) => item.farmId == widget.farmId).toList();

    final planIds = filteredPlans.map((item) => item.id).toSet();

    final filteredRealizations = realizations
        .where((item) => planIds.contains(item.strategyPlanId))
        .toList();

    final filteredDecisions = decisions
        .where((item) => planIds.contains(item.strategyPlanId))
        .toList();

    final generated = const AtlasPortfolioManagementEngine().build(
      plans: filteredPlans,
      realizations: filteredRealizations,
      decisions: filteredDecisions,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      summary = generated;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Portfolio Management Office',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir capacidade e dependências',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasStrategicCapacityScreen(farmId: widget.farmId);
                  },
                ),
              );
            },
            icon: const Icon(Icons.hub_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar portfólio',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : summary.items.isEmpty
          ? const _EmptyView()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    _Hero(summary: summary),
                    const SizedBox(height: 22),
                    const Text(
                      'Prioridades do portfólio',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Estratégias ordenadas por impacto, urgência, saúde e valor em risco.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    ...summary.items.asMap().entries.map(
                      (entry) => _PortfolioCard(
                        position: entry.key + 1,
                        item: entry.value,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.summary});

  final AtlasPortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF0D47A1),
            Color(0xFF37474F),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visão executiva consolidada',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          const Text(
            'Portfólio estratégico da propriedade',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroMetric(
                label: 'Estratégias',
                value: '${summary.totalStrategies}',
              ),
              _HeroMetric(
                label: 'Ativas',
                value: '${summary.activeStrategies}',
              ),
              _HeroMetric(
                label: 'Críticas',
                value: '${summary.criticalStrategies}',
              ),
              _HeroMetric(
                label: 'Investimento',
                value: _currency(summary.committedInvestment),
              ),
              _HeroMetric(
                label: 'Valor esperado',
                value: _currency(summary.expectedValue),
              ),
              _HeroMetric(
                label: 'Valor realizado',
                value: _currency(summary.realizedValue),
              ),
              _HeroMetric(
                label: 'Valor em risco',
                value: _currency(summary.totalValueAtRisk),
              ),
              _HeroMetric(
                label: 'Saúde média',
                value: '${summary.averageHealth.toStringAsFixed(1)}%',
              ),
              _HeroMetric(
                label: 'Progresso médio',
                value: '${summary.averageProgress.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.position, required this.item});

  final int position;
  final AtlasPortfolioItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isCritical
        ? const Color(0xFFC62828)
        : item.healthScore >= 80
        ? const Color(0xFF2E7D32)
        : const Color(0xFFEF6C00);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            '$position',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          item.plan.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item.plan.farmName} · prioridade '
          '${item.priorityScore.toStringAsFixed(1)} · saúde '
          '${item.healthScore.toStringAsFixed(1)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          LinearProgressIndicator(
            value: item.plan.progressPercent / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Prioridade',
                value: item.priorityScore.toStringAsFixed(1),
              ),
              _Metric(
                label: 'Saúde',
                value: '${item.healthScore.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Progresso',
                value: '${item.plan.progressPercent.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Carga de recursos',
                value: '${item.resourceLoad.toStringAsFixed(1)}%',
              ),
              _Metric(
                label: 'Valor em risco',
                value: _currency(item.valueAtRisk),
              ),
              _Metric(
                label: 'ROI esperado',
                value: '${item.plan.expectedRoi.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recomendação do PMO:\n${item.recommendation}',
              style: const TextStyle(height: 1.45),
            ),
          ),
          if (item.governance != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Governança atual: '
                '${item.governance!.executiveSummary}',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspaces_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Ainda não existem estratégias no portfólio.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Transforme cenários em planos de execução para formar o portfólio estratégico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

String _currency(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final remaining = integer.length - index;
    buffer.write(integer[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${negative ? '-' : ''}R\$ '
      '${buffer.toString()},$decimal';
}
