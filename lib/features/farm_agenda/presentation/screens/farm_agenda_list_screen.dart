import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_feedback.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_agenda/presentation/screens/farm_agenda_form_screen.dart';

enum AgendaViewMode { list, week, month }

class FarmAgendaListScreen extends StatefulWidget {
  const FarmAgendaListScreen({
    required this.farm,
    this.embedded = false,
    super.key,
  });

  final FarmData farm;
  final bool embedded;

  @override
  State<FarmAgendaListScreen> createState() {
    return _FarmAgendaListScreenState();
  }
}

class _FarmAgendaListScreenState extends State<FarmAgendaListScreen> {
  final FarmAgendaStorageService storage = FarmAgendaStorageService();

  final searchController = TextEditingController();

  List<FarmAgendaData> tasks = [];

  bool isLoading = true;
  String? loadError;

  String selectedFilter = 'Todas';
  String searchText = '';
  AgendaViewMode viewMode = AgendaViewMode.list;
  DateTime calendarAnchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<FarmAgendaData> get visibleTasks {
    return tasks.where((task) {
      final query = searchText.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.category.toLowerCase().contains(query) ||
          task.responsible.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      if (selectedFilter == 'Pendentes') {
        return task.status == 'Pendente' || task.status == 'Em andamento';
      }

      if (selectedFilter == 'Concluídas') {
        return task.status == 'Concluída';
      }

      if (selectedFilter == 'Atrasadas') {
        return isOverdue(task);
      }

      if (selectedFilter == 'Hoje') {
        return isToday(task);
      }

      return true;
    }).toList();
  }

  int get pendingCount {
    return tasks.where((task) {
      return task.status == 'Pendente' || task.status == 'Em andamento';
    }).length;
  }

  int get completedCount {
    return tasks.where((task) {
      return task.status == 'Concluída';
    }).length;
  }

  int get overdueCount {
    return tasks.where(isOverdue).length;
  }

  int get todayCount {
    return tasks.where(isToday).length;
  }

  int get urgentCount {
    return tasks.where((task) {
      return task.priority == 'Urgente' &&
          !task.isCompleted &&
          !task.isCancelled;
    }).length;
  }

