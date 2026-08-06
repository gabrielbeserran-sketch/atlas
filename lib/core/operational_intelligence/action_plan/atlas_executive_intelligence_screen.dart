import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_outcome_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_executive_intelligence.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_executive_intelligence_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal_service.dart';

class AtlasExecutiveIntelligenceScreen
    extends StatefulWidget {
  const AtlasExecutiveIntelligenceScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasExecutiveIntelligenceScreen> createState() =>
      _AtlasExecutiveIntelligenceScreenState();
}

class _AtlasExecutiveIntelligenceScreenState
    extends State<AtlasExecutiveIntelligenceScreen> {
  final AtlasOperationalGoalService goalService =
      AtlasOperationalGoalService.instance;
  final AtlasActionOutcomeService outcomeService =
      AtlasActionOutcomeService.instance;
  final AtlasExecutiveIntelligenceService service =
      const AtlasExecutiveIntelligenceService();

  AtlasExecutiveIntelligenceSnapshot? snapshot;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    await widget.actionController.load();
    final goals = await goalService.load(
      farmName: widget.actionController.farmName,
    );
    final outcomes = await outcomeService.load(
      farmName: widget.actionController.farmName,
    );

    snapshot = service.build(
      actions: widget.actionController.actions,
      goals: goals,
      outcomes: outcomes,
    );

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inteligência executiva 360°'),
          actions: [
            IconButton(
              tooltip: 'Atualizar inteligência',
              onPressed: isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '360°', icon: Icon(Icons.dashboard)),
              Tab(text: 'Metas', icon: Icon(Icons.flag_outlined)),
              Tab(text: 'Decisões', icon: Icon(Icons.account_tree)),
              Tab(text: 'Simulações', icon: Icon(Icons.science_outlined)),
              Tab(text: 'Gargalos', icon: Icon(Icons.warning_amber)),
              Tab(text: 'Estratégia', icon: Icon(Icons.explore_outlined)),
            ],
          ),
        ),
        body: isLoading && snapshot == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : snapshot == null
                ? const Center(
                    child: Text(
                      'Não foi possível gerar a inteligência executiva.',
                    ),
                  )
                : TabBarView(
                    children: [
                      _OverviewTab(snapshot: snapshot!),
                      _GoalsTab(items: snapshot!.goalProjections),
                      _DecisionTreeTab(snapshot: snapshot!),
                      _ScenariosTab(items: snapshot!.scenarios),
                      _BottlenecksTab(items: snapshot!.bottlenecks),
                      _StrategyTab(snapshot: snapshot!),
                    ],
                  ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.snapshot,
  });

  final AtlasExecutiveIntelligenceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.speed, size: 50),
                const SizedBox(height: 10),
                Text(
                  snapshot.scores.overall.toStringAsFixed(0),
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  snapshot.scores.status,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Atualizado em '
                  '${DateFormat('dd/MM/yyyy HH:mm').format(snapshot.generatedAt)}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: snapshot.kpis
              .map(
                (kpi) => SizedBox(
                  width: 230,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(kpi.title),
                          const SizedBox(height: 8),
                          Text(
                            '${kpi.unit == 'R\$' ? 'R\$ ' : ''}'
                            '${kpi.value.toStringAsFixed(1)}'
                            '${kpi.unit == '%' ? '%' : kpi.unit == 'pontos' ? ' pts' : ''}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(kpi.status),
                          const SizedBox(height: 6),
                          Text(kpi.description),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
        _ScoreRow(
          title: 'Score operacional',
          value: snapshot.scores.operational,
        ),
        _ScoreRow(
          title: 'Score econômico',
          value: snapshot.scores.economic,
        ),
        _ScoreRow(
          title: 'Score zootécnico',
          value: snapshot.scores.zootechnical,
        ),
        _ScoreRow(
          title: 'Score sanitário',
          value: snapshot.scores.sanitary,
        ),
      ],
    );
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({
    required this.items,
  });

  final List<AtlasSmartGoalProjection> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Nenhuma meta ativa para projetar.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      item.onTrack
                          ? Icons.trending_up
                          : Icons.trending_down,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.goalTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        item.onTrack
                            ? 'No ritmo'
                            : 'Em risco',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Atual: '
                  '${item.currentProgressPercent.toStringAsFixed(1)}% • '
                  'Projeção: '
                  '${item.projectedProgressPercent.toStringAsFixed(1)}%',
                ),
                Text(
                  '${item.daysRemaining} dia(s) restante(s).',
                ),
                const SizedBox(height: 8),
                Text(
                  item.recommendation,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DecisionTreeTab extends StatelessWidget {
  const _DecisionTreeTab({
    required this.snapshot,
  });

  final AtlasExecutiveIntelligenceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final topScenario = snapshot.scenarios.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Text(
                  'Decisão estratégica selecionada',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(topScenario.title),
                const SizedBox(height: 12),
                const Icon(Icons.keyboard_arrow_down, size: 34),
                ...topScenario.impacts.map(
                  (impact) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.hub_outlined),
                      title: Text(
                        '${impact.area.name} — ${impact.direction}',
                      ),
                      subtitle: Text(impact.explanation),
                      trailing: Text(
                        '${impact.impactPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScenariosTab extends StatelessWidget {
  const _ScenariosTab({
    required this.items,
  });

  final List<AtlasWhatIfScenario> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.science_outlined),
            title: Text(item.title),
            subtitle: Text(item.description),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      'Atual ${item.baseScore.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Projetado ${item.projectedScore.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'R\$ ${item.projectedFinancialImpact.toStringAsFixed(2)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${item.confidencePercent.toStringAsFixed(0)}% confiança',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...item.impacts.map(
                (impact) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_forward),
                  title: Text(
                    '${impact.area.name}: ${impact.direction}',
                  ),
                  subtitle: Text(impact.explanation),
                  trailing: Text(
                    '${impact.impactPercent.toStringAsFixed(0)}%',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottlenecksTab extends StatelessWidget {
  const _BottlenecksTab({
    required this.items,
  });

  final List<AtlasExecutiveBottleneck> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(item.title),
            subtitle: Text(
              '${item.description}\n${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              item.impactScore.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StrategyTab extends StatelessWidget {
  const _StrategyTab({
    required this.snapshot,
  });

  final AtlasExecutiveIntelligenceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Prioridades estratégicas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...snapshot.strategicPriorities.asMap().entries.map(
          (entry) => Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${entry.key + 1}'),
              ),
              title: Text(entry.value),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Painel estratégico integrado',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _ScoreRow(
          title: 'Operacional',
          value: snapshot.scores.operational,
        ),
        _ScoreRow(
          title: 'Econômico',
          value: snapshot.scores.economic,
        ),
        _ScoreRow(
          title: 'Zootécnico',
          value: snapshot.scores.zootechnical,
        ),
        _ScoreRow(
          title: 'Sanitário',
          value: snapshot.scores.sanitary,
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.title,
    required this.value,
  });

  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        trailing: Text(
          '${value.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
