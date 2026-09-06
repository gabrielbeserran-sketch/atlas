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
          notes.isEmpty)
        continue;
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
