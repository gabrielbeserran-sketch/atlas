import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/atlas_os/domain/models/atlas_os_data.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';

class AtlasOsScreen extends StatefulWidget {
  const AtlasOsScreen({
    required this.data,
    this.executiveBrainData,
    this.onReactiveRefresh,
    this.onOpenExecutiveBrain,
    this.onOpenFarm,
    super.key,
  });

  final AtlasOsData data;
  final AtlasExecutiveBrainData? executiveBrainData;

  final Future<void> Function(AtlasReactiveUpdate update)? onReactiveRefresh;

  final VoidCallback? onOpenExecutiveBrain;
  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasOsScreen> createState() {
    return _AtlasOsScreenState();
  }
}

class _AtlasOsScreenState extends State<AtlasOsScreen> {
  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;

  late List<AtlasOsCommand> commands;

  @override
  void initState() {
    super.initState();

    commands = [...widget.data.commands];

    AtlasReactiveRuntime.instance.start();

    reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.atlasOs,
      handler: _handleReactiveUpdate,
    );
  }

  @override
  void didUpdateWidget(covariant AtlasOsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.data, widget.data)) {
      final completedById = <String, bool>{
        for (final item in commands) item.id: item.completed,
      };

      commands = widget.data.commands.map((item) {
        return item.copyWith(
          completed: completedById[item.id] ?? item.completed,
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    reactiveCoordinator.unregisterHandler(AtlasReactiveTarget.atlasOs);
    super.dispose();
  }

  Future<void> _handleReactiveUpdate(AtlasReactiveUpdate update) async {
    if (!mounted || !update.targets.contains(AtlasReactiveTarget.atlasOs)) {
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
      commands = [...widget.data.commands];
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas OS',
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
                      _AtlasOsHero(data: data),
                      if (widget.executiveBrainData != null &&
                          widget.executiveBrainData!.hasData) ...[
                        const SizedBox(height: 24),
                        _AtlasOsBrainCard(
                          data: widget.executiveBrainData!,
                          onOpen: widget.onOpenExecutiveBrain,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Comandos operacionais',
                        subtitle:
                            'Ações prioritárias coordenadas pelo Atlas OS.',
                      ),
                      const SizedBox(height: 12),
                      _CommandList(
                        items: commands,
                        onChanged: (command, completed) {
                          setState(() {
                            commands = commands.map((item) {
                              return item.id == command.id
                                  ? item.copyWith(completed: completed)
                                  : item;
                            }).toList();
                          });
                        },
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Saúde dos módulos',
                        subtitle: 'Situação das principais camadas do sistema.',
                      ),
                      const SizedBox(height: 12),
                      _ModuleGrid(modules: data.modules),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Ciclo operacional diário',
                        subtitle:
                            'Rotina recomendada para manter a operação sob controle.',
                      ),
                      const SizedBox(height: 12),
                      _DailyCycleList(items: data.dailyCycle),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Itens críticos',
                        subtitle: 'Riscos que exigem acompanhamento direto.',
                      ),
                      const SizedBox(height: 12),
                      _CriticalList(
                        items: data.criticalItems,
                        onOpenFarm: widget.onOpenFarm,
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyAtlasOsView(),
          ),
        ),
      ),
    );
  }
}

class _AtlasOsHero extends StatelessWidget {
  const _AtlasOsHero({required this.data});

