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
    final workbook = Excel.decodeBytes(bytes);
    final sheet = _selectSheet(workbook);
    if (sheet == null) {
      throw const FormatException(
        'Nenhuma aba com dados foi encontrada na planilha.',
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

    final header = _findGenericHeader(sheet);
    if (header == null) {
      return const FarmQuoteReturnImportResult(
        warnings: [
          'Não foi possível localizar as colunas de valor na planilha. '
              'Use uma coluna “Valor total” ou “Total”.',
        ],
      );
    }
    for (var row = header.row + 1; row < sheet.maxRows; row++) {
      final supplier = _cellText(sheet, row, header.supplierColumn).trim();
      final amount = _cellAmount(sheet, row, header.amountColumn);
      final dateText = _cellText(sheet, row, header.dateColumn).trim();
      final notes = _cellText(sheet, row, header.notesColumn).trim();
      if (supplier.isEmpty &&
          amount == null &&
          dateText.isEmpty &&
          notes.isEmpty) {
        continue;
      }
      if (amount == null || amount <= 0) {
        warnings.add(
          'Uma linha sem valor válido foi ignorada.',
        );
        continue;
      }
      final effectiveSupplier = supplier.isEmpty
          ? _unknownSupplierName(request, proposals)
          : supplier;
      if (supplier.isEmpty) {
        warnings.add(
          'Fornecedor não informado: a proposta será incorporada como “$effectiveSupplier”.',
        );
      }
      final normalized = _normalizedSupplier(effectiveSupplier);
      if (known.contains(normalized)) {
        warnings.add(
          '$effectiveSupplier já possui uma proposta no Atlas e foi ignorado.',
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
      final receivedAt = _parseDate(dateText, fallbackYear: importedAt.year);
      if (dateText.isNotEmpty && receivedAt == null) {
        warnings.add(
          'A data de $effectiveSupplier foi substituída pela data da importação.',
        );
      }
      proposals.add(
        FarmSupplierProposal(
          supplierName: effectiveSupplier,
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
        ? _unknownSupplierName(request, const [])
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
    final declaredTotal = _findLabeledAmount(sheet, 'TOTAL DA PROPOSTA');
    if (validItems == 0 && (declaredTotal == null || declaredTotal <= 0)) {
      return FarmQuoteReturnImportResult(
        warnings: [...warnings, 'Nenhum item com valor válido foi encontrado.'],
      );
    }

    final freight = _findLabeledAmount(sheet, 'Frete (R\$)');
    final discount = _findLabeledAmount(sheet, 'Desconto (R\$)');
    total = declaredTotal != null && declaredTotal > 0
        ? declaredTotal
        : total + (freight ?? 0) - (discount ?? 0);
    if (total <= 0) {
      return FarmQuoteReturnImportResult(
        warnings: [...warnings, 'O total calculado da proposta não é válido.'],
      );
    }
    final dateText = _findLabeledText(sheet, 'Data da proposta').trim();
    final receivedAt = _parseDate(dateText, fallbackYear: importedAt.year);
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
      if (_cellText(sheet, row, 3).trim().startsWith(label)) {
        return _cellAmount(sheet, row, 4);
      }
    }
    return null;
  }

  String _findLabeledText(Sheet sheet, String label) {
    for (var row = 0; row < sheet.maxRows; row++) {
      for (var column = 0; column < sheet.maxColumns; column++) {
        if (_cellText(sheet, row, column).trim() == label) {
          for (
            var valueColumn = column + 1;
            valueColumn < sheet.maxColumns;
            valueColumn++
          ) {
            final value = _cellText(sheet, row, valueColumn).trim();
            if (value.isEmpty || value.toLowerCase().startsWith('preencher')) {
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

  Sheet? _selectSheet(Excel workbook) {
    final named = workbook.tables['Retornos'];
    if (named != null) return named;
    for (final sheet in workbook.tables.values) {
      if (sheet.maxRows > 0 && sheet.maxColumns > 0) return sheet;
    }
    return null;
  }

  _GenericHeader? _findGenericHeader(Sheet sheet) {
    for (var row = 0; row < sheet.maxRows; row++) {
      int? supplierColumn;
      int? amountColumn;
      int? dateColumn;
      int? notesColumn;
      for (var column = 0; column < sheet.maxColumns; column++) {
        final label = _normalizeHeader(_cellText(sheet, row, column));
        if (label.isEmpty) continue;
        if (label.contains('fornecedor') || label.contains('empresa')) {
          supplierColumn ??= column;
        } else if (label.contains('valor total') || label == 'total' || label == 'valor') {
          amountColumn ??= column;
        } else if (label.contains('data') || label.contains('recebimento')) {
          dateColumn ??= column;
        } else if (label.contains('observa') || label.contains('condi') || label.contains('prazo')) {
          notesColumn ??= column;
        }
      }
      if (amountColumn != null) {
        return _GenericHeader(
          row: row,
          supplierColumn: supplierColumn ?? -1,
          amountColumn: amountColumn,
          dateColumn: dateColumn ?? -1,
          notesColumn: notesColumn ?? -1,
        );
      }
    }
    return null;
  }

  String _normalizeHeader(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàãâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòõôö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .trim();

  String _unknownSupplierName(
    FarmQuoteRequest request,
    Iterable<FarmSupplierProposal> pending,
  ) {
    const base = 'Fornecedor não identificado';
    final names = request.proposals
        .map((proposal) => _normalizedSupplier(proposal.supplierName))
        .followedBy(pending.map((proposal) => _normalizedSupplier(proposal.supplierName)))
        .toSet();
    if (!names.contains(_normalizedSupplier(base))) return base;
    var index = 2;
    while (names.contains(_normalizedSupplier('$base $index'))) {
      index++;
    }
    return '$base $index';
  }

  String _cellText(Sheet sheet, int row, int column) {
    if (column < 0) return '';
    final value = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .value;
    if (value is TextCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    return value?.toString() ?? '';
  }

  double? _cellAmount(Sheet sheet, int row, int column) {
    if (column < 0) return null;
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

  DateTime? _parseDate(String value, {int? fallbackYear}) {
    final normalizedValue = value.trim().toLowerCase();
    final iso = DateTime.tryParse(normalizedValue);
    if (iso != null) return iso;
    final parts = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
    ).firstMatch(normalizedValue);
    if (parts != null) {
      return _validDate(
        int.tryParse(parts.group(3)!),
        int.tryParse(parts.group(2)!),
        int.tryParse(parts.group(1)!),
      );
    }
    final shortMonth = RegExp(
      r'^(\d{1,2})\s*[/ -]\s*([a-zç]+)$',
    ).firstMatch(normalizedValue);
    if (shortMonth == null || fallbackYear == null) return null;
    const months = {
      'jan': 1,
      'janeiro': 1,
      'fev': 2,
      'fevereiro': 2,
      'mar': 3,
      'março': 3,
      'abr': 4,
      'abril': 4,
      'mai': 5,
      'maio': 5,
      'jun': 6,
      'junho': 6,
      'jul': 7,
      'julho': 7,
      'ago': 8,
      'agosto': 8,
      'set': 9,
      'setembro': 9,
      'out': 10,
      'outubro': 10,
      'nov': 11,
      'novembro': 11,
      'dez': 12,
      'dezembro': 12,
    };
    return _validDate(
      fallbackYear,
      months[shortMonth.group(2)!],
      int.tryParse(shortMonth.group(1)!),
    );
  }

  DateTime? _validDate(int? year, int? month, int? day) {
    if (day == null || month == null || year == null) return null;
    final parsed = DateTime(year, month, day);
    return parsed.day == day && parsed.month == month && parsed.year == year
        ? parsed
        : null;
  }

  String _normalizedSupplier(String value) => value.trim().toLowerCase();
}

class _GenericHeader {
  const _GenericHeader({
    required this.row,
    required this.supplierColumn,
    required this.amountColumn,
    required this.dateColumn,
    required this.notesColumn,
  });

  final int row;
  final int supplierColumn;
  final int amountColumn;
  final int dateColumn;
  final int notesColumn;
}

class FarmQuoteReturnImportResult {
  const FarmQuoteReturnImportResult({
    this.proposals = const [],
    this.warnings = const [],
  });

  final List<FarmSupplierProposal> proposals;
  final List<String> warnings;
}
