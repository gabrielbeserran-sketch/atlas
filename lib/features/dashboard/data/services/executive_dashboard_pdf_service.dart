import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/executive_dashboard_data.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/executive_opinion_service.dart';

class ExecutiveDashboardPdfService {
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

  Future<void> printDashboard({
    required ExecutiveDashboardData dashboard,
    required ExecutiveOpinionData opinion,
  }) async {
    await Printing.layoutPdf(
      name: buildExecutiveDashboardPdfFileName(dashboard),
      onLayout: (format) {
        return buildPdf(dashboard: dashboard, opinion: opinion, format: format);
      },
    );
  }

  Future<Uint8List> buildPdf({
    required ExecutiveDashboardData dashboard,
    required ExecutiveOpinionData opinion,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final document = pw.Document(
      title: 'Dashboard Executivo',
      author: 'Projeto Atlas',
      creator: 'Projeto Atlas',
      subject: 'Relatório executivo consolidado da operação',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.fromLTRB(34, 34, 34, 34),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }

          return _buildHeader(dashboard: dashboard);
        },
        footer: (context) {
          return _buildFooter(context: context);
        },
        build: (context) {
          return [
            _buildCover(dashboard: dashboard, opinion: opinion),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              title: 'Indicadores executivos',
              subtitle: 'Visão consolidada do desempenho da operação.',
            ),
            pw.SizedBox(height: 12),
            _buildKpis(dashboard: dashboard),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Alertas',
              subtitle: 'Pontos que exigem atenção gerencial.',
            ),
            pw.SizedBox(height: 12),
            _buildAlerts(dashboard: dashboard),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Tendências',
              subtitle: 'Comparação com o período anterior.',
            ),
            pw.SizedBox(height: 12),
            _buildTrends(dashboard: dashboard),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Distribuição por status',
              subtitle: 'Composição atual do plano de ação.',
            ),
            pw.SizedBox(height: 12),
            _buildStatusDistribution(dashboard: dashboard),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Rankings',
              subtitle: 'Desempenho por responsável, fazenda e prioridade.',
            ),
            pw.SizedBox(height: 12),
            _buildRankings(dashboard: dashboard),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Evolução mensal',
              subtitle:
                  'Ações criadas, concluídas e atrasadas nos últimos meses.',
            ),
            pw.SizedBox(height: 12),
            _buildEvolutionTable(points: dashboard.monthlyEvolution),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Evolução semanal',
              subtitle: 'Ritmo recente de criação e conclusão das ações.',
            ),
            pw.SizedBox(height: 12),
            _buildEvolutionTable(points: dashboard.weeklyEvolution),
            pw.SizedBox(height: 22),
            _buildOpinionSummary(opinion: opinion),
            pw.SizedBox(height: 20),
            _buildPriorities(opinion: opinion),
            pw.SizedBox(height: 20),
            _buildRecommendations(opinion: opinion),
            pw.SizedBox(height: 18),
            _buildMethodologyNote(dashboard: dashboard, opinion: opinion),
          ];
        },
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader({required ExecutiveDashboardData dashboard}) {
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
                  'Dashboard Executivo',
                  style: pw.TextStyle(color: gray, fontSize: 7),
                ),
              ],
            ),
          ),
          pw.Text(
            dashboard.scopeLabel,
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
              'Projeto Atlas · Dashboard Executivo',
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

  pw.Widget _buildCover({
    required ExecutiveDashboardData dashboard,
    required ExecutiveOpinionData opinion,
  }) {
    final classificationColor = _classificationColor(opinion.classification);

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
            'Dashboard Executivo',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 25,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          pw.Text(
            dashboard.scopeLabel,
            style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
          pw.SizedBox(height: 20),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCoverChip(
                label: 'Índice geral',
                value:
                    '${dashboard.generalPerformanceIndex.toStringAsFixed(0)}/100',
                color: classificationColor,
              ),
              _buildCoverChip(
                label: 'Classificação',
                value: executiveClassificationLabel(opinion.classification),
                color: classificationColor,
              ),
              _buildCoverChip(
                label: 'Confiança',
                value: formatOpinionPercentage(opinion.confidence),
                color: blue,
              ),
              _buildCoverChip(
                label: 'Gerado em',
                value: dashboard.generatedAt,
                color: forestGreen,
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: classificationColor.shade(0.10),
              borderRadius: pw.BorderRadius.circular(9),
              border: pw.Border.all(
                color: classificationColor.shade(0.30),
                width: 0.7,
              ),
            ),
            child: pw.Text(
              opinion.diagnosis,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8.5,
                lineSpacing: 3,
              ),
            ),
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

  pw.Widget _buildKpis({required ExecutiveDashboardData dashboard}) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: dashboard.kpis.map((kpi) {
        final color = _indicatorColor(kpi.status);

        return pw.Container(
          width: 155,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: color.shade(0.07),
            borderRadius: pw.BorderRadius.circular(9),
            border: pw.Border.all(color: color.shade(0.22), width: 0.7),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                kpi.value,
                style: pw.TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                kpi.title,
                style: pw.TextStyle(
                  color: darkText,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                kpi.subtitle,
                style: pw.TextStyle(color: gray, fontSize: 6.5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildAlerts({required ExecutiveDashboardData dashboard}) {
    return pw.Column(
      children: dashboard.alerts.map((alert) {
        final color = _alertColor(alert.severity);

        return pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 8),
          child: pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: color.shade(0.06),
              borderRadius: pw.BorderRadius.circular(9),
              border: pw.Border.all(color: color.shade(0.18), width: 0.7),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 9,
                  height: 9,
                  margin: pw.EdgeInsets.only(top: 2),
                  decoration: pw.BoxDecoration(
                    color: color,
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
                              alert.title,
                              style: pw.TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          if (alert.count > 0)
                            pw.Text(
                              alert.count.toString(),
                              style: pw.TextStyle(
                                color: color,
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        alert.message,
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

  pw.Widget _buildTrends({required ExecutiveDashboardData dashboard}) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildTrendCard(trend: dashboard.productivityTrend)),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildTrendCard(trend: dashboard.delayTrend)),
      ],
    );
  }

  pw.Widget _buildTrendCard({required ExecutiveTrendData trend}) {
    final color = _trendColor(trend);

    return pw.Container(
      padding: pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: color.shade(0.07),
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: color.shade(0.20), width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            trend.label,
            style: pw.TextStyle(
              color: darkText,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            formatOpinionPercentage(trend.percentage),
            style: pw.TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            trend.interpretation,
            style: pw.TextStyle(color: gray, fontSize: 7, lineSpacing: 2),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatusDistribution({
    required ExecutiveDashboardData dashboard,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.7),
      columnWidths: {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: forestGreen),
          children: [
            _buildTableHeaderCell('Status'),
            _buildTableHeaderCell('Quantidade'),
            _buildTableHeaderCell('Participação'),
            _buildTableHeaderCell('Classificação'),
          ],
        ),
        ...dashboard.statusDistribution.map((item) {
          final color = _indicatorColor(item.status);

          return pw.TableRow(
            children: [
              _buildTableCell(item.label, color: color, bold: true),
              _buildTableCell(item.value.toStringAsFixed(0), center: true),
              _buildTableCell(
                formatOpinionPercentage(item.percentage),
                center: true,
              ),
              _buildTableCell(
                item.status.name,
                center: true,
                color: color,
                bold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildRankings({required ExecutiveDashboardData dashboard}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildRankingTable(
          title: 'Responsáveis',
          items: dashboard.responsibleRanking,
        ),
        pw.SizedBox(height: 14),
        _buildRankingTable(title: 'Fazendas', items: dashboard.farmRanking),
        pw.SizedBox(height: 14),
        _buildRankingTable(
          title: 'Prioridades',
          items: dashboard.priorityRanking,
        ),
      ],
    );
  }

  pw.Widget _buildRankingTable({
    required String title,
    required List<ExecutiveRankingItem> items,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: darkText,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: borderGray, width: 0.7),
          columnWidths: {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(4),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: lightGray),
              children: [
                _buildTableCell('#', center: true, bold: true),
                _buildTableCell('Nome', bold: true),
                _buildTableCell('Abertas', center: true, bold: true),
                _buildTableCell('Concluídas', center: true, bold: true),
                _buildTableCell('Desempenho', center: true, bold: true),
              ],
            ),
            ...items.take(8).map((item) {
              final color = _indicatorColor(item.status);

              return pw.TableRow(
                children: [
                  _buildTableCell(item.position.toString(), center: true),
                  _buildTableCell(item.label, bold: true),
                  _buildTableCell(item.value.toStringAsFixed(0), center: true),
                  _buildTableCell(
                    item.secondaryValue.toStringAsFixed(0),
                    center: true,
                  ),
                  _buildTableCell(
                    formatOpinionPercentage(item.percentage),
                    center: true,
                    color: color,
                    bold: true,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildEvolutionTable({
    required List<ExecutiveEvolutionPoint> points,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.7),
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
        5: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: forestGreen),
          children: [
            _buildTableHeaderCell('Período'),
            _buildTableHeaderCell('Criadas'),
            _buildTableHeaderCell('Concluídas'),
            _buildTableHeaderCell('Atrasadas'),
            _buildTableHeaderCell('Conclusão'),
            _buildTableHeaderCell('Saldo'),
          ],
        ),
        ...points.map((point) {
          final balanceColor = point.balance >= 0 ? forestGreen : red;

          return pw.TableRow(
            children: [
              _buildTableCell(point.label, bold: true),
              _buildTableCell(point.createdCount.toString(), center: true),
              _buildTableCell(point.completedCount.toString(), center: true),
              _buildTableCell(point.overdueCount.toString(), center: true),
              _buildTableCell(
                formatOpinionPercentage(point.completionRate),
                center: true,
              ),
              _buildTableCell(
                point.balance.toString(),
                center: true,
                color: balanceColor,
                bold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildOpinionSummary({required ExecutiveOpinionData opinion}) {
    final color = _classificationColor(opinion.classification);

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.07),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: color.shade(0.22), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Parecer Executivo Inteligente',
                  style: pw.TextStyle(
                    color: color,
                    fontSize: 13,
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
          pw.SizedBox(height: 9),
          pw.Text(
            opinion.executiveSummary,
            style: pw.TextStyle(color: darkText, fontSize: 8.5, lineSpacing: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPriorities({required ExecutiveOpinionData opinion}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Prioridades',
          subtitle: 'Sequência recomendada para atuação.',
        ),
        pw.SizedBox(height: 10),
        ...opinion.priorities.map((item) {
          return pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 9),
            child: pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: orange.shade(0.06),
                borderRadius: pw.BorderRadius.circular(9),
                border: pw.Border.all(color: orange.shade(0.18), width: 0.7),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 28,
                    height: 28,
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
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Prazo: ${item.deadline} · '
                          'Resultado esperado: ${item.expectedResult}',
                          style: pw.TextStyle(
                            color: orange,
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
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
        }),
      ],
    );
  }

  pw.Widget _buildRecommendations({required ExecutiveOpinionData opinion}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Recomendações',
          subtitle: 'Ações sugeridas para melhoria da gestão.',
        ),
        pw.SizedBox(height: 10),
        ...opinion.recommendations.map((item) {
          final color = _recommendationColor(item.priority);

          return pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 9),
            child: pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: color.shade(0.06),
                borderRadius: pw.BorderRadius.circular(9),
                border: pw.Border.all(color: color.shade(0.18), width: 0.7),
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
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Ação recomendada: ${item.action}',
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
        }),
      ],
    );
  }

  pw.Widget _buildMethodologyNote({
    required ExecutiveDashboardData dashboard,
    required ExecutiveOpinionData opinion,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'Nota metodológica: este relatório foi gerado automaticamente '
        'pelo Projeto Atlas com base nas ações gerenciais, histórico, '
        'prazos, responsáveis, prioridades e indicadores disponíveis. '
        'Escopo: ${dashboard.scopeLabel}. '
        'Confiança do parecer: '
        '${formatOpinionPercentage(opinion.confidence)}. '
        'O relatório deve apoiar, e não substituir, a avaliação técnica '
        'do consultor responsável.',
        style: pw.TextStyle(color: gray, fontSize: 6.8, lineSpacing: 2),
      ),
    );
  }

  pw.Widget _buildTableHeaderCell(String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(
    String value, {
    bool center = false,
    bool bold = false,
    PdfColor color = darkText,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  PdfColor _indicatorColor(ExecutiveIndicatorStatus status) {
    switch (status) {
      case ExecutiveIndicatorStatus.positive:
        return forestGreen;
      case ExecutiveIndicatorStatus.normal:
        return blue;
      case ExecutiveIndicatorStatus.attention:
        return orange;
      case ExecutiveIndicatorStatus.critical:
        return red;
    }
  }

  PdfColor _alertColor(ExecutiveAlertSeverity severity) {
    switch (severity) {
      case ExecutiveAlertSeverity.information:
        return forestGreen;
      case ExecutiveAlertSeverity.warning:
        return orange;
      case ExecutiveAlertSeverity.critical:
        return red;
    }
  }

  PdfColor _classificationColor(
    ExecutiveOperationClassification classification,
  ) {
    switch (classification) {
      case ExecutiveOperationClassification.excellent:
        return forestGreen;
      case ExecutiveOperationClassification.good:
        return darkGreen;
      case ExecutiveOperationClassification.attention:
        return orange;
      case ExecutiveOperationClassification.critical:
        return red;
      case ExecutiveOperationClassification.severe:
        return PdfColor.fromInt(0xFF8E0000);
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

  PdfColor _trendColor(ExecutiveTrendData trend) {
    if (trend.isStable) {
      return blue;
    }

    if (trend.label == 'Atrasos') {
      return trend.isIncreasing ? red : forestGreen;
    }

    return trend.isIncreasing ? forestGreen : red;
  }
}

String buildExecutiveDashboardPdfFileName(ExecutiveDashboardData dashboard) {
  final scope = dashboard.scopeLabel.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );

  final date = dashboard.generatedAt
      .replaceAll('/', '-')
      .replaceAll(':', '-')
      .replaceAll(' ', '_');

  return 'dashboard_executivo_'
      '${scope}_'
      '$date.pdf';
}
