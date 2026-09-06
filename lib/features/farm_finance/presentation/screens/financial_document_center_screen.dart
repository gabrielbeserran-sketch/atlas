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
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _items = await _service.list(widget.entryId);
    } catch (_) {}
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
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Documentos financeiros')),
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
                'Os arquivos ficam vinculados ao lançamento e exigem revisão humana.',
              ),
              const SizedBox(height: 16),
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
                      'Revisão: ${item['review_status'] ?? 'pending'}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
  );
}
