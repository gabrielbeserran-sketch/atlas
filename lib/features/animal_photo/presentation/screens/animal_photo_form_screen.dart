import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal_photo/domain/models/animal_photo_data.dart';

class AnimalPhotoFormScreen extends StatefulWidget {
  const AnimalPhotoFormScreen({
    this.photo,
    super.key,
  });

  final AnimalPhotoData? photo;

  @override
  State<AnimalPhotoFormScreen> createState() =>
      _AnimalPhotoFormScreenState();
}

class _AnimalPhotoFormScreenState
    extends State<AnimalPhotoFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController referenceController;
  late final TextEditingController dateController;
  late final TextEditingController titleController;
  late final TextEditingController notesController;

  bool isPrimary = false;

  @override
  void initState() {
    super.initState();
    final photo = widget.photo;

    referenceController = TextEditingController(
      text: photo?.reference ?? '',
    );
    dateController = TextEditingController(
      text: photo?.date ?? _today(),
    );
    titleController = TextEditingController(
      text: photo?.title ?? '',
    );
    notesController = TextEditingController(
      text: photo?.notes ?? '',
    );
    isPrimary = photo?.isPrimary ?? false;
  }

  @override
  void dispose() {
    referenceController.dispose();
    dateController.dispose();
    titleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    return '$day/$month/${now.year}';
  }

  Future<void> chooseDate() async {
    final current = _parseDate(dateController.text) ?? DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected == null) return;

    final day = selected.day.toString().padLeft(2, '0');
    final month = selected.month.toString().padLeft(2, '0');

    setState(() {
      dateController.text = '$day/$month/${selected.year}';
    });
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final current = widget.photo;
    final now = DateTime.now().toIso8601String();

    Navigator.of(context).pop(
      AnimalPhotoData(
        id: current?.id ??
            'photo_${DateTime.now().microsecondsSinceEpoch}',
        reference: referenceController.text.trim(),
        date: dateController.text.trim(),
        title: titleController.text.trim(),
        notes: notesController.text.trim(),
        isPrimary: isPrimary,
        createdAt: current?.createdAt ?? now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.photo == null ? 'Nova foto' : 'Editar foto',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Registro fotográfico',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Informe o caminho completo do arquivo de imagem no computador.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Caminho da imagem',
                      hintText: r'C:\Fotos\animal_001.jpg',
                      prefixIcon: Icon(Icons.image_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o caminho da imagem.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    onTap: chooseDate,
                    decoration: const InputDecoration(
                      labelText: 'Data da foto',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex.: Avaliação corporal',
                      prefixIcon: Icon(Icons.title_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      prefixIcon: Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isPrimary,
                    onChanged: (value) {
                      setState(() => isPrimary = value);
                    },
                    title: const Text('Definir como foto principal'),
                    subtitle: const Text(
                      'Somente uma foto pode ser principal.',
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar foto'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
