import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/widgets/atlas_command_center_module_card.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';
import 'package:projeto_atlas/features/executive_brain/presentation/screens/atlas_executive_brain_history_screen.dart';
import 'package:projeto_atlas/features/executive_brain/presentation/screens/atlas_executive_brain_historical_intelligence_screen.dart';

class AtlasExecutiveBrainScreen extends StatefulWidget {
  const AtlasExecutiveBrainScreen({
    required this.data,
    this.onOpenFarm,
    this.onReactiveRefresh,
    super.key,
  });

  final AtlasExecutiveBrainData data;
  final ValueChanged<String>? onOpenFarm;
  final Future<AtlasExecutiveBrainData?> Function(AtlasReactiveUpdate update)?
  onReactiveRefresh;

  @override
  State<AtlasExecutiveBrainScreen> createState() {
    return _AtlasExecutiveBrainScreenState();
  }
}

class _AtlasExecutiveBrainScreenState extends State<AtlasExecutiveBrainScreen> {
  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;

  late AtlasExecutiveBrainData currentData;
  late List<AtlasExecutiveBrainAction> dailyPlan;
  late final String reactiveRegistrationId;
  bool isRefreshing = false;
  bool refreshQueued = false;

  @override
  void initState() {
    super.initState();

    currentData = widget.data;
    dailyPlan = [...currentData.dailyPlan];

    AtlasReactiveRuntime.instance.start();

    reactiveRegistrationId = reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.executiveBrain,
      owner: 'atlas_executive_brain_screen',
      handler: _handleReactiveUpdate,
    );
  }

  @override
  void didUpdateWidget(covariant AtlasExecutiveBrainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.data, widget.data)) {
      currentData = widget.data;
      dailyPlan = [...currentData.dailyPlan];
    }
  }

  @override
  void dispose() {
    reactiveCoordinator.unregisterHandlerById(
      target: AtlasReactiveTarget.executiveBrain,
      registrationId: reactiveRegistrationId,
    );
    super.dispose();
  }

  Future<void> _handleReactiveUpdate(AtlasReactiveUpdate update) async {
    if (!mounted ||
        !update.targets.contains(AtlasReactiveTarget.executiveBrain)) {
      return;
    }

    final callback = widget.onReactiveRefresh;

    if (callback == null) {
      return;
    }

    if (isRefreshing) {
      refreshQueued = true;
      return;
    }

    isRefreshing = true;

    try {
      final refreshedData = await callback(update);

      if (!mounted || refreshedData == null) {
        return;
      }

      setState(() {
        currentData = refreshedData;
        dailyPlan = [...refreshedData.dailyPlan];
      });
    } finally {
      isRefreshing = false;

      if (refreshQueued && mounted) {
        refreshQueued = false;
        await _handleReactiveUpdate(update);
      }
    }
  }

  Future<void> _openHistoricalIntelligence() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AtlasExecutiveBrainHistoricalIntelligenceScreen(
            brainData: currentData,
          );
        },
      ),
    );
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasExecutiveBrainHistoryScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = currentData;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Executive Brain',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Inteligência histórica',
            onPressed: _openHistoricalIntelligence,
            icon: const Icon(Icons.history_edu_outlined),
          ),
          IconButton(
            tooltip: 'Histórico de decisões',
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: data.hasData
                ? ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      _BrainHero(data: data),
                      const SizedBox(height: 18),
                      const AtlasCommandCenterModuleCard(
                        module: AtlasCommandCenterModule.executiveBrain,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Executive Score 360°',
                        subtitle:
                            'Composição do índice geral e contribuição de cada dimensão.',
                      ),
                      const SizedBox(height: 12),
                      _ExecutiveScoreGrid(items: data.scoreDimensions),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Executive Radar',
                        subtitle:
                            'Riscos, oportunidades, ganhos rápidos e atividades críticas.',
                      ),
                      const SizedBox(height: 12),
                      _ExecutiveRadarList(items: data.radarItems),
                      if (data.officialDecision != null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Decisão oficial do Atlas',
                          subtitle:
                              'A decisão que deve orientar todos os módulos.',
                        ),
                        const SizedBox(height: 12),
                        _OfficialDecisionCard(
                          item: data.officialDecision!,
                          onOpenFarm: widget.onOpenFarm,
                        ),
                      ],
                      if (data.strategy != null) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Estratégia central',
                          subtitle:
                              'Direção executiva integrada para os próximos 30 dias.',
                        ),
                        const SizedBox(height: 12),
                        _StrategyCard(item: data.strategy!),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Plano de hoje',
                        subtitle:
                            'Ações imediatas priorizadas pelo Executive Brain.',
                      ),
                      const SizedBox(height: 12),
                      _DailyActionList(
                        items: dailyPlan,
                        onChanged: (item, completed) {
                          setState(() {
                            dailyPlan = dailyPlan.map((current) {
                              return current.id == item.id
                                  ? current.copyWith(completed: completed)
                                  : current;
                            }).toList();
                          });
                        },
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Impactos cruzados',
                        subtitle: 'Como uma área pode afetar as demais.',
                      ),
                      const SizedBox(height: 12),
                      _CrossImpactList(items: data.crossImpacts),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Conflitos identificados',
                        subtitle:
                            'Disputas de recursos, prioridades, prazos e execução.',
                      ),
                      const SizedBox(height: 12),
                      _ConflictList(items: data.conflicts),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Plano semanal',
                        subtitle:
                            'Ações coordenadas para os próximos sete dias.',
                      ),
                      const SizedBox(height: 12),
                      _ActionList(
                        items: data.weeklyPlan,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Plano mensal',
                        subtitle:
                            'Ações estratégicas para os próximos 30 dias.',
                      ),
                      const SizedBox(height: 12),
                      _ActionList(
                        items: data.monthlyPlan,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Memória inteligente',
                        subtitle:
                            'Aprendizados extraídos da memória executiva.',
                      ),
                      const SizedBox(height: 12),
                      _MemoryInsightList(items: data.memoryInsights),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyBrainView(),
          ),
        ),
      ),
    );
  }
}