  final AtlasOsData data;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(data.status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF050B14), Color(0xFF112536), Color(0xFF1F4A5E)],
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
                  Icon(
                    Icons.memory_outlined,
                    color: Color(0xFFB3E5FC),
                    size: 33,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Sistema Operacional Atlas',
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
                  _HeroMetric(label: 'Módulos', value: data.modules.length),
                  _HeroMetric(label: 'Comandos', value: data.commands.length),
                  _HeroMetric(
                    label: 'Críticos',
                    value: data.criticalItems.length,
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
                  data.healthScore.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  atlasOsStatusLabel(data.status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Execução: '
                  '${data.executionPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  'Metas: '
                  '${data.goalProbabilityPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 11),
                Text(
                  'R\$ ${data.estimatedMonthlyImpact.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFA5D6A7),
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

class _AtlasOsBrainCard extends StatelessWidget {
  const _AtlasOsBrainCard({required this.data, required this.onOpen});

  final AtlasExecutiveBrainData data;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final decision = data.officialDecision;
    final color = switch (data.status) {
      AtlasExecutiveBrainStatus.excellent => const Color(0xFF1B5E20),
      AtlasExecutiveBrainStatus.adequate => const Color(0xFF1565C0),
      AtlasExecutiveBrainStatus.attention => const Color(0xFFEF6C00),
      AtlasExecutiveBrainStatus.critical => const Color(0xFFC62828),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: color, size: 29),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Decisão oficial do Executive Brain',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  data.brainScore.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              decision?.title ?? 'Nenhuma decisão oficial disponível.',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            if (decision != null) ...[
              const SizedBox(height: 6),
              Text(
                decision.description,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                decision.expectedResult,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (onOpen != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir Executive Brain'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommandList extends StatelessWidget {
  const _CommandList({
    required this.items,
    required this.onChanged,
    required this.onOpenFarm,
  });

  final List<AtlasOsCommand> items;

  final void Function(AtlasOsCommand command, bool completed) onChanged;

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
              '${item.source} · ${item.farmName} · '
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
          );
        }).toList(),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.modules});

  final List<AtlasOsModuleState> modules;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return const _EmptySection();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: modules.map((item) {
            final color = _moduleColor(item.status);

            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dns_outlined, color: color),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            item.score.toStringAsFixed(0),
                            style: TextStyle(
                              color: color,
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
                      const SizedBox(height: 11),
                      LinearProgressIndicator(
                        minHeight: 8,
                        value: item.score / 100,
                        backgroundColor: color.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '${atlasOsModuleStatusLabel(item.status)} · '
                        '${item.pendingItems} pendências · '
                        '${item.criticalItems} críticas',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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

class _DailyCycleList extends StatelessWidget {
  const _DailyCycleList({required this.items});

  final List<AtlasOsDailyCycleItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptySection();
    }

    return Card(
      child: Column(
        children: items.map((item) {
          final color = _cycleColor(item.status);

          return ListTile(
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
              '${atlasOsDayPeriodLabel(item.period)} · '
              '${item.description}',
            ),
            trailing: Text(
              atlasOsCycleStatusLabel(item.status),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CriticalList extends StatelessWidget {
  const _CriticalList({required this.items, required this.onOpenFarm});

  final List<AtlasOsCriticalItem> items;
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
              '${item.farmName} · '
              '${item.probabilityPercent.toStringAsFixed(0)}% de probabilidade\n'
              '${item.recommendation}',
            ),
            isThreeLine: true,
            trailing: Text(
              atlasOsSeverityLabel(item.severity),
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

class _EmptyAtlasOsView extends StatelessWidget {
  const _EmptyAtlasOsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum dado disponível para o Atlas OS.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

Color _statusColor(AtlasOsStatus status) {
  switch (status) {
    case AtlasOsStatus.stable:
      return const Color(0xFF80CBC4);

    case AtlasOsStatus.attention:
      return const Color(0xFFFFCC80);

    case AtlasOsStatus.highRisk:
      return const Color(0xFFEF9A9A);

    case AtlasOsStatus.critical:
      return const Color(0xFFFF8A80);
  }
}

Color _moduleColor(AtlasOsModuleStatus status) {
  switch (status) {
    case AtlasOsModuleStatus.active:
      return const Color(0xFF1B5E20);

    case AtlasOsModuleStatus.attention:
      return const Color(0xFFEF6C00);

    case AtlasOsModuleStatus.critical:
      return const Color(0xFFC62828);

    case AtlasOsModuleStatus.unavailable:
      return const Color(0xFF616161);
  }
}

Color _priorityColor(AtlasOsPriority priority) {
  switch (priority) {
    case AtlasOsPriority.low:
      return const Color(0xFF2E7D32);

    case AtlasOsPriority.medium:
      return const Color(0xFF1565C0);

    case AtlasOsPriority.high:
      return const Color(0xFFEF6C00);

    case AtlasOsPriority.critical:
      return const Color(0xFFC62828);
  }
}

Color _cycleColor(AtlasOsCycleStatus status) {
  switch (status) {
    case AtlasOsCycleStatus.pending:
      return const Color(0xFF1565C0);

    case AtlasOsCycleStatus.inProgress:
      return const Color(0xFFEF6C00);

    case AtlasOsCycleStatus.completed:
      return const Color(0xFF1B5E20);
  }
}

Color _severityColor(AtlasOsSeverity severity) {
  switch (severity) {
    case AtlasOsSeverity.low:
      return const Color(0xFF2E7D32);

    case AtlasOsSeverity.medium:
      return const Color(0xFF1565C0);

    case AtlasOsSeverity.high:
      return const Color(0xFFEF6C00);

    case AtlasOsSeverity.critical:
      return const Color(0xFFC62828);
  }
}
