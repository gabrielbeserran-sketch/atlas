import 'package:excel/excel.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_quote_request.dart';

/// Lê retornos preenchidos no XLSX exportado pelo Atlas, sem gravar nada.
/// A tela sempre mostra os resultados para revisão antes da incorporação.
class FarmQuoteReturnImportService {
  FarmQuoteReturnImportResult import({
    required List<int> bytes,
    required FarmQuoteRequest request,
    required DateTime importedAt,
  }) {
    final sheet = Excel.decodeBytes(bytes).tables['Retornos'];
    if (sheet == null) {
      throw const FormatException(
        'A aba “Retornos” não foi encontrada na planilha.',
      );
    }
    if (_cellText(sheet, 0, 0).contains('PROPOSTA COMERCIAL')) {
      return _importStructuredProposal(
        sheet: sheet,
        request: request,
        importedAt: importedAt,
      );
    }
    final warnings = <String>[];
    final proposals = <FarmSupplierProposal>[];
    final known = request.proposals
        .map((item) => _normalizedSupplier(item.supplierName))
        .toSet();
    final remaining = 4 - request.proposals.length;
    if (remaining <= 0) {
      return const FarmQuoteReturnImportResult(
        warnings: ['Esta cotação já possui o limite de quatro propostas.'],
      );
    }

    // Linha 0 é o título e linha 1 é o cabeçalho da planilha exportada.
    for (var row = 2; row < sheet.maxRows; row++) {
      final supplier = _cellText(sheet, row, 0).trim();
      final amount = _cellAmount(sheet, row, 1);
      final dateText = _cellText(sheet, row, 2).trim();
      final notes = _cellText(sheet, row, 3).trim();
      if (supplier.isEmpty &&
          amount == null &&
          dateText.isEmpty &&
          notes.isEmpty) {
        continue;
      }
      if (supplier.isEmpty) {
        warnings.add('Uma linha sem fornecedor foi ignorada.');
        continue;
      }
      if (amount == null || amount <= 0) {
        warnings.add(
          'O retorno de $supplier não possui valor válido e foi ignorado.',
        );
        continue;
      }
      final normalized = _normalizedSupplier(supplier);
      if (known.contains(normalized)) {
        warnings.add(
          '$supplier já possui uma proposta no Atlas e foi ignorado.',
        );
        continue;
      }
      if (proposals.length >= remaining) {
        warnings.add(
          'O limite de quatro propostas foi atingido; retornos adicionais foram ignorados.',
        );
        break;
      }
      known.add(normalized);
      final receivedAt = _parseDate(dateText);
      if (dateText.isNotEmpty && receivedAt == null) {
        warnings.add(
          'A data de $supplier foi substituída pela data da importação.',
        );
      }
      proposals.add(
        FarmSupplierProposal(
          supplierName: supplier,
          totalAmount: amount,
          receivedAt: (receivedAt ?? importedAt).toIso8601String(),
          notes: notes,
        ),
      );
    }
    return FarmQuoteReturnImportResult(
      proposals: proposals,
      warnings: warnings,
    );
  }

