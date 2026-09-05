import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_quote_request_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';
import 'package:projeto_atlas/features/farm_finance/presentation/screens/farm_quote_comparison_screen.dart';

class FarmQuoteRequestsScreen extends StatefulWidget {
  const FarmQuoteRequestsScreen({required this.farm, super.key});
  final FarmData farm;

  @override
  State<FarmQuoteRequestsScreen> createState() =>
      _FarmQuoteRequestsScreenState();
}

class _FarmQuoteRequestsScreenState extends State<FarmQuoteRequestsScreen> {
  final FarmQuoteRequestStorageService storage =
      FarmQuoteRequestStorageService();
  List<FarmQuoteRequest> requests = const [];
  bool loading = true;

  String get farmKey => widget.farm.id?.trim().isNotEmpty == true
      ? widget.farm.id!
      : widget.farm.name;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final loaded = await storage.load(farmKey);
    if (mounted) {
      setState(() {
        requests = loaded;
        loading = false;
      });
    }
  }

  Future<void> createRequest() async {
    final result = await showDialog<FarmQuoteRequest>(
      context: context,
      builder: (_) => const _QuoteRequestDialog(),
    );
    if (result == null || !mounted) return;
    final updated = [result, ...requests];
    await storage.save(farmKey, updated);
    if (mounted) setState(() => requests = updated);
  }

  Future<void> openComparison(FarmQuoteRequest request) async {
    final updated = await Navigator.of(context).push<FarmQuoteRequest>(
      MaterialPageRoute<FarmQuoteRequest>(
        builder: (_) => FarmQuoteComparisonScreen(
          farm: widget.farm,
          request: request,
        ),
      ),
    );
    if (updated == null || !mounted) return;

    final next = requests
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false);
    await storage.save(farmKey, next);
    if (mounted) setState(() => requests = next);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Documentos e cotações')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: createRequest,
      icon: const Icon(Icons.add),
      label: const Text('Nova cotação'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.farm.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Crie uma solicitação, registre até quatro propostas e compare os valores recebidos.',
              ),
              const SizedBox(height: 20),
              if (requests.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma cotação em preparação. Toque em “Nova cotação” para registrar a primeira solicitação.',
                    ),
                  ),
                )
              else
                ...requests.map(
                  (request) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.request_quote_outlined),
                      title: Text(request.title),
                      subtitle: Text(
                        '${request.itemsDescription}\n${request.proposals.length} proposta(s) registrada(s) • ${request.suppliers.length} fornecedor(es) previsto(s)',
                      ),
                      isThreeLine: true,
                      trailing: Chip(label: Text(request.displayStatus)),
                      onTap: () => openComparison(request),
                    ),
                  ),
                ),
            ],
          ),
  );
}

class _QuoteRequestDialog extends StatefulWidget {
  const _QuoteRequestDialog();
  @override
  State<_QuoteRequestDialog> createState() => _QuoteRequestDialogState();
}

class _QuoteRequestDialogState extends State<_QuoteRequestDialog> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final items = TextEditingController();
  final suppliers = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    items.dispose();
    suppliers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nova solicitação de cotação'),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o título.'
                  : null,
            ),
            TextFormField(
              controller: items,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Itens e quantidades',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe os itens.'
                  : null,
            ),
            TextFormField(
              controller: suppliers,
              decoration: const InputDecoration(
                labelText: 'Fornecedores (separados por vírgula)',
              ),
              validator: (value) =>
                  (value ?? '')
                          .split(',')
                          .where((item) => item.trim().isNotEmpty)
                          .length >
                      4
                  ? 'Informe no máximo quatro fornecedores.'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            FarmQuoteRequest(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: title.text.trim(),
              itemsDescription: items.text.trim(),
              suppliers: suppliers.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .take(4)
                  .toList(),
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        child: const Text('Salvar'),
      ),
    ],
  );
}
