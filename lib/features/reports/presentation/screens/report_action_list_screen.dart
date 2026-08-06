import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_action_analytics_card.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_pdf_service.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_excel_service.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_action_history_dialog.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_history_storage_service.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_action_kanban_board.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_storage_service.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class ReportActionListScreen extends StatefulWidget {
  const ReportActionListScreen({super.key});

  @override
  State<ReportActionListScreen> createState() {
    return _ReportActionListScreenState();
  }
}

class _ReportActionListScreenState extends State<ReportActionListScreen> {
  static const Color forestGreen = Color(0xFF1B5E20);

  final ReportActionStorageService storage = ReportActionStorageService();

  final ReportActionHistoryStorageService historyStorage =
      ReportActionHistoryStorageService();

  final ReportActionPdfService pdfService = ReportActionPdfService();

  final ReportActionExcelService excelService = ReportActionExcelService();

  final TextEditingController searchController = TextEditingController();

  List<ReportActionItemData> allActions = [];

  Map<String, List<ReportActionHistoryData>> historyByActionId = {};

  bool isLoading = true;
  bool isExportingPdf = false;
  bool isExportingExcel = false;

  ReportActionViewMode viewMode = ReportActionViewMode.list;

  String selectedFarm = 'Todas';
  String selectedStatus = 'Todos';
  String selectedPriority = 'Todas';

