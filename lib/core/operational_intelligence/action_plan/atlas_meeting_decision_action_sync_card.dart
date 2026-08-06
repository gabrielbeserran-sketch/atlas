import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_sync_controller.dart';

class AtlasMeetingDecisionActionSyncCard
    extends StatefulWidget {
  const AtlasMeetingDecisionActionSyncCard({
    this.farmName,
    this.onSynchronized,
    super.key,
  });

  final String? farmName;
  final Future<void> Function()? onSynchronized;

  @override
  State<AtlasMeetingDecisionActionSyncCard> createState() =>
      _AtlasMeetingDecisionActionSyncCardState();
}

class _AtlasMeetingDecisionActionSyncCardState
    extends State<AtlasMeetingDecisionActionSyncCard> {
  late final AtlasMeetingDecisionActionSyncController controller;

  @override
  void initState() {
    super.initState();

    controller =
        AtlasMeetingDecisionActionSyncController(
      farmName: widget.farmName,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    final result = await controller.synchronize();

    if (result != null && widget.onSynchronized != null) {
      await widget.onSynchronized!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final result = controller.lastResult;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync_alt),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sincronização reunião ↔ plano',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: controller.isSyncing
                          ? null
                          : _sync,
                      icon: controller.isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Sincronizar'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mantém conclusão, responsável e prazo '
                  'alinhados entre decisões e ações vinculadas.',
                ),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Falha: ${controller.errorMessage}',
                  ),
                ],
                if (result != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          '${result.checkedLinks} vínculo(s)',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${result.updatedDecisions} decisão(ões) atualizada(s)',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${result.updatedActions} ação(ões) atualizada(s)',
                        ),
                      ),
                      if (result.missingActions > 0)
                        Chip(
                          label: Text(
                            '${result.missingActions} vínculo(s) quebrado(s)',
                          ),
                        ),
                      if (result.repairedLinks > 0)
                        Chip(
                          avatar: const Icon(
                            Icons.build_circle_outlined,
                            size: 17,
                          ),
                          label: Text(
                            '${result.repairedLinks} reparado(s)',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Última sincronização: '
                    '${DateFormat('dd/MM/yyyy HH:mm').format(result.syncedAt)}',
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
