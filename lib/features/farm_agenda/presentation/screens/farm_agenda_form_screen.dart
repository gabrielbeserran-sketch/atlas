import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';

class FarmAgendaFormScreen extends StatefulWidget {
  const FarmAgendaFormScreen({this.task, super.key});

  final FarmAgendaData? task;

  @override
  State<FarmAgendaFormScreen> createState() {
    return _FarmAgendaFormScreenState();
  }
}

class _FarmAgendaFormScreenState extends State<FarmAgendaFormScreen> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final responsibleController = TextEditingController();
  final notesController = TextEditingController();

  String selectedCategory = 'Manejo geral';
  String selectedPriority = 'Normal';
  String selectedStatus = 'Pendente';

  bool isSaving = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    if (task != null) {
      titleController.text = task.title;
      selectedCategory = task.category;
      dateController.text = task.date;
      timeController.text = task.time;
      responsibleController.text = task.responsible;
      selectedPriority = task.priority;
      selectedStatus = task.status;
      notesController.text = task.notes;
    } else {
      dateController.text = formatDate(DateTime.now());
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    timeController.dispose();
    responsibleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }

    return null;
  }

  Future<void> selectDate() async {
    final initialDate = parseDate(dateController.text) ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate == null) {
      return;
    }

    dateController.text = formatDate(selectedDate);
  }

  Future<void> selectTime() async {
    final initialTime = parseTime(timeController.text) ?? TimeOfDay.now();

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null) {
      return;
    }

    timeController.text = formatTime(selectedTime);
  }

  void clearTime() {
    setState(() {
      timeController.clear();
    });
  }

  void saveTask() {
    if (isSaving) {
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final task = FarmAgendaData(
      id: widget.task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      category: selectedCategory,
      date: dateController.text.trim(),
      time: timeController.text.trim(),
      responsible: responsibleController.text.trim(),
      priority: selectedPriority,
      status: selectedStatus,
      notes: notesController.text.trim(),
    );

    Navigator.pop<FarmAgendaData>(context, task);
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  static DateTime? parseDate(String value) {
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

  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  static TimeOfDay? parseTime(String value) {
    final parts = value.trim().split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar compromisso' : 'Novo compromisso'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing
                          ? 'Atualizar compromisso'
                          : 'Adicionar compromisso',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Organize manejos, visitas, tarefas e atividades da fazenda.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Manejo geral',
                          child: Text('Manejo geral'),
                        ),
                        DropdownMenuItem(
                          value: 'Vacinação',
                          child: Text('Vacinação'),
                        ),
                        DropdownMenuItem(
                          value: 'Pesagem',
                          child: Text('Pesagem'),
                        ),
                        DropdownMenuItem(
                          value: 'Reprodução',
                          child: Text('Reprodução'),
                        ),
                        DropdownMenuItem(
                          value: 'Sanidade',
                          child: Text('Sanidade'),
                        ),
                        DropdownMenuItem(
                          value: 'Movimentação',
                          child: Text('Movimentação'),
                        ),
                        DropdownMenuItem(
                          value: 'Manutenção',
                          child: Text('Manutenção'),
                        ),
                        DropdownMenuItem(
                          value: 'Compra ou entrega',
                          child: Text('Compra ou entrega'),
                        ),
                        DropdownMenuItem(
                          value: 'Visita técnica',
                          child: Text('Visita técnica'),
                        ),
                        DropdownMenuItem(
                          value: 'Administrativo',
                          child: Text('Administrativo'),
                        ),
                        DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Exemplo: vacinação do lote de matrizes',
                        prefixIcon: Icon(Icons.task_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useRow = constraints.maxWidth >= 560;

                        final dateField = TextFormField(
                          controller: dateController,
                          validator: requiredValidator,
                          readOnly: true,
                          onTap: selectDate,
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                        );

                        final timeField = TextFormField(
                          controller: timeController,
                          readOnly: true,
                          onTap: selectTime,
                          decoration: InputDecoration(
                            labelText: 'Horário',
                            hintText: 'Opcional',
                            prefixIcon: const Icon(Icons.schedule_outlined),
                            suffixIcon: timeController.text.isEmpty
                                ? const Icon(Icons.arrow_drop_down)
                                : IconButton(
                                    tooltip: 'Remover horário',
                                    onPressed: clearTime,
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                        );

                        if (!useRow) {
                          return Column(
                            children: [
                              dateField,
                              const SizedBox(height: 16),
                              timeField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: dateField),
                            const SizedBox(width: 16),
                            Expanded(child: timeField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: responsibleController,
                      decoration: const InputDecoration(
                        labelText: 'Responsável',
                        hintText: 'Funcionário, veterinário ou prestador',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useRow = constraints.maxWidth >= 560;

                        final priorityField = DropdownButtonFormField<String>(
                          initialValue: selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Prioridade',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Baixa',
                              child: Text('Baixa'),
                            ),
                            DropdownMenuItem(
                              value: 'Normal',
                              child: Text('Normal'),
                            ),
                            DropdownMenuItem(
                              value: 'Alta',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'Urgente',
                              child: Text('Urgente'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              selectedPriority = value;
                            });
                          },
                        );

                        final statusField = DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Situação',
                            prefixIcon: Icon(Icons.fact_check_outlined),
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
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              selectedStatus = value;
                            });
                          },
                        );

                        if (!useRow) {
                          return Column(
                            children: [
                              priorityField,
                              const SizedBox(height: 16),
                              statusField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: priorityField),
                            const SizedBox(width: 16),
                            Expanded(child: statusField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        hintText:
                            'Animais envolvidos, materiais necessários e orientações...',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          isEditing
                              ? 'Salvar alterações'
                              : 'Salvar compromisso',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
