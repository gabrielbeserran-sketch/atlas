import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/models/atlas_workflow_data.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/services/atlas_workflow_service.dart';
import 'package:projeto_atlas/features/workflow_engine/domain/services/atlas_workflow_event_service.dart';

class AtlasWorkflowScreen
    extends StatefulWidget {
  const AtlasWorkflowScreen({
    required this.workflows,
    this.onWorkflowsChanged,
    this.onOpenFarm,
    super.key,
  });

  final List<AtlasWorkflow> workflows;

  final ValueChanged<List<AtlasWorkflow>>?
      onWorkflowsChanged;

  final ValueChanged<String>? onOpenFarm;

  @override
  State<AtlasWorkflowScreen> createState() {
    return _AtlasWorkflowScreenState();
  }
}

class _AtlasWorkflowScreenState
    extends State<AtlasWorkflowScreen> {
  final AtlasWorkflowService service =
      const AtlasWorkflowService();

  final AtlasWorkflowEventService eventService =
      const AtlasWorkflowEventService();

  late List<AtlasWorkflow> workflows;

  AtlasWorkflowStatus? selectedStatus;
  String? selectedFarm;

  @override
  void initState() {
    super.initState();
    workflows = [...widget.workflows];
  }

  AtlasWorkflowData get dashboard {
    return service.buildDashboard(
      workflows: workflows,
    );
  }

  List<String> get farms {
    final result = workflows
        .map((item) => item.farmName)
        .toSet()
        .toList()
      ..sort();

    return result;
  }

  List<AtlasWorkflow> get filteredWorkflows {
    return dashboard.workflows.where((item) {
      if (selectedFarm != null &&
          item.farmName != selectedFarm) {
        return false;
      }

      if (selectedStatus != null &&
          item.status != selectedStatus) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _updateWorkflow(
    AtlasWorkflow updated,
  ) async {
    final previous = workflows
        .cast<AtlasWorkflow?>()
        .firstWhere(
          (item) => item?.id == updated.id,
          orElse: () => null,
        );

    setState(() {
      workflows = workflows.map((item) {
        return item.id == updated.id
            ? updated
            : item;
      }).toList();
    });

    widget.onWorkflowsChanged?.call(
      workflows,
    );

    if (previous == null) {
      await eventService.publishWorkflowCreated(
        workflow: updated,
      );
      return;
    }

    await eventService.publishWorkflowChanged(
      previousWorkflow: previous,
      updatedWorkflow: updated,
    );
  }

  Future<void> _assignResponsible({
    required AtlasWorkflow workflow,
    required AtlasWorkflowTask task,
  }) async {
    final controller = TextEditingController(
      text: task.responsibleName,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Definir responsável',
          ),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(
              labelText:
                  'Nome do responsável',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  controller.text.trim(),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null ||
        result.isEmpty ||
        !mounted) {
      return;
    }

    await _updateWorkflow(
      service.assignResponsible(
        workflow: workflow,
        taskId: task.id,
        responsibleName: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = dashboard;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Workflow Engine',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1240,
            ),
            child: data.hasData
                ? ListView(
                    padding:
                        const EdgeInsets.all(22),
                    children: [
                      _WorkflowHero(data: data),
                      const SizedBox(height: 22),
                      _WorkflowFilters(
                        farms: farms,
                        selectedFarm:
                            selectedFarm,
                        selectedStatus:
                            selectedStatus,
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
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title:
                            'Planos de execução',
                        subtitle:
                            'Tarefas, responsáveis, dependências e cronograma.',
                      ),
                      const SizedBox(height: 13),
                      if (filteredWorkflows.isEmpty)
                        const _EmptyFilteredView()
                      else
                        ...filteredWorkflows.map(
                          (workflow) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 13,
                              ),
                              child:
                                  _WorkflowCard(
                                workflow:
                                    workflow,
                                onStartTask:
                                    (taskId) async {
                                  await _updateWorkflow(
                                    service.startTask(
                                      workflow:
                                          workflow,
                                      taskId: taskId,
                                    ),
                                  );
                                },
                                onProgressChanged:
                                    (
                                  taskId,
                                  value,
                                ) async {
                                  await _updateWorkflow(
                                    service
                                        .updateTaskProgress(
                                      workflow:
                                          workflow,
                                      taskId: taskId,
                                      progressPercent:
                                          value,
                                    ),
                                  );
                                },
                                onAssignResponsible:
                                    (task) {
                                  _assignResponsible(
                                    workflow:
                                        workflow,
                                    task: task,
                                  );
                                },
                                onReplan: (days) async {
                                  await _updateWorkflow(
                                    service.replan(
                                      workflow:
                                          workflow,
                                      additionalDays:
                                          days,
                                    ),
                                  );
                                },
                                onOpenFarm:
                                    widget.onOpenFarm,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  )
                : const _EmptyWorkflowView(),
          ),
        ),
      ),
    );
  }
}

class _WorkflowHero extends StatelessWidget {
  const _WorkflowHero({
    required this.data,
  });

  final AtlasWorkflowData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final compact =
              constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.schema_outlined,
                    color: Color(0xFFB2DFDB),
                    size: 32,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Workflow Executivo',
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
                    label: 'Tarefas',
                    value: data.totalTasks,
                  ),
                  _HeroMetric(
                    label: 'Concluídas',
                    value:
                        data.completedTasks,
                  ),
                  _HeroMetric(
                    label: 'Atrasadas',
                    value: data.delayedTasks,
                  ),
                ],
              ),
            ],
          );

          final side = Container(
            width: 225,
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
                  '${data.progressPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFFB2DFDB),
                    fontSize: 40,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const Text(
                  'Progresso global',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child:
                      LinearProgressIndicator(
                    minHeight: 9,
                    value:
                        data.progressPercent /
                            100,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.12,
                    ),
                    valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(
                      Color(0xFFB2DFDB),
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

class _WorkflowFilters
    extends StatelessWidget {
  const _WorkflowFilters({
    required this.farms,
    required this.selectedFarm,
    required this.selectedStatus,
    required this.onFarmChanged,
    required this.onStatusChanged,
  });

  final List<String> farms;
  final String? selectedFarm;

  final AtlasWorkflowStatus? selectedStatus;

  final ValueChanged<String?>
      onFarmChanged;

  final ValueChanged<AtlasWorkflowStatus?>
      onStatusChanged;

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
              width: 260,
              child: DropdownButtonFormField<
                  String?>(
                initialValue: selectedFarm,
                decoration:
                    const InputDecoration(
                  labelText: 'Fazenda',
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
                      value: farm,
                      child: Text(farm),
                    );
                  }),
                ],
                onChanged: onFarmChanged,
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<
                  AtlasWorkflowStatus?>(
                initialValue: selectedStatus,
                decoration:
                    const InputDecoration(
                  labelText: 'Situação',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todas as situações',
                    ),
                  ),
                  ...AtlasWorkflowStatus.values
                      .map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        atlasWorkflowStatusLabel(
                          status,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: onStatusChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.workflow,
    required this.onStartTask,
    required this.onProgressChanged,
    required this.onAssignResponsible,
    required this.onReplan,
    required this.onOpenFarm,
  });

  final AtlasWorkflow workflow;

  final ValueChanged<String> onStartTask;

  final void Function(
    String taskId,
    double progress,
  ) onProgressChanged;

  final ValueChanged<AtlasWorkflowTask>
      onAssignResponsible;

  final ValueChanged<int> onReplan;

  final ValueChanged<String>? onOpenFarm;

  @override
  Widget build(BuildContext context) {
    final color =
        _workflowStatusColor(workflow.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schema_outlined,
                  color: color,
                  size: 29,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      Text(
                        workflow.farmName,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  atlasWorkflowStatusLabel(
                    workflow.status,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              workflow.description,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              minHeight: 9,
              value:
                  workflow.progressPercent / 100,
              backgroundColor:
                  color.withValues(
                alpha: 0.10,
              ),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${workflow.progressPercent.toStringAsFixed(0)}% concluído · '
              'prazo ${_date(workflow.deadline)}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 15),
            ...workflow.tasks.map((task) {
              final taskColor =
                  _taskStatusColor(task.status);

              return Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                padding:
                    const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: taskColor.withValues(
                    alpha: 0.05,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        taskColor.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              taskColor.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            task.position
                                .toString(),
                            style: TextStyle(
                              color: taskColor,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          atlasWorkflowTaskStatusLabel(
                            task.status,
                          ),
                          style: TextStyle(
                            color: taskColor,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      task.description,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.responsibleName.isEmpty
                          ? 'Responsável não definido'
                          : 'Responsável: ${task.responsibleName}',
                      style: TextStyle(
                        color: taskColor,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      minHeight: 7,
                      value:
                          task.progressPercent /
                              100,
                      backgroundColor:
                          taskColor.withValues(
                        alpha: 0.10,
                      ),
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        taskColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (task.status ==
                                AtlasWorkflowTaskStatus
                                    .pending ||
                            task.status ==
                                AtlasWorkflowTaskStatus
                                    .delayed)
                          OutlinedButton.icon(
                            onPressed: () {
                              onStartTask(task.id);
                            },
                            icon: const Icon(
                              Icons.play_arrow,
                            ),
                            label: const Text(
                              'Iniciar',
                            ),
                          ),
                        if (task.status ==
                            AtlasWorkflowTaskStatus
                                .inProgress)
                          OutlinedButton.icon(
                            onPressed: () {
                              onProgressChanged(
                                task.id,
                                math.min(
                                  task.progressPercent +
                                      25,
                                  100,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add_task,
                            ),
                            label: const Text(
                              'Avançar 25%',
                            ),
                          ),
                        ActionChip(
                          avatar: const Icon(
                            Icons.person_outline,
                            size: 16,
                          ),
                          label: const Text(
                            'Responsável',
                          ),
                          onPressed: () {
                            onAssignResponsible(
                              task,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (workflow.bottlenecks.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Gargalos identificados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...workflow.bottlenecks.map(
                (item) {
                  final severityColor =
                      _bottleneckColor(
                    item.severity,
                  );

                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading: Icon(
                      Icons
                          .warning_amber_outlined,
                      color: severityColor,
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${item.delayDays} dias de atraso · '
                      '${item.recommendation}',
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (workflow
                    .replanningSuggestions
                    .isNotEmpty)
                  FilledButton.icon(
                    onPressed: () {
                      final suggestion =
                          workflow
                              .replanningSuggestions
                              .first;

                      final days = suggestion
                          .newDeadline
                          .difference(
                            workflow.deadline,
                          )
                          .inDays;

                      onReplan(
                        math.max(days, 1),
                      );
                    },
                    icon: const Icon(
                      Icons
                          .calendar_month_outlined,
                    ),
                    label: const Text(
                      'Aplicar replanejamento',
                    ),
                  ),
                if (onOpenFarm != null)
                  ActionChip(
                    avatar: const Icon(
                      Icons.agriculture_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Abrir fazenda',
                    ),
                    onPressed: () {
                      onOpenFarm!(
                        workflow.farmName,
                      );
                    },
                  ),
              ],
            ),
          ],
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

class _EmptyFilteredView
    extends StatelessWidget {
  const _EmptyFilteredView();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'Nenhum workflow encontrado com os filtros atuais.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyWorkflowView
    extends StatelessWidget {
  const _EmptyWorkflowView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum plano de execução disponível.',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }
}

Color _workflowStatusColor(
  AtlasWorkflowStatus status,
) {
  switch (status) {
    case AtlasWorkflowStatus.planned:
      return const Color(0xFF1565C0);

    case AtlasWorkflowStatus.inProgress:
      return const Color(0xFFEF6C00);

    case AtlasWorkflowStatus.delayed:
      return const Color(0xFFC62828);

    case AtlasWorkflowStatus.completed:
      return const Color(0xFF1B5E20);

    case AtlasWorkflowStatus.cancelled:
      return const Color(0xFF616161);
  }
}

Color _taskStatusColor(
  AtlasWorkflowTaskStatus status,
) {
  switch (status) {
    case AtlasWorkflowTaskStatus.blocked:
      return const Color(0xFF616161);

    case AtlasWorkflowTaskStatus.pending:
      return const Color(0xFF1565C0);

    case AtlasWorkflowTaskStatus.inProgress:
      return const Color(0xFFEF6C00);

    case AtlasWorkflowTaskStatus.delayed:
      return const Color(0xFFC62828);

    case AtlasWorkflowTaskStatus.completed:
      return const Color(0xFF1B5E20);

    case AtlasWorkflowTaskStatus.cancelled:
      return const Color(0xFF616161);
  }
}

Color _bottleneckColor(
  AtlasWorkflowBottleneckSeverity severity,
) {
  switch (severity) {
    case AtlasWorkflowBottleneckSeverity.low:
      return const Color(0xFF1565C0);

    case AtlasWorkflowBottleneckSeverity.medium:
      return const Color(0xFFEF6C00);

    case AtlasWorkflowBottleneckSeverity.high:
      return const Color(0xFFC62828);

    case AtlasWorkflowBottleneckSeverity.critical:
      return const Color(0xFF8E0000);
  }
}

String _date(
  DateTime date,
) {
  final day =
      date.day.toString().padLeft(2, '0');

  final month =
      date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
