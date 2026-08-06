import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_monitoring_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_monitoring_item.dart';

class AtlasMeetingDecisionMonitoringScreen extends StatefulWidget {
  const AtlasMeetingDecisionMonitoringScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasMeetingDecisionMonitoringScreen> createState() =>
      _AtlasMeetingDecisionMonitoringScreenState();
}

class _AtlasMeetingDecisionMonitoringScreenState
    extends State<AtlasMeetingDecisionMonitoringScreen> {
  late final AtlasMeetingDecisionMonitoringController controller;

  final AtlasMeetingDecisionActionService actionService =
      AtlasMeetingDecisionActionService.instance;

  @override
  void initState() {
    super.initState();

    controller = AtlasMeetingDecisionMonitoringController(
      farmName: widget.actionController.farmName,
    )..load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Central de decisões'),
            actions: [
              IconButton(
                tooltip: 'Atualizar monitoramento',
                onPressed: controller.isLoading ? null : controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (controller.isLoading && controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar as decisões: '
            '${controller.errorMessage}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (controller.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma decisão foi registrada nas reuniões.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('${controller.pendingCount} pendente(s)')),
              Chip(label: Text('${controller.overdueCount} atrasada(s)')),
              Chip(
                label: Text('${controller.dueSoonCount} próxima(s) do prazo'),
              ),
              Chip(
                label: Text(
                  '${controller.withoutResponsibleCount} sem responsável',
                ),
              ),
              Chip(
                label: Text('${controller.withoutLinkedActionCount} sem ação'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: controller.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = controller.items[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.isCompleted
                                ? Icons.task_alt
                                : item.isOverdue
                                ? Icons.event_busy
                                : Icons.gavel_outlined,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.decision.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (item.decision.description.trim().isNotEmpty)
                        Text(item.decision.description),
                      const SizedBox(height: 8),
                      Text('Reunião: ${item.meeting.title}'),
                      Text(
                        'Responsável: '
                        '${item.hasResponsible ? item.decision.responsibleName : 'Não definido'}',
                      ),
                      Text(
                        item.decision.dueAt == null
                            ? 'Prazo: não definido'
                            : 'Prazo: ${DateFormat('dd/MM/yyyy').format(item.decision.dueAt!)}',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.statuses
                            .map(
                              (status) => Chip(
                                label: Text(
                                  atlasMeetingDecisionMonitoringStatusLabel(
                                    status,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: item.hasLinkedAction
                              ? null
                              : () async {
                                  await actionService.createAction(
                                    meeting: item.meeting,
                                    decision: item.decision,
                                  );

                                  await widget.actionController.load();
                                  await controller.load();

                                  if (!mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Decisão transformada em ação.',
                                      ),
                                    ),
                                  );
                                },
                          icon: Icon(
                            item.hasLinkedAction
                                ? Icons.link
                                : Icons.playlist_add_check,
                          ),
                          label: Text(
                            item.hasLinkedAction
                                ? 'Ação vinculada'
                                : 'Transformar em ação',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
