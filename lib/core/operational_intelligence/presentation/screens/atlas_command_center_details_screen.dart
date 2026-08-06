import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_plan.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_runtime.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_state.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_insight.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';

class AtlasCommandCenterDetailsScreen extends StatefulWidget {
  const AtlasCommandCenterDetailsScreen({
    this.farmName,
    super.key,
  });

  final String? farmName;

  @override
  State<AtlasCommandCenterDetailsScreen> createState() =>
      _AtlasCommandCenterDetailsScreenState();
}

class _AtlasCommandCenterDetailsScreenState
    extends State<AtlasCommandCenterDetailsScreen> {
  AtlasCommandCenterRuntime get runtime =>
      AtlasCommandCenterRuntime.instance;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load({
    bool forceRefresh = false,
  }) async {
    try {
      await runtime.controller.load(
        farmName: widget.farmName,
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      // O controller publica a falha no store.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: runtime.store,
      builder: (context, child) {
        final state = runtime.store.stateFor(widget.farmName);

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.farmName == null ||
                        widget.farmName!.trim().isEmpty
                    ? 'Command Center'
                    : 'Command Center — ${widget.farmName}',
              ),
              actions: [
                IconButton(
                  tooltip: 'Abrir plano de ação',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AtlasCommandCenterActionPlanScreen(
                          farmName: widget.farmName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.task_alt),
                ),
                IconButton(
                  tooltip: 'Atualizar inteligência',
                  onPressed: state.isLoading
                      ? null
                      : () => _load(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(
                    icon: Icon(Icons.dashboard_outlined),
                    text: 'Visão geral',
                  ),
                  Tab(
                    icon: Icon(Icons.priority_high),
                    text: 'Prioridades',
                  ),
                  Tab(
                    icon: Icon(Icons.lightbulb_outline),
                    text: 'Insights',
                  ),
                  Tab(
                    icon: Icon(Icons.timeline),
                    text: 'Linha do tempo',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics_outlined),
                    text: 'Métricas',
                  ),
                ],
              ),
            ),
            body: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    AtlasCommandCenterState state,
  ) {
    if (state.snapshot == null && state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.snapshot == null && state.hasError) {
      return _CommandCenterErrorState(
        message: state.errorMessage!,
        onRetry: () => _load(forceRefresh: true),
      );
    }

    final snapshot = state.snapshot;

    if (snapshot == null) {
      return _CommandCenterEmptyState(
        onRefresh: () => _load(forceRefresh: true),
      );
    }

    return Stack(
      children: [
        TabBarView(
          children: [
            _OverviewTab(
              snapshot: snapshot,
              state: state,
            ),
            _PrioritiesTab(
              priorities: snapshot.priorities,
              farmName: widget.farmName,
            ),
            _InsightsTab(
              insights: snapshot.insights,
            ),
            _TimelineTab(
              entries: snapshot.timeline.entries,
            ),
            _MetricsTab(
              snapshot: snapshot,
            ),
          ],
        ),
        if (state.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.snapshot,
    required this.state,
  });

  final AtlasCommandCenterSnapshot snapshot;
  final AtlasCommandCenterState state;

  @override
  Widget build(BuildContext context) {
    final metrics = snapshot.metrics;
    final topPriority = snapshot.topPriority;
    final topInsight = snapshot.topInsight;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              title: 'Eventos',
              value: metrics.totalEvents.toString(),
              icon: Icons.event_note_outlined,
            ),
            _MetricCard(
              title: 'Últimas 24h',
              value: metrics.eventsLast24Hours.toString(),
              icon: Icons.schedule,
            ),
            _MetricCard(
              title: 'Críticos',
              value: metrics.criticalEvents.toString(),
              icon: Icons.warning_amber_rounded,
            ),
            _MetricCard(
              title: 'Módulos ativos',
              value: metrics.activeModules.toString(),
              icon: Icons.extension_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Situação da inteligência',
          icon: Icons.hub_outlined,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  'Versão ${state.version?.number ?? 0}',
                ),
              ),
              Chip(
                label: Text(
                  'Atualizada em ${_formatDateTime(state.updatedAt)}',
                ),
              ),
              Chip(
                label: Text(
                  snapshot.farmName ?? 'Operação global',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Principal prioridade',
          icon: Icons.priority_high,
          child: topPriority == null
              ? const Text(
                  'Nenhuma prioridade operacional foi identificada.',
                )
              : _PrioritySummary(priority: topPriority),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Principal insight',
          icon: Icons.lightbulb_outline,
          child: topInsight == null
              ? const Text(
                  'Nenhum insight operacional foi gerado.',
                )
              : _InsightSummary(insight: topInsight),
        ),
      ],
    );
  }
}

