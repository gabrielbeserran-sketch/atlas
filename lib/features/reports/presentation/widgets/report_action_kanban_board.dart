import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class ReportActionKanbanBoard extends StatelessWidget {
  const ReportActionKanbanBoard({
    required this.actions,
    required this.onEdit,
    required this.onViewHistory,
    required this.onChangeStatus,
    super.key,
  });

  final List<ReportActionItemData> actions;
  final ValueChanged<ReportActionItemData> onEdit;
  final ValueChanged<ReportActionItemData> onViewHistory;
  final void Function(ReportActionItemData action, String status)
  onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final columns = [
      ReportActionKanbanColumnData(
        status: 'Pendente',
        title: 'Pendentes',
        icon: Icons.schedule_outlined,
        color: const Color(0xFFEF6C00),
        actions: _actionsByStatus('Pendente'),
      ),
      ReportActionKanbanColumnData(
        status: 'Em andamento',
        title: 'Em andamento',
        icon: Icons.play_circle_outline,
        color: const Color(0xFF1565C0),
        actions: _actionsByStatus('Em andamento'),
      ),
      ReportActionKanbanColumnData(
        status: 'Concluída',
        title: 'Concluídas',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF1B5E20),
        actions: _actionsByStatus('Concluída'),
      ),
      ReportActionKanbanColumnData(
        status: 'Cancelada',
        title: 'Canceladas',
        icon: Icons.cancel_outlined,
        color: const Color(0xFF607D8B),
        actions: _actionsByStatus('Cancelada'),
      ),
    ];

    if (actions.isEmpty) {
      return const ReportActionKanbanEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1050;
        final tablet = constraints.maxWidth >= 650;

        if (desktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(columns.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == columns.length - 1 ? 0 : 14,
                  ),
                  child: ReportActionKanbanColumn(
                    data: columns[index],
                    onEdit: onEdit,
                    onViewHistory: onViewHistory,
                    onChangeStatus: onChangeStatus,
                  ),
                ),
              );
            }),
          );
        }

        if (tablet) {
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: columns.map((column) {
              return SizedBox(
                width: (constraints.maxWidth - 14) / 2,
                child: ReportActionKanbanColumn(
                  data: column,
                  onEdit: onEdit,
                  onViewHistory: onViewHistory,
                  onChangeStatus: onChangeStatus,
                ),
              );
            }).toList(),
          );
        }

        return Column(
          children: List.generate(columns.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == columns.length - 1 ? 0 : 14,
              ),
              child: ReportActionKanbanColumn(
                data: columns[index],
                onEdit: onEdit,
                onViewHistory: onViewHistory,
                onChangeStatus: onChangeStatus,
              ),
            );
          }),
        );
      },
    );
  }

  List<ReportActionItemData> _actionsByStatus(String status) {
    final filtered = actions.where((action) {
      return action.status == status;
    }).toList();

    filtered.sort(compareReportActions);

    return filtered;
  }
}

class ReportActionKanbanColumn extends StatelessWidget {
  const ReportActionKanbanColumn({
    required this.data,
    required this.onEdit,
    required this.onViewHistory,
    required this.onChangeStatus,
    super.key,
  });

