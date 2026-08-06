import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal_document/domain/models/animal_document_data.dart';

class AnimalDocumentFormScreen extends StatefulWidget {
  const AnimalDocumentFormScreen({
    this.document,
    super.key,
  });

  final AnimalDocumentData? document;

  @override
  State<AnimalDocumentFormScreen> createState() {
    return _AnimalDocumentFormScreenState();
  }
}

class _AnimalDocumentFormScreenState
    extends State<AnimalDocumentFormScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController dateController;
  late final TextEditingController expirationController;
  late final TextEditingController referenceController;
  late final TextEditingController issuerController;
  late final TextEditingController notesController;

  late String selectedType;
  late String selectedCategory;

  bool isFavorite = false;
  bool isSaving = false;
  bool isSelectingFile = false;

  static const types = <String>[
    'GTA',
    'Atestado',
    'Laudo',
    'Exame',
    'Certificado',
    'Receituário',
    'Nota fiscal',
    'Contrato',
    'Compra',
    'Venda',
    'SISBOV',
    'Registro genealógico',
    'Documento de transporte',
    'IATF',
    'IA',
    'Diagnóstico de gestação',
    'Protocolo hormonal',
    'Parto',
    'Outro',
  ];

  static const categories = <String>[
    'Sanitário',
    'Reprodutivo',
    'Comercial',
    'Oficial',
    'Outro',
  ];

  bool get isEditing => widget.document != null;

  @override
  void initState() {
    super.initState();

    final document = widget.document;
    selectedType = document?.type ?? 'GTA';
    selectedCategory =
        document?.category ?? inferDocumentCategory(selectedType);
    isFavorite = document?.isFavorite ?? false;

    titleController = TextEditingController(
      text: document?.title ?? '',
    );
    dateController = TextEditingController(
      text: document?.date ?? formatDate(DateTime.now()),
    );
    expirationController = TextEditingController(
      text: document?.expirationDate ?? '',
    );
    referenceController = TextEditingController(
      text: document?.reference ?? '',
    );
    issuerController = TextEditingController(
      text: document?.issuer ?? '',
    );
    notesController = TextEditingController(
      text: document?.notes ?? '',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    expirationController.dispose();
    referenceController.dispose();
    issuerController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    return null;
  }

  String? referenceValidator(String? value) {
    final reference = value?.trim() ?? '';
    if (reference.isEmpty) return null;

    final uri = Uri.tryParse(reference);
    final isWebUrl = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (isWebUrl) return null;

    final directory = Directory(reference);
    if (directory.existsSync()) {
      return 'Selecione um arquivo, não uma pasta.';
    }

    final file = File(reference);
    if (!file.existsSync()) {
      return 'O arquivo informado não foi localizado.';
    }

    return null;
  }

  Future<void> selectDate({
    required TextEditingController controller,
  }) async {
    final initial = parseDocumentDate(controller.text) ?? DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null || !mounted) return;

    setState(() {
      controller.text = formatDate(selected);
    });
  }

  void clearExpiration() {
    setState(expirationController.clear);
  }

  Future<void> selectFile() async {
    if (isSelectingFile) return;

    setState(() => isSelectingFile = true);

    const acceptedTypes = <XTypeGroup>[
      XTypeGroup(
        label: 'Documentos suportados',
        extensions: <String>[
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'csv',
          'txt',
        ],
      ),
    ];

    try {
      final selectedFile = await openFile(
        acceptedTypeGroups: acceptedTypes,
      );

      if (!mounted || selectedFile == null) return;

      final selectedPath = selectedFile.path.trim();

      if (selectedPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O seletor não retornou um caminho válido.',
            ),
          ),
        );
        return;
      }

      final file = File(selectedPath);

      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O arquivo selecionado não foi localizado.',
            ),
          ),
        );
        return;
      }

      setState(() {
        referenceController.text = file.path;

        if (titleController.text.trim().isEmpty) {
          titleController.text = fileNameWithoutExtension(file.path);
        }
      });

      formKey.currentState?.validate();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível abrir o seletor de arquivos: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSelectingFile = false);
      }
    }
  }

  void clearReference() {
    setState(referenceController.clear);
    formKey.currentState?.validate();
  }

  void saveDocument() {
    if (isSaving || !formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final now = DateTime.now().toIso8601String();
    final current = widget.document;

    Navigator.pop<AnimalDocumentData>(
      context,
      AnimalDocumentData(
        id: current?.id ??
            'document_${DateTime.now().microsecondsSinceEpoch}',
        type: selectedType,
        category: selectedCategory,
        title: titleController.text.trim(),
        date: dateController.text.trim(),
        expirationDate: expirationController.text.trim(),
        reference: referenceController.text.trim(),
        issuer: issuerController.text.trim(),
        notes: notesController.text.trim(),
        isFavorite: isFavorite,
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final reference = referenceController.text.trim();
    final attachment = attachmentInformation(reference);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar documento' : 'Novo documento'),
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
                  Text(
                    isEditing
                        ? 'Atualizar documento'
                        : 'Registrar documento',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cadastre validade, emissor e selecione o arquivo pelo explorador do Windows.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 26),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de documento',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: types
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedType = value;
                        selectedCategory =
                            inferDocumentCategory(selectedType);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    validator: requiredValidator,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex.: Exame de brucelose',
                      prefixIcon: Icon(Icons.title_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: dateController,
                    validator: requiredValidator,
                    readOnly: true,
                    onTap: () => selectDate(controller: dateController),
                    decoration: const InputDecoration(
                      labelText: 'Data de emissão',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: expirationController,
                    readOnly: true,
                    onTap: () => selectDate(
                      controller: expirationController,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Data de vencimento',
                      helperText: 'Opcional',
                      prefixIcon:
                          const Icon(Icons.event_busy_outlined),
                      suffixIcon: expirationController.text.isEmpty
                          ? const Icon(Icons.arrow_drop_down)
                          : IconButton(
                              tooltip: 'Remover vencimento',
                              onPressed: clearExpiration,
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: referenceController,
                    validator: referenceValidator,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Arquivo ou link',
                      hintText: 'Selecione um arquivo ou informe uma URL',
                      prefixIcon:
                          const Icon(Icons.attach_file_outlined),
                      suffixIcon: reference.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Remover anexo',
                              onPressed: clearReference,
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed:
                          isSelectingFile ? null : selectFile,
                      icon: isSelectingFile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.folder_open_outlined),
                      label: Text(
                        isSelectingFile
                            ? 'Abrindo explorador...'
                            : 'Selecionar arquivo',
                      ),
                    ),
                  ),
                  if (attachment != null) ...[
                    const SizedBox(height: 10),
                    AttachmentPreview(information: attachment),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: issuerController,
                    decoration: const InputDecoration(
                      labelText: 'Emissor ou responsável',
                      prefixIcon: Icon(Icons.business_outlined),
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
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isFavorite,
                    onChanged: (value) {
                      setState(() => isFavorite = value);
                    },
                    title: const Text('Marcar como favorito'),
                    subtitle: const Text(
                      'Favoritos aparecem no início da listagem.',
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: isSaving ? null : saveDocument,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      isEditing
                          ? 'Salvar alterações'
                          : 'Cadastrar documento',
                    ),
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

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    required this.information,
    super.key,
  });

  final AttachmentInformation information;

  @override
  Widget build(BuildContext context) {
    final icon = switch (information.kind) {
      AttachmentKind.url => Icons.link_outlined,
      AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
      AttachmentKind.image => Icons.image_outlined,
      AttachmentKind.spreadsheet => Icons.table_chart_outlined,
      AttachmentKind.document => Icons.description_outlined,
      AttachmentKind.other => Icons.insert_drive_file_outlined,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(information.name),
        subtitle: Text(
          information.kind == AttachmentKind.url
              ? 'Link externo'
              : '${information.extension.toUpperCase()} • ${formatFileSize(information.sizeBytes)}',
        ),
      ),
    );
  }
}

enum AttachmentKind {
  url,
  pdf,
  image,
  spreadsheet,
  document,
  other,
}

class AttachmentInformation {
  const AttachmentInformation({
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.kind,
  });

  final String name;
  final String extension;
  final int sizeBytes;
  final AttachmentKind kind;
}

AttachmentInformation? attachmentInformation(String reference) {
  final normalized = reference.trim();
  if (normalized.isEmpty) return null;

  final uri = Uri.tryParse(normalized);
  final isUrl = uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https');

  if (isUrl) {
    return AttachmentInformation(
      name: uri.pathSegments.isEmpty
          ? normalized
          : uri.pathSegments.last,
      extension: '',
      sizeBytes: 0,
      kind: AttachmentKind.url,
    );
  }

  final file = File(normalized);
  if (!file.existsSync()) return null;

  final name = fileName(normalized);
  final extension = fileExtension(normalized);
  final lowerExtension = extension.toLowerCase();

  final kind = switch (lowerExtension) {
    'pdf' => AttachmentKind.pdf,
    'jpg' || 'jpeg' || 'png' || 'webp' => AttachmentKind.image,
    'xls' || 'xlsx' || 'csv' => AttachmentKind.spreadsheet,
    'doc' || 'docx' || 'txt' => AttachmentKind.document,
    _ => AttachmentKind.other,
  };

  return AttachmentInformation(
    name: name,
    extension: extension,
    sizeBytes: file.lengthSync(),
    kind: kind,
  );
}

String fileName(String path) {
  return path
      .replaceAll('\\', '/')
      .split('/')
      .where((part) => part.isNotEmpty)
      .last;
}

String fileNameWithoutExtension(String path) {
  final name = fileName(path);
  final position = name.lastIndexOf('.');
  return position <= 0 ? name : name.substring(0, position);
}

String fileExtension(String path) {
  final name = fileName(path);
  final position = name.lastIndexOf('.');
  return position == -1 || position == name.length - 1
      ? ''
      : name.substring(position + 1);
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';

  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) {
    return '${kilobytes.toStringAsFixed(1)} KB';
  }

  final megabytes = kilobytes / 1024;
  if (megabytes < 1024) {
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  final gigabytes = megabytes / 1024;
  return '${gigabytes.toStringAsFixed(1)} GB';
}
