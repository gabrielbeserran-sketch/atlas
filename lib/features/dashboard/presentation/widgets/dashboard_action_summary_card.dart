import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_storage_service.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_history_storage_service.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';
import 'package:projeto_atlas/features/reports/presentation/screens/report_action_list_screen.dart';

class DashboardActionSummaryCard extends StatefulWidget {
  const DashboardActionSummaryCard({super.key});

  @override
  State<DashboardActionSummaryCard> createState() {
    return _DashboardActionSummaryCardState();
  }
}

class _DashboardActionSummaryCardState
    extends State<DashboardActionSummaryCard> {
  static const Color forestGreen = Color(0xFF1B5E20);

  final ReportActionStorageService storage = ReportActionStorageService();

  final ReportActionHistoryStorageService historyStorage =
      ReportActionHistoryStorageService();

  List<ReportActionItemData> actions = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadActions();
  }

  List<ReportActionItemData> get openActions {
    final open = actions.where((action) {
      return action.isOpen;
    }).toList();

    open.sort(compareReportActions);

    return open;
  }

  List<ReportActionItemData> get highlightedActions {
    return openActions.take(3).toList();
  }

  int get openCount {
    return actions.where((action) {
      return action.isOpen;
    }).length;
  }

  int get overdueCount {
    return actions.where((action) {
      return action.isOverdue;
    }).length;
  }

  int get urgentCount {
    return actions.where((action) {
      return action.isUrgent && action.isOpen;
    }).length;
  }

  int get completedCount {
    return actions.where((action) {
      return action.isCompleted;
    }).length;
  }

  Future<void> loadActions() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final loadedActions = await storage.loadActions();

    if (!mounted) {
      return;
    }

    setState(() {
      actions = loadedActions;
      isLoading = false;
    });
  }

  Future<void> openActionScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const ReportActionListScreen();
        },
      ),
    );

    await loadActions();
  }

  Future<void> markAsCompleted(ReportActionItemData action) async {
    if (action.isCompleted) {
      return;
    }

    final updatedAction = action.markAsCompleted();

    await storage.updateAction(updatedAction);

    await historyStorage.registerStatusChange(
      actionId: action.id,
      actionTitle: action.title,
      previousStatus: action.status,
      newStatus: updatedAction.status,
      source: 'Dashboard',
      createdBy: 'Gabriel Beserra',
    );

    await loadActions();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ação marcada como concluída.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: isLoading
          ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildMetrics(),
                if (highlightedActions.isEmpty)
                  _buildEmptyState()
                else
                  _buildActionList(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ações gerenciais',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Pendências prioritárias da operação.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: loadActions,
            color: Colors.white,
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            tooltip: 'Abrir ações',
            onPressed: openActionScreen,
            color: Colors.white,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth >= 620
              ? (constraints.maxWidth - 30) / 4
              : constraints.maxWidth >= 340
              ? (constraints.maxWidth - 10) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DashboardActionMetric(
                width: itemWidth,
                value: openCount,
                label: 'Abertas',
                icon: Icons.schedule_outlined,
                color: const Color(0xFF1565C0),
              ),
              DashboardActionMetric(
                width: itemWidth,
                value: overdueCount,
                label: 'Atrasadas',
                icon: Icons.event_busy_outlined,
                color: overdueCount > 0 ? const Color(0xFFC62828) : forestGreen,
              ),
              DashboardActionMetric(
                width: itemWidth,
                value: urgentCount,
                label: 'Urgentes',
                icon: Icons.priority_high,
                color: urgentCount > 0 ? const Color(0xFFEF6C00) : forestGreen,
              ),
              DashboardActionMetric(
                width: itemWidth,
                value: completedCount,
                label: 'Concluídas',
                icon: Icons.check_circle_outline,
                color: forestGreen,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: forestGreen, size: 30),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Nenhuma ação gerencial aberta.',
                style: TextStyle(
                  color: forestGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        children: [
          ...highlightedActions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DashboardActionTile(
                action: action,
                onOpen: openActionScreen,
                onComplete: () {
                  markAsCompleted(action);
                },
              ),
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: openActionScreen,
              icon: const Icon(Icons.list_alt_outlined),
              label: Text(
                openCount > 3
                    ? 'Ver todas as $openCount ações abertas'
                    : 'Abrir acompanhamento',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardActionMetric extends StatelessWidget {
  const DashboardActionMetric({
    required this.width,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    super.key,
  });

  final double width;
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label, style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardActionTile extends StatelessWidget {
  const DashboardActionTile({
    required this.action,
    required this.onOpen,
    required this.onComplete,
    super.key,
  });

  final ReportActionItemData action;
  final VoidCallback onOpen;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final color = dashboardActionColor(action);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(15),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                action.isOverdue
                    ? Icons.event_busy_outlined
                    : action.isUrgent
                    ? Icons.priority_high
                    : Icons.assignment_outlined,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (action.farmName.isNotEmpty) action.farmName,
                      if (action.deadline.isNotEmpty) action.deadline,
                      action.status,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Marcar como concluída',
              onPressed: onComplete,
              icon: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color dashboardActionColor(ReportActionItemData action) {
  if (action.isOverdue) {
    return const Color(0xFFC62828);
  }

  if (action.isUrgent) {
    return const Color(0xFFEF6C00);
  }

  if (action.isInProgress) {
    return const Color(0xFF1565C0);
  }

  return const Color(0xFF1B5E20);
}