  FarmQuoteReturnImportResult _importStructuredProposal({
    required Sheet sheet,
    required FarmQuoteRequest request,
    required DateTime importedAt,
  }) {
    final warnings = <String>[];
    if (request.proposals.length >= 4) {
      return const FarmQuoteReturnImportResult(
        warnings: ['Esta cotação já possui o limite de quatro propostas.'],
      );
    }

    final suppliedName = _findLabeledText(sheet, 'Fornecedor').trim();
    final supplier =
        suppliedName.isEmpty || suppliedName == 'Preencher pelo fornecedor'
        ? _unknownSupplierName(request)
        : suppliedName;
    if (supplier != suppliedName) {
      warnings.add(
        'Fornecedor não informado: a proposta será incorporada como “$supplier”.',
      );
    }
    final normalized = _normalizedSupplier(supplier);
    if (request.proposals
        .map((proposal) => _normalizedSupplier(proposal.supplierName))
        .contains(normalized)) {
      return FarmQuoteReturnImportResult(
        warnings: ['$supplier já possui uma proposta no Atlas e foi ignorado.'],
      );
    }

    final headerRow = _findStructuredItemsHeader(sheet);
    if (headerRow == null) {
      throw const FormatException(
        'A tabela de itens da proposta não foi encontrada na planilha.',
      );
    }
    var total = 0.0;
    var validItems = 0;
    for (var row = headerRow + 1; row < sheet.maxRows; row++) {
      final item = _cellText(sheet, row, 0).trim();
      if (item.isEmpty) break;
      final quantity = _cellAmount(sheet, row, 2);
      final unitAmount = _cellAmount(sheet, row, 3);
      final lineAmount = _cellAmount(sheet, row, 4);
      final computed = quantity != null && unitAmount != null
          ? quantity * unitAmount
          : lineAmount;
      if (computed == null || computed <= 0) {
        warnings.add('O item $item não possui valor válido e foi ignorado.');
        continue;
      }
      total += computed;
      validItems++;
    }
    if (validItems == 0) {
      return FarmQuoteReturnImportResult(
        warnings: [...warnings, 'Nenhum item com valor válido foi encontrado.'],
      );
    }

    final freight = _findLabeledAmount(sheet, 'Frete (R\$)');
    final discount = _findLabeledAmount(sheet, 'Desconto (R\$)');
    total += freight ?? 0;
    total -= discount ?? 0;
    if (total <= 0) {
      return FarmQuoteReturnImportResult(
        warnings: [...warnings, 'O total calculado da proposta não é válido.'],
      );
    }
    final dateText = _findLabeledText(sheet, 'Data da proposta').trim();
    final receivedAt = _parseDate(dateText);
    if (dateText.isNotEmpty && receivedAt == null) {
      warnings.add(
        'A data de $supplier foi substituída pela data da importação.',
      );
    }
    return FarmQuoteReturnImportResult(
      proposals: [
        FarmSupplierProposal(
          supplierName: supplier,
          totalAmount: total,
          receivedAt: (receivedAt ?? importedAt).toIso8601String(),
          notes: _findLabeledText(sheet, 'Prazo / condições').trim(),
        ),
      ],
      warnings: warnings,
    );
  }

  int? _findStructuredItemsHeader(Sheet sheet) {
    for (var row = 0; row < sheet.maxRows; row++) {
      final first = _cellText(sheet, row, 0).trim();
      final price = _cellText(sheet, row, 3).trim();
      if (first == 'Item' && price.startsWith('Valor unitário')) return row;
    }
    return null;
  }

  double? _findLabeledAmount(Sheet sheet, String label) {
    for (var row = 0; row < sheet.maxRows; row++) {
      if (_cellText(sheet, row, 3).trim() == label) {
        return _cellAmount(sheet, row, 4);
      }
    }
    return null;
  }

  String _findLabeledText(Sheet sheet, String label) {
    for (var row = 0; row < sheet.maxRows; row++) {
      for (var column = 0; column < sheet.maxColumns; column++) {
        if (_cellText(sheet, row, column).trim() == label) {
          for (var valueColumn = column + 1;
              valueColumn < sheet.maxColumns;
              valueColumn++) {
            final value = _cellText(sheet, row, valueColumn).trim();
            if (value.isEmpty ||
                value.toLowerCase().startsWith('preencher')) {
              continue;
            }
            return value;
          }
          return '';
        }
      }
    }
    return '';
  }

  String _unknownSupplierName(FarmQuoteRequest request) {
    const base = 'Fornecedor não identificado';
    final names = request.proposals
        .map((proposal) => _normalizedSupplier(proposal.supplierName))
        .toSet();
    if (!names.contains(_normalizedSupplier(base))) return base;
    var index = 2;
    while (names.contains(_normalizedSupplier('$base $index'))) {
      index++;
    }
    return '$base $index';
  }

  String _cellText(Sheet sheet, int row, int column) {
    final value = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .value;
    if (value is TextCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    return value?.toString() ?? '';
  }

  double? _cellAmount(Sheet sheet, int row, int column) {
    final value = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .value;
    if (value is IntCellValue) return value.value.toDouble();
    if (value is DoubleCellValue) return value.value;
    final text = _cellText(
      sheet,
      row,
      column,
    ).replaceAll('R\$', '').replaceAll(' ', '').trim();
    if (text.isEmpty) return null;
    return double.tryParse(
      text.contains(',') ? text.replaceAll('.', '').replaceAll(',', '.') : text,
    );
  }

  DateTime? _parseDate(String value) {
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final parts = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
    if (parts == null) return null;
    final day = int.tryParse(parts.group(1)!);
    final month = int.tryParse(parts.group(2)!);
    final year = int.tryParse(parts.group(3)!);
    if (day == null || month == null || year == null) return null;
    final parsed = DateTime(year, month, day);
    return parsed.day == day && parsed.month == month && parsed.year == year
        ? parsed
        : null;
  }

  String _normalizedSupplier(String value) => value.trim().toLowerCase();
}

class FarmQuoteReturnImportResult {
  const FarmQuoteReturnImportResult({
    this.proposals = const [],
    this.warnings = const [],
  });

  final List<FarmSupplierProposal> proposals;
  final List<String> warnings;
}
