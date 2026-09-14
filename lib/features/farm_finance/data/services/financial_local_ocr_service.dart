import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    hide InputImage;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extrai texto da nota no próprio aparelho.
///
/// O serviço nunca envia a imagem ou o texto para a rede. A interpretação é
/// deliberadamente conservadora: dados incompletos viram avisos para revisão,
/// jamais um lançamento automático.
class FinancialLocalOcrService {
  const FinancialLocalOcrService();

  bool get isAvailable => Platform.isAndroid || Platform.isIOS;

  Future<Map<String, dynamic>> readSuggestion(String filePath) async {
    if (!isAvailable) return const {};

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final scanner = BarcodeScanner(
      formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128],
    );
    try {
      final image = InputImage.fromFilePath(filePath);
      final results = await Future.wait([
        recognizer.processImage(image),
        scanner.processImage(image),
      ]);
      final suggestion = parseRecognizedText(
        (results[0] as RecognizedText).text,
      );
      final accessKey = accessKeyFromBarcode(
        (results[1] as List<Barcode>)
            .map((barcode) => barcode.rawValue ?? '')
            .join('\n'),
      );
      if (accessKey.isEmpty) return suggestion;
      return {
        ...suggestion,
        'document_number': accessKey,
        'document_access_key': accessKey,
        'confidence': 100,
        'warnings': (suggestion['warnings'] as List)
            .where(
              (warning) => warning != 'Número do documento não identificado.',
            )
            .toList(),
      };
    } finally {
      await recognizer.close();
      await scanner.close();
    }
  }

  /// Converte texto reconhecido em sugestões conservadoras para revisão.
  /// Público para permitir testes sem câmera, plugin nativo ou rede.
  Map<String, dynamic> parseRecognizedText(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const {};

    final supplier = _supplier(lines);
    final date = _firstMatch(rawText, RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{4})\b'));
    final documentNumber = _documentNumber(rawText);
    final total = _total(lines);
    final category = _category(rawText);
    final warnings = <String>[];
    if (supplier.isEmpty) {
      warnings.add('Fornecedor não identificado.');
    }
    if (date.isEmpty) {
      warnings.add('Data da nota não identificada.');
    }
    if (documentNumber.isEmpty) {
      warnings.add('Número do documento não identificado.');
    }
    if (total.isEmpty) {
      warnings.add('Valor total não identificado.');
    }

    final recognized = [
      supplier,
      date,
      documentNumber,
      total,
    ].where((value) => value.isNotEmpty).length;
    return {
      'supplier': supplier,
      'document_number': documentNumber,
      'document_date': date,
      'total_amount': total,
      'type': 'Despesa',
      'category': category,
      'confidence': (recognized * 25).clamp(0, 100),
      'warnings': warnings,
      'source': 'on_device',
    };
  }

  /// Localiza a chave de acesso de 44 dígitos presente no QR Code da NF-e.
  String accessKeyFromBarcode(String value) {
    final queryKey = RegExp(
      r'(?:chNFe|chaveNFe)=([0-9]{44})',
      caseSensitive: false,
    ).firstMatch(value)?.group(1);
    return queryKey ?? RegExp(r'\b\d{44}\b').firstMatch(value)?.group(0) ?? '';
  }

  String _supplier(List<String> lines) {
    const ignored = [
      'nota fiscal',
      'documento auxiliar',
      'danfe',
      'nfe',
      'nf-e',
      'cnpj',
      'cpf',
      'endereço',
      'total',
    ];
    for (final line in lines.take(12)) {
      final normalized = line.toLowerCase();
      if (line.length >= 3 &&
          line.length <= 100 &&
          !ignored.any(normalized.contains) &&
          RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(line)) {
        return line;
      }
    }
    return '';
  }

  String _documentNumber(String text) {
    final match = RegExp(
      r'\b(?:n(?:ota)?\s*fiscal|nf-?e|n[úu]mero)\b\s*(?:n[º°.]?\s*)?[:#-]?\s*([A-Za-z0-9.-]{3,})',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  String _total(List<String> lines) {
    final totalLine = lines.lastWhere(
      (line) => RegExp(
        r'total\s*(?:a\s*)?(?:pagar|da nota|geral)?',
        caseSensitive: false,
      ).hasMatch(line),
      orElse: () => '',
    );
    final value = _money(totalLine);
    if (value.isNotEmpty) return value;
    for (final line in lines.reversed.take(12)) {
      final candidate = _money(line);
      if (candidate.isNotEmpty) return candidate;
    }
    return '';
  }

  String _money(String text) {
    final matches = RegExp(
      r'(?:R\$\s*)?(\d{1,3}(?:\.\d{3})*,\d{2}|\d+[.,]\d{2})',
      caseSensitive: false,
    ).allMatches(text).toList();
    return matches.isEmpty ? '' : matches.last.group(1)!.trim();
  }

  String _category(String text) {
    final normalized = text.toLowerCase();
    if (RegExp(
      r'ra[cç][aã]o|sal mineral|milho|farelo|suplemento',
    ).hasMatch(normalized)) {
      return 'Alimentação';
    }
    if (RegExp(r'vacina|medicamento|veterin').hasMatch(normalized)) {
      return 'Sanidade';
    }
    if (RegExp(r'combust[ií]vel|diesel|gasolina').hasMatch(normalized)) {
      return 'Combustível';
    }
    return 'Outras despesas';
  }

  String _firstMatch(String text, RegExp pattern) =>
      pattern.firstMatch(text)?.group(1)?.trim() ?? '';
}
