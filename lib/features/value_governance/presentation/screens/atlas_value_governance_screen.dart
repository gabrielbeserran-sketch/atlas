import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/portfolio_management/presentation/screens/atlas_portfolio_management_screen.dart';
import 'package:projeto_atlas/features/benefits_realization/data/services/atlas_benefits_realization_repository.dart';
import 'package:projeto_atlas/features/benefits_realization/domain/models/atlas_benefit_realization.dart';
import 'package:projeto_atlas/features/value_governance/data/services/atlas_value_governance_repository.dart';
import 'package:projeto_atlas/features/value_governance/domain/models/atlas_value_governance.dart';
import 'package:projeto_atlas/features/value_governance/domain/services/atlas_value_governance_engine.dart';

class AtlasValueGovernanceScreen extends StatefulWidget {
  const AtlasValueGovernanceScreen({
    super.key,
    this.farmId,
  });

  final String? farmId;

  @override
  State<AtlasValueGovernanceScreen> createState() =>
      _AtlasValueGovernanceScreenState();
}

class _AtlasValueGovernanceScreenState
    extends State<AtlasValueGovernanceScreen> {
  bool loading = true;
  List<AtlasBenefitRealization> realizations =
      <AtlasBenefitRealization>[];
  List<AtlasValueGovernanceDecision> decisions =
      <AtlasValueGovernanceDecision>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allRealizations =
        await AtlasBenefitsRealizationRepository.instance
            .loadAll();
    final allDecisions =
        await AtlasValueGovernanceRepository.instance
            .loadAll();

    final filtered = widget.farmId == null
        ? allRealizations
        : allRealizations
            .where((item) => item.farmId == widget.farmId)
            .toList();

    final planIds =
        filtered.map((item) => item.strategyPlanId).toSet();

    if (!mounted) {
      return;
    }

    setState(() {
      realizations = filtered;
      decisions = allDecisions
          .where(
            (item) => planIds.contains(item.strategyPlanId),
          )
          .toList();
      loading = false;
    });
  }

  AtlasValueGovernanceDecision? _findDecision(
    String planId,
  ) {
    for (final item in decisions) {
      if (item.strategyPlanId == planId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _govern(
    AtlasBenefitRealization realization,
  ) async {
    final decision =
        const AtlasValueGovernanceEngine().govern(
      realization,
    );

    await AtlasValueGovernanceRepository.instance.save(
      decision,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Value Governance Engine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir Portfolio Management Office',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return AtlasPortfolioManagementScreen(
                      farmId: widget.farmId,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.workspaces_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : realizations.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Registre benefícios realizados antes de gerar decisões executivas.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 1180),
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _Hero(decisions: decisions),
                        const SizedBox(height: 22),
                        const Text(
                          'Comitê executivo de valor',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Aprovação, correção, pausa ou encerramento dos investimentos.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        ...realizations.map(
                          (realization) => _DecisionCard(
                            realization: realization,
                            decision: _findDecision(
                              realization.strategyPlanId,
                            ),
                            onGovern: () => _govern(realization),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.decisions});

  final List<AtlasValueGovernanceDecision> decisions;

  @override
  Widget build(BuildContext context) {
    final average = decisions.isEmpty
        ? 0.0
        : decisions.fold<double>(
              0,
              (sum, item) => sum + item.valueScore,
            ) /
            decisions.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF07111F),
            Color(0xFF263238),
            Color(0xFF455A64),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _HeroMetric(
            label: 'Decisões governadas',
            value: '${decisions.length}',
          ),
          _HeroMetric(
            label: 'Score médio de valor',
            value: average.toStringAsFixed(1),
          ),
          _HeroMetric(
            label: 'Aprovações',
            value:
                '${decisions.where((item) => item.decision == AtlasValueGovernanceDecisionType.approve).length}',
          ),
          _HeroMetric(
            label: 'Correções ou pausas',
            value:
                '${decisions.where((item) => item.decision == AtlasValueGovernanceDecisionType.correct || item.decision == AtlasValueGovernanceDecisionType.pause).length}',
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.realization,
    required this.decision,
    required this.onGovern,
  });

  final AtlasBenefitRealization realization;
  final AtlasValueGovernanceDecision? decision;
  final VoidCallback onGovern;

  @override
  Widget build(BuildContext context) {
    final current = decision;

    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(
          child: Icon(Icons.account_balance_outlined),
        ),
        title: Text(
          realization.strategyTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          current == null
              ? '${realization.farmName} · aguardando governança'
              : '${realization.farmName} · '
                  '${atlasValueGovernanceDecisionLabel(current.decision)} · '
                  'score ${current.valueScore.toStringAsFixed(1)}',
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          if (current != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(current.executiveSummary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  label: 'Financeiro',
                  value:
                      current.financialScore.toStringAsFixed(1),
                ),
                _Metric(
                  label: 'Execução',
                  value:
                      current.executionScore.toStringAsFixed(1),
                ),
                _Metric(
                  label: 'Risco',
                  value:
                      current.riskScore.toStringAsFixed(1),
                ),
                _Metric(
                  label: 'Próxima revisão',
                  value: _date(current.nextReviewAt),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ListBlock(
              title: 'Condições para continuidade',
              items: current.conditions,
            ),
            _ListBlock(
              title: 'Ações obrigatórias',
              items: current.requiredActions,
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onGovern,
              icon: const Icon(Icons.gavel_outlined),
              label: Text(
                current == null
                    ? 'Gerar decisão executiva'
                    : 'Recalcular governança',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
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

class _ListBlock extends StatelessWidget {
  const _ListBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...items.map((item) => Text('• $item')),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}
