import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/financial_document_remote_service.dart';

class FinancialDocumentCenterScreen extends StatefulWidget {
  const FinancialDocumentCenterScreen({
    required this.entryId,
    required this.title,
    this.capturedDocumentPath,
    super.key,
  });
  final String entryId;
  final String title;
  final String? capturedDocumentPath;
  @override
  State<FinancialDocumentCenterScreen> createState() =>
      _FinancialDocumentCenterScreenState();
}

class _FinancialDocumentCenterScreenState
    extends State<FinancialDocumentCenterScreen> {
  final _service = FinancialDocumentRemoteService();
  final _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _uploading = false;
  String? _loadError;
  String? _capturedDocumentPath;
  @override
  void initState() {
    super.initState();
    _capturedDocumentPath = widget.capturedDocumentPath;
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loadError = null);
    try {
      _items = await _service.list(widget.entryId);
    } catch (_) {
      _loadError = 'Não foi possível carregar os documentos agora.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _upload() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Documento',
          extensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'xlsx'],
        ),
      ],
    );
    if (file == null || !mounted) return;
    await _uploadPath(
      file.path,
      successMessage: 'Documento anexado e aguardando revisão humana.',
    );
  }

  Future<void> _captureDocument() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (photo == null || !mounted) return;
      await _uploadPath(
        photo.path,
        successMessage: 'Foto da nota anexada e aguardando conferência.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Não foi possível abrir a câmera. Verifique a permissão do dispositivo.',
      );
    }
  }

  Future<bool> _uploadPath(
    String filePath, {
    required String successMessage,
  }) async {
    setState(() => _uploading = true);
    try {
      await _service.upload(entryId: widget.entryId, filePath: filePath);
      await _load();
      if (!mounted) return false;
      _showMessage(successMessage);
      return true;
    } catch (_) {
      if (!mounted) return false;
      _showMessage('Não foi possível anexar o documento. Tente novamente.');
      return false;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _attachCapturedDocument() async {
    final path = _capturedDocumentPath;
    if (path == null) return;
    final attached = await _uploadPath(
      path,
      successMessage: 'Foto da nota anexada e aguardando conferência.',
    );
    if (attached && mounted) setState(() => _capturedDocumentPath = null);
  }

  Future<void> _saveCopy(Map<String, dynamic> item) async {
    final filename = item['original_filename']?.toString() ?? 'documento';
    final location = await getSaveLocation(suggestedName: filename);
    if (location == null || !mounted) return;

    try {
      final bytes = await _service.download(item['id'].toString());
      await XFile.fromData(
        Uint8List.fromList(bytes),
        name: filename,
      ).saveTo(location.path);
      if (!mounted) return;
      _showMessage('Cópia do documento salva.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível salvar a cópia do documento.');
    }
  }

  Future<void> _review(Map<String, dynamic> item, String status) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewDocumentDialog(status: status),
    );
    if (notes == null || !mounted) return;

    try {
      await _service.review(
        documentId: item['id'].toString(),
        status: status,
        notes: notes,
      );
      await _load();
      if (!mounted) return;
      _showMessage(_reviewMessage(status));
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível registrar a revisão. Tente novamente.');
    }
  }

  Map<String, dynamic> _extractedData(Map<String, dynamic> item) {
    final raw = item['extracted_data'];
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  String _dataSummary(Map<String, dynamic> item) {
    final data = _extractedData(item);
    final values = [
      data['supplier']?.toString(),
      data['document_number']?.toString(),
      data['document_date']?.toString(),
      data['total_amount']?.toString(),
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return values.isEmpty ? 'Dados ainda não conferidos' : values.join(' • ');
  }

  Future<void> _captureData(Map<String, dynamic> item) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DocumentDataDialog(initialData: _extractedData(item)),
    );
    if (data == null || !mounted) return;

    final currentStatus = item['review_status']?.toString();
    try {
      await _service.review(
        documentId: item['id'].toString(),
        status:
            const {'pending', 'reviewed', 'rejected'}.contains(currentStatus)
            ? currentStatus!
            : 'pending',
        extractedData: data,
        notes: item['review_notes']?.toString() ?? '',
      );
      await _load();
      if (!mounted) return;
      _showMessage('Dados do documento registrados para conferência.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível registrar os dados do documento.');
    }
  }

  String _reviewMessage(String status) => switch (status) {
    'reviewed' => 'Documento marcado como revisado.',
    'rejected' => 'Documento marcado para correção.',
    _ => 'Status do documento atualizado.',
  };

  String _reviewLabel(Object? value) => switch (value?.toString()) {
    'reviewed' => 'Revisado',
    'rejected' => 'Precisa de correção',
    _ => 'Aguardando revisão',
  };

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Documentos financeiros'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _loading
              ? null
              : () {
                  setState(() => _loading = true);
                  _load();
                },
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _uploading ? null : _upload,
      icon: const Icon(Icons.upload_file_outlined),
      label: Text(_uploading ? 'Enviando...' : 'Anexar documento'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Os arquivos ficam vinculados ao lançamento. Confira os dados antes de aprovar; a aprovação continua sempre humana.',
              ),
              const SizedBox(height: 16),
              if (_capturedDocumentPath != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Foto capturada pronta para anexar'),
                    subtitle: const Text(
                      'Confirme o envio para vincular a foto a este lançamento.',
                    ),
                    trailing: FilledButton(
                      onPressed: _uploading ? null : _attachCapturedDocument,
                      child: const Text('Anexar foto'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Fotografar nota ou documento'),
                  subtitle: const Text(
                    'Use a câmera do celular para anexar o comprovante a este lançamento.',
                  ),
                  trailing: FilledButton.icon(
                    onPressed: _uploading ? null : _captureDocument,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Fotografar'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_loadError != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_outlined),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_loadError!)),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhum documento anexado.'),
                  ),
                ),
              ..._items.map(
                (item) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      item['original_filename']?.toString() ?? 'Documento',
                    ),
                    subtitle: Text(
                      'Revisão: ${_reviewLabel(item['review_status'])}\n${_dataSummary(item)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Ações do documento',
                      onSelected: (value) async {
                        if (value == 'save') {
                          await _saveCopy(item);
                          return;
                        }
                        if (value == 'capture') {
                          await _captureData(item);
                          return;
                        }
                        await _review(item, value);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'save',
                          child: Text('Salvar cópia'),
                        ),
                        PopupMenuItem(
                          value: 'capture',
                          child: Text('Conferir dados do documento'),
                        ),
                        PopupMenuItem(
                          value: 'reviewed',
                          child: Text('Marcar como revisado'),
                        ),
                        PopupMenuItem(
                          value: 'rejected',
                          child: Text('Marcar para correção'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
  );
}

class _ReviewDocumentDialog extends StatefulWidget {
  const _ReviewDocumentDialog({required this.status});

  final String status;

  @override
  State<_ReviewDocumentDialog> createState() => _ReviewDocumentDialogState();
}

class _DocumentDataDialog extends StatefulWidget {
  const _DocumentDataDialog({required this.initialData});

  final Map<String, dynamic> initialData;

  @override
  State<_DocumentDataDialog> createState() => _DocumentDataDialogState();
}

class _DocumentDataDialogState extends State<_DocumentDataDialog> {
  late final TextEditingController _supplier;
  late final TextEditingController _documentNumber;
  late final TextEditingController _documentDate;
  late final TextEditingController _totalAmount;

  @override
  void initState() {
    super.initState();
    _supplier = TextEditingController(
      text: widget.initialData['supplier']?.toString() ?? '',
    );
    _documentNumber = TextEditingController(
      text: widget.initialData['document_number']?.toString() ?? '',
    );
    _documentDate = TextEditingController(
      text: widget.initialData['document_date']?.toString() ?? '',
    );
    _totalAmount = TextEditingController(
      text: widget.initialData['total_amount']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _supplier.dispose();
    _documentNumber.dispose();
    _documentDate.dispose();
    _totalAmount.dispose();
    super.dispose();
  }

  Map<String, dynamic> _data() {
    final values = <String, String>{
      'supplier': _supplier.text.trim(),
      'document_number': _documentNumber.text.trim(),
      'document_date': _documentDate.text.trim(),
      'total_amount': _totalAmount.text.trim(),
    };
    values.removeWhere((_, value) => value.isEmpty);
    return values;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Conferir dados do documento'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Registre os dados que você conferiu no arquivo. Eles ficam auditáveis junto ao lançamento.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _supplier,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Fornecedor / emissor',
            ),
          ),
          TextField(
            controller: _documentNumber,
            decoration: const InputDecoration(labelText: 'Número do documento'),
          ),
          TextField(
            controller: _documentDate,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(labelText: 'Data do documento'),
          ),
          TextField(
            controller: _totalAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor total'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _data()),
        child: const Text('Salvar conferência'),
      ),
    ],
  );
}

class _ReviewDocumentDialogState extends State<_ReviewDocumentDialog> {
  final _notes = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correction = widget.status == 'rejected';
    return AlertDialog(
      title: Text(correction ? 'Marcar para correção' : 'Concluir revisão'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _notes,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              labelText: correction
                  ? 'Motivo da correção'
                  : 'Observações da revisão',
              hintText: correction
                  ? 'Explique o que precisa ser corrigido.'
                  : 'Opcional',
            ),
          ),
          if (_validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _validationMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final notes = _notes.text.trim();
            if (correction && notes.isEmpty) {
              setState(
                () => _validationMessage =
                    'Informe o motivo para manter a revisão auditável.',
              );
              return;
            }
            Navigator.pop(context, notes);
          },
          child: Text(correction ? 'Registrar correção' : 'Marcar revisado'),
        ),
      ],
    );
  }
}
