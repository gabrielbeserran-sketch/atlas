import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AtlasReportGenerator {
  const AtlasReportGenerator();

  Future<Uint8List> executivePdf(Map<String, dynamic> report) async {
    final document = pw.Document();

    final company = Map<String, dynamic>.from(report['company'] as Map);
    final indicators = (report['indicators'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final alerts = (report['alerts'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            'Projeto Atlas — Relatório Executivo',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Empresa: ${company['name'] ?? ''}'),
          pw.Text('Fazenda: ${report['farm_id'] ?? ''}'),
          pw.Text('Gerado em: ${report['generated_at'] ?? ''}'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Indicadores',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Indicador', 'Valor', 'Unidade', 'Fórmula'],
            data: indicators
                .map(
                  (item) => [
                    item['name']?.toString() ?? '',
                    item['value']?.toString() ?? '',
                    item['unit']?.toString() ?? '',
                    item['formula']?.toString() ?? '',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Alertas',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (alerts.isEmpty)
            pw.Text('Nenhum alerta aberto.')
          else
            ...alerts.map(
              (item) => pw.Bullet(
                text:
                    '${item['severity']}: ${item['title']} — ${item['description']}',
              ),
            ),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Text(
            'Relatório gerado pelo Projeto Atlas.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return document.save();
  }
}
