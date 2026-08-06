import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_area_performance.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_farm_execution_score.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_goal_action_link.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_goal_action_link_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_goal_performance_summary.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_strategy_performance_service.dart';

class AtlasStrategyPerformanceScreen extends StatefulWidget {
  const AtlasStrategyPerformanceScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasStrategyPerformanceScreen> createState() =>
      _AtlasStrategyPerformanceScreenState();
}

class _AtlasStrategyPerformanceScreenState
    extends State<AtlasStrategyPerformanceScreen> {
  final AtlasOperationalGoalService goalService =
      AtlasOperationalGoalService.instance;
  final AtlasGoalActionLinkService linkService =
      AtlasGoalActionLinkService.instance;
  final AtlasStrategyPerformanceService performanceService =
      const AtlasStrategyPerformanceService();

  List<AtlasOperationalGoal> goals = <AtlasOperationalGoal>[];
  List<AtlasGoalActionLink> links = <AtlasGoalActionLink>[];
  bool isLoading = false;
  bool includeInactive = false;

  List<AtlasAreaPerformance> get areas => performanceService.buildAreas(
    actions: widget.actionController.actions,
    goals: goals,
    links: links,
  );

  List<AtlasGoalPerformanceSummary> get goalSummaries =>
      performanceService.buildGoals(
        actions: widget.actionController.actions,
        goals: goals,
        links: links,
      );

  AtlasFarmExecutionScore get farmScore => performanceService.buildFarmScore(
    actions: widget.actionController.actions,
    goals: goals,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    await widget.actionController.load();
    goals = await goalService.load(
      farmName: widget.actionController.farmName,
      includeInactive: includeInactive,
    );
    links = await linkService.loadAll();

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createOrEditGoal({AtlasOperationalGoal? goal}) async {
    final title = TextEditingController(text: goal?.title ?? '');
    final description = TextEditingController(text: goal?.description ?? '');
    final target = TextEditingController(
      text: goal == null ? '' : goal.targetValue.toStringAsFixed(2),
    );
    final current = TextEditingController(
      text: goal == null ? '' : goal.currentValue.toStringAsFixed(2),
    );

    var area = goal?.area ?? AtlasOperationalArea.general;
    var period = goal?.period ?? AtlasGoalPeriod.monthly;
    var metricType = goal?.metricType ?? AtlasGoalMetricType.percentage;
    var startAt = goal?.startAt ?? DateTime.now();
    var endAt = goal?.endAt ?? DateTime.now().add(const Duration(days: 30));
    var active = goal?.active ?? true;

    final result = await showDialog<AtlasOperationalGoal>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(goal == null ? 'Nova meta' : 'Editar meta'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Título da meta',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: description,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasOperationalArea>(
                        initialValue: area,
                        decoration: const InputDecoration(
                          labelText: 'Área operacional',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasOperationalArea.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(atlasOperationalAreaLabel(value)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => area = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasGoalPeriod>(
                        initialValue: period,
                        decoration: const InputDecoration(
                          labelText: 'Período',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasGoalPeriod.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(atlasGoalPeriodLabel(value)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => period = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasGoalMetricType>(
                        initialValue: metricType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de indicador',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasGoalMetricType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(atlasGoalMetricTypeLabel(value)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => metricType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: target,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Valor planejado',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: current,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Valor realizado',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Período da meta'),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(startAt)} '
                          'a ${DateFormat('dd/MM/yyyy').format(endAt)}',
                        ),
                        trailing: const Icon(Icons.date_range_outlined),
                        onTap: () async {
                          final selectedStart = await showDatePicker(
                            context: dialogContext,
                            initialDate: startAt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (selectedStart == null || !dialogContext.mounted) {
                            return;
                          }

                          final selectedEnd = await showDatePicker(
                            context: dialogContext,
                            initialDate: endAt.isBefore(selectedStart)
                                ? selectedStart
                                : endAt,
                            firstDate: selectedStart,
                            lastDate: DateTime(2100),
                          );

                          if (selectedEnd == null) {
                            return;
                          }

                          setDialogState(() {
                            startAt = selectedStart;
                            endAt = selectedEnd;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Meta ativa'),
                        value: active,
                        onChanged: (value) {
                          setDialogState(() => active = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (title.text.trim().isEmpty) {
                      return;
                    }

                    final now = DateTime.now();

                    Navigator.of(dialogContext).pop(
                      goal == null
                          ? AtlasOperationalGoal(
                              id:
                                  'goal_'
                                  '${now.microsecondsSinceEpoch}',
                              title: title.text.trim(),
                              description: description.text.trim(),
                              area: area,
                              period: period,
                              metricType: metricType,
                              targetValue: _parseNumber(target.text),
                              currentValue: _parseNumber(current.text),
                              startAt: startAt,
                              endAt: endAt,
                              farmName: widget.actionController.farmName,
                              active: active,
                              createdAt: now,
                              updatedAt: now,
                            )
                          : goal.copyWith(
                              title: title.text.trim(),
                              description: description.text.trim(),
                              area: area,
                              period: period,
                              metricType: metricType,
                              targetValue: _parseNumber(target.text),
                              currentValue: _parseNumber(current.text),
                              startAt: startAt,
                              endAt: endAt,
                              active: active,
                            ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    title.dispose();
    description.dispose();
    target.dispose();
    current.dispose();

    if (result == null) {
      return;
    }

    await goalService.save(result);
    await _load();
  }

  Future<void> _linkActions(AtlasOperationalGoal goal) async {
    final existingLinks = await linkService.loadByGoal(goal.id);
    final selectedIds = existingLinks.map((link) => link.actionId).toSet();

    if (!mounted) {
      return;
    }

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Vincular ações — ${goal.title}'),
              content: SizedBox(
                width: 680,
                height: 520,
                child: widget.actionController.actions.isEmpty
                    ? const Center(child: Text('Nenhuma ação disponível.'))
                    : ListView.builder(
                        itemCount: widget.actionController.actions.length,
                        itemBuilder: (context, index) {
                          final action = widget.actionController.actions[index];

                          return CheckboxListTile(
                            value: selectedIds.contains(action.id),
                            title: Text(action.title),
                            subtitle: Text(
                              '${action.progressPercent}% • '
                              '${action.responsibleName.trim().isEmpty ? 'Sem responsável' : action.responsibleName}',
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedIds.add(action.id);
                                } else {
                                  selectedIds.remove(action.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(Set<String>.from(selectedIds)),
                  child: const Text('Salvar vínculos'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    await linkService.replaceGoalLinks(goal: goal, actionIds: result);
    await _load();
  }

  Future<void> _deleteGoal(AtlasOperationalGoal goal) async {
    await linkService.removeGoal(goal.id);
    await goalService.delete(goal.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Metas e desempenho'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.flag_outlined), text: 'Metas'),
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Áreas'),
              Tab(
                icon: Icon(Icons.compare_arrows),
                text: 'Planejado x realizado',
              ),
              Tab(icon: Icon(Icons.speed_outlined), text: 'Score da fazenda'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: isLoading ? null : () => _createOrEditGoal(),
          icon: const Icon(Icons.add),
          label: const Text('Nova meta'),
        ),
        body: isLoading && goals.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _GoalsTab(
                    goals: goals,
                    links: links,
                    includeInactive: includeInactive,
                    onIncludeInactiveChanged: (value) async {
                      setState(() => includeInactive = value);
                      await _load();
                    },
                    onEdit: (goal) => _createOrEditGoal(goal: goal),
                    onLink: _linkActions,
                    onDelete: _deleteGoal,
                  ),
                  _AreasTab(areas: areas),
                  _PlannedRealizedTab(summaries: goalSummaries),
                  _FarmScoreTab(score: farmScore),
                ],
              ),
      ),
    );
  }

  static double _parseNumber(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(normalized) ?? 0;
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({
    required this.goals,
    required this.links,
    required this.includeInactive,
    required this.onIncludeInactiveChanged,
    required this.onEdit,
    required this.onLink,
    required this.onDelete,
  });

  final List<AtlasOperationalGoal> goals;
  final List<AtlasGoalActionLink> links;
  final bool includeInactive;
  final ValueChanged<bool> onIncludeInactiveChanged;
  final ValueChanged<AtlasOperationalGoal> onEdit;
  final ValueChanged<AtlasOperationalGoal> onLink;
  final ValueChanged<AtlasOperationalGoal> onDelete;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma meta operacional foi cadastrada.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Mostrar metas inativas'),
          value: includeInactive,
          onChanged: onIncludeInactiveChanged,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final goal = goals[index];
              final linkedCount = links
                  .where((link) => link.goalId == goal.id)
                  .length;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            goal.isCompleted
                                ? Icons.task_alt
                                : goal.isOverdue
                                ? Icons.event_busy
                                : Icons.flag_outlined,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              goal.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit(goal);
                              } else if (value == 'link') {
                                onLink(goal);
                              } else if (value == 'delete') {
                                onDelete(goal);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'link',
                                child: Text('Vincular ações'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(goal.description),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: goal.progressPercent / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${goal.progressPercent.toStringAsFixed(0)}% • '
                        '${_formatGoalValue(goal.currentValue, goal.metricType)} '
                        'de ${_formatGoalValue(goal.targetValue, goal.metricType)}',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(atlasOperationalAreaLabel(goal.area)),
                          ),
                          Chip(label: Text(atlasGoalPeriodLabel(goal.period))),
                          Chip(label: Text('$linkedCount ação(ões)')),
                          Chip(
                            label: Text(
                              'Até ${DateFormat('dd/MM/yyyy').format(goal.endAt)}',
                            ),
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

  static String _formatGoalValue(double value, AtlasGoalMetricType type) {
    switch (type) {
      case AtlasGoalMetricType.currency:
        return 'R\$ ${value.toStringAsFixed(2)}';
      case AtlasGoalMetricType.percentage:
        return '${value.toStringAsFixed(1)}%';
      case AtlasGoalMetricType.quantity:
      case AtlasGoalMetricType.score:
        return value.toStringAsFixed(1);
    }
  }
}

class _AreasTab extends StatelessWidget {
  const _AreasTab({required this.areas});

  final List<AtlasAreaPerformance> areas;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: areas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final area = areas[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        atlasOperationalAreaLabel(area.area),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${area.performanceScore.toStringAsFixed(0)} pontos',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: area.performanceScore / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('${area.totalActions} ações')),
                    Chip(label: Text('${area.completedActions} concluídas')),
                    Chip(label: Text('${area.overdueActions} atrasadas')),
                    Chip(
                      label: Text(
                        '${area.averageProgressPercent.toStringAsFixed(0)}% progresso',
                      ),
                    ),
                    Chip(label: Text('${area.activeGoals} metas ativas')),
                    Chip(
                      label: Text(
                        'R\$ ${area.expectedFinancialImpact.toStringAsFixed(2)} esperado',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlannedRealizedTab extends StatelessWidget {
  const _PlannedRealizedTab({required this.summaries});

  final List<AtlasGoalPerformanceSummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Center(
        child: Text('Cadastre metas para comparar planejado e realizado.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: summaries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final summary = summaries[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.goal.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        'Planejado: ${summary.plannedValue.toStringAsFixed(2)}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Realizado: ${summary.realizedValue.toStringAsFixed(2)}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Diferença: ${summary.variance.toStringAsFixed(2)}',
                      ),
                    ),
                    Chip(
                      label: Text('${summary.linkedActions} ações vinculadas'),
                    ),
                    Chip(label: Text('${summary.completedActions} concluídas')),
                    Chip(label: Text('${summary.overdueActions} atrasadas')),
                    Chip(
                      label: Text(
                        '${summary.averageActionProgressPercent.toStringAsFixed(0)}% progresso das ações',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Score de execução: '
                  '${summary.executionScore.toStringAsFixed(0)} pontos',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: summary.executionScore / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FarmScoreTab extends StatelessWidget {
  const _FarmScoreTab({required this.score});

  final AtlasFarmExecutionScore score;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.speed_outlined, size: 52),
                const SizedBox(height: 12),
                Text(
                  score.score.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  score.statusLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: score.score / 100,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ScoreComponent(
          title: 'Conclusão das ações',
          value: score.completionComponent,
        ),
        _ScoreComponent(
          title: 'Progresso médio',
          value: score.progressComponent,
        ),
        _ScoreComponent(
          title: 'Cumprimento de prazos',
          value: score.deadlineComponent,
        ),
        _ScoreComponent(
          title: 'Cobertura de responsáveis',
          value: score.responsibilityComponent,
        ),
        _ScoreComponent(
          title: 'Progresso das metas',
          value: score.goalComponent,
        ),
      ],
    );
  }
}

class _ScoreComponent extends StatelessWidget {
  const _ScoreComponent({required this.title, required this.value});

  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        trailing: Text(
          '${value.toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
