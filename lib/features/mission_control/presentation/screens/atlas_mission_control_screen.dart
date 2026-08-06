import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/mission_control/domain/models/atlas_mission_control_data.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';

class AtlasMissionControlScreen extends StatefulWidget {
  const AtlasMissionControlScreen({
    required this.data,
    this.executiveBrainData,
    this.onReactiveRefresh,
    this.onOpenExecutiveBrain,
    this.onOpenFarm,
    super.key,
  });

  final AtlasMissionControlData data;
  final AtlasExecutiveBrainData? executiveBrainData;

  final Future<void> Function(
    AtlasReactiveUpdate update,
  )? onReactiveRefresh;

  final VoidCallback? onOpenExecutiveBrain;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasMissionControlScreen> createState() {
    return _AtlasMissionControlScreenState();
  }
}

class _AtlasMissionControlScreenState extends State<AtlasMissionControlScreen> {
  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;

  late List<AtlasMissionDailyAction> dailyPlan;

  @override
  void initState() {
    super.initState();

    dailyPlan = [...widget.data.dailyPlan];

    AtlasReactiveRuntime.instance.start();

    reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.missionControl,
      handler: _handleReactiveUpdate,
    );
  }

  @override
  void didUpdateWidget(
    covariant AtlasMissionControlScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.data, widget.data)) {
      final completedByPosition = <int, bool>{
        for (final item in dailyPlan)
          item.position: item.completed,
      };

      dailyPlan = widget.data.dailyPlan.map((item) {
        return item.copyWith(
          completed:
              completedByPosition[item.position] ??
                  item.completed,
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    reactiveCoordinator.unregisterHandler(
      AtlasReactiveTarget.missionControl,
    );
    super.dispose();
  }

  Future<void> _handleReactiveUpdate(
    AtlasReactiveUpdate update,
  ) async {
    if (!mounted ||
        !update.targets.contains(
          AtlasReactiveTarget.missionControl,
        )) {
      return;
    }

    final callback = widget.onReactiveRefresh;

    if (callback != null) {
      await callback(update);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      dailyPlan = [...widget.data.dailyPlan];
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Mission Control',
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
                      _MissionHero(data: data),
                      if (widget.executiveBrainData != null &&
                          widget.executiveBrainData!.hasData) ...[
                        const SizedBox(height: 24),
                        _MissionOfficialDecisionCard(
                          data: widget.executiveBrainData!,
                          onOpen: widget.onOpenExecutiveBrain,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Plano de hoje',
                        subtitle: 'Ações que exigem execução imediata.',
                      ),
                      const SizedBox(height: 12),
                      _DailyPlan(
                        items: dailyPlan,
                        onChanged: (item, completed) {
                          setState(() {
                            dailyPlan = dailyPlan.map((current) {
                              return current.position == item.position
                                  ? current.copyWith(completed: completed)
                                  : current;
                            }).toList();
                          });
                        },
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Prioridades globais',
                        subtitle:
                            'Ranking consolidado de decisões, riscos e execução.',
                      ),
                      const SizedBox(height: 12),
                      _PriorityList(
                        items: data.priorities,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Alertas',
                        subtitle:
                            'Riscos e atrasos que podem comprometer os resultados.',
                      ),
                      const SizedBox(height: 12),
                      _AlertList(
                        items: data.alerts,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Workflows',
                        subtitle: 'Progresso dos planos em execução.',
                      ),
                      const SizedBox(height: 12),
                      _WorkflowList(
                        items: data.workflows,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Decisões',
                        subtitle:
                            'Principais decisões recomendadas pelo Atlas.',
                      ),
                      const SizedBox(height: 12),
                      _DecisionList(
                        items: data.decisions,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyMissionView(),
          ),
        ),
      ),
    );
  }
}

class _MissionHero extends StatelessWidget {
  const _MissionHero({required this.data});

  final AtlasMissionControlData data;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF07111F), Color(0xFF132A3A), Color(0xFF254B62)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.greeting,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aqui está o resumo executivo da operação.',
                style: TextStyle(
                  color: Color(0xFFB3E5FC),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(color: Colors.white70, height: 1.48),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Prioridades',
                    value: data.priorities.length,
                  ),
                  _HeroMetric(label: 'Alertas', value: data.alerts.length),
                  _HeroMetric(label: 'Workflows', value: data.workflows.length),
                ],
              ),
            ],
          );

          final side = Container(
            width: 250,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.globalScore.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  atlasMissionControlStatusLabel(data.status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Execução prevista: '
                  '${data.executionProbabilityPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  'Metas: '
                  '${data.goalProbabilityPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Text(
                  'R\$ ${data.estimatedMonthlyImpact.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFA5D6A7),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Impacto mensal estimado',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
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

class _MissionOfficialDecisionCard extends StatelessWidget {
  const _MissionOfficialDecisionCard({
    required this.data,
    required this.onOpen,
  });

  final AtlasExecutiveBrainData data;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final decision = data.officialDecision;

    if (decision == null) {
      return const SizedBox.shrink();
    }

    final color = switch (decision.priority) {
      AtlasExecutiveBrainPriority.low => const Color(0xFF2E7D32),
      AtlasExecutiveBrainPriority.medium => const Color(0xFF1565C0),
      AtlasExecutiveBrainPriority.high => const Color(0xFFEF6C00),
      AtlasExecutiveBrainPriority.critical => const Color(0xFFC62828),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel_outlined, color: color, size: 29),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Decisão oficial do Atlas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  decision.score.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              decision.title,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              decision.description,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              '${decision.deadlineHours} horas · '
              '${decision.confidencePercent.toStringAsFixed(0)}% de confiança · '
              '${decision.expectedResult}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (onOpen != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver estratégia completa'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyPlan extends StatelessWidget {
  const _DailyPlan({
    required this.items,
    required this.onChanged,
    required this.onOpenFarm,
  });

  final List<AtlasMissionDailyAction> items;

  final void Function(AtlasMissionDailyAction item, bool completed) onChanged;

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
              '${item.farmName} · '
              '${item.deadlineHours} horas\n'
              '${item.expectedImpact}',
            ),
            isThreeLine: true,
            secondary: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                item.position.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
          );
        }).toList(),
      ),
    );
  }
}

