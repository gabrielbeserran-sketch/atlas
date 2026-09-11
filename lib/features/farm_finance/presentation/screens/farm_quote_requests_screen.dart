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
        builder: (_) =>
            FarmQuoteComparisonScreen(farm: widget.farm, request: request),
      ),
    );
    if (updated == null || !mounted) return;

    final next = requests
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false);
    await storage.save(farmKey, next);
    if (mounted) setState(() => requests = next);
  }

  Future<void> deleteRequest(FarmQuoteRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Excluir cotação?'),
        content: Text(
          'A solicitação “${request.title}”, suas propostas e comparações serão removidas deste dispositivo. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await storage.delete(farmKey, request.id);
    if (!mounted) return;
    setState(
      () => requests = requests
          .where((item) => item.id != request.id)
          .toList(growable: false),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cotação excluída deste dispositivo.')),
    );
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
                        '${request.normalizedItems.length} item(ns) solicitado(s) • ${request.proposals.length} proposta(s) registrada(s)${request.deadline?.isNotEmpty == true ? '\nRetorno até ${_displayDate(request.deadline!)}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(label: Text(request.displayStatus)),
                          PopupMenuButton<String>(
                            tooltip: 'Opções da cotação',
                            onSelected: (action) {
                              if (action == 'delete') deleteRequest(request);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Excluir cotação'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => openComparison(request),
                    ),
                  ),
                ),
            ],
          ),
  );

  String _displayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _QuoteRequestDialog extends StatefulWidget {
  const _QuoteRequestDialog();
  @override
  State<_QuoteRequestDialog> createState() => _QuoteRequestDialogState();
}

class _QuoteRequestDialogState extends State<_QuoteRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _delivery = TextEditingController();
  final _payment = TextEditingController();
  final List<_QuoteItemDraft> _items = [_QuoteItemDraft()];
  DateTime? _deadline;

  @override
  void dispose() {
    _title.dispose();
    _delivery.dispose();
    _payment.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date != null && mounted) setState(() => _deadline = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final items = _items
        .map(
          (draft) => FarmQuoteItem(
            description: draft.description.text.trim(),
            unit: draft.unit.text.trim().isEmpty
                ? 'un.'
                : draft.unit.text.trim(),
            quantity: double.parse(
              draft.quantity.text.trim().replaceAll(',', '.'),
            ),
          ),
        )
        .toList(growable: false);
    Navigator.pop(
      context,
      FarmQuoteRequest(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        itemsDescription: items
            .map(
              (item) => '${item.description} — ${item.quantity} ${item.unit}',
            )
            .join('\n'),
        suppliers: const [],
        items: items,
        deliveryInstructions: _delivery.text.trim(),
        paymentTerms: _payment.text.trim(),
        deadline: _deadline?.toIso8601String(),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  String _dateLabel() {
    if (_deadline == null) return 'Definir prazo de retorno';
    return 'Retorno até ${_deadline!.day.toString().padLeft(2, '0')}/${_deadline!.month.toString().padLeft(2, '0')}/${_deadline!.year}';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Row(
      children: [
        Icon(Icons.request_quote_outlined),
        SizedBox(width: 10),
        Expanded(child: Text('Nova solicitação de cotação')),
      ],
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estruture os itens. A planilha enviada ao fornecedor será neutra e calculará o total automaticamente.',
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título da solicitação',
                  hintText: 'Ex.: Compra de suplemento mineral',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o título.'
                    : null,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Itens solicitados',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _items.add(_QuoteItemDraft())),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar item'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ..._items.asMap().entries.map(
                (entry) => _itemEditor(entry.key, entry.value),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDeadline,
                icon: const Icon(Icons.event_outlined),
                label: Text(_dateLabel()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _delivery,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Entrega / local (opcional)',
                  hintText: 'Ex.: Entrega na Fazenda Atlas, até 10 dias',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _payment,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Condição de pagamento (opcional)',
                  hintText: 'Ex.: 30 dias após entrega',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Criar solicitação'),
      ),
    ],
  );

  Widget _itemEditor(int index, _QuoteItemDraft item) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_items.length > 1)
                IconButton(
                  tooltip: 'Remover item',
                  onPressed: () => setState(() {
                    final removed = _items.removeAt(index);
                    removed.dispose();
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          TextFormField(
            controller: item.description,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Descrição do item'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o item.'
                : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.unit,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: item.quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    return parsed == null || parsed <= 0
                        ? 'Quantidade inválida.'
                        : null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _QuoteItemDraft {
  _QuoteItemDraft()
    : description = TextEditingController(),
      unit = TextEditingController(text: 'un.'),
      quantity = TextEditingController(text: '1');

  final TextEditingController description;
  final TextEditingController unit;
  final TextEditingController quantity;

  void dispose() {
    description.dispose();
    unit.dispose();
    quantity.dispose();
  }
}