  @override
  void initState() {
    super.initState();
    loadActions();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> get farmOptions {
    final names =
        allActions
            .map((action) => action.farmName)
            .where((name) => name.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['Todas', ...names];
  }

  List<ReportActionItemData> get filteredActions {
    final query = searchController.text.trim().toLowerCase();

    final actions = allActions.where((action) {
      final matchesFarm =
          selectedFarm == 'Todas' || action.farmName == selectedFarm;

      final matchesStatus =
          selectedStatus == 'Todos' || action.status == selectedStatus;

      final matchesPriority =
          selectedPriority == 'Todas' || action.priority == selectedPriority;

      final matchesSearch =
          query.isEmpty ||
          action.title.toLowerCase().contains(query) ||
          action.action.toLowerCase().contains(query) ||
          action.responsible.toLowerCase().contains(query) ||
          action.farmName.toLowerCase().contains(query) ||
          action.notes.toLowerCase().contains(query);

      return matchesFarm && matchesStatus && matchesPriority && matchesSearch;
    }).toList();

    actions.sort(compareReportActions);

    return actions;
  }

  int get totalCount {
    return allActions.length;
  }

  int get openCount {
    return allActions.where((action) {
      return action.isOpen;
    }).length;
  }

  int get overdueCount {
    return allActions.where((action) {
      return action.isOverdue;
    }).length;
  }

  int get completedCount {
    return allActions.where((action) {
      return action.isCompleted;
    }).length;
  }

  int get pendingCount {
    return allActions.where((action) {
      return action.isPending;
    }).length;
  }

  int get inProgressCount {
    return allActions.where((action) {
      return action.isInProgress;
    }).length;
  }

  int get cancelledCount {
    return allActions.where((action) {
      return action.isCancelled;
    }).length;
  }

  double get completionRate {
    final consideredActions = allActions.where((action) {
      return !action.isCancelled;
    }).length;

    if (consideredActions == 0) {
      return 0;
    }

    return completedCount / consideredActions;
  }

  int get urgentCount {
    return allActions.where((action) {
      return action.isUrgent && action.isOpen;
    }).length;
  }

  Future<void> loadActions() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final actions = await storage.loadActions();

    final historyEntries = await Future.wait(
      actions.map((action) async {
        final history = await historyStorage.loadActionHistory(action.id);

        return MapEntry(action.id, history);
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      allActions = actions;
      historyByActionId = {
        for (final entry in historyEntries) entry.key: entry.value,
      };

      if (!farmOptions.contains(selectedFarm)) {
        selectedFarm = 'Todas';
      }

      isLoading = false;
    });
  }

  Future<void> createAction() async {
    final action = await showDialog<ReportActionItemData>(
      context: context,
      builder: (dialogContext) {
        return const ReportActionFormDialog();
      },
    );

    if (action == null) {
      return;
    }

    final savedAction = await storage.addAction(action);

    await historyStorage.registerCreation(
      actionId: savedAction.id,
      actionTitle: savedAction.title,
      source: 'Cadastro manual',
      createdBy: 'Gabriel Beserra',
    );

    await loadActions();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ação criada com sucesso.')));
  }

  Future<void> editAction(ReportActionItemData action) async {
    final updated = await showDialog<ReportActionItemData>(
      context: context,
      builder: (dialogContext) {
        return ReportActionFormDialog(initialAction: action);
      },
    );

    if (updated == null) {
      return;
    }

    await storage.updateAction(updated);

    final historyItems = <ReportActionHistoryData>[];

    if (action.status != updated.status) {
      historyItems.add(
        createActionStatusHistory(
          actionId: action.id,
          actionTitle: updated.title,
          previousStatus: action.status,
          newStatus: updated.status,
          source: 'Formulário de edição',
          createdBy: 'Gabriel Beserra',
        ),
      );
    }

    if (action.deadline != updated.deadline) {
      historyItems.add(
        createActionDeadlineHistory(
          actionId: action.id,
          actionTitle: updated.title,
          previousDeadline: action.deadline,
          newDeadline: updated.deadline,
          source: 'Formulário de edição',
          createdBy: 'Gabriel Beserra',
        ),
      );
    }

    if (action.responsible != updated.responsible) {
      historyItems.add(
        createActionResponsibleHistory(
          actionId: action.id,
          actionTitle: updated.title,
          previousResponsible: action.responsible,
          newResponsible: updated.responsible,
          source: 'Formulário de edição',
          createdBy: 'Gabriel Beserra',
        ),
      );
    }

    if (action.priority != updated.priority) {
      historyItems.add(
        createActionPriorityHistory(
          actionId: action.id,
          actionTitle: updated.title,
          previousPriority: action.priority,
          newPriority: updated.priority,
          source: 'Formulário de edição',
          createdBy: 'Gabriel Beserra',
        ),
      );
    }

    if (action.notes != updated.notes) {
      historyItems.add(
        createActionNotesHistory(
          actionId: action.id,
          actionTitle: updated.title,
          previousNotes: action.notes,
          newNotes: updated.notes,
          source: 'Formulário de edição',
          createdBy: 'Gabriel Beserra',
        ),
      );
    }

    if (historyItems.isNotEmpty) {
      await historyStorage.addHistoryItems(historyItems);
    }

    await loadActions();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ação atualizada com sucesso.')),
    );
  }

  Future<void> changeStatus(ReportActionItemData action, String status) async {
    if (action.status == status) {
      return;
    }

    ReportActionItemData updated;

    switch (status) {
      case 'Pendente':
        updated = action.markAsPending();
        break;

      case 'Em andamento':
        updated = action.markAsInProgress();
        break;

      case 'Concluída':
        updated = action.markAsCompleted();
        break;

      case 'Cancelada':
        updated = action.markAsCancelled();
        break;

      default:
        return;
    }

    await storage.updateAction(updated);

    await historyStorage.registerStatusChange(
      actionId: action.id,
      actionTitle: action.title,
      previousStatus: action.status,
      newStatus: updated.status,
      source: viewMode == ReportActionViewMode.kanban
          ? 'Kanban'
          : 'Lista de ações',
      createdBy: 'Gabriel Beserra',
    );

    await loadActions();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Status alterado para $status.')));
  }

  Future<void> deleteAction(ReportActionItemData action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir ação'),
          content: Text(
            'Deseja excluir definitivamente a ação "${action.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await storage.deleteAction(action.id);
    await historyStorage.deleteActionHistory(action.id);
    await loadActions();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ação excluída.')));
  }

  Future<void> exportFilteredActionsPdf() async {
    final actions = filteredActions;

    if (actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma ação encontrada para exportar.')),
      );
      return;
    }

    if (isExportingPdf) {
      return;
    }

    setState(() {
      isExportingPdf = true;
    });

    try {
      final historyByActionId = <String, List<ReportActionHistoryData>>{};

      for (final action in actions) {
        historyByActionId[action.id] = await historyStorage.loadActionHistory(
          action.id,
        );
      }

      final scopeLabel = buildPdfScopeLabel();

      final report = ReportActionPdfData(
        title: 'Relatório de Ações Gerenciais',
        scopeLabel: scopeLabel,
        issueDate: formatActionPdfDateTime(DateTime.now()),
        consultantName: 'Gabriel Beserra',
        actions: actions,
        historyByActionId: historyByActionId,
      );

      await pdfService.printReport(report: report);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExportingPdf = false;
        });
      }
    }
  }

  Future<void> exportFilteredActionsExcel() async {
    final actions = filteredActions;

    if (actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma ação encontrada para exportar.')),
      );
      return;
    }

    if (isExportingExcel) {
      return;
    }

    setState(() {
      isExportingExcel = true;
    });

    try {
      final historyByActionId = <String, List<ReportActionHistoryData>>{};

      for (final action in actions) {
        historyByActionId[action.id] = await historyStorage.loadActionHistory(
          action.id,
        );
      }

      final report = ReportActionExcelData(
        scopeLabel: buildPdfScopeLabel(),
        issueDate: formatActionPdfDateTime(DateTime.now()),
        consultantName: 'Gabriel Beserra',
        actions: actions,
        historyByActionId: historyByActionId,
      );

      await excelService.exportReport(report: report);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planilha Excel gerada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o Excel: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExportingExcel = false;
        });
      }
    }
  }

  String buildPdfScopeLabel() {
    final parts = <String>[];

    if (selectedFarm != 'Todas') {
      parts.add(selectedFarm);
    } else {
      parts.add('Todas as fazendas');
    }

    if (selectedStatus != 'Todos') {
      parts.add('Status: $selectedStatus');
    }

    if (selectedPriority != 'Todas') {
      parts.add('Prioridade: $selectedPriority');
    }

    final query = searchController.text.trim();

    if (query.isNotEmpty) {
      parts.add('Busca: $query');
    }

    return parts.join(' · ');
  }

  Future<void> openActionHistory(ReportActionItemData action) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ReportActionHistoryDialog(action: action);
      },
    );
  }

  void changeViewMode(ReportActionViewMode mode) {
    setState(() {
      viewMode = mode;
    });
  }

  void clearFilters() {
    searchController.clear();

    setState(() {
      selectedFarm = 'Todas';
      selectedStatus = 'Todos';
      selectedPriority = 'Todas';
    });
  }

  @override
  Widget build(BuildContext context) {
    final actions = filteredActions;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Ações Gerenciais',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isExportingPdf || isExportingExcel)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2.3),
                ),
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Exportar PDF',
              onPressed: exportFilteredActionsPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              tooltip: 'Exportar Excel',
              onPressed: exportFilteredActionsExcel,
              icon: const Icon(Icons.table_view_outlined),
            ),
          ],
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : loadActions,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createAction,
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Nova ação'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadActions,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        ActionListHeader(
                          totalCount: totalCount,
                          openCount: openCount,
                          overdueCount: overdueCount,
                          completedCount: completedCount,
                          urgentCount: urgentCount,
                        ),
                        const SizedBox(height: 24),
                        ActionPerformanceCard(
                          completionRate: completionRate,
                          pendingCount: pendingCount,
                          inProgressCount: inProgressCount,
                          completedCount: completedCount,
                          cancelledCount: cancelledCount,
                          overdueCount: overdueCount,
                        ),
                        const SizedBox(height: 24),
                        ActionFiltersCard(
                          farmOptions: farmOptions,
                          selectedFarm: selectedFarm,
                          selectedStatus: selectedStatus,
                          selectedPriority: selectedPriority,
                          searchController: searchController,
                          onFarmChanged: (value) {
                            setState(() {
                              selectedFarm = value;
                            });
                          },
                          onStatusChanged: (value) {
                            setState(() {
                              selectedStatus = value;
                            });
                          },
                          onPriorityChanged: (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          },
                          onSearchChanged: (_) {
                            setState(() {});
                          },
                          onClearFilters: clearFilters,
                        ),
                        const SizedBox(height: 24),
                        ReportActionAnalyticsCard(
                          actions: actions,
                          historyByActionId: {
                            for (final action in actions)
                              action.id:
                                  historyByActionId[action.id] ?? const [],
                          },
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 620;

                            final heading = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ações cadastradas',
                                  style: TextStyle(
                                    color: Color(0xFF263238),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${actions.length} '
                                  '${actions.length == 1 ? 'ação encontrada' : 'ações encontradas'}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            );

                            final selector =
                                SegmentedButton<ReportActionViewMode>(
                                  segments: const [
                                    ButtonSegment<ReportActionViewMode>(
                                      value: ReportActionViewMode.list,
                                      icon: Icon(Icons.view_list_outlined),
                                      label: Text('Lista'),
                                    ),
                                    ButtonSegment<ReportActionViewMode>(
                                      value: ReportActionViewMode.kanban,
                                      icon: Icon(Icons.view_kanban_outlined),
                                      label: Text('Kanban'),
                                    ),
                                  ],
                                  selected: {viewMode},
                                  onSelectionChanged: (selection) {
                                    if (selection.isEmpty) {
                                      return;
                                    }

                                    changeViewMode(selection.first);
                                  },
                                );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  heading,
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              isExportingPdf || isExportingExcel
                                              ? null
                                              : exportFilteredActionsPdf,
                                          icon: const Icon(
                                            Icons.picture_as_pdf_outlined,
                                          ),
                                          label: const Text('PDF'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              isExportingPdf || isExportingExcel
                                              ? null
                                              : exportFilteredActionsExcel,
                                          icon: const Icon(
                                            Icons.table_view_outlined,
                                          ),
                                          label: const Text('Excel'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  selector,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: heading),
                                OutlinedButton.icon(
                                  onPressed: isExportingPdf || isExportingExcel
                                      ? null
                                      : exportFilteredActionsPdf,
                                  icon: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                  ),
                                  label: const Text('Exportar PDF'),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: isExportingPdf || isExportingExcel
                                      ? null
                                      : exportFilteredActionsExcel,
                                  icon: const Icon(Icons.table_view_outlined),
                                  label: const Text('Exportar Excel'),
                                ),
                                const SizedBox(width: 10),
                                selector,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        if (viewMode == ReportActionViewMode.list) ...[
                          if (actions.isEmpty)
                            const EmptyActionListCard()
                          else
                            ...actions.map((action) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ReportActionCard(
                                  action: action,
                                  onEdit: () {
                                    editAction(action);
                                  },
                                  onDelete: () {
                                    deleteAction(action);
                                  },
                                  onViewHistory: () {
                                    openActionHistory(action);
                                  },
                                  onChangeStatus: (status) {
                                    changeStatus(action, status);
                                  },
                                ),
                              );
                            }),
                        ] else
                          ReportActionKanbanBoard(
                            actions: actions,
                            onEdit: editAction,
                            onViewHistory: openActionHistory,
                            onChangeStatus: (action, status) {
                              changeStatus(action, status);
                            },
                          ),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