  final ReportActionKanbanColumnData data;
  final ValueChanged<ReportActionItemData> onEdit;
  final ValueChanged<ReportActionItemData> onViewHistory;
  final void Function(ReportActionItemData action, String status)
  onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ReportActionItemData>(
      onWillAcceptWithDetails: (details) {
        return details.data.status != data.status;
      },
      onAcceptWithDetails: (details) {
        onChangeStatus(details.data, data.status);
      },
      builder: (context, candidateData, rejectedData) {
        final isReceiving = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 220),
          decoration: BoxDecoration(
            color: isReceiving
                ? data.color.withValues(alpha: 0.08)
                : const Color(0xFFF1F3F4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isReceiving
                  ? data.color
                  : data.color.withValues(alpha: 0.18),
              width: isReceiving ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isReceiving: isReceiving),
              if (isReceiving)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: data.color.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.move_to_inbox_outlined,
                          color: data.color,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Solte para mover para ${data.title.toLowerCase()}',
                          style: TextStyle(
                            color: data.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (data.actions.isEmpty)
                _buildEmptyColumn(isReceiving: isReceiving)
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: List.generate(data.actions.length, (index) {
                      final action = data.actions[index];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == data.actions.length - 1 ? 0 : 10,
                        ),
                        child: LongPressDraggable<ReportActionItemData>(
                          data: action,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          feedback: ReportActionDragFeedback(
                            action: action,
                            color: data.color,
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.28,
                            child: ReportActionKanbanCard(
                              action: action,
                              columnColor: data.color,
                              onEdit: () {},
                              onViewHistory: () {},
                              onChangeStatus: (_) {},
                            ),
                          ),
                          child: ReportActionKanbanCard(
                            action: action,
                            columnColor: data.color,
                            onEdit: () {
                              onEdit(action);
                            },
                            onViewHistory: () {
                              onViewHistory(action);
                            },
                            onChangeStatus: (status) {
                              onChangeStatus(action, status);
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isReceiving}) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isReceiving)
                  Text(
                    'Destino selecionado',
                    style: TextStyle(
                      color: data.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                data.actions.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn({required bool isReceiving}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 3, 15, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isReceiving
              ? data.color.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(
              data.icon,
              color: data.color.withValues(alpha: 0.55),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhuma ação',
              style: TextStyle(color: data.color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportActionKanbanCard extends StatelessWidget {
  const ReportActionKanbanCard({
    required this.action,
    required this.columnColor,
    required this.onEdit,
    required this.onViewHistory,
    required this.onChangeStatus,
    super.key,
  });

  final ReportActionItemData action;
  final Color columnColor;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;
  final ValueChanged<String> onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final color = action.isOverdue ? const Color(0xFFC62828) : columnColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      action.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    tooltip: 'Alterar status',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 190),
                    onSelected: (value) {
                      if (value == 'Histórico') {
                        onViewHistory();
                        return;
                      }

                      if (value == 'Editar') {
                        onEdit();
                        return;
                      }

                      onChangeStatus(value);
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'Pendente',
                          child: Text('Mover para pendente'),
                        ),
                        PopupMenuItem(
                          value: 'Em andamento',
                          child: Text('Mover para em andamento'),
                        ),
                        PopupMenuItem(
                          value: 'Concluída',
                          child: Text('Marcar como concluída'),
                        ),
                        PopupMenuItem(
                          value: 'Cancelada',
                          child: Text('Cancelar ação'),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'Histórico',
                          child: Row(
                            children: [
                              Icon(Icons.history_outlined),
                              SizedBox(width: 10),
                              Text('Ver histórico'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Editar ação'),
                            ],
                          ),
                        ),
                      ];
                    },
                    icon: const Icon(Icons.more_vert, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                action.action,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (action.farmName.isNotEmpty)
                    ReportActionKanbanTag(
                      icon: Icons.home_work_outlined,
                      text: action.farmName,
                      color: const Color(0xFF1565C0),
                    ),
                  ReportActionKanbanTag(
                    icon: Icons.flag_outlined,
                    text: action.priority,
                    color: kanbanPriorityColor(action.priority),
                  ),
                  if (action.deadline.isNotEmpty)
                    ReportActionKanbanTag(
                      icon: Icons.schedule_outlined,
                      text: action.deadline,
                      color: action.isOverdue
                          ? const Color(0xFFC62828)
                          : const Color(0xFFEF6C00),
                    ),
                ],
              ),
              if (action.responsible.trim().isNotEmpty) ...[
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        action.responsible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (action.isOverdue) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: Color(0xFFC62828),
                        size: 17,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Prazo vencido',
                        style: TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ReportActionDragFeedback extends StatelessWidget {
  const ReportActionDragFeedback({
    required this.action,
    required this.color,
    super.key,
  });

  final ReportActionItemData action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.drag_indicator, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    action.farmName.isEmpty
                        ? action.status
                        : '${action.farmName} · ${action.status}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportActionKanbanTag extends StatelessWidget {
  const ReportActionKanbanTag({
    required this.icon,
    required this.text,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 185),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportActionKanbanColumnData {
  const ReportActionKanbanColumnData({
    required this.status,
    required this.title,
    required this.icon,
    required this.color,
    required this.actions,
  });

  final String status;
  final String title;
  final IconData icon;
  final Color color;
  final List<ReportActionItemData> actions;
}

class ReportActionKanbanEmptyState extends StatelessWidget {
  const ReportActionKanbanEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(38),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.view_kanban_outlined,
                color: Color(0xFF1B5E20),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma ação para exibir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF263238),
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crie ações ou altere os filtros para visualizar o quadro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color kanbanPriorityColor(String priority) {
  switch (priority) {
    case 'Muito alta':
    case 'Urgente':
      return const Color(0xFFC62828);

    case 'Alta':
      return const Color(0xFFEF6C00);

    case 'Média':
    case 'Normal':
      return const Color(0xFF1565C0);

    default:
      return const Color(0xFF1B5E20);
  }
}
