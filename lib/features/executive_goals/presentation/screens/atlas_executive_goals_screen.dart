import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/executive_goals/data/services/atlas_executive_goal_storage_service.dart';
import 'package:projeto_atlas/features/executive_goals/data/services/atlas_executive_goal_history_storage_service.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal_history.dart';
import 'package:projeto_atlas/features/executive_goals/domain/services/atlas_executive_goal_history_service.dart';
import 'package:projeto_atlas/features/executive_goals/presentation/screens/atlas_executive_goal_history_screen.dart';
import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';
import 'package:projeto_atlas/features/executive_goals/domain/services/atlas_executive_goal_service.dart';
import 'package:projeto_atlas/features/executive_kpis/domain/models/atlas_executive_kpi.dart';

class AtlasExecutiveGoalsScreen
    extends StatefulWidget {
  const AtlasExecutiveGoalsScreen({
    required this.data,
    this.onOpenFarm,
    super.key,
  });

  final AtlasExecutiveGoalDashboardData data;

  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasExecutiveGoalsScreen>
      createState() {
    return _AtlasExecutiveGoalsScreenState();
  }
}

class _AtlasExecutiveGoalsScreenState
    extends State<AtlasExecutiveGoalsScreen> {
  final AtlasExecutiveGoalStorageService
      storageService =
      const AtlasExecutiveGoalStorageService();

  final AtlasExecutiveGoalService goalService =
      const AtlasExecutiveGoalService();

  final AtlasExecutiveGoalHistoryStorageService
      historyStorageService =
      const AtlasExecutiveGoalHistoryStorageService();

  final AtlasExecutiveGoalHistoryService
      historyService =
      const AtlasExecutiveGoalHistoryService();

  List<AtlasExecutiveGoalHistoryEvent>
      historyEvents = [];

  bool isLoadingHistory = true;

  String? selectedFarm;

  AtlasExecutiveGoalStatus? selectedStatus;

  AtlasExecutiveKpiCategory?
      selectedCategory;

  bool isSaving = false;

  late List<AtlasExecutiveGoal> goals;

  @override
  void initState() {
    super.initState();
    goals = [...widget.data.goals];
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    var events = await historyStorageService.load();

    final goalIdsWithEvents = events
        .map((event) => event.goalId)
        .toSet();

    for (final goal in goals) {
      if (!goalIdsWithEvents.contains(goal.id)) {
        events.add(
          historyService.createEvent(
            goal: goal,
            type:
                AtlasExecutiveGoalHistoryEventType
                    .created,
            description:
                'A meta foi adicionada ao acompanhamento.',
          ),
        );
      }
    }

    await historyStorageService.save(events);

    if (!mounted) {
      return;
    }

    setState(() {
      historyEvents = events;
      isLoadingHistory = false;
    });
  }

  AtlasExecutiveGoalHistorySummary
      get historyData {
    return historyService.buildSummary(
      events: historyEvents,
      goals: goals,
    );
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return AtlasExecutiveGoalHistoryScreen(
            data: historyData,
          );
        },
      ),
    );
  }

  Future<void> _recordHistoryEvent({
    required AtlasExecutiveGoal goal,
    required AtlasExecutiveGoalHistoryEventType
        type,
    required String description,
  }) async {
    final updatedEvents = [
      ...historyEvents,
      historyService.createEvent(
        goal: goal,
        type: type,
        description: description,
      ),
    ];

    await historyStorageService.save(
      updatedEvents,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      historyEvents = updatedEvents;
    });
  }

  AtlasExecutiveGoalDashboardData get data {
    return goalService.buildDashboard(
      goals: goals,
    );
  }

  List<AtlasExecutiveGoal> get filteredGoals {
    return data.goals.where((goal) {
      if (selectedFarm != null &&
          goal.farmName != selectedFarm) {
        return false;
      }

      if (selectedStatus != null &&
          goal.status != selectedStatus) {
        return false;
      }

      if (selectedCategory != null &&
          goal.category != selectedCategory) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _saveGoals(
    List<AtlasExecutiveGoal> updatedGoals,
  ) async {
    setState(() {
      isSaving = true;
      goals = updatedGoals;
    });

    await storageService.save(updatedGoals);

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });
  }

  Future<void> _editGoal(
    AtlasExecutiveGoal goal,
  ) async {
    final targetController =
        TextEditingController(
      text: goal.targetValue.toStringAsFixed(
        goal.targetValue ==
                goal.targetValue.roundToDouble()
            ? 0
            : 1,
      ),
    );

    final responsibleController =
        TextEditingController(
      text: goal.responsibleName,
    );

    final notesController =
        TextEditingController(
      text: goal.notes,
    );

    var deadline = goal.deadline;

    final result =
        await showDialog<_GoalEditResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Editar meta',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.kpiTitle,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goal.farmName} · '
                        'Atual: ${_formatValue(goal.currentValue, goal.unit)}',
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller:
                            targetController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Valor-alvo (${goal.unit})',
                          prefixIcon: const Icon(
                            Icons.flag_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: const Icon(
                          Icons.event_outlined,
                        ),
                        title: const Text(
                          'Prazo da meta',
                        ),
                        subtitle: Text(
                          _formatDate(deadline),
                        ),
                        trailing: IconButton(
                          tooltip:
                              'Alterar prazo',
                          onPressed: () async {
                            final picked =
                                await showDatePicker(
                              context:
                                  dialogContext,
                              initialDate:
                                  deadline,
                              firstDate:
                                  DateTime.now()
                                      .subtract(
                                const Duration(
                                  days: 3650,
                                ),
                              ),
                              lastDate:
                                  DateTime.now().add(
                                const Duration(
                                  days: 3650,
                                ),
                              ),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                deadline = picked;
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.edit_calendar,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller:
                            responsibleController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Responsável',
                          prefixIcon: Icon(
                            Icons.person_outline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller:
                            notesController,
                        minLines: 3,
                        maxLines: 6,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Observações',
                          hintText:
                              'Registre estratégia, recursos ou impedimentos.',
                          prefixIcon: Icon(
                            Icons
                                .description_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final normalized =
                        targetController.text
                            .trim()
                            .replaceAll('.', '')
                            .replaceAll(',', '.');

                    final target =
                        double.tryParse(normalized);

                    if (target == null) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Digite um valor-alvo válido.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(
                      _GoalEditResult(
                        targetValue: target,
                        deadline: deadline,
                        responsibleName:
                            responsibleController
                                .text
                                .trim(),
                        notes:
                            notesController.text
                                .trim(),
                      ),
                    );
                  },
                  child: const Text(
                    'Salvar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    targetController.dispose();
    responsibleController.dispose();
    notesController.dispose();

    if (result == null || !mounted) {
      return;
    }

    final updated = goalService.updateGoal(
      goal: goal,
      targetValue: result.targetValue,
      deadline: result.deadline,
      responsibleName:
          result.responsibleName,
      notes: result.notes,
    );

    final updatedGoals = goals.map((item) {
      return item.id == goal.id
          ? updated
          : item;
    }).toList();

    await _saveGoals(updatedGoals);

    if (goal.targetValue != updated.targetValue) {
      await _recordHistoryEvent(
        goal: updated,
        type:
            AtlasExecutiveGoalHistoryEventType
                .targetChanged,
        description:
            'O valor-alvo foi alterado de '
            '${goal.targetValue} para '
            '${updated.targetValue}.',
      );
    }

    if (goal.deadline != updated.deadline) {
      await _recordHistoryEvent(
        goal: updated,
        type:
            AtlasExecutiveGoalHistoryEventType
                .deadlineChanged,
        description:
            'O prazo foi alterado de '
            '${_formatDate(goal.deadline)} para '
            '${_formatDate(updated.deadline)}.',
      );
    }

    if (goal.responsibleName !=
        updated.responsibleName) {
      await _recordHistoryEvent(
        goal: updated,
        type:
            AtlasExecutiveGoalHistoryEventType
                .responsibleChanged,
        description:
            'O responsável pela meta foi alterado.',
      );
    }

    if (goal.targetValue == updated.targetValue &&
        goal.deadline == updated.deadline &&
        goal.responsibleName ==
            updated.responsibleName) {
      await _recordHistoryEvent(
        goal: updated,
        type:
            AtlasExecutiveGoalHistoryEventType
                .updated,
        description:
            'As observações da meta foram atualizadas.',
      );
    }
  }

  Future<void> _changeStatus(
    AtlasExecutiveGoal goal,
    AtlasExecutiveGoalStatus status,
  ) async {
    final updated = goalService.updateGoal(
      goal: goal,
      status: status,
    );

    final updatedGoals = goals.map((item) {
      return item.id == goal.id
          ? updated
          : item;
    }).toList();

    await _saveGoals(updatedGoals);

    final eventType = switch (status) {
      AtlasExecutiveGoalStatus.completed =>
        AtlasExecutiveGoalHistoryEventType
            .completed,
      AtlasExecutiveGoalStatus.cancelled =>
        AtlasExecutiveGoalHistoryEventType
            .cancelled,
      _ =>
        AtlasExecutiveGoalHistoryEventType
            .statusChanged,
    };

    await _recordHistoryEvent(
      goal: updated,
      type: eventType,
      description:
          'O status foi alterado para '
          '${atlasExecutiveGoalStatusLabel(status)}.',
    );
  }

  Future<void> _reopenGoal(
    AtlasExecutiveGoal goal,
  ) async {
    final updated = goal.copyWith(
      status: AtlasExecutiveGoalStatus.active,
      updatedAt: DateTime.now(),
      clearCompletedAt: true,
    );

    final updatedGoals = goals.map((item) {
      return item.id == goal.id
          ? updated
          : item;
    }).toList();

    await _saveGoals(updatedGoals);

    await _recordHistoryEvent(
      goal: updated,
      type:
          AtlasExecutiveGoalHistoryEventType
              .reopened,
      description:
          'A meta foi reaberta para novo acompanhamento.',
    );
  }

  Future<void> _deleteGoal(
    AtlasExecutiveGoal goal,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Excluir meta',
          ),
          content: Text(
            'Deseja excluir permanentemente a meta "${goal.kpiTitle}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFFC62828),
              ),
              child: const Text(
                'Excluir',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _recordHistoryEvent(
      goal: goal,
      type:
          AtlasExecutiveGoalHistoryEventType
              .deleted,
      description:
          'A meta foi excluída do acompanhamento.',
    );

    final updatedGoals = goals.where((item) {
      return item.id != goal.id;
    }).toList();

    await _saveGoals(updatedGoals);
  }

  @override
  Widget build(BuildContext context) {
    final currentData = data;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Metas Inteligentes',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Histórico das Metas',
            onPressed:
                isLoadingHistory
                    ? null
                    : _openHistory,
            icon: const Icon(
              Icons.timeline_outlined,
            ),
          ),
          if (isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1240,
            ),
            child: currentData.hasGoals
                ? ListView(
                    padding:
                        const EdgeInsets.all(22),
                    children: [
                      _GoalsHero(
                        data: currentData,
                      ),
                      const SizedBox(height: 22),
                      _GoalFilters(
                        farms: currentData.farms,
                        selectedFarm:
                            selectedFarm,
                        selectedStatus:
                            selectedStatus,
                        selectedCategory:
                            selectedCategory,
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
                        onCategoryChanged:
                            (value) {
                          setState(() {
                            selectedCategory =
                                value;
                          });
                        },
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title:
                            'Metas prioritárias',
                        subtitle:
                            'Metas ordenadas por atraso, risco, prioridade e prazo.',
                      ),
                      const SizedBox(height: 13),
                      _GoalList(
                        goals: filteredGoals,
                        onOpenFarm:
                            widget.onOpenFarm,
                        onEdit: _editGoal,
                        onChangeStatus:
                            _changeStatus,
                        onReopen: _reopenGoal,
                        onDelete: _deleteGoal,
                      ),
                      const SizedBox(height: 30),
                    ],
                  )
                : const _EmptyGoalsView(),
          ),
        ),
      ),
    );
  }
}

class _GoalsHero extends StatelessWidget {
  const _GoalsHero({
    required this.data,
  });

  final AtlasExecutiveGoalDashboardData data;

  @override
  Widget build(BuildContext context) {
    final progress = data.progress;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3D2A00),
            Color(0xFF6D4C00),
            Color(0xFF8D6E00),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color:
                        Color(0xFFFFE082),
                    size: 31,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Central de Metas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                data.summary,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroMetric(
                    label: 'Total',
                    value: progress.total,
                  ),
                  _HeroMetric(
                    label: 'No prazo',
                    value: progress.active,
                  ),
                  _HeroMetric(
                    label: 'Em risco',
                    value: progress.atRisk,
                  ),
                  _HeroMetric(
                    label: 'Atrasadas',
                    value: progress.overdue,
                  ),
                  _HeroMetric(
                    label: 'Concluídas',
                    value: progress.completed,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 220,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${progress.averageProgressPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 40,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const Text(
                  'Progresso médio',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 11),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child:
                      LinearProgressIndicator(
                    minHeight: 9,
                    value:
                        progress.averageProgressPercent /
                            100,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.12,
                    ),
                    valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(
                      Color(0xFFFFE082),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                information,
                const SizedBox(height: 20),
                side,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 24),
              side,
            ],
          );
        },
      ),
    );
  }
}

