import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/presentation/screens/atlas_command_center_details_screen.dart';
import 'package:projeto_atlas/core/operational_intelligence/adapters/atlas_copilot_command_center_view.dart';
import 'package:projeto_atlas/core/operational_intelligence/adapters/atlas_dashboard_command_center_view.dart';
import 'package:projeto_atlas/core/operational_intelligence/adapters/atlas_digital_twin_command_center_view.dart';
import 'package:projeto_atlas/core/operational_intelligence/adapters/atlas_executive_brain_command_center_view.dart';
import 'package:projeto_atlas/core/operational_intelligence/adapters/atlas_technical_dashboard_command_center_view.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_runtime.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_state.dart';

enum AtlasCommandCenterModule {
  executiveDashboard,
  executiveBrain,
  copilot,
  technicalDashboard,
  digitalTwin,
}

class AtlasCommandCenterModuleCard extends StatefulWidget {
  const AtlasCommandCenterModuleCard({
    required this.module,
    this.farmName,
    super.key,
  });

  final AtlasCommandCenterModule module;
  final String? farmName;

  @override
  State<AtlasCommandCenterModuleCard> createState() =>
      _AtlasCommandCenterModuleCardState();
}

class _AtlasCommandCenterModuleCardState
    extends State<AtlasCommandCenterModuleCard> {
  AtlasCommandCenterRuntime get runtime =>
      AtlasCommandCenterRuntime.instance;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void didUpdateWidget(
    covariant AtlasCommandCenterModuleCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.farmName != widget.farmName ||
        oldWidget.module != widget.module) {
      _load();
    }
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
      // O estado de erro é publicado pelo controller e exibido no card.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: runtime.store,
      builder: (context, child) {
        final state = runtime.store.stateFor(widget.farmName);

        return _CommandCenterCardContent(
          module: widget.module,
          farmName: widget.farmName,
          state: state,
          onRefresh: () => _load(forceRefresh: true),
        );
      },
    );
  }
}

class _CommandCenterCardContent extends StatelessWidget {
  const _CommandCenterCardContent({
    required this.module,
    required this.farmName,
    required this.state,
    required this.onRefresh,
  });

  final AtlasCommandCenterModule module;
  final String? farmName;
  final AtlasCommandCenterState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: snapshot == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AtlasCommandCenterDetailsScreen(
                      farmName: farmName,
                    ),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: snapshot == null
              ? _buildUnavailableContent(context)
              : _buildSnapshotContent(context),
        ),
      ),
    );
  }

  Widget _buildUnavailableContent(
    BuildContext context,
  ) {
    if (state.isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Consolidando a inteligência operacional...',
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          state.hasError
              ? Icons.warning_amber_rounded
              : Icons.hub_outlined,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            state.hasError
                ? 'Não foi possível carregar o Command Center: '
                    '${state.errorMessage}'
                : 'A inteligência operacional ainda não possui dados.',
          ),
        ),
        IconButton(
          tooltip: 'Tentar novamente',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildSnapshotContent(
    BuildContext context,
  ) {
    final snapshot = state.snapshot!;
    final summary = _summary(snapshot);
    final detail = _detail(snapshot);
    final version = state.version?.number ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hub_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Atualizar Command Center',
              onPressed: state.isLoading ? null : onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          summary,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          style: const TextStyle(
            color: Colors.black54,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(
                Icons.event_note_outlined,
                size: 17,
              ),
              label: Text(
                '${snapshot.metrics.totalEvents} eventos',
              ),
            ),
            Chip(
              avatar: const Icon(
                Icons.warning_amber_outlined,
                size: 17,
              ),
              label: Text(
                '${snapshot.metrics.criticalEvents} críticos',
              ),
            ),
            Chip(
              avatar: const Icon(
                Icons.extension_outlined,
                size: 17,
              ),
              label: Text(
                '${snapshot.metrics.activeModules} módulos',
              ),
            ),
            Chip(
              avatar: const Icon(
                Icons.update_outlined,
                size: 17,
              ),
              label: Text('Versão $version'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Abrir Command Center',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.arrow_forward,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _title {
    switch (module) {
      case AtlasCommandCenterModule.executiveDashboard:
        return 'Command Center executivo';
      case AtlasCommandCenterModule.executiveBrain:
        return 'Command Center do Executive Brain';
      case AtlasCommandCenterModule.copilot:
        return 'Contexto operacional do Copilot';
      case AtlasCommandCenterModule.technicalDashboard:
        return 'Command Center técnico';
      case AtlasCommandCenterModule.digitalTwin:
        return 'Command Center do Digital Twin';
    }
  }

  String _summary(snapshot) {
    switch (module) {
      case AtlasCommandCenterModule.executiveDashboard:
        final view =
            AtlasDashboardCommandCenterView.fromSnapshot(snapshot);
        return view.topPriority?.title ??
            'Operação consolidada sem prioridade crítica pendente.';

      case AtlasCommandCenterModule.executiveBrain:
        final view =
            AtlasExecutiveBrainCommandCenterView.fromSnapshot(snapshot);
        return view.officialPriority?.title ??
            'Nenhuma decisão operacional prioritária detectada.';

      case AtlasCommandCenterModule.copilot:
        final view =
            AtlasCopilotCommandCenterView.fromSnapshot(snapshot);
        return view.contextSummary;

      case AtlasCommandCenterModule.technicalDashboard:
        final view =
            AtlasTechnicalDashboardCommandCenterView.fromSnapshot(
          snapshot,
        );
        return '${view.eventsLast24Hours} evento(s) nas últimas '
            '24 horas e ${view.eventsLast7Days} nos últimos 7 dias.';

      case AtlasCommandCenterModule.digitalTwin:
        final view =
            AtlasDigitalTwinCommandCenterView.fromSnapshot(snapshot);
        return 'Saúde operacional estimada em '
            '${view.operationalHealthPercent.toStringAsFixed(0)}%.';
    }
  }

  String _detail(snapshot) {
    switch (module) {
      case AtlasCommandCenterModule.executiveDashboard:
        final view =
            AtlasDashboardCommandCenterView.fromSnapshot(snapshot);
        return view.topInsight?.description ??
            'Os módulos estão compartilhando a mesma memória operacional.';

      case AtlasCommandCenterModule.executiveBrain:
        final view =
            AtlasExecutiveBrainCommandCenterView.fromSnapshot(snapshot);
        return 'Score operacional: '
            '${view.operationalScore.toStringAsFixed(0)}. '
            '${view.insights.isEmpty ? 'Sem novos insights.' : view.insights.first.description}';

      case AtlasCommandCenterModule.copilot:
        final view =
            AtlasCopilotCommandCenterView.fromSnapshot(snapshot);
        return view.insights.isEmpty
            ? 'O Copilot já pode utilizar o contexto consolidado da operação.'
            : view.insights.first.description;

      case AtlasCommandCenterModule.technicalDashboard:
        final view =
            AtlasTechnicalDashboardCommandCenterView.fromSnapshot(
          snapshot,
        );
        return '${view.criticalEvents} ocorrência(s) crítica(s) e '
            '${view.highPriorityEvents} de alta prioridade.';

      case AtlasCommandCenterModule.digitalTwin:
        final view =
            AtlasDigitalTwinCommandCenterView.fromSnapshot(snapshot);
        return '${view.recentEvents} evento(s) recente(s), '
            '${view.activeModules} módulo(s) ativos e '
            '${view.priorities.length} prioridade(s) consolidadas.';
    }
  }
}