  Future<void> loadTasks() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }
    try {
      final savedTasks = await storage.loadTasks(
        widget.farm.name,
        farmId: widget.farm.id ?? '',
      );
      savedTasks.sort(compareTasks);
      if (!mounted) return;
      setState(() {
        tasks = savedTasks;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = error.toString();
      });
    }
  }

  Future<void> saveTasks() async {
    await storage.saveTasks(farmName: widget.farm.name, tasks: tasks);
  }

  Future<void> openTaskForm() async {
    final newTask = await Navigator.push<FarmAgendaData>(
      context,
      MaterialPageRoute<FarmAgendaData>(
        builder: (context) {
          return const FarmAgendaFormScreen();
        },
      ),
    );

    if (newTask == null || !mounted) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    try {
      final savedTask = farmId.isEmpty
          ? newTask
          : await storage.createTask(
              farmName: widget.farm.name,
              farmId: farmId,
              task: newTask,
            );
      if (!mounted) {
        return;
      }
      setState(() {
        tasks.removeWhere((item) => item.id == savedTask.id);
        tasks.add(savedTask);
        tasks.sort(compareTasks);
      });

      if (farmId.isEmpty) {
        await saveTasks();
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compromisso salvo e confirmado no servidor.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar o compromisso: $error'),
        ),
      );
    }
  }

  Future<void> editTask(FarmAgendaData task) async {
    final editedTask = await Navigator.push<FarmAgendaData>(
      context,
      MaterialPageRoute<FarmAgendaData>(
        builder: (context) {
          return FarmAgendaFormScreen(task: task);
        },
      ),
    );

    if (editedTask == null || !mounted) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    try {
      final savedTask = farmId.isEmpty
          ? editedTask
          : await storage.updateTask(
              farmName: widget.farm.name,
              farmId: farmId,
              task: editedTask,
            );
      final taskIndex = tasks.indexWhere((item) => item.id == task.id);
      if (taskIndex == -1 || !mounted) {
        return;
      }

      setState(() {
        tasks[taskIndex] = savedTask;
        tasks.sort(compareTasks);
      });

      if (farmId.isEmpty) {
        await saveTasks();
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alterações salvas e confirmadas no servidor.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível atualizar o compromisso: $error'),
        ),
      );
    }
  }

  Future<void> toggleCompleted(FarmAgendaData task) async {
    final taskIndex = tasks.indexWhere((item) => item.id == task.id);

    if (taskIndex == -1) {
      return;
    }

    final newStatus = task.isCompleted ? 'Pendente' : 'Concluída';
    final updated = task.copyWith(status: newStatus);
    final farmId = widget.farm.id ?? '';
    final savedTask = farmId.isEmpty
        ? updated
        : await storage.updateTask(
            farmName: widget.farm.name,
            farmId: farmId,
            task: updated,
          );
    if (!mounted) return;
    setState(() {
      tasks[taskIndex] = savedTask;
    });

    if (farmId.isEmpty) await saveTasks();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'Concluída'
              ? 'Tarefa marcada como concluída.'
              : 'Tarefa reaberta.',
        ),
      ),
    );
  }

  Future<void> deleteTask(FarmAgendaData task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir compromisso'),
          content: Text('Deseja excluir ${task.title}?'),
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

    if (shouldDelete != true) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    if (farmId.isNotEmpty) {
      await storage.cancelTask(farmName: widget.farm.name, task: task);
    }
    if (!mounted) return;
    setState(() {
      tasks.removeWhere((item) => item.id == task.id);
    });

    if (farmId.isEmpty) await saveTasks();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Compromisso excluído.')));
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = visibleTasks;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : loadTasks,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openTaskForm,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo compromisso'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : loadError != null && tasks.isEmpty
                    ? AtlasLoadErrorState(
                        message: 'Verifique sua conexão e tente novamente.',
                        onRetry: loadTasks,
                      )
                    : RefreshIndicator(
                    onRefresh: loadTasks,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        AgendaHeader(
                          farm: widget.farm,
                          pendingCount: pendingCount,
                          todayCount: todayCount,
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            AgendaSummaryCard(
                              title: 'Compromissos',
                              value: tasks.length.toString(),
                              icon: Icons.calendar_month_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            AgendaSummaryCard(
                              title: 'Pendentes',
                              value: pendingCount.toString(),
                              icon: Icons.schedule_outlined,
                              color: pendingCount > 0
                                  ? const Color(0xFFEF6C00)
                                  : const Color(0xFF1B5E20),
                            ),
                            AgendaSummaryCard(
                              title: 'Hoje',
                              value: todayCount.toString(),
                              icon: Icons.today_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            AgendaSummaryCard(
                              title: 'Atrasadas',
                              value: overdueCount.toString(),
                              icon: Icons.warning_amber_outlined,
                              color: overdueCount > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                            AgendaSummaryCard(
                              title: 'Urgentes',
                              value: urgentCount.toString(),
                              icon: Icons.priority_high,
                              color: urgentCount > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                            AgendaSummaryCard(
                              title: 'Concluídas',
                              value: completedCount.toString(),
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF1B5E20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchText = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Pesquisar compromisso',
                            hintText: 'Título, categoria ou responsável',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            AgendaFilterChip(
                              label: 'Todas',
                              selected: selectedFilter == 'Todas',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Todas';
                                });
                              },
                            ),
                            AgendaFilterChip(
                              label: 'Hoje',
                              selected: selectedFilter == 'Hoje',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Hoje';
                                });
                              },
                            ),
                            AgendaFilterChip(
                              label: 'Pendentes',
                              selected: selectedFilter == 'Pendentes',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Pendentes';
                                });
                              },
                            ),
                            AgendaFilterChip(
                              label: 'Atrasadas',
                              selected: selectedFilter == 'Atrasadas',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Atrasadas';
                                });
                              },
                            ),
                            AgendaFilterChip(
                              label: 'Concluídas',
                              selected: selectedFilter == 'Concluídas',
                              onSelected: () {
                                setState(() {
                                  selectedFilter = 'Concluídas';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AgendaViewSelector(
                          mode: viewMode,
                          onChanged: (mode) {
                            setState(() {
                              viewMode = mode;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        if (viewMode != AgendaViewMode.list)
                          AgendaCalendarNavigator(
                            mode: viewMode,
                            anchor: calendarAnchor,
                            onPrevious: () {
                              setState(() {
                                calendarAnchor = viewMode == AgendaViewMode.week
                                    ? calendarAnchor.subtract(
                                        const Duration(days: 7),
                                      )
                                    : DateTime(
                                        calendarAnchor.year,
                                        calendarAnchor.month - 1,
                                        1,
                                      );
                              });
                            },
                            onToday: () {
                              setState(() {
                                calendarAnchor = DateTime.now();
                              });
                            },
                            onNext: () {
                              setState(() {
                                calendarAnchor = viewMode == AgendaViewMode.week
                                    ? calendarAnchor.add(
                                        const Duration(days: 7),
                                      )
                                    : DateTime(
                                        calendarAnchor.year,
                                        calendarAnchor.month + 1,
                                        1,
                                      );
                              });
                            },
                          ),
                        if (viewMode != AgendaViewMode.list)
                          const SizedBox(height: 14),
                        if (viewMode == AgendaViewMode.week)
                          AgendaWeekCalendar(
                            anchor: calendarAnchor,
                            tasks: filteredTasks,
                            onTaskTap: editTask,
                          )
                        else if (viewMode == AgendaViewMode.month)
                          AgendaMonthCalendar(
                            anchor: calendarAnchor,
                            tasks: filteredTasks,
                            onTaskTap: editTask,
                          )
                        else ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Compromissos',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${filteredTasks.length} registros',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Atividades organizadas por data e horário.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          if (filteredTasks.isEmpty)
                            EmptyAgendaMessage(
                              hasFilter:
                                  selectedFilter != 'Todas' ||
                                  searchText.trim().isNotEmpty,
                            )
                          else
                            ...filteredTasks.map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AgendaTaskCard(
                                  task: task,
                                  overdue: isOverdue(task),
                                  onEdit: () {
                                    editTask(task);
                                  },
                                  onComplete: () {
                                    toggleCompleted(task);
                                  },
                                  onDelete: () {
                                    deleteTask(task);
                                  },
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AgendaHeader extends StatelessWidget {
  const AgendaHeader({
    required this.farm,
    required this.pendingCount,
    required this.todayCount,
    super.key,
  });

  final FarmData farm;
  final int pendingCount;
  final int todayCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agenda da propriedade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  farm.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${farm.city} - ${farm.state}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AgendaHeaderMetric(value: todayCount.toString(), label: 'hoje'),
              AgendaHeaderMetric(
                value: pendingCount.toString(),
                label: 'pendentes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AgendaHeaderMetric extends StatelessWidget {
  const AgendaHeaderMetric({
    required this.value,
    required this.label,
    super.key,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AgendaSummaryCard extends StatelessWidget {
  const AgendaSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AgendaFilterChip extends StatelessWidget {
  const AgendaFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onSelected();
      },
    );
  }
}

class AgendaTaskCard extends StatelessWidget {
  const AgendaTaskCard({
    required this.task,
    required this.overdue,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
    super.key,
  });

  final FarmAgendaData task;
  final bool overdue;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = taskStatusColor(task, overdue);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  categoryIcon(task.category),
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.category,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        AgendaInformation(
                          icon: Icons.calendar_month_outlined,
                          text: task.date,
                        ),
                        if (task.time.isNotEmpty)
                          AgendaInformation(
                            icon: Icons.schedule_outlined,
                            text: task.time,
                          ),
                        if (task.responsible.isNotEmpty)
                          AgendaInformation(
                            icon: Icons.person_outline,
                            text: task.responsible,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 9,
                      runSpacing: 8,
                      children: [
                        AgendaBadge(label: task.status, color: color),
                        AgendaBadge(
                          label: 'Prioridade ${task.priority}',
                          color: priorityColor(task.priority),
                        ),
                        if (overdue)
                          AgendaBadge(
                            label: 'Atrasada',
                            color: Colors.red.shade700,
                          ),
                      ],
                    ),
                    if (task.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(task.notes, style: const TextStyle(height: 1.4)),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (value) {
                  if (value == 'complete') {
                    onComplete();
                  }

                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted
                                ? Icons.restart_alt_outlined
                                : Icons.check_circle_outline,
                            color: const Color(0xFF1B5E20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            task.isCompleted
                                ? 'Reabrir tarefa'
                                : 'Marcar como concluída',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Color(0xFF1565C0)),
                          SizedBox(width: 10),
                          Text('Editar compromisso'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Excluir compromisso'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AgendaInformation extends StatelessWidget {
  const AgendaInformation({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class AgendaBadge extends StatelessWidget {
  const AgendaBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EmptyAgendaMessage extends StatelessWidget {
  const EmptyAgendaMessage({required this.hasFilter, super.key});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 60,
              color: Color(0xFF1B5E20),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'Nenhum compromisso encontrado.'
                  : 'A agenda está vazia.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Altere a pesquisa ou o filtro selecionado.'
                  : 'Cadastre o primeiro manejo, visita ou tarefa.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaViewSelector extends StatelessWidget {
  const AgendaViewSelector({
    required this.mode,
    required this.onChanged,
    super.key,
  });
  final AgendaViewMode mode;
  final ValueChanged<AgendaViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<AgendaViewMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: AgendaViewMode.list,
            icon: Icon(Icons.view_list_outlined),
            label: Text('Lista'),
          ),
          ButtonSegment(
            value: AgendaViewMode.week,
            icon: Icon(Icons.view_week_outlined),
            label: Text('Semana'),
          ),
          ButtonSegment(
            value: AgendaViewMode.month,
            icon: Icon(Icons.calendar_month_outlined),
            label: Text('Mês'),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

class AgendaCalendarNavigator extends StatelessWidget {
  const AgendaCalendarNavigator({
    required this.mode,
    required this.anchor,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
    super.key,
  });
  final AgendaViewMode mode;
  final DateTime anchor;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = mode == AgendaViewMode.week
        ? _weekLabel(anchor)
        : '${_monthName(anchor.month)} ${anchor.year}';
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        OutlinedButton(onPressed: onToday, child: const Text('Hoje')),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class AgendaWeekCalendar extends StatelessWidget {
  const AgendaWeekCalendar({
    required this.anchor,
    required this.tasks,
    required this.onTaskTap,
    super.key,
  });
  final DateTime anchor;
  final List<FarmAgendaData> tasks;
  final ValueChanged<FarmAgendaData> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final start = _startOfWeek(anchor);
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 980
            ? (constraints.maxWidth - 48) / 7
            : 220.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: days.map((day) {
              final dayTasks =
                  tasks
                      .where(
                        (task) => _sameDay(parseAgendaDate(task.date), day),
                      )
                      .toList()
                    ..sort(compareTasks);
              return Container(
                width: width,
                constraints: const BoxConstraints(minHeight: 340),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _sameDay(day, DateTime.now())
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF7F9F4),
                  border: Border.all(color: const Color(0xFFD7DDCF)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weekdayName(day.weekday)} ${day.day}/${day.month}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (dayTasks.isEmpty)
                      const Text(
                        'Sem tarefas',
                        style: TextStyle(color: Colors.black45),
                      )
                    else
                      ...dayTasks.map(
                        (task) => _CalendarTaskTile(
                          task: task,
                          onTap: () => onTaskTap(task),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class AgendaMonthCalendar extends StatelessWidget {
  const AgendaMonthCalendar({
    required this.anchor,
    required this.tasks,
    required this.onTaskTap,
    super.key,
  });
  final DateTime anchor;
  final List<FarmAgendaData> tasks;
  final ValueChanged<FarmAgendaData> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(anchor.year, anchor.month, 1);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Center(child: Text('Seg'))),
            Expanded(child: Center(child: Text('Ter'))),
            Expanded(child: Center(child: Text('Qua'))),
            Expanded(child: Center(child: Text('Qui'))),
            Expanded(child: Center(child: Text('Sex'))),
            Expanded(child: Center(child: Text('Sáb'))),
            Expanded(child: Center(child: Text('Dom'))),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.05,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final dayTasks =
                tasks
                    .where((task) => _sameDay(parseAgendaDate(task.date), day))
                    .toList()
                  ..sort(compareTasks);
            final inMonth = day.month == anchor.month;
            return Container(
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _sameDay(day, DateTime.now())
                    ? const Color(0xFFE8F5E9)
                    : Colors.white,
                border: Border.all(color: const Color(0xFFD7DDCF)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: inMonth ? Colors.black87 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView(
                      children: dayTasks
                          .take(3)
                          .map(
                            (task) => _CalendarTaskTile(
                              task: task,
                              compact: true,
                              onTap: () => onTaskTap(task),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (dayTasks.length > 3)
                    Text(
                      '+${dayTasks.length - 3}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarTaskTile extends StatelessWidget {
  const _CalendarTaskTile({
    required this.task,
    required this.onTap,
    this.compact = false,
  });
  final FarmAgendaData task;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final color = taskStatusColor(task, isOverdue(task));
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: compact ? 4 : 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${task.time.isEmpty ? '' : '${task.time} '} ${task.title}'.trim(),
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 10 : 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

DateTime _startOfWeek(DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
).subtract(Duration(days: date.weekday - 1));
bool _sameDay(DateTime? a, DateTime b) =>
    a != null && a.year == b.year && a.month == b.month && a.day == b.day;
String _weekdayName(int weekday) =>
    const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][weekday - 1];
String _monthName(int month) => const [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
][month - 1];
String _weekLabel(DateTime anchor) {
  final start = _startOfWeek(anchor);
  final end = start.add(const Duration(days: 6));
  return '${start.day}/${start.month} – ${end.day}/${end.month}/${end.year}';
}

bool isToday(FarmAgendaData task) {
  final date = parseAgendaDate(task.date);

  if (date == null) {
    return false;
  }

  final now = DateTime.now();

  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

bool isOverdue(FarmAgendaData task) {
  if (task.isCompleted || task.isCancelled) {
    return false;
  }

  final date = parseAgendaDate(task.date);

  if (date == null) {
    return false;
  }

  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  return date.isBefore(today);
}

int compareTasks(FarmAgendaData first, FarmAgendaData second) {
  final firstDate = parseAgendaDate(first.date) ?? DateTime(2100);

  final secondDate = parseAgendaDate(second.date) ?? DateTime(2100);

  final dateComparison = firstDate.compareTo(secondDate);

  if (dateComparison != 0) {
    return dateComparison;
  }

  final firstMinutes = parseMinutes(first.time);

  final secondMinutes = parseMinutes(second.time);

  return firstMinutes.compareTo(secondMinutes);
}

DateTime? parseAgendaDate(String value) {
  final parts = value.trim().split('/');

  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return null;
  }

  final date = DateTime(year, month, day);

  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}

int parseMinutes(String value) {
  final parts = value.trim().split(':');

  if (parts.length != 2) {
    return 24 * 60;
  }

  final hour = int.tryParse(parts[0]) ?? 24;
  final minute = int.tryParse(parts[1]) ?? 0;

  return hour * 60 + minute;
}

Color taskStatusColor(FarmAgendaData task, bool overdue) {
  if (overdue) {
    return Colors.red.shade700;
  }

  switch (task.status) {
    case 'Concluída':
      return const Color(0xFF1B5E20);
    case 'Em andamento':
      return const Color(0xFF1565C0);
    case 'Cancelada':
      return Colors.grey.shade700;
    default:
      return const Color(0xFFEF6C00);
  }
}

Color priorityColor(String priority) {
  switch (priority) {
    case 'Urgente':
      return Colors.red.shade700;
    case 'Alta':
      return const Color(0xFFEF6C00);
    case 'Baixa':
      return const Color(0xFF1565C0);
    default:
      return const Color(0xFF1B5E20);
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Vacinação':
      return Icons.vaccines_outlined;
    case 'Pesagem':
      return Icons.monitor_weight_outlined;
    case 'Reprodução':
      return Icons.favorite_outline;
    case 'Sanidade':
      return Icons.medical_services_outlined;
    case 'Movimentação':
      return Icons.swap_horiz_outlined;
    case 'Manutenção':
      return Icons.handyman_outlined;
    case 'Compra ou entrega':
      return Icons.local_shipping_outlined;
    case 'Visita técnica':
      return Icons.badge_outlined;
    case 'Administrativo':
      return Icons.business_center_outlined;
    default:
      return Icons.task_alt_outlined;
  }
}
