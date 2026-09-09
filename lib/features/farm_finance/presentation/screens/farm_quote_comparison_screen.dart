import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';
import 'package:projeto_atlas/features/farm_finance/domain/services/farm_quote_comparison_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/services/farm_quote_request_excel_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/services/farm_quote_return_import_service.dart';

class FarmQuoteComparisonScreen extends StatefulWidget {
  const FarmQuoteComparisonScreen({
    required this.farm,
    required this.request,
    super.key,
  });

  final FarmData farm;
  final FarmQuoteRequest request;

  @override
  State<FarmQuoteComparisonScreen> createState() =>
      _FarmQuoteComparisonScreenState();
}

class _FarmQuoteComparisonScreenState extends State<FarmQuoteComparisonScreen> {
  static const _comparison = FarmQuoteComparisonService();
  static final _excel = FarmQuoteRequestExcelService();
  static final _returnImporter = FarmQuoteReturnImportService();
  late FarmQuoteRequest request = widget.request;
  bool exporting = false;
  bool importing = false;

  List<FarmSupplierProposal> get ranked => _comparison.rank(request.proposals);

  Future<void> addProposal() async {
    final proposal = await showDialog<FarmSupplierProposal>(
      context: context,
      builder: (_) => _SupplierProposalDialog(
        existingSuppliers: request.proposals
            .map((item) => item.supplierName)
            .toList(growable: false),
      ),
    );
    if (proposal == null || !mounted) return;

    final updated = request.copyWith(
      proposals: [...request.proposals, proposal],
    );
    setState(() => request = updated);
  }

  void closeWithUpdatedRequest() {
    Navigator.of(context).pop(request);
  }

  Future<void> exportSpreadsheet() async {
    if (exporting) return;
    final suggestedName = _excel.suggestedFileName(request);
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Planilha Excel',
          extensions: ['xlsx'],
        ),
      ],
    );
    if (location == null || !mounted) return;

    setState(() => exporting = true);
    try {
      final bytes = _excel.build(farm: widget.farm, request: request);
      await XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        name: suggestedName,
      ).saveTo(location.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planilha de cotação exportada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a planilha. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> importSpreadsheet() async {
    if (importing || request.proposals.length >= 4) return;
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Planilha Excel', extensions: ['xlsx']),
      ],
    );
    if (file == null || !mounted) return;

    setState(() => importing = true);
    try {
      final result = _returnImporter.import(
        bytes: await file.readAsBytes(),
        request: request,
        importedAt: DateTime.now(),
      );
      if (!mounted) return;
      final approved = await showDialog<List<FarmSupplierProposal>>(
        context: context,
        builder: (_) => _ImportedProposalsReviewDialog(result: result),
      );
      if (approved == null || approved.isEmpty || !mounted) return;
      setState(() {
        request = request.copyWith(
          proposals: [...request.proposals, ...approved],
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${approved.length} proposta(s) incorporada(s) à comparação.'),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível ler a planilha. Use o XLSX exportado pelo Atlas.'),
        ),
      );
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final best = _comparison.bestProposal(request.proposals);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return PopScope<FarmQuoteRequest>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          closeWithUpdatedRequest();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comparar cotações'),
          actions: [
            IconButton(
              onPressed: importing || exporting || request.proposals.length >= 4
                  ? null
                  : importSpreadsheet,
              icon: importing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              tooltip: 'Importar retorno XLSX',
            ),
            IconButton(
              onPressed: exporting || importing ? null : exportSpreadsheet,
              icon: exporting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.table_view_outlined),
              tooltip: 'Exportar planilha XLSX',
            ),
          ],
        ),
        floatingActionButton: request.proposals.length >= 4
            ? null
            : FloatingActionButton.extended(
                onPressed: addProposal,
                icon: const Icon(Icons.add),
                label: const Text('Registrar proposta'),
              ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              request.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(request.itemsDescription),
            const SizedBox(height: 14),
            Text(
              '${request.proposals.length} de 4 propostas registradas',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (best != null) ...[
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFFE8F5E9),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Melhor oferta atual'),
                  subtitle: Text(best.supplierName),
                  trailing: Text(
                    currency.format(best.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (ranked.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Registre os retornos recebidos para comparar valores. A leitura automática de documentos será adicionada em uma próxima etapa.',
                  ),
                ),
              )
            else
              ...ranked.asMap().entries.map((entry) {
                final proposal = entry.value;
                final difference = _comparison.differenceFromBest(
                  proposal: proposal,
                  proposals: request.proposals,
                );
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${entry.key + 1}º')),
                    title: Text(proposal.supplierName),
                    subtitle: Text(
                      difference == 0
                          ? 'Menor valor informado'
                          : '${currency.format(difference)} acima da melhor oferta',
                    ),
                    trailing: Text(
                      currency.format(proposal.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }
}

class _ImportedProposalsReviewDialog extends StatelessWidget {
  const _ImportedProposalsReviewDialog({required this.result});

  final FarmQuoteReturnImportResult result;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return AlertDialog(
      title: const Text('Revisar retorno importado'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.proposals.isEmpty)
                const Text(
                  'Nenhuma proposta válida foi encontrada para incorporar.',
                )
              else ...[
                const Text(
                  'Confira os valores abaixo. Eles só serão incorporados quando você confirmar.',
                ),
                const SizedBox(height: 12),
                ...result.proposals.map(
                  (proposal) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.request_quote_outlined),
                    title: Text(proposal.supplierName),
                    subtitle: proposal.notes.isEmpty ? null : Text(proposal.notes),
                    trailing: Text(
                      currency.format(proposal.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Avisos', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ...result.warnings.map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $warning'),
                  ),
                ),
              ],
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
          onPressed: result.proposals.isEmpty
              ? null
              : () => Navigator.pop(context, result.proposals),
          child: const Text('Incorporar propostas'),
        ),
      ],
    );
  }
}

class _SupplierProposalDialog extends StatefulWidget {
  const _SupplierProposalDialog({required this.existingSuppliers});

  final List<String> existingSuppliers;

  @override
  State<_SupplierProposalDialog> createState() =>
      _SupplierProposalDialogState();
}

class _SupplierProposalDialogState extends State<_SupplierProposalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supplier = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _supplier.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) {
    final trimmed = value.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.contains(',')
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : trimmed;
    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar proposta'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _supplier,
              decoration: const InputDecoration(labelText: 'Fornecedor'),
              validator: (value) {
                final normalized = value?.trim().toLowerCase() ?? '';
                if (normalized.isEmpty) return 'Informe o fornecedor.';
                if (widget.existingSuppliers
                    .map((item) => item.trim().toLowerCase())
                    .contains(normalized)) {
                  return 'Esse fornecedor já possui uma proposta.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Valor total (R\$)'),
              validator: (value) {
                final amount = _parseAmount(value ?? '');
                return amount == null || amount <= 0
                    ? 'Informe um valor maior que zero.'
                    : null;
              },
            ),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
              ),
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
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            FarmSupplierProposal(
              supplierName: _supplier.text.trim(),
              totalAmount: _parseAmount(_amount.text)!,
              notes: _notes.text.trim(),
              receivedAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        child: const Text('Salvar proposta'),
      ),
    ],
  );
}
