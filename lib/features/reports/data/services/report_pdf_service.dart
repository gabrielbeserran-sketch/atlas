import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPdfService {
  static const PdfColor forestGreen = PdfColor.fromInt(0xFF1B5E20);

  static const PdfColor mediumGreen = PdfColor.fromInt(0xFF2E7D32);

  static const PdfColor lightGreen = PdfColor.fromInt(0xFFE8F5E9);

  static const PdfColor darkText = PdfColor.fromInt(0xFF263238);

  static const PdfColor grayText = PdfColor.fromInt(0xFF616161);

  static const PdfColor lightGray = PdfColor.fromInt(0xFFF2F4F5);

  static const PdfColor borderGray = PdfColor.fromInt(0xFFD8DDDF);

  static const PdfColor blue = PdfColor.fromInt(0xFF1565C0);

  static const PdfColor orange = PdfColor.fromInt(0xFFEF6C00);

  static const PdfColor red = PdfColor.fromInt(0xFFC62828);

  Future<void> printReport({required ReportPdfData report}) async {
    final bytes = await buildReport(report: report);

    await Printing.layoutPdf(
      name: createFileName(report),
      onLayout: (format) async {
        return bytes;
      },
    );
  }

  Future<Uint8List> buildReport({required ReportPdfData report}) async {
    final document = pw.Document(
      title: 'Relatório Gerencial - Projeto Atlas',
      author: 'Projeto Atlas',
      subject: 'Relatório gerencial pecuário',
      creator: 'Beserra Consultoria Veterinária',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 36),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }

          return _buildPageHeader(report: report);
        },
        footer: (context) {
          return _buildPageFooter(context: context);
        },
        build: (context) {
          return [
            _buildMainHeader(report: report),
            pw.SizedBox(height: 22),
            _buildReportIdentification(report: report),
            pw.SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Resumo executivo',
              subtitle:
                  'Principais resultados encontrados nos filtros selecionados.',
            ),
            pw.SizedBox(height: 12),
            _buildSummaryCards(report: report),
            pw.SizedBox(height: 24),
            _buildFinancialResult(report: report),
            pw.SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Alertas operacionais',
              subtitle: 'Situações que precisam de acompanhamento pela gestão.',
            ),
            pw.SizedBox(height: 12),
            _buildAlertsTable(report: report),
            pw.SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Despesas por categoria',
              subtitle: 'Categorias com participação nas despesas do período.',
            ),
            pw.SizedBox(height: 12),
            _buildExpenseCategories(report: report),
            pw.SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Ranking financeiro',
              subtitle: 'Propriedades ordenadas pelo resultado financeiro.',
            ),
            pw.SizedBox(height: 12),
            _buildFarmRanking(
              farms: report.financialRanking,
              valueTitle: 'Resultado',
              valueBuilder: (farm) {
                return formatCurrency(farm.balance);
              },
              valueColorBuilder: (farm) {
                return farm.balance >= 0 ? forestGreen : red;
              },
            ),
            pw.SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Ranking de estoque',
              subtitle: 'Propriedades ordenadas pelo valor atual do estoque.',
            ),
            pw.SizedBox(height: 12),
            _buildFarmRanking(
              farms: report.inventoryRanking,
              valueTitle: 'Valor do estoque',
              valueBuilder: (farm) {
                return formatCurrency(farm.inventoryValue);
              },
              valueColorBuilder: (farm) {
                return blue;
              },
            ),
            pw.SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Resultado por propriedade',
              subtitle:
                  'Resumo financeiro, operacional e patrimonial de cada fazenda.',
            ),
            pw.SizedBox(height: 12),
            ...report.farms.expand((farm) {
              return [
                pw.NewPage(freeSpace: 190),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 14),
                  child: _buildFarmCard(farm: farm),
                ),
              ];
            }),
            pw.SizedBox(height: 18),
            _buildSectionTitle(
              title: 'Diagnóstico gerencial Atlas',
              subtitle:
                  'Principais conclusões automáticas com base nos dados do relatório.',
            ),
            pw.SizedBox(height: 12),
            _buildManagementDiagnosis(report: report),
            pw.SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Plano de ação gerencial',
              subtitle:
                  'Ações recomendadas organizadas por prioridade e prazo.',
            ),
            pw.SizedBox(height: 12),
            _buildActionPlan(report: report),
            pw.SizedBox(height: 18),
            _buildClosingNote(report: report),
          ];
        },
      ),
    );

    return document.save();
  }

  pw.Widget _buildMainHeader({required ReportPdfData report}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(22),
      decoration: pw.BoxDecoration(
        color: forestGreen,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 56,
            height: 56,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Center(
              child: pw.Text(
                'A',
                style: pw.TextStyle(
                  color: forestGreen,
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PROJETO ATLAS',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Relatório Gerencial Pecuário',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 13,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Beserra Consultoria Veterinária',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFDDECDD),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: mediumGreen,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'EMISSÃO',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  report.issueDate,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageHeader({required ReportPdfData report}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: borderGray, width: 0.8)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'PROJETO ATLAS',
            style: pw.TextStyle(
              color: forestGreen,
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.Spacer(),
          pw.Text(
            report.reportTitle,
            style: const pw.TextStyle(color: grayText, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter({required pw.Context context}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderGray, width: 0.8)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Dados que guiam. Resultados que permanecem.',
              style: const pw.TextStyle(color: grayText, fontSize: 8),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de '
            '${context.pagesCount}',
            style: const pw.TextStyle(color: grayText, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportIdentification({required ReportPdfData report}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: borderGray, width: 0.7),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _buildIdentificationItem(
              label: 'RELATÓRIO',
              value: report.reportTitle,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _buildIdentificationItem(
              label: 'PROPRIEDADE',
              value: report.farmFilter,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _buildIdentificationItem(
              label: 'PERÍODO',
              value: report.periodLabel,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIdentificationItem({
    required String label,
    required String value,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: forestGreen,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: darkText,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 5,
              height: 22,
              decoration: pw.BoxDecoration(
                color: forestGreen,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
            pw.SizedBox(width: 9),
            pw.Text(
              title,
              style: pw.TextStyle(
                color: darkText,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 14),
          child: pw.Text(
            subtitle,
            style: const pw.TextStyle(color: grayText, fontSize: 9),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryCards({required ReportPdfData report}) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetricCard(
          title: 'Fazendas',
          value: report.farms.length.toString(),
          color: forestGreen,
        ),
        _buildMetricCard(
          title: 'Receitas',
          value: formatCurrency(report.totalIncome),
          color: forestGreen,
        ),
        _buildMetricCard(
          title: 'Despesas',
          value: formatCurrency(report.totalExpenses),
          color: red,
        ),
        _buildMetricCard(
          title: 'Resultado',
          value: formatCurrency(report.totalBalance),
          color: report.totalBalance >= 0 ? forestGreen : red,
        ),
        _buildMetricCard(
          title: 'Valor do estoque',
          value: formatCurrency(report.totalInventoryValue),
          color: blue,
        ),
        _buildMetricCard(
          title: 'Compromissos',
          value: report.totalAgendaTasks.toString(),
          color: blue,
        ),
      ],
    );
  }

  pw.Widget _buildMetricCard({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      width: 164,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: borderGray, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            maxLines: 1,
            style: pw.TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: const pw.TextStyle(color: grayText, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFinancialResult({required ReportPdfData report}) {
    final largestValue = [report.totalIncome.abs(), report.totalExpenses.abs()]
        .fold<double>(0, (largest, value) {
          return value > largest ? value : largest;
        });

    final incomeProgress = largestValue == 0
        ? 0.0
        : report.totalIncome / largestValue;

    final expenseProgress = largestValue == 0
        ? 0.0
        : report.totalExpenses / largestValue;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: borderGray, width: 0.7),
      ),
      child: pw.Column(
        children: [
          _buildFinancialBar(
            label: 'Receitas',
            value: report.totalIncome,
            progress: incomeProgress,
            color: forestGreen,
          ),
          pw.SizedBox(height: 16),
          _buildFinancialBar(
            label: 'Despesas',
            value: report.totalExpenses,
            progress: expenseProgress,
            color: red,
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: borderGray, thickness: 0.7),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Resultado do período',
                  style: pw.TextStyle(
                    color: darkText,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                formatCurrency(report.totalBalance),
                style: pw.TextStyle(
                  color: report.totalBalance >= 0 ? forestGreen : red,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFinancialBar({
    required String label,
    required double value,
    required double progress,
    required PdfColor color,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);

    final filledFlex = (safeProgress * 1000).round();

    final emptyFlex = 1000 - filledFlex;

    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  color: darkText,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              formatCurrency(value),
              style: pw.TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Container(
          width: double.infinity,
          height: 9,
          decoration: pw.BoxDecoration(
            color: lightGray,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            children: [
              if (filledFlex > 0)
                pw.Expanded(
                  flex: filledFlex,
                  child: pw.Container(
                    height: 9,
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (emptyFlex > 0)
                pw.Expanded(flex: emptyFlex, child: pw.SizedBox(height: 9)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildAlertsTable({required ReportPdfData report}) {
    final alerts = [
      ReportAlertPdfData(
        title: 'Estoque baixo',
        value: report.lowStockCount,
        description: 'Produtos no estoque mínimo ou abaixo.',
        severity: report.lowStockCount > 0
            ? ReportAlertSeverity.warning
            : ReportAlertSeverity.normal,
      ),
      ReportAlertPdfData(
        title: 'Produtos vencidos',
        value: report.expiredItemsCount,
        description: 'Produtos cadastrados fora da validade.',
        severity: report.expiredItemsCount > 0
            ? ReportAlertSeverity.critical
            : ReportAlertSeverity.normal,
      ),
      ReportAlertPdfData(
        title: 'Tarefas atrasadas',
        value: report.overdueTasksCount,
        description: 'Compromissos da agenda fora do prazo.',
        severity: report.overdueTasksCount > 0
            ? ReportAlertSeverity.critical
            : ReportAlertSeverity.normal,
      ),
      ReportAlertPdfData(
        title: 'Tarefas urgentes',
        value: report.urgentTasksCount,
        description: 'Prioridades urgentes ainda abertas.',
        severity: report.urgentTasksCount > 0
            ? ReportAlertSeverity.critical
            : ReportAlertSeverity.normal,
      ),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(4),
        3: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: forestGreen),
          children: [
            _buildTableHeaderCell('Indicador'),
            _buildTableHeaderCell('Quantidade'),
            _buildTableHeaderCell('Descrição'),
            _buildTableHeaderCell('Situação'),
          ],
        ),
        ...alerts.map((alert) {
          final color = alertSeverityColor(alert.severity);

          return pw.TableRow(
            children: [
              _buildTableCell(alert.title, bold: true),
              _buildTableCell(
                alert.value.toString(),
                color: color,
                bold: true,
                center: true,
              ),
              _buildTableCell(alert.description),
              _buildTableCell(
                alertSeverityLabel(alert.severity),
                color: color,
                bold: true,
                center: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildExpenseCategories({required ReportPdfData report}) {
    if (report.expenseCategories.isEmpty) {
      return _buildEmptyMessage(
        'Nenhuma despesa por categoria foi encontrada no período.',
      );
    }

    final categories = report.expenseCategories.take(8).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.7),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: forestGreen),
          children: [
            _buildTableHeaderCell('Posição'),
            _buildTableHeaderCell('Categoria'),
            _buildTableHeaderCell('Valor'),
            _buildTableHeaderCell('Participação'),
          ],
        ),
        ...List.generate(categories.length, (index) {
          final category = categories[index];

          final percentage = report.totalExpenses <= 0
              ? 0.0
              : category.value / report.totalExpenses * 100;

          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}ª', center: true, bold: true),
              _buildTableCell(category.name),
              _buildTableCell(
                formatCurrency(category.value),
                color: red,
                bold: true,
              ),
              _buildTableCell(formatPercentage(percentage), center: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildFarmRanking({
    required List<FarmPdfSummary> farms,
    required String valueTitle,
    required String Function(FarmPdfSummary farm) valueBuilder,
    required PdfColor Function(FarmPdfSummary farm) valueColorBuilder,
  }) {
    if (farms.isEmpty) {
      return _buildEmptyMessage(
        'Nenhuma propriedade disponível para este ranking.',
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: forestGreen),
          children: [
            _buildTableHeaderCell('Posição'),
            _buildTableHeaderCell('Propriedade'),
            _buildTableHeaderCell('Localização'),
            _buildTableHeaderCell(valueTitle),
          ],
        ),
        ...List.generate(farms.length, (index) {
          final farm = farms[index];

          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}º', center: true, bold: true),
              _buildTableCell(farm.name, bold: true),
              _buildTableCell('${farm.city} - ${farm.state}'),
              _buildTableCell(
                valueBuilder(farm),
                color: valueColorBuilder(farm),
                bold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildFarmCard({required FarmPdfSummary farm}) {
    final balanceColor = farm.balance >= 0 ? forestGreen : red;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: borderGray, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 34,
                height: 34,
                decoration: pw.BoxDecoration(
                  color: lightGreen,
                  borderRadius: pw.BorderRadius.circular(9),
                ),
                child: pw.Center(
                  child: pw.Text(
                    farm.name.isEmpty
                        ? 'F'
                        : farm.name.substring(0, 1).toUpperCase(),
                    style: pw.TextStyle(
                      color: forestGreen,
                      fontSize: 16,
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
                      farm.name,
                      style: pw.TextStyle(
                        color: darkText,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${farm.city} - ${farm.state} · '
                      '${formatNumber(farm.area)} hectares',
                      style: const pw.TextStyle(color: grayText, fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: balanceColor.shade(0.1),
                  borderRadius: pw.BorderRadius.circular(7),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'RESULTADO',
                      style: const pw.TextStyle(color: grayText, fontSize: 6.5),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      formatCurrency(farm.balance),
                      style: pw.TextStyle(
                        color: balanceColor,
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: borderGray, width: 0.6),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.35),
              1: pw.FlexColumnWidth(1.65),
              2: pw.FlexColumnWidth(1.35),
              3: pw.FlexColumnWidth(1.65),
            },
            children: [
              _buildFarmMetricRow(
                leftLabel: 'Receitas',
                leftValue: formatCurrency(farm.income),
                leftColor: forestGreen,
                rightLabel: 'Despesas',
                rightValue: formatCurrency(farm.expenses),
                rightColor: red,
              ),
              _buildFarmMetricRow(
                leftLabel: 'Estoque',
                leftValue: formatCurrency(farm.inventoryValue),
                leftColor: blue,
                rightLabel: 'Produtos',
                rightValue: farm.inventoryItemsCount.toString(),
                rightColor: darkText,
              ),
              _buildFarmMetricRow(
                leftLabel: 'Estoque baixo',
                leftValue: farm.lowStockCount.toString(),
                leftColor: farm.lowStockCount > 0 ? orange : forestGreen,
                rightLabel: 'Vencidos',
                rightValue: farm.expiredItemsCount.toString(),
                rightColor: farm.expiredItemsCount > 0 ? red : forestGreen,
              ),
              _buildFarmMetricRow(
                leftLabel: 'Pendentes',
                leftValue: farm.pendingTasksCount.toString(),
                leftColor: farm.pendingTasksCount > 0 ? orange : forestGreen,
                rightLabel: 'Atrasadas',
                rightValue: farm.overdueTasksCount.toString(),
                rightColor: farm.overdueTasksCount > 0 ? red : forestGreen,
              ),
              _buildFarmMetricRow(
                leftLabel: 'Urgentes',
                leftValue: farm.urgentTasksCount.toString(),
                leftColor: farm.urgentTasksCount > 0 ? red : forestGreen,
                rightLabel: 'Saldo',
                rightValue: formatCurrency(farm.balance),
                rightColor: balanceColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildFarmMetricRow({
    required String leftLabel,
    required String leftValue,
    required PdfColor leftColor,
    required String rightLabel,
    required String rightValue,
    required PdfColor rightColor,
  }) {
    return pw.TableRow(
      children: [
        _buildFarmMetricLabelCell(leftLabel),
        _buildFarmMetricValueCell(leftValue, leftColor),
        _buildFarmMetricLabelCell(rightLabel),
        _buildFarmMetricValueCell(rightValue, rightColor),
      ],
    );
  }

  pw.Widget _buildFarmMetricLabelCell(String label) {
    return pw.Container(
      color: lightGray,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: pw.Text(
        label,
        style: const pw.TextStyle(color: grayText, fontSize: 7.5),
      ),
    );
  }

  pw.Widget _buildFarmMetricValueCell(String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: pw.Text(
        value,
        maxLines: 1,
        style: pw.TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildManagementDiagnosis({required ReportPdfData report}) {
    final insights = buildPdfManagementInsights(report);

    return pw.Column(
      children: List.generate(insights.length, (index) {
        final insight = insights[index];
        final color = pdfInsightColor(insight.severity);

        return pw.Padding(
          padding: pw.EdgeInsets.only(
            bottom: index == insights.length - 1 ? 0 : 9,
          ),
          child: pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: color, width: 0.7),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 28,
                  height: 28,
                  decoration: pw.BoxDecoration(
                    color: color.shade(0.12),
                    borderRadius: pw.BorderRadius.circular(7),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${index + 1}',
                      style: pw.TextStyle(
                        color: color,
                        fontSize: 9,
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
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              insight.title,
                              style: pw.TextStyle(
                                color: darkText,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: color.shade(0.10),
                              borderRadius: pw.BorderRadius.circular(7),
                            ),
                            child: pw.Text(
                              pdfInsightSeverityLabel(insight.severity),
                              style: pw.TextStyle(
                                color: color,
                                fontSize: 6.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        insight.message,
                        style: const pw.TextStyle(
                          color: grayText,
                          fontSize: 8,
                          lineSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Recomendação: ${insight.recommendation}',
                        style: pw.TextStyle(
                          color: color,
                          fontSize: 8,
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
    );
  }

  pw.Widget _buildActionPlan({required ReportPdfData report}) {
    final actions = buildPdfManagementInsights(
      report,
    ).map(PdfActionPlanItem.fromInsight).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: borderGray, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.7),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(4.2),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.9),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: forestGreen),
          children: [
            _buildTableHeaderCell('Nº'),
            _buildTableHeaderCell('Problema'),
            _buildTableHeaderCell('Ação recomendada'),
            _buildTableHeaderCell('Prazo'),
            _buildTableHeaderCell('Responsável'),
          ],
        ),
        ...List.generate(actions.length, (index) {
          final action = actions[index];
          final color = pdfActionDeadlineColor(action.deadline);

          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}', center: true, bold: true),
              _buildTableCell(action.title, bold: true, color: color),
              _buildTableCell(action.action),
              _buildTableCell(
                action.deadlineText,
                center: true,
                bold: true,
                color: color,
              ),
              _buildTableCell(action.responsible),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildClosingNote({required ReportPdfData report}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: lightGreen,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: forestGreen, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Observação gerencial',
            style: pw.TextStyle(
              color: forestGreen,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            buildManagementInsight(report),
            style: const pw.TextStyle(
              color: darkText,
              fontSize: 9,
              lineSpacing: 3,
            ),
          ),
          pw.SizedBox(height: 9),
          pw.Text(
            'Este documento foi gerado automaticamente com base '
            'nos dados cadastrados no Projeto Atlas.',
            style: const pw.TextStyle(color: grayText, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEmptyMessage(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Text(
        message,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(color: grayText, fontSize: 9),
      ),
    );
  }

  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    PdfColor color = darkText,
    bool bold = false,
    bool center = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String createFileName(ReportPdfData report) {
    final farmName = report.farmFilter.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    final date = report.issueDate.replaceAll('/', '-').replaceAll(' ', '_');

    return 'relatorio_atlas_${farmName}_$date.pdf';
  }
}

class ReportPdfData {
  const ReportPdfData({
    required this.reportTitle,
    required this.farmFilter,
    required this.periodLabel,
    required this.issueDate,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalInventoryValue,
    required this.totalAgendaTasks,
    required this.lowStockCount,
    required this.expiredItemsCount,
    required this.overdueTasksCount,
    required this.urgentTasksCount,
    required this.expenseCategories,
    required this.farms,
    required this.financialRanking,
    required this.inventoryRanking,
  });

  final String reportTitle;
  final String farmFilter;
  final String periodLabel;
  final String issueDate;

  final double totalIncome;
  final double totalExpenses;
  final double totalInventoryValue;

  final int totalAgendaTasks;
  final int lowStockCount;
  final int expiredItemsCount;
  final int overdueTasksCount;
  final int urgentTasksCount;

  final List<CategoryPdfData> expenseCategories;
  final List<FarmPdfSummary> farms;
  final List<FarmPdfSummary> financialRanking;
  final List<FarmPdfSummary> inventoryRanking;

  double get totalBalance {
    return totalIncome - totalExpenses;
  }
}

class FarmPdfSummary {
  const FarmPdfSummary({
    required this.name,
    required this.city,
    required this.state,
    required this.area,
    required this.income,
    required this.expenses,
    required this.inventoryValue,
    required this.inventoryItemsCount,
    required this.lowStockCount,
    required this.expiredItemsCount,
    required this.pendingTasksCount,
    required this.overdueTasksCount,
    required this.urgentTasksCount,
  });

  final String name;
  final String city;
  final String state;
  final double area;

  final double income;
  final double expenses;
  final double inventoryValue;

  final int inventoryItemsCount;
  final int lowStockCount;
  final int expiredItemsCount;
  final int pendingTasksCount;
  final int overdueTasksCount;
  final int urgentTasksCount;

  double get balance {
    return income - expenses;
  }
}

class CategoryPdfData {
  const CategoryPdfData({required this.name, required this.value});

  final String name;
  final double value;
}

class ReportAlertPdfData {
  const ReportAlertPdfData({
    required this.title,
    required this.value,
    required this.description,
    required this.severity,
  });

  final String title;
  final int value;
  final String description;
  final ReportAlertSeverity severity;
}

enum ReportAlertSeverity { normal, warning, critical }

PdfColor alertSeverityColor(ReportAlertSeverity severity) {
  switch (severity) {
    case ReportAlertSeverity.warning:
      return ReportPdfService.orange;

    case ReportAlertSeverity.critical:
      return ReportPdfService.red;

    case ReportAlertSeverity.normal:
      return ReportPdfService.forestGreen;
  }
}

String alertSeverityLabel(ReportAlertSeverity severity) {
  switch (severity) {
    case ReportAlertSeverity.warning:
      return 'ATENÇÃO';

    case ReportAlertSeverity.critical:
      return 'CRÍTICO';

    case ReportAlertSeverity.normal:
      return 'NORMAL';
  }
}

String buildManagementInsight(ReportPdfData report) {
  if (report.totalBalance < 0) {
    return 'O resultado financeiro do período está negativo em '
        '${formatCurrency(report.totalBalance.abs())}. '
        'Recomenda-se revisar as categorias com maiores despesas, '
        'os custos operacionais e a programação de pagamentos.';
  }

  if (report.overdueTasksCount > 0) {
    return 'O resultado financeiro está positivo, porém existem '
        '${report.overdueTasksCount} tarefas atrasadas. '
        'A regularização da agenda deve ser priorizada para evitar '
        'impactos nos manejos da propriedade.';
  }

  if (report.expiredItemsCount > 0) {
    return 'Foram identificados '
        '${report.expiredItemsCount} produtos vencidos. '
        'Recomenda-se separar esses itens, registrar a destinação '
        'adequada e revisar os procedimentos de controle do estoque.';
  }

  if (report.lowStockCount > 0) {
    return 'A operação apresenta resultado financeiro positivo, '
        'mas possui ${report.lowStockCount} produtos com estoque baixo. '
        'Avalie a necessidade de reposição conforme o planejamento '
        'sanitário, nutricional e operacional.';
  }

  if (report.urgentTasksCount > 0) {
    return 'Existem ${report.urgentTasksCount} tarefas urgentes abertas. '
        'Confirme os responsáveis, materiais necessários e prazos '
        'para garantir a execução das atividades.';
  }

  return 'Os dados disponíveis não apresentam pendências críticas. '
      'Mantenha os registros financeiros, o estoque e a agenda '
      'atualizados para preservar a qualidade dos indicadores.';
}

class PdfManagementInsight {
  const PdfManagementInsight({
    required this.title,
    required this.message,
    required this.recommendation,
    required this.severity,
    required this.priority,
  });

  final String title;
  final String message;
  final String recommendation;
  final PdfInsightSeverity severity;
  final int priority;
}

enum PdfInsightSeverity { normal, warning, critical }

enum PdfActionDeadline { immediate, shortTerm, monitoring }

class PdfActionPlanItem {
  const PdfActionPlanItem({
    required this.title,
    required this.action,
    required this.deadline,
    required this.deadlineText,
    required this.responsible,
  });

  factory PdfActionPlanItem.fromInsight(PdfManagementInsight insight) {
    final deadline = pdfDeadlineFromInsight(insight);

    return PdfActionPlanItem(
      title: insight.title,
      action: insight.recommendation,
      deadline: deadline,
      deadlineText: pdfSuggestedDeadlineText(deadline),
      responsible: pdfSuggestedResponsible(insight.title),
    );
  }

  final String title;
  final String action;
  final PdfActionDeadline deadline;
  final String deadlineText;
  final String responsible;
}

List<PdfManagementInsight> buildPdfManagementInsights(ReportPdfData report) {
  final insights = <PdfManagementInsight>[];

  final negativeFarms = report.farms.where((farm) {
    return farm.balance < 0;
  }).length;

  if (report.totalBalance < 0) {
    insights.add(
      PdfManagementInsight(
        title: 'Resultado financeiro negativo',
        message:
            'As despesas superaram as receitas em '
            '${formatCurrency(report.totalBalance.abs())}.',
        recommendation:
            'Revisar os maiores centros de custo, adiar gastos não essenciais '
            'e elaborar um plano de recuperação do caixa.',
        severity: PdfInsightSeverity.critical,
        priority: 100,
      ),
    );
  }

  if (report.totalIncome == 0 && report.totalExpenses > 0) {
    insights.add(
      const PdfManagementInsight(
        title: 'Ausência de receitas no período',
        message:
            'Foram registradas despesas, mas nenhuma receita foi identificada.',
        recommendation:
            'Verificar se as vendas e demais entradas foram cadastradas '
            'e revisar o planejamento comercial da propriedade.',
        severity: PdfInsightSeverity.critical,
        priority: 95,
      ),
    );
  }

  if (report.overdueTasksCount > 0) {
    insights.add(
      PdfManagementInsight(
        title: 'Atividades atrasadas',
        message:
            '${report.overdueTasksCount} '
            '${report.overdueTasksCount == 1 ? 'atividade está' : 'atividades estão'} '
            'fora do prazo.',
        recommendation:
            'Reorganizar a agenda, definir responsáveis e concluir primeiro '
            'as tarefas de maior impacto sanitário ou produtivo.',
        severity: PdfInsightSeverity.critical,
        priority: 88,
      ),
    );
  }

  if (report.urgentTasksCount > 0) {
    insights.add(
      PdfManagementInsight(
        title: 'Prioridades urgentes abertas',
        message:
            '${report.urgentTasksCount} '
            '${report.urgentTasksCount == 1 ? 'tarefa urgente permanece aberta' : 'tarefas urgentes permanecem abertas'}.',
        recommendation:
            'Confirmar imediatamente responsáveis, materiais necessários '
            'e prazos de execução.',
        severity: PdfInsightSeverity.critical,
        priority: 86,
      ),
    );
  }

  if (report.expiredItemsCount > 0) {
    insights.add(
      PdfManagementInsight(
        title: 'Produtos vencidos no estoque',
        message:
            '${report.expiredItemsCount} '
            '${report.expiredItemsCount == 1 ? 'produto vencido foi identificado' : 'produtos vencidos foram identificados'}.',
        recommendation:
            'Separar os itens, registrar a destinação correta e revisar '
            'o controle de validade do estoque.',
        severity: PdfInsightSeverity.critical,
        priority: 84,
      ),
    );
  }

  if (negativeFarms > 0) {
    insights.add(
      PdfManagementInsight(
        title: 'Propriedades com resultado negativo',
        message:
            '$negativeFarms de ${report.farms.length} '
            '${negativeFarms == 1 ? 'propriedade apresenta' : 'propriedades apresentam'} '
            'resultado financeiro negativo.',
        recommendation:
            'Analisar as propriedades separadamente, comparar custos por '
            'hectare e definir planos de ação específicos.',
        severity: negativeFarms == report.farms.length
            ? PdfInsightSeverity.critical
            : PdfInsightSeverity.warning,
        priority: 75,
      ),
    );
  }

  if (report.lowStockCount > 0) {
    insights.add(
      PdfManagementInsight(
        title: 'Produtos com estoque baixo',
        message:
            '${report.lowStockCount} '
            '${report.lowStockCount == 1 ? 'produto está' : 'produtos estão'} '
            'no nível mínimo ou abaixo.',
        recommendation:
            'Avaliar a reposição conforme o calendário sanitário, nutricional '
            'e operacional.',
        severity: PdfInsightSeverity.warning,
        priority: 65,
      ),
    );
  }

  if (insights.isEmpty) {
    insights.add(
      const PdfManagementInsight(
        title: 'Operação sem pendências críticas',
        message:
            'Os dados do relatório não apresentam alertas financeiros, '
            'operacionais ou de estoque relevantes.',
        recommendation:
            'Manter os registros atualizados e acompanhar periodicamente '
            'os indicadores da operação.',
        severity: PdfInsightSeverity.normal,
        priority: 10,
      ),
    );
  }

  insights.sort((first, second) => second.priority.compareTo(first.priority));

  return insights.take(6).toList();
}

PdfActionDeadline pdfDeadlineFromInsight(PdfManagementInsight insight) {
  if (insight.severity == PdfInsightSeverity.critical ||
      insight.priority >= 85) {
    return PdfActionDeadline.immediate;
  }

  if (insight.severity == PdfInsightSeverity.warning ||
      insight.priority >= 60) {
    return PdfActionDeadline.shortTerm;
  }

  return PdfActionDeadline.monitoring;
}

String pdfSuggestedDeadlineText(PdfActionDeadline deadline) {
  switch (deadline) {
    case PdfActionDeadline.immediate:
      return 'Até 48 h';
    case PdfActionDeadline.shortTerm:
      return 'Até 7 dias';
    case PdfActionDeadline.monitoring:
      return 'Próxima revisão';
  }
}

String pdfSuggestedResponsible(String title) {
  final normalized = title.toLowerCase();

  if (normalized.contains('financeir') ||
      normalized.contains('receita') ||
      normalized.contains('despesa')) {
    return 'Gestor financeiro';
  }

  if (normalized.contains('estoque') || normalized.contains('produto')) {
    return 'Responsável pelo estoque';
  }

  if (normalized.contains('atividade') ||
      normalized.contains('tarefa') ||
      normalized.contains('prioridade')) {
    return 'Gerente da fazenda';
  }

  if (normalized.contains('propriedade')) {
    return 'Consultor e gestor';
  }

  return 'Gestor responsável';
}

PdfColor pdfInsightColor(PdfInsightSeverity severity) {
  switch (severity) {
    case PdfInsightSeverity.normal:
      return ReportPdfService.forestGreen;
    case PdfInsightSeverity.warning:
      return ReportPdfService.orange;
    case PdfInsightSeverity.critical:
      return ReportPdfService.red;
  }
}

String pdfInsightSeverityLabel(PdfInsightSeverity severity) {
  switch (severity) {
    case PdfInsightSeverity.normal:
      return 'POSITIVO';
    case PdfInsightSeverity.warning:
      return 'ATENÇÃO';
    case PdfInsightSeverity.critical:
      return 'CRÍTICO';
  }
}

PdfColor pdfActionDeadlineColor(PdfActionDeadline deadline) {
  switch (deadline) {
    case PdfActionDeadline.immediate:
      return ReportPdfService.red;
    case PdfActionDeadline.shortTerm:
      return ReportPdfService.orange;
    case PdfActionDeadline.monitoring:
      return ReportPdfService.blue;
  }
}

String formatCurrency(double value) {
  final negative = value < 0;
  final absoluteValue = value.abs();

  final parts = absoluteValue.toStringAsFixed(2).split('.');

  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();

  for (var index = 0; index < integerPart.length; index++) {
    final positionFromEnd = integerPart.length - index;

    buffer.write(integerPart[index]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  final formatted = 'R\$ ${buffer.toString()},$decimalPart';

  return negative ? '-$formatted' : formatted;
}

String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String formatPercentage(double value) {
  return '${value.toStringAsFixed(1).replaceAll('.', ',')}%';
}