class _PriorityList extends StatelessWidget {
  const _PriorityList({required this.items, required this.onOpenFarm});

  final List<AtlasMissionPriority> items;
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
              '${atlasMissionSourceLabel(item.source)} · '
              '${item.farmName} · '
              '${atlasMissionUrgencyLabel(item.urgency)}\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              item.impactScore.toStringAsFixed(0),
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

class _AlertList extends StatelessWidget {
  const _AlertList({required this.items, required this.onOpenFarm});

  final List<AtlasMissionAlert> items;
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
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${atlasMissionSourceLabel(item.source)} · '
              '${item.farmName}\n'
              '${item.description}',
            ),
            isThreeLine: true,
            trailing: Text(
              '${item.probabilityPercent.toStringAsFixed(0)}%',
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

class _WorkflowList extends StatelessWidget {
  const _WorkflowList({required this.items, required this.onOpenFarm});

  final List<AtlasMissionWorkflowSummary> items;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Column(
      children: items.map((item) {
        final color = _workflowColor(item.status);

        return Card(
          child: ListTile(
            leading: Icon(Icons.schema_outlined, color: color),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.farmName} · '
              '${item.completedTasks}/${item.totalTasks} tarefas · '
              '${item.delayedTasks} atrasadas',
            ),
            trailing: Text(
              '${item.progressPercent.toStringAsFixed(0)}%',
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

class _DecisionList extends StatelessWidget {
  const _DecisionList({required this.items, required this.onOpenFarm});

  final List<AtlasMissionDecisionSummary> items;

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
              '${item.farmName} · '
              '${item.deadlineDays} dias · '
              '${item.confidencePercent.toStringAsFixed(0)}% de confiança',
            ),
            trailing: Text(
              'R\$ ${item.expectedFinancialImpact.toStringAsFixed(0)}',
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

class _EmptyMissionView extends StatelessWidget {
  const _EmptyMissionView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum dado disponível para o Mission Control.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

Color _statusColor(AtlasMissionControlStatus status) {
  switch (status) {
    case AtlasMissionControlStatus.stable:
      return const Color(0xFF80CBC4);

    case AtlasMissionControlStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasMissionControlStatus.highRisk:
      return const Color(0xFFEF9A9A);

    case AtlasMissionControlStatus.critical:
      return const Color(0xFFFF8A80);
  }
}

Color _priorityColor(AtlasMissionPriorityLevel priority) {
  switch (priority) {
    case AtlasMissionPriorityLevel.low:
      return const Color(0xFF2E7D32);

    case AtlasMissionPriorityLevel.medium:
      return const Color(0xFF1565C0);

    case AtlasMissionPriorityLevel.high:
      return const Color(0xFFEF6C00);

    case AtlasMissionPriorityLevel.critical:
      return const Color(0xFFC62828);
  }
}

Color _severityColor(AtlasMissionSeverity severity) {
  switch (severity) {
    case AtlasMissionSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasMissionSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasMissionSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasMissionSeverity.critical:
      return const Color(0xFFC62828);
  }
}

Color _workflowColor(AtlasMissionWorkflowStatus status) {
  switch (status) {
    case AtlasMissionWorkflowStatus.planned:
      return const Color(0xFF1565C0);

    case AtlasMissionWorkflowStatus.inProgress:
      return const Color(0xFFEF6C00);

    case AtlasMissionWorkflowStatus.delayed:
      return const Color(0xFFC62828);

    case AtlasMissionWorkflowStatus.completed:
      return const Color(0xFF1B5E20);

    case AtlasMissionWorkflowStatus.cancelled:
      return const Color(0xFF616161);
  }
}
