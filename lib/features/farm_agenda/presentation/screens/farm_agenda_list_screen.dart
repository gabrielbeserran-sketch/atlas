import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_agenda/presentation/screens/farm_agenda_form_screen.dart';

class FarmAgendaListScreen extends StatefulWidget {
  const FarmAgendaListScreen({required this.farm, super.key});

  final FarmData farm;

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

  String selectedFilter = 'Todas';
  String searchText = '';

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
    final savedTasks = await storage.loadTasks(widget.farm.name);

    savedTasks.sort(compareTasks);

    if (!mounted) {
      return;
    }

    setState(() {
      tasks = savedTasks;
      isLoading = false;
    });
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

    setState(() {
      tasks.add(newTask);
      tasks.sort(compareTasks);
    });

    await saveTasks();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compromisso adicionado à agenda.')),
    );
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

    final taskIndex = tasks.indexWhere((item) => item.id == task.id);

    if (taskIndex == -1) {
      return;
    }

    setState(() {
      tasks[taskIndex] = editedTask;
      tasks.sort(compareTasks);
    });

    await saveTasks();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Compromisso atualizado.')));
  }

  Future<void> toggleCompleted(FarmAgendaData task) async {
    final taskIndex = tasks.indexWhere((item) => item.id == task.id);

    if (taskIndex == -1) {
      return;
    }

    final newStatus = task.isCompleted ? 'Pendente' : 'Concluída';

    setState(() {
      tasks[taskIndex] = task.copyWith(status: newStatus);
    });

    await saveTasks();

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

    setState(() {
      tasks.removeWhere((item) => item.id == task.id);
    });

    await saveTasks();

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
      appBar: AppBar(
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
                        const SizedBox(height: 28),
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
