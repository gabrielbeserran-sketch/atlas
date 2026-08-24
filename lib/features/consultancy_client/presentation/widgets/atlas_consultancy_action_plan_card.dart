import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_consultancy_action.dart';

class AtlasConsultancyActionPlanCard extends StatelessWidget {
  const AtlasConsultancyActionPlanCard({
    required this.actions,
    required this.canManage,
    required this.busy,
    required this.hasPriorities,
    required this.onCreateFromPriorities,
    required this.onComplete,
    super.key,
  });

  final List<AtlasConsultancyAction> actions;
  final bool canManage;
  final bool busy;
  final bool hasPriorities;
  final VoidCallback onCreateFromPriorities;
  final ValueChanged<AtlasConsultancyAction> onComplete;

  @override
  Widget build(BuildContext context) {
    final open = actions.where((item) => item.isOpen).toList(growable: false);
    final completed = actions.where((item) => item.isCompleted).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.assignment_turned_in_outlined)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plano de ação da consultoria',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Ações confirmadas entram automaticamente na Agenda e permanecem sincronizadas.',
                      ),
                    ],
                  ),
                ),
                Text('${open.length} abertas • $completed concluídas'),
              ],
            ),
            const SizedBox(height: 14),
            if (open.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhuma ação consultiva aberta para esta fazenda.'),
              )
            else
              ...open.take(5).map(
                (action) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    action.priority == 'critical'
                        ? Icons.error_outline
                        : Icons.task_alt_outlined,
                  ),
                  title: Text(
                    action.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_subtitle(action)),
                  trailing: canManage
                      ? IconButton(
                          tooltip: 'Concluir ação',
                          onPressed: busy ? null : () => onComplete(action),
                          icon: const Icon(Icons.check_circle_outline),
                        )
                      : null,
                ),
              ),
            if (canManage) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: busy || !hasPriorities ? null : onCreateFromPriorities,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_add_check_circle_outlined),
                label: const Text('Transformar prioridades em plano'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle(AtlasConsultancyAction action) {
    final parts = <String>[
      action.area,
      _priorityLabel(action.priority),
      if (action.dueAt != null)
        'Prazo ${action.dueAt!.day.toString().padLeft(2, '0')}/'
            '${action.dueAt!.month.toString().padLeft(2, '0')}/'
            '${action.dueAt!.year}',
      if (action.agendaTaskId.isNotEmpty) 'Agenda sincronizada',
    ];
    if (action.description.trim().isNotEmpty) {
      parts.add(action.description.trim());
    }
    return parts.join(' • ');
  }

  String _priorityLabel(String value) {
    switch (value) {
      case 'critical':
        return 'Crítica';
      case 'high':
        return 'Alta';
      case 'low':
        return 'Baixa';
      default:
        return 'Média';
    }
  }
}
