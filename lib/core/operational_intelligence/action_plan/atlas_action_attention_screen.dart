import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_attention.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_attention_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';

class AtlasActionAttentionScreen extends StatefulWidget {
  const AtlasActionAttentionScreen({
    required this.actionController,
    this.onOpenAction,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;
  final ValueChanged<String>? onOpenAction;

  @override
  State<AtlasActionAttentionScreen> createState() =>
      _AtlasActionAttentionScreenState();
}

class _AtlasActionAttentionScreenState
    extends State<AtlasActionAttentionScreen> {
  final AtlasActionAttentionController controller =
      AtlasActionAttentionController();

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _rebuild() {
    return controller.rebuild(
      actions: widget.actionController.actions,
      latestUpdateDates: <String, DateTime>{
        for (final action in widget.actionController.actions)
          if (widget.actionController.latestUpdateFor(action.id) != null)
            action.id: widget.actionController.latestUpdateFor(action.id)!,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Central de atenção'),
            actions: [
              IconButton(
                tooltip: 'Atualizar alertas',
                onPressed: controller.isLoading ? null : _rebuild,
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

    if (controller.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt, size: 56),
              SizedBox(height: 16),
              Text(
                'Nenhuma atenção operacional pendente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(
                avatar: const Icon(Icons.warning_amber_rounded, size: 17),
                label: Text('${controller.criticalCount} crítica(s)'),
              ),
              Chip(
                avatar: const Icon(
                  Icons.notification_important_outlined,
                  size: 17,
                ),
                label: Text('${controller.warningCount} atenção(ões)'),
              ),
              Chip(label: Text('${controller.items.length} no total')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: controller.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final attention = controller.items[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_iconFor(attention)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              attention.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              atlasActionAttentionSeverityLabel(
                                attention.severity,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(attention.description),
                      const SizedBox(height: 8),
                      Text(
                        attention.recommendedAction,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Text('Ação: ${attention.action.title}'),
                      if (attention.action.dueAt != null)
                        Text(
                          'Prazo: ${DateFormat('dd/MM/yyyy HH:mm').format(attention.action.dueAt!)}',
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await controller.snooze(attention);
                            },
                            icon: const Icon(Icons.snooze),
                            label: const Text('Adiar 24 horas'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              widget.onOpenAction?.call(attention.action.id);
                              Navigator.of(context).pop(attention.action.id);
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Abrir ação'),
                          ),
                        ],
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

  IconData _iconFor(AtlasActionAttention attention) {
    switch (attention.type) {
      case AtlasActionAttentionType.overdue:
        return Icons.event_busy;
      case AtlasActionAttentionType.dueSoon:
        return Icons.schedule;
      case AtlasActionAttentionType.withoutResponsible:
        return Icons.person_off_outlined;
      case AtlasActionAttentionType.withoutFollowUp:
        return Icons.history_toggle_off;
      case AtlasActionAttentionType.blocked:
        return Icons.block;
    }
  }
}