enum ReportActionViewMode { list, kanban }

class ActionListHeader extends StatelessWidget {
  const ActionListHeader({
    required this.totalCount,
    required this.openCount,
    required this.overdueCount,
    required this.completedCount,
    required this.urgentCount,
    super.key,
  });

  final int totalCount;
  final int openCount;
  final int overdueCount;
  final int completedCount;
  final int urgentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acompanhamento das ações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Controle das recomendações gerenciais até a conclusão.',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ActionHeaderMetric(
                value: totalCount,
                label: 'total',
                icon: Icons.assignment_outlined,
              ),
              ActionHeaderMetric(
                value: openCount,
                label: 'abertas',
                icon: Icons.schedule_outlined,
              ),
              ActionHeaderMetric(
                value: overdueCount,
                label: 'atrasadas',
                icon: Icons.event_busy_outlined,
                highlight: overdueCount > 0,
              ),
              ActionHeaderMetric(
                value: urgentCount,
                label: 'urgentes',
                icon: Icons.priority_high,
                highlight: urgentCount > 0,
              ),
              ActionHeaderMetric(
                value: completedCount,
                label: 'concluídas',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionHeaderMetric extends StatelessWidget {
  const ActionHeaderMetric({
    required this.value,
    required this.label,
    required this.icon,
    this.highlight = false,
    super.key,
  });

  final int value;
  final String label;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.red.withValues(alpha: 0.23)
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionPerformanceCard extends StatelessWidget {
  const ActionPerformanceCard({
    required this.completionRate,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.overdueCount,
    super.key,
  });

  final double completionRate;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final int cancelledCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    final percentage = completionRate * 100;

    final progressColor = percentage >= 75
        ? const Color(0xFF1B5E20)
        : percentage >= 40
        ? const Color(0xFF1565C0)
        : const Color(0xFFEF6C00);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 10),
                Text(
                  'Desempenho do plano de ação',
                  style: TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              buildActionPerformanceMessage(
                completionRate: completionRate,
                overdueCount: overdueCount,
                inProgressCount: inProgressCount,
              ),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;

                final progress = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Taxa de conclusão',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1).replaceAll('.', ',')}%',
                          style: TextStyle(
                            color: progressColor,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 14,
                        value: completionRate.clamp(0.0, 1.0),
                        backgroundColor: progressColor.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ),
                  ],
                );

                final metrics = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ActionPerformanceMetric(
                      value: pendingCount,
                      label: 'Pendentes',
                      color: const Color(0xFFEF6C00),
                    ),
                    ActionPerformanceMetric(
                      value: inProgressCount,
                      label: 'Em andamento',
                      color: const Color(0xFF1565C0),
                    ),
                    ActionPerformanceMetric(
                      value: completedCount,
                      label: 'Concluídas',
                      color: const Color(0xFF1B5E20),
                    ),
                    ActionPerformanceMetric(
                      value: cancelledCount,
                      label: 'Canceladas',
                      color: const Color(0xFF607D8B),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [progress, const SizedBox(height: 20), metrics],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: progress),
                    const SizedBox(width: 28),
                    Expanded(child: metrics),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ActionPerformanceMetric extends StatelessWidget {
  const ActionPerformanceMetric({
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 125),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String buildActionPerformanceMessage({
  required double completionRate,
  required int overdueCount,
  required int inProgressCount,
}) {
  if (overdueCount > 0) {
    return 'Existem $overdueCount '
        '${overdueCount == 1 ? 'ação atrasada' : 'ações atrasadas'}. '
        'Priorize essas pendências para recuperar o ritmo do plano.';
  }

  if (completionRate >= 0.75) {
    return 'O plano apresenta bom avanço. Mantenha o acompanhamento '
        'das ações restantes até a conclusão.';
  }

  if (completionRate >= 0.40) {
    return 'O plano está em evolução, mas ainda possui etapas importantes '
        'a serem concluídas.';
  }

  if (inProgressCount > 0) {
    return 'As primeiras ações já estão em andamento. Acompanhe os prazos '
        'e registre as conclusões.';
  }

  return 'O plano ainda está no início. Defina responsáveis e coloque '
      'as ações prioritárias em andamento.';
}

class ActionFiltersCard extends StatelessWidget {
  const ActionFiltersCard({
    required this.farmOptions,
    required this.selectedFarm,
    required this.selectedStatus,
    required this.selectedPriority,
    required this.searchController,
    required this.onFarmChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onSearchChanged,
    required this.onClearFilters,
    super.key,
  });

  final List<String> farmOptions;
  final String selectedFarm;
  final String selectedStatus;
  final String selectedPriority;
  final TextEditingController searchController;
  final ValueChanged<String> onFarmChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 9),
                Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'Buscar ação',
                prefixIcon: Icon(Icons.search),
                hintText: 'Problema, ação, responsável ou fazenda',
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow = constraints.maxWidth >= 820;

                final farmField = DropdownButtonFormField<String>(
                  initialValue: selectedFarm,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Fazenda',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  items: farmOptions.map((farm) {
                    return DropdownMenuItem(
                      value: farm,
                      child: Text(
                        farm == 'Todas' ? 'Todas as fazendas' : farm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onFarmChanged(value);
                    }
                  },
                );

                final statusField = DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.task_alt_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Todos',
                      child: Text('Todos os status'),
                    ),
                    DropdownMenuItem(
                      value: 'Pendente',
                      child: Text('Pendente'),
                    ),
                    DropdownMenuItem(
                      value: 'Em andamento',
                      child: Text('Em andamento'),
                    ),
                    DropdownMenuItem(
                      value: 'Concluída',
                      child: Text('Concluída'),
                    ),
                    DropdownMenuItem(
                      value: 'Cancelada',
                      child: Text('Cancelada'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChanged(value);
                    }
                  },
                );

                final priorityField = DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Todas',
                      child: Text('Todas as prioridades'),
                    ),
                    DropdownMenuItem(
                      value: 'Muito alta',
                      child: Text('Muito alta'),
                    ),
                    DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'Média', child: Text('Média')),
                    DropdownMenuItem(
                      value: 'Acompanhamento',
                      child: Text('Acompanhamento'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onPriorityChanged(value);
                    }
                  },
                );

                if (!useRow) {
                  return Column(
                    children: [
                      farmField,
                      const SizedBox(height: 14),
                      statusField,
                      const SizedBox(height: 14),
                      priorityField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: farmField),
                    const SizedBox(width: 14),
                    Expanded(child: statusField),
                    const SizedBox(width: 14),
                    Expanded(child: priorityField),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportActionCard extends StatelessWidget {
  const ReportActionCard({
    required this.action,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
    required this.onChangeStatus,
    super.key,
  });

  final ReportActionItemData action;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;
  final ValueChanged<String> onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final color = reportActionColor(action);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    action.isCompleted
                        ? Icons.check_circle_outline
                        : action.isOverdue
                        ? Icons.event_busy_outlined
                        : Icons.assignment_outlined,
                    color: color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        action.action,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Mais opções',
                  onSelected: (value) {
                    if (value == 'Histórico') {
                      onViewHistory();
                      return;
                    }

                    if (value == 'Editar') {
                      onEdit();
                      return;
                    }

                    if (value == 'Excluir') {
                      onDelete();
                      return;
                    }

                    onChangeStatus(value);
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'Pendente',
                        child: Text('Marcar como pendente'),
                      ),
                      PopupMenuItem(
                        value: 'Em andamento',
                        child: Text('Marcar em andamento'),
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
                      PopupMenuItem(value: 'Editar', child: Text('Editar')),
                      PopupMenuItem(value: 'Excluir', child: Text('Excluir')),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 17),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionInformationChip(
                  icon: Icons.home_work_outlined,
                  label: action.farmName.isEmpty
                      ? 'Todas as fazendas'
                      : action.farmName,
                  color: const Color(0xFF1565C0),
                ),
                ActionInformationChip(
                  icon: Icons.person_outline,
                  label: action.responsible.isEmpty
                      ? 'Sem responsável'
                      : action.responsible,
                  color: const Color(0xFF6A1B9A),
                ),
                ActionInformationChip(
                  icon: Icons.flag_outlined,
                  label: action.priority,
                  color: reportActionPriorityColor(action.priority),
                ),
                ActionInformationChip(
                  icon: Icons.schedule_outlined,
                  label: action.deadline.isEmpty
                      ? 'Sem prazo'
                      : action.deadline,
                  color: action.isOverdue
                      ? Colors.red.shade700
                      : const Color(0xFFEF6C00),
                ),
                ActionInformationChip(
                  icon: Icons.task_alt_outlined,
                  label: action.isOverdue ? 'Atrasada' : action.status,
                  color: color,
                ),
              ],
            ),
            if (action.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  action.notes,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ActionInformationChip extends StatelessWidget {
  const ActionInformationChip({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyActionListCard extends StatelessWidget {
  const EmptyActionListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(38),
        child: Column(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 62,
              color: Color(0xFF1B5E20),
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma ação encontrada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              'Crie uma nova ação ou altere os filtros selecionados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportActionFormDialog extends StatefulWidget {
  const ReportActionFormDialog({this.initialAction, super.key});

  final ReportActionItemData? initialAction;

  @override
  State<ReportActionFormDialog> createState() {
    return _ReportActionFormDialogState();
  }
}

class _ReportActionFormDialogState extends State<ReportActionFormDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController farmController;
  late final TextEditingController titleController;
  late final TextEditingController actionController;
  late final TextEditingController responsibleController;
  late final TextEditingController deadlineController;
  late final TextEditingController notesController;

  late String selectedPriority;
  late String selectedStatus;

  @override
  void initState() {
    super.initState();

    final action = widget.initialAction;

    farmController = TextEditingController(text: action?.farmName ?? '');

    titleController = TextEditingController(text: action?.title ?? '');

    actionController = TextEditingController(text: action?.action ?? '');

    responsibleController = TextEditingController(
      text: action?.responsible ?? '',
    );

    deadlineController = TextEditingController(text: action?.deadline ?? '');

    notesController = TextEditingController(text: action?.notes ?? '');

    selectedPriority = action?.priority ?? 'Alta';

    selectedStatus = action?.status ?? 'Pendente';
  }

  @override
  void dispose() {
    farmController.dispose();
    titleController.dispose();
    actionController.dispose();
    responsibleController.dispose();
    deadlineController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> selectDeadline() async {
    final initial =
        tryParseActionDate(deadlineController.text) ?? DateTime.now();

    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: initial,
      helpText: 'Selecionar prazo',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );

    if (selected == null) {
      return;
    }

    deadlineController.text = formatActionDate(selected);
  }

  void save() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final existing = widget.initialAction;

    final completedAt = selectedStatus == 'Concluída'
        ? existing?.completedAt.isNotEmpty == true
              ? existing!.completedAt
              : formatActionDate(DateTime.now())
        : '';

    final result = ReportActionItemData(
      id: existing?.id ?? createReportActionId(),
      farmName: farmController.text.trim(),
      title: titleController.text.trim(),
      action: actionController.text.trim(),
      responsible: responsibleController.text.trim(),
      deadline: deadlineController.text.trim(),
      priority: selectedPriority,
      status: selectedStatus,
      createdAt: existing?.createdAt ?? formatActionDate(DateTime.now()),
      completedAt: completedAt,
      notes: notesController.text.trim(),
      source: existing?.source ?? 'Cadastro manual',
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialAction != null;

    return AlertDialog(
      title: Text(editing ? 'Editar ação' : 'Nova ação'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: farmController,
                  decoration: const InputDecoration(
                    labelText: 'Fazenda ou escopo',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Problema identificado',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o problema identificado.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: actionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ação recomendada',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.task_alt_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe a ação recomendada.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: responsibleController,
                  decoration: const InputDecoration(
                    labelText: 'Responsável',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: deadlineController,
                  readOnly: true,
                  onTap: selectDeadline,
                  decoration: InputDecoration(
                    labelText: 'Prazo',
                    prefixIcon: const Icon(Icons.date_range_outlined),
                    suffixIcon: IconButton(
                      tooltip: 'Limpar prazo',
                      onPressed: () {
                        deadlineController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useRow = constraints.maxWidth >= 520;

                    final priorityField = DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Muito alta',
                          child: Text('Muito alta'),
                        ),
                        DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                        DropdownMenuItem(value: 'Média', child: Text('Média')),
                        DropdownMenuItem(
                          value: 'Acompanhamento',
                          child: Text('Acompanhamento'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPriority = value;
                          });
                        }
                      },
                    );

                    final statusField = DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.task_alt_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pendente',
                          child: Text('Pendente'),
                        ),
                        DropdownMenuItem(
                          value: 'Em andamento',
                          child: Text('Em andamento'),
                        ),
                        DropdownMenuItem(
                          value: 'Concluída',
                          child: Text('Concluída'),
                        ),
                        DropdownMenuItem(
                          value: 'Cancelada',
                          child: Text('Cancelada'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    );

                    if (!useRow) {
                      return Column(
                        children: [
                          priorityField,
                          const SizedBox(height: 14),
                          statusField,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: priorityField),
                        const SizedBox(width: 14),
                        Expanded(child: statusField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
          ),
          icon: const Icon(Icons.save_outlined),
          label: Text(editing ? 'Salvar alterações' : 'Criar ação'),
        ),
      ],
    );
  }
}

String formatActionPdfDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/${date.year} '
      '$hour:$minute';
}

Color reportActionColor(ReportActionItemData action) {
  if (action.isOverdue) {
    return Colors.red.shade700;
  }

  switch (action.status) {
    case 'Em andamento':
      return const Color(0xFF1565C0);

    case 'Concluída':
      return const Color(0xFF1B5E20);

    case 'Cancelada':
      return const Color(0xFF607D8B);

    default:
      return const Color(0xFFEF6C00);
  }
}

Color reportActionPriorityColor(String priority) {
  switch (priority) {
    case 'Muito alta':
    case 'Urgente':
      return Colors.red.shade700;

    case 'Alta':
      return const Color(0xFFEF6C00);

    case 'Média':
    case 'Normal':
      return const Color(0xFF1565C0);

    default:
      return const Color(0xFF1B5E20);
  }
}