class _PrioritiesTab extends StatelessWidget {
  const _PrioritiesTab({
    required this.priorities,
    required this.farmName,
  });

  final List<AtlasOperationalPriority> priorities;
  final String? farmName;

  @override
  Widget build(BuildContext context) {
    if (priorities.isEmpty) {
      return const _SimpleEmptyMessage(
        icon: Icons.task_alt,
        title: 'Nenhuma prioridade pendente',
        description:
            'O motor de prioridades não encontrou ações urgentes.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: priorities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final priority = priorities[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _PrioritySummary(
              priority: priority,
              showDetails: true,
              onCreateAction: () =>
                  _createAction(context, priority),
            ),
          ),
        );
      },
    );
  }

  Future<void> _createAction(
    BuildContext context,
    AtlasOperationalPriority priority,
  ) async {
    final action =
        await AtlasCommandCenterActionService.instance
            .createFromPriority(
      priority: priority,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ação "${action.title}" adicionada ao plano.',
        ),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AtlasCommandCenterActionPlanScreen(
                  farmName: farmName,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({
    required this.insights,
  });

  final List<AtlasOperationalInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const _SimpleEmptyMessage(
        icon: Icons.lightbulb_outline,
        title: 'Nenhum insight disponível',
        description:
            'Novos insights aparecerão conforme a memória operacional crescer.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: insights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final insight = insights[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _InsightSummary(
              insight: insight,
              showDetails: true,
            ),
          ),
        );
      },
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({
    required this.entries,
  });

  final List<AtlasOperationalMemoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _SimpleEmptyMessage(
        icon: Icons.timeline,
        title: 'Linha do tempo vazia',
        description:
            'Os eventos registrados pelos módulos aparecerão aqui.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final entry = entries[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Icon(
              _eventPriorityIcon(entry.priority),
              size: 20,
            ),
          ),
          title: Text(
            entry.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.description),
                const SizedBox(height: 6),
                Text(
                  '${entry.sourceModule} • '
                  '${DateFormat('dd/MM/yyyy HH:mm').format(entry.occurredAt)}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing: Text(
            _eventPriorityLabel(entry.priority),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _MetricsTab extends StatelessWidget {
  const _MetricsTab({
    required this.snapshot,
  });

  final AtlasCommandCenterSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final metrics = snapshot.metrics;
    final modules = metrics.eventsByModule.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final entities = metrics.eventsByEntityType.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final indicators = metrics.numericIndicators.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: 'Resumo temporal',
          icon: Icons.schedule,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(
                label: Text(
                  '${metrics.eventsLast24Hours} nas últimas 24h',
                ),
              ),
              Chip(
                label: Text(
                  '${metrics.eventsLast7Days} nos últimos 7 dias',
                ),
              ),
              Chip(
                label: Text(
                  '${metrics.highPriorityEvents} de alta prioridade',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _MapMetricsSection(
          title: 'Eventos por módulo',
          icon: Icons.extension_outlined,
          entries: modules,
          emptyMessage: 'Nenhum módulo possui eventos registrados.',
        ),
        const SizedBox(height: 16),
        _MapMetricsSection(
          title: 'Eventos por entidade',
          icon: Icons.category_outlined,
          entries: entities,
          emptyMessage: 'Nenhuma entidade foi identificada.',
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Indicadores numéricos encontrados',
          icon: Icons.analytics_outlined,
          child: indicators.isEmpty
              ? const Text(
                  'Nenhum indicador numérico foi encontrado nos eventos.',
                )
              : Column(
                  children: indicators
                      .map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.key),
                          trailing: Text(
                            entry.value.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PrioritySummary extends StatelessWidget {
  const _PrioritySummary({
    required this.priority,
    this.showDetails = false,
    this.onCreateAction,
  });

  final AtlasOperationalPriority priority;
  final bool showDetails;
  final VoidCallback? onCreateAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _canonicalPriorityIcon(priority.priority),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                priority.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              priority.score.toStringAsFixed(0),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(priority.description),
        const SizedBox(height: 8),
        Text(
          priority.recommendedAction,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showDetails) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(priority.sourceModule)),
              Chip(
                label: Text(
                  priority.farmName ?? 'Operação global',
                ),
              ),
              Chip(
                label: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(
                    priority.occurredAt,
                  ),
                ),
              ),
            ],
          ),
          if (onCreateAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreateAction,
              icon: const Icon(Icons.playlist_add_check),
              label: const Text(
                'Adicionar ao plano de ação',
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _InsightSummary extends StatelessWidget {
  const _InsightSummary({
    required this.insight,
    this.showDetails = false,
  });

  final AtlasOperationalInsight insight;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _canonicalPriorityIcon(insight.priority),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                insight.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              '${insight.confidencePercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(insight.description),
        const SizedBox(height: 8),
        Text(
          insight.recommendation,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showDetails) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...insight.modules.map(
                (module) => Chip(label: Text(module)),
              ),
              Chip(
                label: Text(
                  insight.farmName ?? 'Operação global',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MapMetricsSection extends StatelessWidget {
  const _MapMetricsSection({
    required this.title,
    required this.icon,
    required this.entries,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<MapEntry<String, int>> entries;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      icon: icon,
      child: entries.isEmpty
          ? Text(emptyMessage)
          : Column(
              children: entries
                  .map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.key),
                      trailing: Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _CommandCenterErrorState extends StatelessWidget {
  const _CommandCenterErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar o Command Center.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandCenterEmptyState extends StatelessWidget {
  const _CommandCenterEmptyState({
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hub_outlined,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'A inteligência operacional ainda não possui dados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleEmptyMessage extends StatelessWidget {
  const _SimpleEmptyMessage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'ainda não registrada';
  }

  return DateFormat('dd/MM/yyyy HH:mm').format(value);
}

IconData _canonicalPriorityIcon(
  AtlasCanonicalPriority priority,
) {
  switch (priority) {
    case AtlasCanonicalPriority.low:
      return Icons.info_outline;
    case AtlasCanonicalPriority.medium:
      return Icons.remove_circle_outline;
    case AtlasCanonicalPriority.high:
      return Icons.priority_high;
    case AtlasCanonicalPriority.critical:
      return Icons.warning_amber_rounded;
  }
}

IconData _eventPriorityIcon(
  AtlasEventPriority priority,
) {
  switch (priority) {
    case AtlasEventPriority.low:
      return Icons.info_outline;
    case AtlasEventPriority.normal:
      return Icons.circle_outlined;
    case AtlasEventPriority.high:
      return Icons.priority_high;
    case AtlasEventPriority.critical:
      return Icons.warning_amber_rounded;
  }
}

String _eventPriorityLabel(
  AtlasEventPriority priority,
) {
  switch (priority) {
    case AtlasEventPriority.low:
      return 'Baixa';
    case AtlasEventPriority.normal:
      return 'Normal';
    case AtlasEventPriority.high:
      return 'Alta';
    case AtlasEventPriority.critical:
      return 'Crítica';
  }
}
