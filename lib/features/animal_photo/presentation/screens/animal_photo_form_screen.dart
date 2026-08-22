import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projeto_atlas/features/animal_photo/domain/models/animal_photo_data.dart';

class AnimalPhotoFormScreen extends StatefulWidget {
  const AnimalPhotoFormScreen({this.photo, super.key});
  final AnimalPhotoData? photo;

  @override
  State<AnimalPhotoFormScreen> createState() => _AnimalPhotoFormScreenState();
}

class _AnimalPhotoFormScreenState extends State<AnimalPhotoFormScreen> {
  final formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();

  late final TextEditingController referenceController;
  late final TextEditingController dateController;
  late final TextEditingController titleController;
  late final TextEditingController notesController;

  bool isPrimary = false;
  bool isSelectingImage = false;

  @override
  void initState() {
    super.initState();
    final photo = widget.photo;
    referenceController = TextEditingController(text: photo?.reference ?? '');
    dateController = TextEditingController(text: photo?.date ?? _today());
    titleController = TextEditingController(text: photo?.title ?? '');
    notesController = TextEditingController(text: photo?.notes ?? '');
    isPrimary = photo?.isPrimary ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      recoverLostImage();
    });
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

  Future<void> recoverLostImage() async {
    try {
      final response = await picker.retrieveLostData();
      if (response.isEmpty || !mounted) return;
      final recovered = response.files?.isNotEmpty == true
          ? response.files!.first
          : null;
      if (recovered != null) {
        applySelectedImage(recovered.path);
      }
    } catch (_) {}
  }

  Future<void> pickImage(ImageSource source) async {
    if (isSelectingImage) return;
    setState(() => isSelectingImage = true);

    try {
      final selected = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (selected == null || !mounted) return;
      applySelectedImage(selected.path);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar a foto: $error')),
      );
    } finally {
      if (mounted) setState(() => isSelectingImage = false);
    }
  }

  void applySelectedImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A imagem selecionada não está mais disponível.'),
        ),
      );
      return;
    }
    setState(() => referenceController.text = file.path);
    formKey.currentState?.validate();
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
    setState(() => dateController.text = '$day/$month/${selected.year}');
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
        id: current?.id ?? 'photo_${DateTime.now().microsecondsSinceEpoch}',
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
    final reference = referenceController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.photo == null ? 'Nova foto' : 'Editar foto'),
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Escolha uma imagem da galeria do Android ou tire uma foto com a câmera.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: isSelectingImage
                            ? null
                            : () => pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeria'),
                      ),
                      OutlinedButton.icon(
                        onPressed: isSelectingImage
                            ? null
                            : () => pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Câmera'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: referenceController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Imagem selecionada',
                      hintText: 'Nenhuma imagem selecionada',
                      prefixIcon: const Icon(Icons.image_outlined),
                      suffixIcon: reference.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar seleção',
                              onPressed: () {
                                setState(referenceController.clear);
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final path = value?.trim() ?? '';
                      if (path.isEmpty) return 'Selecione uma imagem.';
                      if (!File(path).existsSync()) {
                        return 'A imagem selecionada não está disponível.';
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
                    onChanged: (value) => setState(() => isPrimary = value),
                    title: const Text('Definir como foto principal'),
                    subtitle: const Text(
                      'Somente uma foto pode ser principal.',
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: isSelectingImage ? null : save,
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
