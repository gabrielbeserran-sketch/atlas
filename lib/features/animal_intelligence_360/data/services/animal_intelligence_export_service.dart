import 'dart:convert';
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AnimalIntelligenceExportService {
  const AnimalIntelligenceExportService();

  Directory _outputDirectory() {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    final downloads = Directory('$home${Platform.pathSeparator}Downloads');
    if (!downloads.existsSync()) {
      downloads.createSync(recursive: true);
    }
    return downloads;
  }

  String _safeName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.isEmpty ? 'animal' : normalized;
  }

  String _stamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  Future<File> savePdf({
    required String animalName,
    required Map<String, dynamic> snapshot,
    required List<String> recommendations,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'Projeto Atlas — Relatório Executivo do Animal',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Animal: $animalName'),
          pw.Text('Gerado em: ${DateTime.now().toLocal()}'),
          pw.SizedBox(height: 18),
          pw.Text(
            'Indicadores consolidados',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...snapshot.entries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text('${entry.key}: ${entry.value}'),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Recomendações',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...recommendations.map(
            (item) => pw.Bullet(text: item),
          ),
        ],
      ),
    );

    final file = File(
      '${_outputDirectory().path}${Platform.pathSeparator}'
      'atlas_${_safeName(animalName)}_${_stamp()}.pdf',
    );
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<File> saveCsv({
    required String animalName,
    required Map<String, dynamic> snapshot,
  }) async {
    final buffer = StringBuffer('indicador;valor\n');
    for (final entry in snapshot.entries) {
      final key = entry.key.toString().replaceAll(';', ',');
      final value = entry.value.toString().replaceAll(';', ',');
      buffer.writeln('$key;$value');
    }

    final file = File(
      '${_outputDirectory().path}${Platform.pathSeparator}'
      'atlas_${_safeName(animalName)}_${_stamp()}.csv',
    );
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  Future<File> saveBackup({
    required String animalName,
    required Map<String, dynamic> backup,
  }) async {
    final file = File(
      '${_outputDirectory().path}${Platform.pathSeparator}'
      'atlas_backup_${_safeName(animalName)}_${_stamp()}.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
      flush: true,
    );
    return file;
  }
}