class _GoalFilters extends StatelessWidget {
  const _GoalFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.onFarmChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
  });

  final List<AtlasExecutiveFarmGoalSummary>
      farms;

  final String? selectedFarm;

  final AtlasExecutiveGoalStatus?
      selectedStatus;

  final AtlasExecutiveKpiCategory?
      selectedCategory;

  final ValueChanged<String?>
      onFarmChanged;

  final ValueChanged<
      AtlasExecutiveGoalStatus?>
      onStatusChanged;

  final ValueChanged<
      AtlasExecutiveKpiCategory?>
      onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 270,
              child: DropdownButtonFormField<
                  String?>(
                initialValue: selectedFarm,
                decoration:
                    const InputDecoration(
                  labelText: 'Fazenda',
                  prefixIcon: Icon(
                    Icons
                        .agriculture_outlined,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todas as fazendas',
                    ),
                  ),
                  ...farms.map((farm) {
                    return DropdownMenuItem(
                      value: farm.farmName,
                      child: Text(
                        farm.farmName,
                      ),
                    );
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<
                  AtlasExecutiveGoalStatus?>(
                initialValue:
                    selectedStatus,
                decoration:
                    const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(
                    Icons.filter_alt_outlined,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todos os status',
                    ),
                  ),
                  ...AtlasExecutiveGoalStatus
                      .values
                      .map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        atlasExecutiveGoalStatusLabel(
                          status,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<
                  AtlasExecutiveKpiCategory?>(
                initialValue:
                    selectedCategory,
                decoration:
                    const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(
                    Icons.category_outlined,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todas as categorias',
                    ),
                  ),
                  ...AtlasExecutiveKpiCategory
                      .values
                      .map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        atlasExecutiveKpiCategoryLabel(
                          category,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged:
                    onCategoryChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({
    required this.goals,
    required this.onOpenFarm,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReopen,
    required this.onDelete,
  });

  final List<AtlasExecutiveGoal> goals;

  final ValueChanged<String>? onOpenFarm;

  final ValueChanged<AtlasExecutiveGoal>
      onEdit;

  final void Function(
    AtlasExecutiveGoal goal,
    AtlasExecutiveGoalStatus status,
  ) onChangeStatus;

  final ValueChanged<AtlasExecutiveGoal>
      onReopen;

  final ValueChanged<AtlasExecutiveGoal>
      onDelete;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Center(
            child: Text(
              'Nenhuma meta encontrada com os filtros atuais.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: goals.map((goal) {
        final color =
            _goalStatusColor(goal.status);

        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 10,
          ),
          child: Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color:
                              color.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                        child: Icon(
                          Icons.flag_outlined,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.kpiTitle,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${goal.farmName} · '
                              '${atlasExecutiveKpiCategoryLabel(goal.category)}',
                              style:
                                  TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _GoalStatusBadge(
                        status: goal.status,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  LinearProgressIndicator(
                    minHeight: 9,
                    value:
                        goal.progressPercent / 100,
                    backgroundColor:
                        color.withValues(
                      alpha: 0.10,
                    ),
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Atual: ${_formatValue(goal.currentValue, goal.unit)}',
                          style:
                              const TextStyle(
                            color:
                                Colors.black54,
                          ),
                        ),
                      ),
                      Text(
                        '${goal.progressPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Meta: ${_formatValue(goal.targetValue, goal.unit)} · '
                    'Prazo: ${_formatDate(goal.deadline)}',
                    style:
                        const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                  if (goal.responsibleName
                      .isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Responsável: ${goal.responsibleName}',
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (goal.notes.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      goal.notes,
                      style:
                          const TextStyle(
                        color:
                            Colors.black45,
                        fontStyle:
                            FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GoalInfoChip(
                        label:
                            atlasExecutiveGoalPriorityLabel(
                          goal.priority,
                        ),
                        color:
                            _priorityColor(
                          goal.priority,
                        ),
                      ),
                      _GoalInfoChip(
                        label: goal.remainingDays >= 0
                            ? '${goal.remainingDays} dias restantes'
                            : '${goal.remainingDays.abs()} dias de atraso',
                        color: goal.isOverdue
                            ? const Color(
                                0xFFC62828,
                              )
                            : const Color(
                                0xFF1565C0,
                              ),
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                        ),
                        label: const Text(
                          'Editar',
                        ),
                        onPressed: () {
                          onEdit(goal);
                        },
                      ),
                      PopupMenuButton<
                          AtlasExecutiveGoalStatus>(
                        tooltip:
                            'Alterar status',
                        onSelected: (status) {
                          onChangeStatus(
                            goal,
                            status,
                          );
                        },
                        itemBuilder: (context) {
                          return AtlasExecutiveGoalStatus
                              .values
                              .where((status) {
                            return status !=
                                goal.status;
                          }).map((status) {
                            return PopupMenuItem(
                              value: status,
                              child: Text(
                                atlasExecutiveGoalStatusLabel(
                                  status,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        child: const ActionChip(
                          avatar: Icon(
                            Icons.sync_alt_outlined,
                            size: 16,
                          ),
                          label: Text(
                            'Alterar status',
                          ),
                        ),
                      ),
                      if (goal.status ==
                              AtlasExecutiveGoalStatus
                                  .completed ||
                          goal.status ==
                              AtlasExecutiveGoalStatus
                                  .cancelled)
                        ActionChip(
                          avatar: const Icon(
                            Icons.refresh_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            'Reabrir',
                          ),
                          onPressed: () {
                            onReopen(goal);
                          },
                        ),
                      ActionChip(
                        avatar: const Icon(
                          Icons
                              .agriculture_outlined,
                          size: 16,
                        ),
                        label: const Text(
                          'Abrir fazenda',
                        ),
                        onPressed:
                            onOpenFarm == null
                                ? null
                                : () {
                                    onOpenFarm!(
                                      goal.farmName,
                                    );
                                  },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.delete_outline,
                          size: 16,
                        ),
                        label: const Text(
                          'Excluir',
                        ),
                        onPressed: () {
                          onDelete(goal);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GoalStatusBadge
    extends StatelessWidget {
  const _GoalStatusBadge({
    required this.status,
  });

  final AtlasExecutiveGoalStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _goalStatusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(11),
      ),
      child: Text(
        atlasExecutiveGoalStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GoalInfoChip extends StatelessWidget {
  const _GoalInfoChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _EmptyGoalsView extends StatelessWidget {
  const _EmptyGoalsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 58,
              color: Colors.black38,
            ),
            SizedBox(height: 14),
            Text(
              'Nenhuma meta cadastrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'As metas aparecerão aqui após serem criadas a partir dos indicadores.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalEditResult {
  const _GoalEditResult({
    required this.targetValue,
    required this.deadline,
    required this.responsibleName,
    required this.notes,
  });

  final double targetValue;
  final DateTime deadline;
  final String responsibleName;
  final String notes;
}

Color _goalStatusColor(
  AtlasExecutiveGoalStatus status,
) {
  switch (status) {
    case AtlasExecutiveGoalStatus.active:
      return const Color(0xFF1B5E20);

    case AtlasExecutiveGoalStatus.atRisk:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveGoalStatus.overdue:
      return const Color(0xFFC62828);

    case AtlasExecutiveGoalStatus.completed:
      return const Color(0xFF1565C0);

    case AtlasExecutiveGoalStatus.cancelled:
      return const Color(0xFF616161);
  }
}

Color _priorityColor(
  AtlasExecutiveGoalPriority priority,
) {
  switch (priority) {
    case AtlasExecutiveGoalPriority.low:
      return const Color(0xFF2E7D32);

    case AtlasExecutiveGoalPriority.medium:
      return const Color(0xFF1565C0);

    case AtlasExecutiveGoalPriority.high:
      return const Color(0xFFEF6C00);

    case AtlasExecutiveGoalPriority.critical:
      return const Color(0xFFC62828);
  }
}

String _formatDate(
  DateTime date,
) {
  final day =
      date.day.toString().padLeft(2, '0');

  final month =
      date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _formatValue(
  double value,
  String unit,
) {
  final decimals =
      value == value.roundToDouble()
          ? 0
          : 1;

  if (unit == 'R\$') {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  if (unit.isEmpty) {
    return value.toStringAsFixed(decimals);
  }

  return '${value.toStringAsFixed(decimals)} $unit';
}