class _ExecutiveScoreGrid extends StatelessWidget {
  const _ExecutiveScoreGrid({required this.items});

  final List<AtlasExecutiveScoreDimension> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptySection();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 600
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final score = item.score.clamp(0.0, 100.0).toDouble();
            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${score.toStringAsFixed(0)}/100',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _scoreColor(score),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: score / 100, minHeight: 8),
                      const SizedBox(height: 10),
                      Text(
                        'Peso: ${item.weightPercent.toStringAsFixed(0)}% · contribuição: ${item.weightedContribution.toStringAsFixed(1)} pontos',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.explanation,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
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

class _ExecutiveRadarList extends StatelessWidget {
  const _ExecutiveRadarList({required this.items});

  final List<AtlasExecutiveRadarItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptySection();
    return Column(
      children: items.map((item) {
        final color = _radarTypeColor(item.type);
        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(_radarTypeIcon(item.type), color: color),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasExecutiveRadarTypeLabel(item.type)} · prioridade ${atlasExecutiveBrainPriorityLabel(item.priority)} · confiança ${item.confidencePercent.toStringAsFixed(0)}%',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(item.description),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Impacto financeiro estimado: ${_formatCurrency(item.expectedFinancialImpact)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Ação recomendada: ${item.recommendedAction}'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _BrainHero extends StatelessWidget {
  const _BrainHero({required this.data});

  final AtlasExecutiveBrainData data;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF02040A), Color(0xFF0E1B2B), Color(0xFF1A3B52)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_outlined, color: Color(0xFFB3E5FC), size: 34),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Atlas Executive Brain',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(color: Colors.white70, height: 1.48),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Impactos',
                    value: data.crossImpacts.length,
                  ),
                  _HeroMetric(label: 'Conflitos', value: data.conflicts.length),
                  _HeroMetric(label: 'Hoje', value: data.dailyPlan.length),
                  _HeroMetric(
                    label: 'Memórias',
                    value: data.memoryInsights.length,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 245,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.brainScore.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  atlasExecutiveBrainStatusLabel(data.status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  '${data.confidencePercent.toStringAsFixed(0)}% de confiança',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 20), side],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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

class _OfficialDecisionCard extends StatelessWidget {
  const _OfficialDecisionCard({required this.item, required this.onOpenFarm});

  final AtlasExecutiveBrainDecision item;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(item.priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel_outlined, color: color, size: 30),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.farmName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.score.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
            const SizedBox(height: 10),
            Text(
              item.reasoning,
              style: const TextStyle(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            ...item.actions.map((action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(action)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Text(
              '${item.deadlineHours} horas · '
              '${item.confidencePercent.toStringAsFixed(0)}% de confiança · '
              '${item.expectedResult}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            if (onOpenFarm != null && item.farmName != 'Operação') ...[
              const SizedBox(height: 12),
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
  }
}

class _StrategyCard extends StatelessWidget {
  const _StrategyCard({required this.item});

  final AtlasExecutiveBrainStrategy item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            Text(item.summary, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 9),
            Text(
              'Objetivo: ${item.objective}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ...item.pillars.map((pillar) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          child: Text(
                            pillar.position.toString(),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pillar.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '${pillar.weightPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      pillar.description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Meta: ${pillar.target}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              '${item.horizonDays} dias · '
              '${item.successProbabilityPercent.toStringAsFixed(0)}% de sucesso · '
              'R\$ ${item.expectedFinancialImpact.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyActionList extends StatelessWidget {
  const _DailyActionList({
    required this.items,
    required this.onChanged,
    required this.onOpenFarm,
  });

  final List<AtlasExecutiveBrainAction> items;

  final void Function(AtlasExecutiveBrainAction item, bool completed) onChanged;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Card(
      child: Column(
        children: items.map((item) {
          final color = _priorityColor(item.priority);

          return CheckboxListTile(
            value: item.completed,
            onChanged: (value) {
              onChanged(item, value ?? false);
            },
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: item.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${item.source} · '
              '${item.farmName} · '
              '${item.deadlineHours} horas\n'
              '${item.description}',
            ),
            isThreeLine: true,
            secondary: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                item.position.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CrossImpactList extends StatelessWidget {
  const _CrossImpactList({required this.items});

  final List<AtlasExecutiveCrossImpact> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = _impactDirectionColor(item.direction);

        return Card(
          child: ListTile(
            leading: Icon(Icons.compare_arrows_outlined, color: color),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.sourceArea} → ${item.affectedArea} · '
              '${item.probabilityPercent.toStringAsFixed(0)}% de probabilidade\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              item.impactScore.toStringAsFixed(0),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ConflictList extends StatelessWidget {
  const _ConflictList({required this.items});

  final List<AtlasExecutiveConflict> items;

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
            leading: Icon(Icons.report_problem_outlined, color: color),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasExecutiveConflictTypeLabel(item.type)} · '
              '${atlasExecutiveBrainSeverityLabel(item.severity)}\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.items, required this.onOpenFarm});

  final List<AtlasExecutiveBrainAction> items;
  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = _priorityColor(item.priority);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                item.position.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasExecutiveBrainHorizonLabel(item.horizon)} · '
              '${item.farmName} · '
              '${item.deadlineHours} horas\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasExecutiveBrainPriorityLabel(item.priority),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            onTap: onOpenFarm == null || item.farmName == 'Operação'
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

class _MemoryInsightList extends StatelessWidget {
  const _MemoryInsightList({required this.items});

  final List<AtlasExecutiveMemoryInsight> items;

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
              Icons.psychology_alt_outlined,
              color: Color(0xFF455A64),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasExecutiveMemoryInsightTypeLabel(item.type)} · '
              '${item.farmName}\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              item.relevanceScore.toStringAsFixed(0),
              style: const TextStyle(
                color: Color(0xFF455A64),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
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
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _EmptyBrainView extends StatelessWidget {
  const _EmptyBrainView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma inteligência executiva disponível.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

String _formatCurrency(double value) {
  final negative = value < 0;
  final digits = value.abs().toStringAsFixed(2).split('.');
  final chars = digits[0].split('').reversed.toList();
  final groups = <String>[];
  for (var i = 0; i < chars.length; i += 3) {
    groups.add(chars.skip(i).take(3).toList().reversed.join());
  }
  final integer = groups.reversed.join('.');
  return '${negative ? '-' : ''}R\$ $integer,${digits[1]}';
}

Color _scoreColor(double score) {
  if (score >= 80) return const Color(0xFF2E7D32);
  if (score >= 65) return const Color(0xFF1565C0);
  if (score >= 50) return const Color(0xFFEF6C00);
  return const Color(0xFFC62828);
}

IconData _radarTypeIcon(AtlasExecutiveRadarType type) {
  switch (type) {
    case AtlasExecutiveRadarType.opportunity:
      return Icons.trending_up;
    case AtlasExecutiveRadarType.risk:
      return Icons.warning_amber_rounded;
    case AtlasExecutiveRadarType.quickWin:
      return Icons.bolt;
    case AtlasExecutiveRadarType.waste:
      return Icons.money_off_csred_outlined;
    case AtlasExecutiveRadarType.criticalActivity:
      return Icons.timer_outlined;
  }
}

Color _radarTypeColor(AtlasExecutiveRadarType type) {
  switch (type) {
    case AtlasExecutiveRadarType.opportunity:
      return const Color(0xFF2E7D32);
    case AtlasExecutiveRadarType.risk:
      return const Color(0xFFC62828);
    case AtlasExecutiveRadarType.quickWin:
      return const Color(0xFF1565C0);
    case AtlasExecutiveRadarType.waste:
      return const Color(0xFF6A1B9A);
    case AtlasExecutiveRadarType.criticalActivity:
      return const Color(0xFFEF6C00);
  }
}

Color _statusColor(AtlasExecutiveBrainStatus status) {
  switch (status) {
    case AtlasExecutiveBrainStatus.excellent:
      return const Color(0xFF80CBC4);

    case AtlasExecutiveBrainStatus.adequate:
      return const Color(0xFFA5D6A7);

    case AtlasExecutiveBrainStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasExecutiveBrainStatus.critical:
      return const Color(0xFFEF9A9A);
  }
}

Color _priorityColor(AtlasExecutiveBrainPriority priority) {
  switch (priority) {
    case AtlasExecutiveBrainPriority.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveBrainPriority.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveBrainPriority.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveBrainPriority.critical:
      return const Color(0xFFC62828);
  }
}

Color _severityColor(AtlasExecutiveBrainSeverity severity) {
  switch (severity) {
    case AtlasExecutiveBrainSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveBrainSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveBrainSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveBrainSeverity.critical:
      return const Color(0xFFC62828);
  }
}

Color _impactDirectionColor(AtlasExecutiveImpactDirection direction) {
  switch (direction) {
    case AtlasExecutiveImpactDirection.positive:
      return const Color(0xFF1B5E20);

    case AtlasExecutiveImpactDirection.negative:
      return const Color(0xFFC62828);

    case AtlasExecutiveImpactDirection.mixed:
      return const Color(0xFF6A1B9A);
  }
}
