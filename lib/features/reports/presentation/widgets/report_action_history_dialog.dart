import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_history_storage_service.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class ReportActionHistoryDialog extends StatefulWidget {
  const ReportActionHistoryDialog({required this.action, super.key});

  final ReportActionItemData action;

  @override
  State<ReportActionHistoryDialog> createState() {
    return _ReportActionHistoryDialogState();
  }
}

class _ReportActionHistoryDialogState extends State<ReportActionHistoryDialog> {
  final ReportActionHistoryStorageService storage =
      ReportActionHistoryStorageService();

  List<ReportActionHistoryData> history = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final loadedHistory = await storage.loadActionHistory(widget.action.id);

    if (!mounted) {
      return;
    }

    setState(() {
      history = loadedHistory;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : history.isEmpty
                  ? const ReportActionHistoryEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(22),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];

                        return ReportActionHistoryTimelineItem(
                          item: item,
                          isFirst: index == 0,
                          isLast: index == history.length - 1,
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: loadHistory,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Atualizar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                    ),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.history_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Histórico da ação',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ReportActionHistoryHeaderChip(
                      icon: Icons.home_work_outlined,
                      label: widget.action.farmName.isEmpty
                          ? 'Todas as fazendas'
                          : widget.action.farmName,
                    ),
                    ReportActionHistoryHeaderChip(
                      icon: Icons.task_alt_outlined,
                      label: widget.action.status,
                    ),
                    ReportActionHistoryHeaderChip(
                      icon: Icons.flag_outlined,
                      label: widget.action.priority,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () {
              Navigator.pop(context);
            },
            color: Colors.white,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class ReportActionHistoryHeaderChip extends StatelessWidget {
  const ReportActionHistoryHeaderChip({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportActionHistoryTimelineItem extends StatelessWidget {
  const ReportActionHistoryTimelineItem({
    required this.item,
    required this.isFirst,
    required this.isLast,
    super.key,
  });

  final ReportActionHistoryData item;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = reportActionHistoryColor(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            children: [
              if (!isFirst)
                Container(width: 2, height: 14, color: Colors.black12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(
                  reportActionHistoryIcon(item),
                  color: color,
                  size: 18,
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 92, color: Colors.black12),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.eventType,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        item.createdAt,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.description,
                    style: const TextStyle(color: Colors.black87, height: 1.35),
                  ),
                  if (item.previousValue.isNotEmpty ||
                      item.newValue.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 430;

                        final previous = ReportActionHistoryValueBox(
                          label: 'Antes',
                          value: item.previousValue,
                          color: const Color(0xFF607D8B),
                        );

                        final current = ReportActionHistoryValueBox(
                          label: 'Depois',
                          value: item.newValue,
                          color: color,
                        );

                        if (compact) {
                          return Column(
                            children: [
                              previous,
                              const SizedBox(height: 9),
                              current,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: previous),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 9),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.black38,
                                size: 18,
                              ),
                            ),
                            Expanded(child: current),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 9,
                    runSpacing: 8,
                    children: [
                      ReportActionHistoryMetaChip(
                        icon: Icons.person_outline,
                        text: item.createdBy.trim().isEmpty
                            ? 'Usuário'
                            : item.createdBy,
                      ),
                      ReportActionHistoryMetaChip(
                        icon: Icons.source_outlined,
                        text: item.source.trim().isEmpty
                            ? 'Sistema'
                            : item.source,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ReportActionHistoryValueBox extends StatelessWidget {
  const ReportActionHistoryValueBox({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? 'Não informado' : value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportActionHistoryMetaChip extends StatelessWidget {
  const ReportActionHistoryMetaChip({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black45),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(color: Colors.black54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class ReportActionHistoryEmptyState extends StatelessWidget {
  const ReportActionHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(38),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(
                Icons.history_toggle_off_outlined,
                color: Color(0xFF1B5E20),
                size: 38,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Nenhuma movimentação registrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF263238),
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'As próximas alterações feitas nesta ação aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color reportActionHistoryColor(ReportActionHistoryData item) {
  if (item.isCompletion) {
    return const Color(0xFF1B5E20);
  }

  if (item.isCancellation) {
    return const Color(0xFF607D8B);
  }

  if (item.isStatusChange) {
    return const Color(0xFF1565C0);
  }

  if (item.isDeadlineChange) {
    return const Color(0xFFEF6C00);
  }

  if (item.isResponsibleChange) {
    return const Color(0xFF6A1B9A);
  }

  if (item.isPriorityChange) {
    return const Color(0xFFC62828);
  }

  if (item.isNotesChange) {
    return const Color(0xFF00838F);
  }

  return const Color(0xFF1B5E20);
}

IconData reportActionHistoryIcon(ReportActionHistoryData item) {
  if (item.isCompletion) {
    return Icons.check_circle_outline;
  }

  if (item.isCancellation) {
    return Icons.cancel_outlined;
  }

  if (item.isStatusChange) {
    return Icons.swap_horiz_outlined;
  }

  if (item.isDeadlineChange) {
    return Icons.date_range_outlined;
  }

  if (item.isResponsibleChange) {
    return Icons.person_outline;
  }

  if (item.isPriorityChange) {
    return Icons.flag_outlined;
  }

  if (item.isNotesChange) {
    return Icons.notes_outlined;
  }

  return Icons.add_circle_outline;
}
