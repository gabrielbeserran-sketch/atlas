import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/financial_document_remote_service.dart';

class FinancialDocumentCenterScreen extends StatefulWidget {
  const FinancialDocumentCenterScreen({
    required this.entryId,
    required this.title,
    super.key,
  });
  final String entryId;
  final String title;
  @override
  State<FinancialDocumentCenterScreen> createState() =>
      _FinancialDocumentCenterScreenState();
}

class _FinancialDocumentCenterScreenState
    extends State<FinancialDocumentCenterScreen> {
  final _service = FinancialDocumentRemoteService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _uploading = false;
  String? _loadError;
  @override
  void initState() {
    super.initState();
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
    setState(() => _uploading = true);
    try {
      await _service.upload(entryId: widget.entryId, filePath: file.path);
      await _load();
      if (!mounted) return;
      _showMessage('Documento anexado e aguardando revisão humana.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível anexar o documento. Tente novamente.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Documentos financeiros'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _loading ? null : () {
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
                'Os arquivos ficam vinculados ao lançamento. A leitura e a aprovação são sempre humanas.',
              ),
              const SizedBox(height: 16),
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
                        TextButton(onPressed: _load, child: const Text('Tentar novamente')),
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
                    subtitle: Text('Revisão: ${_reviewLabel(item['review_status'])}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Ações do documento',
                      onSelected: (value) async {
                        if (value == 'save') {
                          await _saveCopy(item);
                          return;
                        }
                        await _review(item, value);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'save', child: Text('Salvar cópia')),
                        PopupMenuItem(value: 'reviewed', child: Text('Marcar como revisado')),
                        PopupMenuItem(value: 'rejected', child: Text('Marcar para correção')),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
