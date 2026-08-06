import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_action_analytics_card.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';

class ReportActionPdfService {
  static const PdfColor forestGreen = PdfColor.fromInt(0xFF1B5E20);

  static const PdfColor darkGreen = PdfColor.fromInt(0xFF124317);

  static const PdfColor blue = PdfColor.fromInt(0xFF1565C0);

  static const PdfColor orange = PdfColor.fromInt(0xFFEF6C00);

  static const PdfColor red = PdfColor.fromInt(0xFFC62828);

  static const PdfColor gray = PdfColor.fromInt(0xFF607D8B);

  static const PdfColor darkText = PdfColor.fromInt(0xFF263238);

  static const PdfColor lightGray = PdfColor.fromInt(0xFFF2F4F5);

  static const PdfColor borderGray = PdfColor.fromInt(0xFFDADFE2);

  Future<void> printReport({required ReportActionPdfData report}) async {
    await Printing.layoutPdf(
      name: report.fileName,
      onLayout: (format) {
        return buildPdf(report: report, format: format);
      },
    );
  }

  Future<Uint8List> buildPdf({
    required ReportActionPdfData report,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final document = pw.Document(
      title: report.title,
      author: 'Projeto Atlas',
      creator: 'Projeto Atlas',
      subject: 'Relatório de acompanhamento das ações gerenciais',
    );

    final orderedActions = List<ReportActionItemData>.from(report.actions)
      ..sort(compareReportActions);

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: pw.EdgeInsets.fromLTRB(34, 34, 34, 34),
        header: (context) {
          return _buildHeader(report: report, context: context);
        },
        footer: (context) {
          return _buildFooter(context: context);
        },
        build: (context) {
          return [
            _buildCoverSummary(report: report),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              title: 'Resumo executivo',
              subtitle: 'Situação consolidada do plano de ação.',
            ),
            pw.SizedBox(height: 12),
            _buildSummaryMetrics(report: report),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Análise gerencial',
              subtitle: 'Indicadores de execução, atraso e responsabilidade.',
            ),
            pw.SizedBox(height: 12),
            _buildAnalyticsSection(report: report),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Distribuição por status',
              subtitle: 'Quantidade de ações em cada etapa de execução.',
            ),
            pw.SizedBox(height: 12),
            _buildStatusTable(report: report),
            pw.SizedBox(height: 22),
            _buildSectionTitle(
              title: 'Ações gerenciais',
              subtitle: 'Detalhamento em ordem de prioridade e prazo.',
            ),
            pw.SizedBox(height: 12),
            if (orderedActions.isEmpty)
              _buildEmptyState()
            else
              ...orderedActions.map((action) {
                return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 12),
                  child: _buildActionCard(
                    action: action,
                    history: report.historyByActionId[action.id] ?? const [],
                  ),
                );
              }),
            pw.SizedBox(height: 16),
            _buildClosingNote(report: report),
          ];
        },
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader({
    required ReportActionPdfData report,
    required pw.Context context,
  }) {
    if (context.pageNumber == 1) {
      return pw.SizedBox();
    }

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
                  report.title,
                  style: pw.TextStyle(color: gray, fontSize: 7),
                ),
              ],
            ),
          ),
          pw.Text(
            report.scopeLabel,
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
              'Projeto Atlas · Acompanhamento gerencial',
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

  pw.Widget _buildCoverSummary({required ReportActionPdfData report}) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: forestGreen,
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
            report.title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          pw.Text(
            'Acompanhamento das recomendações até a conclusão.',
            style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
          pw.SizedBox(height: 20),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCoverChip(label: 'Escopo', value: report.scopeLabel),
              _buildCoverChip(label: 'Emissão', value: report.issueDate),
              _buildCoverChip(
                label: 'Responsável',
                value: report.consultantName,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCoverChip({required String label, required String value}) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white.shade(0.10),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.white.shade(0.25), width: 0.6),
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

  pw.Widget _buildSummaryMetrics({required ReportActionPdfData report}) {
    final completionColor = report.completionRate >= 0.75
        ? forestGreen
        : report.completionRate >= 0.40
        ? blue
        : orange;

    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildMetricCard(
          label: 'Total',
          value: report.totalCount.toString(),
          color: blue,
        ),
        _buildMetricCard(
          label: 'Abertas',
          value: report.openCount.toString(),
          color: orange,
        ),
        _buildMetricCard(
          label: 'Atrasadas',
          value: report.overdueCount.toString(),
          color: report.overdueCount > 0 ? red : forestGreen,
        ),
        _buildMetricCard(
          label: 'Urgentes',
          value: report.urgentCount.toString(),
          color: report.urgentCount > 0 ? red : forestGreen,
        ),
        _buildMetricCard(
          label: 'Concluídas',
          value: report.completedCount.toString(),
          color: forestGreen,
        ),
        _buildMetricCard(
          label: 'Conclusão',
          value:
              '${(report.completionRate * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
          color: completionColor,
        ),
      ],
    );
  }

  pw.Widget _buildMetricCard({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      width: 155,
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.08),
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: color.shade(0.25), width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(label, style: pw.TextStyle(color: gray, fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildAnalyticsSection({required ReportActionPdfData report}) {
    final analytics = ReportActionAnalytics.fromData(
      actions: report.actions,
      historyByActionId: report.historyByActionId,
    );

    final recommendation = buildAnalyticsRecommendation(analytics);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildAnalyticsMetric(
              label: 'Taxa de atraso',
              value: formatAnalyticsPercentage(analytics.overdueRate),
              description: '${analytics.overdueCount} ações atrasadas',
              color: analytics.overdueCount > 0 ? red : forestGreen,
            ),
            _buildAnalyticsMetric(
              label: 'Prazo médio',
              value: analytics.averageCompletionDaysLabel,
              description: 'Tempo médio até a conclusão',
              color: blue,
            ),
            _buildAnalyticsMetric(
              label: 'Mais ações abertas',
              value: analytics.topResponsible,
              description: '${analytics.topResponsibleOpenCount} ações abertas',
              color: PdfColor.fromInt(0xFF6A1B9A),
            ),
            _buildAnalyticsMetric(
              label: 'Prioridade predominante',
              value: analytics.mainPriority,
              description: '${analytics.mainPriorityCount} ações',
              color: _priorityColor(analytics.mainPriority),
            ),
            _buildAnalyticsMetric(
              label: 'Sem responsável',
              value: analytics.withoutResponsibleCount.toString(),
              description: 'Ações abertas sem responsável',
              color: analytics.withoutResponsibleCount > 0
                  ? orange
                  : forestGreen,
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildResponsibilityDistribution(analytics: analytics),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildAnalyticsRecommendation(
                recommendation: recommendation,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAnalyticsMetric({
    required String label,
    required String value,
    required String description,
    required PdfColor color,
  }) {
    return pw.Container(
      width: 155,
      padding: pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: color.shade(0.08),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color.shade(0.24), width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            label,
            style: pw.TextStyle(
              color: darkText,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(description, style: pw.TextStyle(color: gray, fontSize: 6.5)),
        ],
      ),
    );
  }

  pw.Widget _buildResponsibilityDistribution({
    required ReportActionAnalytics analytics,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: borderGray, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Distribuição por responsável',
            style: pw.TextStyle(
              color: darkText,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 9),
          if (analytics.responsibilityItems.isEmpty)
            pw.Text(
              'Nenhuma ação com responsável definido.',
              style: pw.TextStyle(color: gray, fontSize: 7),
            )
          else
            ...analytics.responsibilityItems.map((item) {
              return pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 7),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            item.responsible,
                            maxLines: 1,
                            overflow: pw.TextOverflow.clip,
                            style: pw.TextStyle(
                              color: darkText,
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Text(
                          '${item.openCount} abertas · '
                          '${item.completedCount} concluídas',
                          style: pw.TextStyle(color: gray, fontSize: 6),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      height: 6,
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          height: 6,
                          width: 220 * item.completionRate.clamp(0.0, 1.0),
                          decoration: pw.BoxDecoration(
                            color: forestGreen,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  pw.Widget _buildAnalyticsRecommendation({
    required ReportActionAnalyticsRecommendationData recommendation,
  }) {
    final color = PdfColor.fromInt(recommendation.color.toARGB32());

    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.08),
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: color.shade(0.24), width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            recommendation.title,
            style: pw.TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          pw.Text(
            recommendation.message,
            style: pw.TextStyle(color: darkText, fontSize: 7, lineSpacing: 2),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Ação recomendada: '
            '${recommendation.action}',
            style: pw.TextStyle(
              color: color,
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatusTable({required ReportActionPdfData report}) {
    final rows = [
      _StatusRow(label: 'Pendente', value: report.pendingCount, color: orange),
      _StatusRow(
        label: 'Em andamento',
        value: report.inProgressCount,
        color: blue,
      ),
      _StatusRow(
        label: 'Concluída',
        value: report.completedCount,
        color: forestGreen,
      ),
      _StatusRow(label: 'Cancelada', value: report.cancelledCount, color: gray),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: forestGreen),
          children: [
            _buildTableHeaderCell('Status'),
            _buildTableHeaderCell('Quantidade'),
            _buildTableHeaderCell('Participação'),
          ],
        ),
        ...rows.map((row) {
          final participation = report.totalCount == 0
              ? 0.0
              : row.value / report.totalCount * 100;

          return pw.TableRow(
            children: [
              _buildTableCell(row.label, color: row.color, bold: true),
              _buildTableCell(row.value.toString(), center: true, bold: true),
              _buildTableCell(
                '${participation.toStringAsFixed(1).replaceAll('.', ',')}%',
                center: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildActionCard({
    required ReportActionItemData action,
    required List<ReportActionHistoryData> history,
  }) {
    final statusColor = _actionStatusColor(action);

    final orderedHistory = List<ReportActionHistoryData>.from(history)
      ..sort(compareReportActionHistory);

    final visibleHistory = orderedHistory.take(4).toList();

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: statusColor.shade(0.35), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 34,
                height: 34,
                decoration: pw.BoxDecoration(
                  color: statusColor.shade(0.10),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    _statusInitial(action.status),
                    style: pw.TextStyle(
                      color: statusColor,
                      fontSize: 13,
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
                      action.title,
                      style: pw.TextStyle(
                        color: darkText,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      action.action,
                      style: pw.TextStyle(
                        color: gray,
                        fontSize: 8,
                        lineSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: statusColor.shade(0.10),
                  borderRadius: pw.BorderRadius.circular(7),
                ),
                child: pw.Text(
                  action.isOverdue ? 'ATRASADA' : action.status.toUpperCase(),
                  style: pw.TextStyle(
                    color: statusColor,
                    fontSize: 6.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                label: 'Fazenda',
                value: action.farmName.isEmpty ? 'Todas' : action.farmName,
                color: blue,
              ),
              _buildInfoChip(
                label: 'Prioridade',
                value: action.priority,
                color: _priorityColor(action.priority),
              ),
              _buildInfoChip(
                label: 'Prazo',
                value: action.deadline.isEmpty ? 'Sem prazo' : action.deadline,
                color: action.isOverdue ? red : orange,
              ),
              _buildInfoChip(
                label: 'Responsável',
                value: action.responsible.isEmpty
                    ? 'Não definido'
                    : action.responsible,
                color: darkGreen,
              ),
            ],
          ),
          if (action.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(7),
              ),
              child: pw.Text(
                'Observações: ${action.notes}',
                style: pw.TextStyle(color: gray, fontSize: 7.5, lineSpacing: 2),
              ),
            ),
          ],
          if (visibleHistory.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'HISTÓRICO RECENTE',
              style: pw.TextStyle(
                color: darkText,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            ...visibleHistory.map((item) {
              return pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      margin: pw.EdgeInsets.only(top: 2),
                      decoration: pw.BoxDecoration(
                        color: _historyColor(item),
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Text(
                        '${item.createdAt} · '
                        '${item.eventType}: '
                        '${item.description}',
                        style: pw.TextStyle(
                          color: gray,
                          fontSize: 7,
                          lineSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildInfoChip({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color.shade(0.07),
        borderRadius: pw.BorderRadius.circular(7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(color: color, fontSize: 5.5),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color,
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
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

  pw.Widget _buildEmptyState() {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(28),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Nenhuma ação encontrada',
            style: pw.TextStyle(
              color: forestGreen,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Não existem ações para os filtros selecionados.',
            style: pw.TextStyle(color: gray, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClosingNote({required ReportActionPdfData report}) {
    String message;

    if (report.overdueCount > 0) {
      message =
          'Existem ${report.overdueCount} '
          '${report.overdueCount == 1 ? 'ação atrasada' : 'ações atrasadas'}. '
          'Priorize a revisão dos prazos e responsáveis.';
    } else if (report.completionRate >= 0.75) {
      message =
          'O plano apresenta bom avanço. '
          'Mantenha o acompanhamento das ações restantes.';
    } else if (report.inProgressCount > 0) {
      message =
          'O plano está em execução. '
          'Acompanhe os prazos e registre as conclusões.';
    } else {
      message =
          'O plano ainda está no início. '
          'Defina responsáveis e inicie as ações prioritárias.';
    }

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: forestGreen.shade(0.08),
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: forestGreen.shade(0.25), width: 0.7),
      ),
      child: pw.Text(
        'Observação gerencial: $message',
        style: pw.TextStyle(
          color: forestGreen,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          lineSpacing: 2,
        ),
      ),
    );
  }

  PdfColor _actionStatusColor(ReportActionItemData action) {
    if (action.isOverdue) {
      return red;
    }

    switch (action.status) {
      case 'Em andamento':
        return blue;
      case 'Concluída':
        return forestGreen;
      case 'Cancelada':
        return gray;
      default:
        return orange;
    }
  }

  PdfColor _priorityColor(String priority) {
    switch (priority) {
      case 'Muito alta':
      case 'Urgente':
        return red;
      case 'Alta':
        return orange;
      case 'Média':
      case 'Normal':
        return blue;
      default:
        return forestGreen;
    }
  }

  PdfColor _historyColor(ReportActionHistoryData item) {
    if (item.isCompletion) {
      return forestGreen;
    }

    if (item.isCancellation) {
      return gray;
    }

    if (item.isDeadlineChange) {
      return orange;
    }

    if (item.isPriorityChange) {
      return red;
    }

    if (item.isResponsibleChange) {
      return blue;
    }

    return forestGreen;
  }

  String _statusInitial(String status) {
    switch (status) {
      case 'Em andamento':
        return 'EA';
      case 'Concluída':
        return 'C';
      case 'Cancelada':
        return 'X';
      default:
        return 'P';
    }
  }
}

class ReportActionPdfData {
  const ReportActionPdfData({
    required this.title,
    required this.scopeLabel,
    required this.issueDate,
    required this.consultantName,
    required this.actions,
    required this.historyByActionId,
  });

  final String title;
  final String scopeLabel;
  final String issueDate;
  final String consultantName;
  final List<ReportActionItemData> actions;
  final Map<String, List<ReportActionHistoryData>> historyByActionId;

  int get totalCount {
    return actions.length;
  }

  int get pendingCount {
    return actions.where((action) {
      return action.isPending;
    }).length;
  }

  int get inProgressCount {
    return actions.where((action) {
      return action.isInProgress;
    }).length;
  }

  int get completedCount {
    return actions.where((action) {
      return action.isCompleted;
    }).length;
  }

  int get cancelledCount {
    return actions.where((action) {
      return action.isCancelled;
    }).length;
  }

  int get overdueCount {
    return actions.where((action) {
      return action.isOverdue;
    }).length;
  }

  int get urgentCount {
    return actions.where((action) {
      return action.isUrgent && action.isOpen;
    }).length;
  }

  int get openCount {
    return actions.where((action) {
      return action.isOpen;
    }).length;
  }

  double get completionRate {
    final considered = actions.where((action) {
      return !action.isCancelled;
    }).length;

    if (considered == 0) {
      return 0;
    }

    return completedCount / considered;
  }

  String get fileName {
    final normalizedScope = scopeLabel.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    final normalizedDate = issueDate.replaceAll('/', '-').replaceAll(' ', '_');

    return 'acoes_gerenciais_'
        '${normalizedScope}_'
        '$normalizedDate.pdf';
  }
}

class _StatusRow {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final PdfColor color;
}
