import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal_event/domain/models/animal_event_data.dart';

class AnimalEventFormScreen extends StatefulWidget {
  const AnimalEventFormScreen({this.event, super.key});

  final AnimalEventData? event;

  @override
  State<AnimalEventFormScreen> createState() => _AnimalEventFormScreenState();
}

class _AnimalEventFormScreenState extends State<AnimalEventFormScreen> {
  final formKey = GlobalKey<FormState>();

  final dateController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedType = 'Pesagem';
  bool isSaving = false;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    final event = widget.event;

    if (event != null) {
      selectedType = event.type;
      dateController.text = event.date;
      titleController.text = event.title;
      descriptionController.text = event.description;
    } else {
      final now = DateTime.now();

      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      final year = now.year.toString();

      dateController.text = '$day/$month/$year';
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }

    return null;
  }

  Future<void> selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate == null) {
      return;
    }

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();

    dateController.text = '$day/$month/$year';
  }

  void saveEvent() {
    if (isSaving) {
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final event = AnimalEventData(
      id: widget.event?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: selectedType,
      date: dateController.text.trim(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
    );

    Navigator.pop<AnimalEventData>(context, event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar evento' : 'Novo evento')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing
                          ? 'Atualizar acontecimento'
                          : 'Registrar acontecimento',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'O evento será adicionado à linha do tempo do animal.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo do evento',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Nascimento',
                          child: Text('Nascimento'),
                        ),
                        DropdownMenuItem(
                          value: 'Pesagem',
                          child: Text('Pesagem'),
                        ),
                        DropdownMenuItem(
                          value: 'Vacinação',
                          child: Text('Vacinação'),
                        ),
                        DropdownMenuItem(
                          value: 'Tratamento',
                          child: Text('Tratamento'),
                        ),
                        DropdownMenuItem(
                          value: 'Vermifugação',
                          child: Text('Vermifugação'),
                        ),
                        DropdownMenuItem(
                          value: 'Mudança de lote',
                          child: Text('Mudança de lote'),
                        ),
                        DropdownMenuItem(value: 'IATF', child: Text('IATF')),
                        DropdownMenuItem(
                          value: 'Diagnóstico',
                          child: Text('Diagnóstico'),
                        ),
                        DropdownMenuItem(value: 'Parto', child: Text('Parto')),
                        DropdownMenuItem(
                          value: 'Observação',
                          child: Text('Observação'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      validator: requiredValidator,
                      readOnly: true,
                      onTap: selectDate,
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      validator: requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Pesagem de rotina',
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Descrição ou observações',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          isEditing ? 'Salvar alterações' : 'Salvar evento',
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
