import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/executive_opinion_service.dart';

class ExecutiveOpinionPdfService {
  static const PdfColor forestGreen = PdfColor.fromInt(0xFF1B5E20);

  static const PdfColor darkGreen = PdfColor.fromInt(0xFF124317);

  static const PdfColor blue = PdfColor.fromInt(0xFF1565C0);

  static const PdfColor orange = PdfColor.fromInt(0xFFEF6C00);

  static const PdfColor red = PdfColor.fromInt(0xFFC62828);

  static const PdfColor purple = PdfColor.fromInt(0xFF6A1B9A);

  static const PdfColor teal = PdfColor.fromInt(0xFF00838F);

  static const PdfColor gray = PdfColor.fromInt(0xFF607D8B);

  static const PdfColor darkText = PdfColor.fromInt(0xFF263238);

  static const PdfColor lightGray = PdfColor.fromInt(0xFFF2F4F5);

  static const PdfColor borderGray = PdfColor.fromInt(0xFFDADFE2);

  Future<void> printOpinion({required ExecutiveOpinionData opinion}) async {
    await Printing.layoutPdf(
      name: buildExecutiveOpinionFileName(opinion),
      onLayout: (format) {
        return buildPdf(opinion: opinion, format: format);
      },
    );
  }

  Future<Uint8List> buildPdf({
    required ExecutiveOpinionData opinion,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final document = pw.Document(
      title: 'Parecer Executivo Inteligente',
      author: 'Projeto Atlas',
      creator: 'Projeto Atlas',
      subject: 'Parecer executivo da operação',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.fromLTRB(34, 34, 34, 34),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }

          return _buildHeader(opinion: opinion);
        },
        footer: (context) {
          return _buildFooter(context: context);
        },
        build: (context) {
          return [
            _buildCover(opinion: opinion),
            pw.SizedBox(height: 20),
            _buildDiagnosisSection(opinion: opinion),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              title: 'Pontos fortes',
              subtitle: 'Aspectos positivos identificados na operação.',
            ),
            pw.SizedBox(height: 10),
            _buildOpinionItems(
              items: opinion.strengths,
              color: forestGreen,
              emptyMessage: 'Nenhum ponto forte específico foi identificado.',
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              title: 'Gargalos',
              subtitle: 'Pontos que limitam a execução do plano.',
            ),
            pw.SizedBox(height: 10),
            _buildOpinionItems(
              items: opinion.bottlenecks,
              color: orange,
              emptyMessage: 'Nenhum gargalo relevante foi identificado.',
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              title: 'Riscos',
              subtitle: 'Situações que podem comprometer o desempenho.',
            ),
            pw.SizedBox(height: 10),
            _buildOpinionItems(
              items: opinion.risks,
              color: red,
              emptyMessage: 'Nenhum risco relevante foi identificado.',
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              title: 'Oportunidades',
              subtitle: 'Possibilidades de melhoria e evolução.',
            ),
            pw.SizedBox(height: 10),
            _buildOpinionItems(
              items: opinion.opportunities,
              color: teal,
              emptyMessage: 'Nenhuma oportunidade específica foi identificada.',
            ),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              title: 'Plano de prioridades',
              subtitle: 'Sequência recomendada para atuação.',
            ),
            pw.SizedBox(height: 10),
            _buildPriorities(priorities: opinion.priorities),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              title: 'Recomendações',
              subtitle: 'Ações gerenciais sugeridas pelo Atlas.',
            ),
            pw.SizedBox(height: 10),
            _buildRecommendations(recommendations: opinion.recommendations),
            pw.SizedBox(height: 20),
            _buildExecutiveSummary(opinion: opinion),
            pw.SizedBox(height: 18),
            _buildMethodologyNote(opinion: opinion),
          ];
        },
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader({required ExecutiveOpinionData opinion}) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: borderGray, width: 0.7)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 28,
            height: 28,
            decoration: pw.BoxDecoration(
              color: forestGreen,
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Center(
              child: pw.Text(
                'A',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 9),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PROJETO ATLAS',
                  style: pw.TextStyle(
                    color: forestGreen,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Parecer Executivo Inteligente',
                  style: pw.TextStyle(color: gray, fontSize: 7),
                ),
              ],
            ),
          ),
          pw.Text(
            opinion.scopeLabel,
            style: pw.TextStyle(color: gray, fontSize: 7),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter({required pw.Context context}) {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderGray, width: 0.7)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Projeto Atlas · Parecer executivo',
              style: pw.TextStyle(color: gray, fontSize: 7),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de '
            '${context.pagesCount}',
            style: pw.TextStyle(color: gray, fontSize: 7),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCover({required ExecutiveOpinionData opinion}) {
    final color = _classificationColor(opinion.classification);

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: darkText,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PROJETO ATLAS',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Parecer Executivo Inteligente',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          pw.Text(
            opinion.scopeLabel,
            style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildCoverChip(
                      label: 'Classificação',
                      value: executiveClassificationLabel(
                        opinion.classification,
                      ),
                      color: color,
                    ),
                    _buildCoverChip(
                      label: 'Índice geral',
                      value:
                          '${opinion.performanceIndex.toStringAsFixed(0)}/100',
                      color: color,
                    ),
                    _buildCoverChip(
                      label: 'Confiança',
                      value: formatOpinionPercentage(opinion.confidence),
                      color: blue,
                    ),
                    _buildCoverChip(
                      label: 'Emissão',
                      value: opinion.generatedAt,
                      color: forestGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCoverChip({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: color.shade(0.18),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color.shade(0.55), width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(color: PdfColors.white, fontSize: 6),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDiagnosisSection({required ExecutiveOpinionData opinion}) {
    final color = _classificationColor(opinion.classification);

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.08),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: color.shade(0.25), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Diagnóstico geral',
                  style: pw.TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                executiveClassificationLabel(
                  opinion.classification,
                ).toUpperCase(),
                style: pw.TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            opinion.diagnosis,
            style: pw.TextStyle(color: darkText, fontSize: 9, lineSpacing: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(subtitle, style: pw.TextStyle(color: gray, fontSize: 8)),
      ],
    );
  }

  pw.Widget _buildOpinionItems({
    required List<ExecutiveOpinionItem> items,
    required PdfColor color,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: lightGray,
          borderRadius: pw.BorderRadius.circular(9),
        ),
        child: pw.Text(
          emptyMessage,
          style: pw.TextStyle(color: gray, fontSize: 8),
        ),
      );
    }

    return pw.Column(
      children: items.map((item) {
        final itemColor = _impactColor(item.impact);

        return pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 9),
          child: pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: itemColor.shade(0.06),
              borderRadius: pw.BorderRadius.circular(9),
              border: pw.Border.all(color: itemColor.shade(0.18), width: 0.7),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  margin: pw.EdgeInsets.only(top: 2),
                  decoration: pw.BoxDecoration(
                    color: itemColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 9),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              item.title,
                              style: pw.TextStyle(
                                color: darkText,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            item.category,
                            style: pw.TextStyle(
                              color: itemColor,
                              fontSize: 6.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        item.description,
                        style: pw.TextStyle(
                          color: gray,
                          fontSize: 7.5,
                          lineSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildPriorities({
    required List<ExecutiveOpinionPriorityItem> priorities,
  }) {
    return pw.Column(
      children: priorities.map((item) {
        return pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 10),
          child: pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: orange.shade(0.06),
              borderRadius: pw.BorderRadius.circular(9),
              border: pw.Border.all(color: orange.shade(0.20), width: 0.7),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 30,
                  height: 30,
                  decoration: pw.BoxDecoration(
                    color: orange.shade(0.14),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      item.position.toString(),
                      style: pw.TextStyle(
                        color: orange,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.title,
                        style: pw.TextStyle(
                          color: darkText,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        item.description,
                        style: pw.TextStyle(
                          color: gray,
                          fontSize: 7.5,
                          lineSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Prazo: ${item.deadline}',
                        style: pw.TextStyle(
                          color: orange,
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Resultado esperado: '
                        '${item.expectedResult}',
                        style: pw.TextStyle(
                          color: gray,
                          fontSize: 7,
                          lineSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildRecommendations({
    required List<ExecutiveOpinionRecommendation> recommendations,
  }) {
    return pw.Column(
      children: recommendations.map((item) {
        final color = _recommendationColor(item.priority);

        return pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 10),
          child: pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: color.shade(0.06),
              borderRadius: pw.BorderRadius.circular(9),
              border: pw.Border.all(color: color.shade(0.20), width: 0.7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        item.title,
                        style: pw.TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      '${formatOpinionPercentage(item.confidence)} de confiança',
                      style: pw.TextStyle(color: color, fontSize: 6.5),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  item.explanation,
                  style: pw.TextStyle(
                    color: gray,
                    fontSize: 7.5,
                    lineSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Ação recomendada: '
                  '${item.action}',
                  style: pw.TextStyle(
                    color: color,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildExecutiveSummary({required ExecutiveOpinionData opinion}) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: purple.shade(0.07),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: purple.shade(0.22), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumo executivo',
            style: pw.TextStyle(
              color: purple,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            opinion.executiveSummary,
            style: pw.TextStyle(color: darkText, fontSize: 8.5, lineSpacing: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMethodologyNote({required ExecutiveOpinionData opinion}) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'Nota metodológica: este parecer foi gerado automaticamente '
        'pelo Projeto Atlas com base nas ações gerenciais, prazos, '
        'responsáveis, prioridades, histórico e indicadores disponíveis. '
        'Nível de confiança estimado: '
        '${formatOpinionPercentage(opinion.confidence)}. '
        'O parecer deve apoiar, e não substituir, a avaliação técnica '
        'do consultor responsável.',
        style: pw.TextStyle(color: gray, fontSize: 6.8, lineSpacing: 2),
      ),
    );
  }

  PdfColor _classificationColor(
    ExecutiveOperationClassification classification,
  ) {
    switch (classification) {
      case ExecutiveOperationClassification.excellent:
        return forestGreen;

      case ExecutiveOperationClassification.good:
        return PdfColor.fromInt(0xFF2E7D32);

      case ExecutiveOperationClassification.attention:
        return orange;

      case ExecutiveOperationClassification.critical:
        return red;

      case ExecutiveOperationClassification.severe:
        return PdfColor.fromInt(0xFF8E0000);
    }
  }

  PdfColor _impactColor(ExecutiveOpinionImpact impact) {
    switch (impact) {
      case ExecutiveOpinionImpact.low:
        return forestGreen;

      case ExecutiveOpinionImpact.medium:
        return blue;

      case ExecutiveOpinionImpact.high:
        return orange;

      case ExecutiveOpinionImpact.critical:
        return red;
    }
  }

  PdfColor _recommendationColor(String priority) {
    switch (priority) {
      case 'critical':
        return red;

      case 'high':
        return orange;

      case 'medium':
        return blue;

      case 'low':
        return forestGreen;

      default:
        return gray;
    }
  }
}

String buildExecutiveOpinionFileName(ExecutiveOpinionData opinion) {
  final scope = opinion.scopeLabel.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );

  final date = opinion.generatedAt
      .replaceAll('/', '-')
      .replaceAll(':', '-')
      .replaceAll(' ', '_');

  return 'parecer_executivo_'
      '${scope}_'
      '$date.pdf';
}
