import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_chart_widgets.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_period_comparison_card.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_management_insights_card.dart';
import 'package:projeto_atlas/features/reports/presentation/widgets/report_action_plan_card.dart';
import 'package:projeto_atlas/features/reports/data/services/report_pdf_service.dart'
    as report_pdf;
import 'package:projeto_atlas/features/reports/data/services/report_excel_service.dart'
    as report_excel;
import 'package:projeto_atlas/features/reports/data/services/report_action_storage_service.dart';
import 'package:projeto_atlas/features/reports/data/services/report_action_history_storage_service.dart';
import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';
import 'package:projeto_atlas/features/reports/presentation/screens/report_action_list_screen.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_agenda/data/services/farm_agenda_storage_service.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() {
    return _ReportsScreenState();
  }
}

class _ReportsScreenState extends State<ReportsScreen> {
  final report_pdf.ReportPdfService pdfService = report_pdf.ReportPdfService();

  final report_excel.ReportExcelService excelService =
      report_excel.ReportExcelService();

  final ReportActionStorageService actionStorage = ReportActionStorageService();

  final ReportActionHistoryStorageService actionHistoryStorage =
      ReportActionHistoryStorageService();

  final FarmStorageService farmStorage = FarmStorageService();

  final FarmFinanceStorageService financeStorage = FarmFinanceStorageService();

  final FarmInventoryStorageService inventoryStorage =
      FarmInventoryStorageService();

  final FarmAgendaStorageService agendaStorage = FarmAgendaStorageService();

  List<FarmReportData> allFarmReports = [];

  bool isLoading = true;
  bool isExporting = false;

  String selectedFarmName = 'Todas';
  String selectedPeriod = 'Todos';

  DateTime? customStartDate;
  DateTime? customEndDate;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  List<FarmReportData> get visibleFarmReports {
    if (selectedFarmName == 'Todas') {
      return allFarmReports;
    }

    return allFarmReports.where((report) {
      return report.farm.name == selectedFarmName;
    }).toList();
  }

  List<FarmReportData> get filteredReports {
    return visibleFarmReports.map((report) {
      return report.copyWith(
        financeRecords: report.financeRecords.where((record) {
          return isDateInsideSelectedPeriod(record.date);
        }).toList(),
        agendaTasks: report.agendaTasks.where((task) {
          return isDateInsideSelectedPeriod(task.date);
        }).toList(),
      );
    }).toList();
  }

  DateTime? get periodStartDate {
    final today = reportToday();

    switch (selectedPeriod) {
      case 'Mês atual':
        return DateTime(today.year, today.month, 1);

      case 'Últimos 30 dias':
        return today.subtract(const Duration(days: 29));

      case 'Ano atual':
        return DateTime(today.year, 1, 1);

      case 'Personalizado':
        return customStartDate;

      default:
        return null;
    }
  }

  DateTime? get periodEndDate {
    final today = reportToday();

    if (selectedPeriod == 'Personalizado') {
      return customEndDate;
    }

    if (selectedPeriod == 'Todos') {
      return null;
    }

    return today;
  }

  double get totalIncome {
    return filteredReports.fold<double>(0, (total, report) {
      return total + report.totalIncome;
    });
  }

  double get totalExpenses {
    return filteredReports.fold<double>(0, (total, report) {
      return total + report.totalExpenses;
    });
  }

  double get totalBalance {
    return totalIncome - totalExpenses;
  }

  double get totalInventoryValue {
    return visibleFarmReports.fold<double>(0, (total, report) {
      return total + report.inventoryValue;
    });
  }

  int get totalInventoryItems {
    return visibleFarmReports.fold<int>(0, (total, report) {
      return total + report.inventoryItems.length;
    });
  }

  int get totalLowStock {
    return visibleFarmReports.fold<int>(0, (total, report) {
      return total + report.lowStockCount;
    });
  }

  int get totalExpiredItems {
    return visibleFarmReports.fold<int>(0, (total, report) {
      return total + report.expiredCount;
    });
  }

  int get totalAgendaTasks {
    return filteredReports.fold<int>(0, (total, report) {
      return total + report.agendaTasks.length;
    });
  }

  int get totalPendingTasks {
    return filteredReports.fold<int>(0, (total, report) {
      return total + report.pendingCount;
    });
  }

  int get totalOverdueTasks {
    return filteredReports.fold<int>(0, (total, report) {
      return total + report.overdueCount;
    });
  }

  int get totalUrgentTasks {
    return filteredReports.fold<int>(0, (total, report) {
      return total + report.urgentCount;
    });
  }

  int get totalAlerts {
    return totalLowStock +
        totalExpiredItems +
        totalOverdueTasks +
        totalUrgentTasks;
  }

  List<CategoryReportData> get expenseCategories {
    final totals = <String, double>{};

    for (final report in filteredReports) {
      for (final record in report.financeRecords) {
        if (!record.isExpense) {
          continue;
        }

        final category = AtlasUiText.category(record.category);
        totals.update(
          category,
          (value) => value + record.amount,
          ifAbsent: () => record.amount,
        );
      }
    }

    final categories = totals.entries.map((entry) {
      return CategoryReportData(name: entry.key, value: entry.value);
    }).toList();

    categories.sort((first, second) {
      return second.value.compareTo(first.value);
    });

    return categories;
  }

  DateTimeRange? get effectiveCurrentComparisonRange {
    if (selectedPeriod != 'Todos') {
      final start = periodStartDate;
      final end = periodEndDate;

      if (start == null || end == null) {
        return null;
      }

      return DateTimeRange(
        start: normalizeDate(start),
        end: normalizeDate(end),
      );
    }

    final dates = <DateTime>[];

    for (final report in visibleFarmReports) {
      for (final record in report.financeRecords) {
        final date = parseReportDate(record.date);

        if (date != null) {
          dates.add(date);
        }
      }
    }

    if (dates.isEmpty) {
      return null;
    }

    dates.sort();

    return DateTimeRange(start: dates.first, end: dates.last);
  }

  DateTimeRange? get previousComparisonRange {
    final currentRange = effectiveCurrentComparisonRange;

    if (currentRange == null) {
      return null;
    }

    final durationInDays =
        currentRange.end.difference(currentRange.start).inDays + 1;

    final previousEnd = currentRange.start.subtract(const Duration(days: 1));

    final previousStart = previousEnd.subtract(
      Duration(days: durationInDays - 1),
    );

    return DateTimeRange(start: previousStart, end: previousEnd);
  }

  ReportPeriodComparisonData get periodComparisonData {
    final currentRange = effectiveCurrentComparisonRange;

    final previousRange = previousComparisonRange;

    if (currentRange == null || previousRange == null) {
      return const ReportPeriodComparisonData(
        currentIncome: 0,
        previousIncome: 0,
        currentExpenses: 0,
        previousExpenses: 0,
      );
    }

    final currentTotals = calculateFinancialTotals(currentRange);

    final previousTotals = calculateFinancialTotals(previousRange);

    return ReportPeriodComparisonData(
      currentIncome: currentTotals.income,
      previousIncome: previousTotals.income,
      currentExpenses: currentTotals.expenses,
      previousExpenses: previousTotals.expenses,
    );
  }

  _PeriodFinancialTotals calculateFinancialTotals(DateTimeRange range) {
    var income = 0.0;
    var expenses = 0.0;

    for (final report in visibleFarmReports) {
      for (final record in report.financeRecords) {
        final date = parseReportDate(record.date);

        if (date == null ||
            date.isBefore(range.start) ||
            date.isAfter(range.end)) {
          continue;
        }

        if (record.isIncome) {
          income += record.amount;
        }

        if (record.isExpense) {
          expenses += record.amount;
        }
      }
    }

    return _PeriodFinancialTotals(income: income, expenses: expenses);
  }

  String get currentComparisonLabel {
    final range = effectiveCurrentComparisonRange;

    if (range == null) {
      return 'Período atual';
    }

    return formatComparisonRange(range);
  }

  String get previousComparisonLabel {
    final range = previousComparisonRange;

    if (range == null) {
      return 'Período anterior';
    }

    return formatComparisonRange(range);
  }

  ReportManagementInsightData get managementInsightData {
    final comparison = periodComparisonData;

    final negativeFarms = filteredReports.where((report) {
      return report.balance < 0;
    }).length;

    return ReportManagementInsightData(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      previousIncome: comparison.previousIncome,
      previousExpenses: comparison.previousExpenses,
      lowStockCount: totalLowStock,
      expiredItemsCount: totalExpiredItems,
      overdueTasksCount: totalOverdueTasks,
      urgentTasksCount: totalUrgentTasks,
      negativeFarmsCount: negativeFarms,
      totalFarmsCount: filteredReports.length,
    );
  }

  List<ReportMonthlyPoint> get monthlyChartPoints {
    final monthlyValues = <DateTime, _MonthlyChartAccumulator>{};

    for (final report in filteredReports) {
      for (final record in report.financeRecords) {
        final date = parseReportDate(record.date);

        if (date == null) {
          continue;
        }

        final month = DateTime(date.year, date.month);

        final accumulator = monthlyValues.putIfAbsent(
          month,
          _MonthlyChartAccumulator.new,
        );

        if (record.isIncome) {
          accumulator.income += record.amount;
        }

        if (record.isExpense) {
          accumulator.expenses += record.amount;
        }
      }
    }

    final months = monthlyValues.keys.toList()..sort();

    final visibleMonths = months.length > 12
        ? months.sublist(months.length - 12)
        : months;

    return visibleMonths.map((month) {
      final accumulator = monthlyValues[month]!;

      return ReportMonthlyPoint(
        label: formatChartMonth(month),
        income: accumulator.income,
        expenses: accumulator.expenses,
      );
    }).toList();
  }

  List<ReportCategoryPoint> get categoryChartPoints {
    return expenseCategories.map((category) {
      return ReportCategoryPoint(label: category.name, value: category.value);
    }).toList();
  }

  List<ReportFarmComparisonPoint> get farmComparisonPoints {
    final points = filteredReports.map((report) {
      return ReportFarmComparisonPoint(
        farmName: report.farm.name,
        income: report.totalIncome,
        expenses: report.totalExpenses,
      );
    }).toList();

    points.sort((first, second) {
      return second.balance.compareTo(first.balance);
    });

    return points;
  }

  List<FarmReportData> get financialRanking {
    final reports = List<FarmReportData>.from(filteredReports);

    reports.sort((first, second) {
      return second.balance.compareTo(first.balance);
    });

    return reports;
  }

  List<FarmReportData> get inventoryRanking {
    final reports = List<FarmReportData>.from(visibleFarmReports);

    reports.sort((first, second) {
      return second.inventoryValue.compareTo(first.inventoryValue);
    });

    return reports;
  }

  Future<void> loadReports() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final farms = await farmStorage.loadFarms();

    final reports = await Future.wait(
      farms.map((farm) async {
        final results = await Future.wait<dynamic>([
          financeStorage.loadRecords(farm.name),
          inventoryStorage.loadItems(farm.name),
          agendaStorage.loadTasks(farm.name),
        ]);

        return FarmReportData(
          farm: farm,
          financeRecords: results[0] as List<FarmFinanceData>,
          inventoryItems: results[1] as List<FarmInventoryData>,
          agendaTasks: results[2] as List<FarmAgendaData>,
        );
      }),
    );

    reports.sort((first, second) {
      return first.farm.name.toLowerCase().compareTo(
        second.farm.name.toLowerCase(),
      );
    });

    if (!mounted) {
      return;
    }

    setState(() {
      allFarmReports = reports;

      if (selectedFarmName != 'Todas' &&
          !reports.any((report) => report.farm.name == selectedFarmName)) {
        selectedFarmName = 'Todas';
      }

      isLoading = false;
    });
  }

  bool isDateInsideSelectedPeriod(String dateText) {
    if (selectedPeriod == 'Todos') {
      return true;
    }

    final date = parseReportDate(dateText);

    if (date == null) {
      return false;
    }

    final start = periodStartDate;
    final end = periodEndDate;

    if (start != null && date.isBefore(normalizeDate(start))) {
      return false;
    }

    if (end != null && date.isAfter(normalizeDate(end))) {
      return false;
    }

    return true;
  }

  Future<void> selectCustomPeriod() async {
    final today = reportToday();

    final initialRange = DateTimeRange(
      start: customStartDate ?? today.subtract(const Duration(days: 29)),
      end: customEndDate ?? today,
    );

    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: initialRange,
      helpText: 'Selecionar período',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      fieldStartHintText: 'Data inicial',
      fieldEndHintText: 'Data final',
      fieldStartLabelText: 'Início',
      fieldEndLabelText: 'Fim',
    );

    if (selectedRange == null || !mounted) {
      return;
    }

    setState(() {
      selectedPeriod = 'Personalizado';
      customStartDate = normalizeDate(selectedRange.start);
      customEndDate = normalizeDate(selectedRange.end);
    });
  }

  void changePeriod(String period) {
    if (period == 'Personalizado') {
      selectCustomPeriod();
      return;
    }

    setState(() {
      selectedPeriod = period;
      customStartDate = null;
      customEndDate = null;
    });
  }

  void clearFilters() {
    setState(() {
      selectedFarmName = 'Todas';
      selectedPeriod = 'Todos';
      customStartDate = null;
      customEndDate = null;
    });
  }

  void showReportInformation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Relatório gerencial'),
          content: const Text(
            'Os filtros de período são aplicados aos lançamentos '
            'financeiros e aos compromissos da agenda. O estoque '
            'representa a posição atual cadastrada em cada propriedade.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
              ),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  report_pdf.ReportPdfData buildExportReportData() {
    return report_pdf.ReportPdfData(
      reportTitle: 'Relatório Gerencial Pecuário',
      farmFilter: selectedFarmName == 'Todas'
          ? 'Todas as propriedades'
          : selectedFarmName,
      periodLabel: selectedPeriodLabel,
      issueDate: formatDate(DateTime.now()),
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalInventoryValue: totalInventoryValue,
      totalAgendaTasks: totalAgendaTasks,
      lowStockCount: totalLowStock,
      expiredItemsCount: totalExpiredItems,
      overdueTasksCount: totalOverdueTasks,
      urgentTasksCount: totalUrgentTasks,
      expenseCategories: expenseCategories.map((category) {
        return report_pdf.CategoryPdfData(
          name: category.name,
          value: category.value,
        );
      }).toList(),
      farms: filteredReports.map(_toPdfSummary).toList(),
      financialRanking: financialRanking.map(_toPdfSummary).toList(),
      inventoryRanking: inventoryRanking.map(_toPdfSummary).toList(),
    );
  }

  Future<void> exportPdfReport() async {
    if (filteredReports.isEmpty) {
      showNoExportDataMessage();
      return;
    }

    setState(() {
      isExporting = true;
    });

    try {
      await pdfService.printReport(report: buildExportReportData());
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  Future<void> exportExcelReport() async {
    if (filteredReports.isEmpty) {
      showNoExportDataMessage();
      return;
    }

    setState(() {
      isExporting = true;
    });

    try {
      await excelService.exportReport(report: buildExportReportData());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório em Excel gerado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o Excel: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  void showNoExportDataMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não há dados disponíveis para gerar o relatório.'),
      ),
    );
  }

  report_pdf.FarmPdfSummary _toPdfSummary(FarmReportData report) {
    return report_pdf.FarmPdfSummary(
      name: report.farm.name,
      city: report.farm.city,
      state: report.farm.state,
      area: report.farm.area.toDouble(),
      income: report.totalIncome,
      expenses: report.totalExpenses,
      inventoryValue: report.inventoryValue,
      inventoryItemsCount: report.inventoryItems.length,
      lowStockCount: report.lowStockCount,
      expiredItemsCount: report.expiredCount,
      pendingTasksCount: report.pendingCount,
      overdueTasksCount: report.overdueCount,
      urgentTasksCount: report.urgentCount,
    );
  }

  Future<void> openSavedActions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const ReportActionListScreen();
        },
      ),
    );
  }

  Future<void> saveGeneratedActions() async {
    final insights = buildManagementInsights(managementInsightData);

    if (insights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma recomendação foi encontrada para salvar.'),
        ),
      );
      return;
    }

    final existingActions = await actionStorage.loadActions();

    final farmScope = selectedFarmName == 'Todas'
        ? 'Todas as propriedades'
        : selectedFarmName;

    final source = 'Relatório · $selectedPeriodLabel';

    final existingKeys = existingActions.map((action) {
      return '${action.farmName}|${action.title}|${action.source}'
          .trim()
          .toLowerCase();
    }).toSet();

    final createdAt = formatActionDate(DateTime.now());

    final actionsToSave = <ReportActionItemData>[];

    for (final insight in insights) {
      final planItem = ReportActionPlanItem.fromInsight(insight);

      final key = '$farmScope|${planItem.title}|$source'.trim().toLowerCase();

      if (existingKeys.contains(key)) {
        continue;
      }

      actionsToSave.add(
        ReportActionItemData(
          id: createReportActionId(),
          farmName: farmScope,
          title: planItem.title,
          action: planItem.action,
          responsible: planItem.suggestedResponsible,
          deadline: actionDeadlineDate(planItem.deadline),
          priority: planItem.priorityLabel,
          status: 'Pendente',
          createdAt: createdAt,
          completedAt: '',
          notes:
              'Ação gerada automaticamente pelo Diagnóstico Gerencial Atlas.',
          source: source,
        ),
      );

      existingKeys.add(key);
    }

    if (actionsToSave.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As recomendações deste relatório já estão salvas.'),
        ),
      );
      return;
    }

    await actionStorage.addActions(actionsToSave);

    for (final action in actionsToSave) {
      await actionHistoryStorage.registerCreation(
        actionId: action.id,
        actionTitle: action.title,
        source: source,
        createdBy: 'Gabriel Beserra',
      );
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          actionsToSave.length == 1
              ? '1 ação foi salva para acompanhamento.'
              : '${actionsToSave.length} ações foram salvas para acompanhamento.',
        ),
        action: SnackBarAction(label: 'ABRIR', onPressed: openSavedActions),
      ),
    );
  }

  String actionDeadlineDate(ReportActionDeadline deadline) {
    final now = DateTime.now();

    switch (deadline) {
      case ReportActionDeadline.immediate:
        return formatActionDate(now.add(const Duration(days: 2)));

      case ReportActionDeadline.shortTerm:
        return formatActionDate(now.add(const Duration(days: 7)));

      case ReportActionDeadline.monitoring:
        return formatActionDate(now.add(const Duration(days: 30)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = expenseCategories;
    final financeRanking = financialRanking;
    final stockRanking = inventoryRanking;
    final monthlyPoints = monthlyChartPoints;
    final categoryPoints = categoryChartPoints;
    final comparisonPoints = farmComparisonPoints;
    final comparisonData = periodComparisonData;
    final insightData = managementInsightData;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Relatórios',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Ações gerenciais salvas',
            onPressed: openSavedActions,
            icon: const Icon(Icons.assignment_turned_in_outlined),
          ),
          if (isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            PopupMenuButton<ReportExportType>(
              tooltip: 'Exportar relatório',
              enabled: !isLoading,
              icon: const Icon(Icons.download_outlined),
              onSelected: (type) {
                switch (type) {
                  case ReportExportType.pdf:
                    exportPdfReport();
                    break;
                  case ReportExportType.excel:
                    exportExcelReport();
                    break;
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem<ReportExportType>(
                    value: ReportExportType.pdf,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Color(0xFFC62828),
                      ),
                      title: Text('Exportar em PDF'),
                      subtitle: Text('Visualizar, imprimir ou salvar'),
                    ),
                  ),
                  PopupMenuItem<ReportExportType>(
                    value: ReportExportType.excel,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.table_chart_outlined,
                        color: Color(0xFF1B5E20),
                      ),
                      title: Text('Exportar em Excel'),
                      subtitle: Text('Gerar planilha com várias abas'),
                    ),
                  ),
                ];
              },
            ),
          IconButton(
            tooltip: 'Informações do relatório',
            onPressed: showReportInformation,
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : loadReports,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadReports,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        ReportsHeader(
                          farmCount: visibleFarmReports.length,
                          balance: totalBalance,
                          alertCount: totalAlerts,
                          periodLabel: selectedPeriodLabel,
                        ),
                        const SizedBox(height: 24),
                        ReportsFilterCard(
                          reports: allFarmReports,
                          selectedFarmName: selectedFarmName,
                          selectedPeriod: selectedPeriod,
                          customStartDate: customStartDate,
                          customEndDate: customEndDate,
                          onFarmChanged: (value) {
                            setState(() {
                              selectedFarmName = value;
                            });
                          },
                          onPeriodChanged: changePeriod,
                          onClearFilters: clearFilters,
                        ),
                        const SizedBox(height: 28),
                        const ReportsSectionTitle(
                          title: 'Resumo consolidado',
                          subtitle:
                              'Visão geral conforme os filtros selecionados.',
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ReportMetricCard(
                              title: 'Fazendas',
                              value: visibleFarmReports.length.toString(),
                              subtitle: 'Propriedades no relatório',
                              icon: Icons.home_work_outlined,
                              color: const Color(0xFF1B5E20),
                            ),
                            ReportMetricCard(
                              title: 'Receitas',
                              value: formatCurrency(totalIncome),
                              subtitle: 'Entradas no período',
                              icon: Icons.trending_up_outlined,
                              color: const Color(0xFF1B5E20),
                            ),
                            ReportMetricCard(
                              title: 'Despesas',
                              value: formatCurrency(totalExpenses),
                              subtitle: 'Saídas no período',
                              icon: Icons.trending_down_outlined,
                              color: Colors.red.shade700,
                            ),
                            ReportMetricCard(
                              title: 'Resultado',
                              value: formatCurrency(totalBalance),
                              subtitle: totalBalance >= 0
                                  ? 'Resultado positivo'
                                  : 'Resultado negativo',
                              icon: Icons.account_balance_wallet_outlined,
                              color: totalBalance >= 0
                                  ? const Color(0xFF1B5E20)
                                  : Colors.red.shade700,
                            ),
                            ReportMetricCard(
                              title: 'Valor dos estoques',
                              value: formatCurrency(totalInventoryValue),
                              subtitle:
                                  '$totalInventoryItems produtos cadastrados',
                              icon: Icons.inventory_2_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            ReportMetricCard(
                              title: 'Compromissos',
                              value: totalAgendaTasks.toString(),
                              subtitle: '$totalPendingTasks tarefas pendentes',
                              icon: Icons.calendar_month_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const ReportsSectionTitle(
                          title: 'Distribuição financeira',
                          subtitle:
                              'Comparação entre receitas, despesas e resultado.',
                        ),
                        const SizedBox(height: 18),
                        FinancialDistributionCard(
                          income: totalIncome,
                          expenses: totalExpenses,
                          balance: totalBalance,
                        ),
                        const SizedBox(height: 32),
                        ReportPeriodComparisonCard(
                          data: comparisonData,
                          currentPeriodLabel: currentComparisonLabel,
                          previousPeriodLabel: previousComparisonLabel,
                        ),
                        const SizedBox(height: 32),
                        ReportManagementInsightsCard(data: insightData),
                        const SizedBox(height: 32),
                        ReportActionPlanCard(insightData: insightData),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 560;

                            final saveButton = FilledButton.icon(
                              onPressed: saveGeneratedActions,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                              ),
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Salvar plano de ação'),
                            );

                            final openButton = OutlinedButton.icon(
                              onPressed: openSavedActions,
                              icon: const Icon(
                                Icons.assignment_turned_in_outlined,
                              ),
                              label: const Text('Acompanhar ações'),
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  saveButton,
                                  const SizedBox(height: 10),
                                  openButton,
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                openButton,
                                const SizedBox(width: 10),
                                saveButton,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        const ReportsSectionTitle(
                          title: 'Análise gráfica',
                          subtitle:
                              'Evolução financeira, resultado acumulado e comparativos visuais.',
                        ),
                        const SizedBox(height: 18),
                        ReportFinancialEvolutionCard(points: monthlyPoints),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useRow = constraints.maxWidth >= 900;

                            final balanceChart = ReportBalanceTrendCard(
                              points: monthlyPoints,
                            );

                            final categoryChart = ReportExpenseCategoryChart(
                              categories: categoryPoints,
                            );

                            if (!useRow) {
                              return Column(
                                children: [
                                  balanceChart,
                                  const SizedBox(height: 18),
                                  categoryChart,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: balanceChart),
                                const SizedBox(width: 18),
                                Expanded(child: categoryChart),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        ReportFarmComparisonChart(farms: comparisonPoints),
                        const SizedBox(height: 32),
                        const ReportsSectionTitle(
                          title: 'Despesas por categoria',
                          subtitle:
                              'Categorias com maior participação nas despesas do período.',
                        ),
                        const SizedBox(height: 18),
                        ExpenseCategoriesCard(
                          categories: categories,
                          totalExpenses: totalExpenses,
                        ),
                        const SizedBox(height: 32),
                        const ReportsSectionTitle(
                          title: 'Alertas da operação',
                          subtitle:
                              'Pendências que precisam de acompanhamento.',
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ReportMetricCard(
                              title: 'Estoque baixo',
                              value: totalLowStock.toString(),
                              subtitle: 'Produtos no mínimo ou abaixo',
                              icon: Icons.warning_amber_outlined,
                              color: totalLowStock > 0
                                  ? const Color(0xFFEF6C00)
                                  : const Color(0xFF1B5E20),
                            ),
                            ReportMetricCard(
                              title: 'Produtos vencidos',
                              value: totalExpiredItems.toString(),
                              subtitle: 'Itens fora da validade',
                              icon: Icons.event_busy_outlined,
                              color: totalExpiredItems > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                            ReportMetricCard(
                              title: 'Tarefas atrasadas',
                              value: totalOverdueTasks.toString(),
                              subtitle: 'Compromissos fora do prazo',
                              icon: Icons.schedule_outlined,
                              color: totalOverdueTasks > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                            ReportMetricCard(
                              title: 'Tarefas urgentes',
                              value: totalUrgentTasks.toString(),
                              subtitle: 'Prioridades urgentes abertas',
                              icon: Icons.priority_high,
                              color: totalUrgentTasks > 0
                                  ? Colors.red.shade700
                                  : const Color(0xFF1B5E20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const ReportsSectionTitle(
                          title: 'Ranking financeiro',
                          subtitle:
                              'Propriedades ordenadas pelo resultado do período.',
                        ),
                        const SizedBox(height: 18),
                        RankingCard(
                          reports: financeRanking,
                          type: RankingType.finance,
                        ),
                        const SizedBox(height: 32),
                        const ReportsSectionTitle(
                          title: 'Ranking de estoque',
                          subtitle:
                              'Propriedades ordenadas pelo valor atual do estoque.',
                        ),
                        const SizedBox(height: 18),
                        RankingCard(
                          reports: stockRanking,
                          type: RankingType.inventory,
                        ),
                        const SizedBox(height: 32),
                        const ReportsSectionTitle(
                          title: 'Resultado por propriedade',
                          subtitle: 'Comparativo financeiro, estoque e agenda.',
                        ),
                        const SizedBox(height: 18),
                        if (filteredReports.isEmpty)
                          const EmptyReportsMessage()
                        else
                          ...filteredReports.map((report) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: FarmReportCard(report: report),
                            );
                          }),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String get selectedPeriodLabel {
    if (selectedPeriod != 'Personalizado') {
      return selectedPeriod;
    }

    if (customStartDate == null || customEndDate == null) {
      return 'Personalizado';
    }

    return '${formatDate(customStartDate!)} a '
        '${formatDate(customEndDate!)}';
  }
}

class ReportsFilterCard extends StatelessWidget {
  const ReportsFilterCard({
    required this.reports,
    required this.selectedFarmName,
    required this.selectedPeriod,
    required this.customStartDate,
    required this.customEndDate,
    required this.onFarmChanged,
    required this.onPeriodChanged,
    required this.onClearFilters,
    super.key,
  });

  final List<FarmReportData> reports;
  final String selectedFarmName;
  final String selectedPeriod;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final ValueChanged<String> onFarmChanged;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final farmNames = reports.map((report) => report.farm.name).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 10),
                Text(
                  'Filtros do relatório',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow = constraints.maxWidth >= 700;

                final farmField = DropdownButtonFormField<String>(
                  initialValue: selectedFarmName,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Propriedade',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'Todas',
                      child: Text('Todas as propriedades'),
                    ),
                    ...farmNames.map((farmName) {
                      return DropdownMenuItem<String>(
                        value: farmName,
                        child: Text(farmName, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onFarmChanged(value);
                    }
                  },
                );

                final periodField = DropdownButtonFormField<String>(
                  initialValue: selectedPeriod,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Período',
                    prefixIcon: Icon(Icons.date_range_outlined),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Todos',
                      child: Text('Todo o período'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Mês atual',
                      child: Text('Mês atual'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Últimos 30 dias',
                      child: Text('Últimos 30 dias'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Ano atual',
                      child: Text('Ano atual'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Personalizado',
                      child: Text('Selecionar datas'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onPeriodChanged(value);
                    }
                  },
                );

                if (!useRow) {
                  return Column(
                    children: [
                      farmField,
                      const SizedBox(height: 16),
                      periodField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: farmField),
                    const SizedBox(width: 16),
                    Expanded(child: periodField),
                  ],
                );
              },
            ),
            if (selectedPeriod == 'Personalizado' &&
                customStartDate != null &&
                customEndDate != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Período selecionado: '
                        '${formatDate(customStartDate!)} até '
                        '${formatDate(customEndDate!)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({
    required this.farmCount,
    required this.balance,
    required this.alertCount,
    required this.periodLabel,
    super.key,
  });

  final int farmCount;
  final double balance;
  final int alertCount;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Relatório gerencial',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Visão consolidada da operação atendida pela consultoria.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.date_range_outlined,
                    color: Colors.white70,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      periodLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ReportsHeaderMetric(
                value: farmCount.toString(),
                label: 'fazendas',
              ),
              ReportsHeaderMetric(
                value: formatCompactCurrency(balance),
                label: 'resultado',
              ),
              ReportsHeaderMetric(
                value: alertCount.toString(),
                label: 'alertas',
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 20), metrics],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              metrics,
            ],
          );
        },
      ),
    );
  }
}

class ReportsHeaderMetric extends StatelessWidget {
  const ReportsHeaderMetric({
    required this.value,
    required this.label,
    super.key,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ReportsSectionTitle extends StatelessWidget {
  const ReportsSectionTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF263238),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class ReportMetricCard extends StatelessWidget {
  const ReportMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinancialDistributionCard extends StatelessWidget {
  const FinancialDistributionCard({
    required this.income,
    required this.expenses,
    required this.balance,
    super.key,
  });

  final double income;
  final double expenses;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final largestValue = [income.abs(), expenses.abs()].fold<double>(0, (
      largest,
      value,
    ) {
      return value > largest ? value : largest;
    });

    final incomeProgress = largestValue == 0 ? 0.0 : income / largestValue;

    final expenseProgress = largestValue == 0 ? 0.0 : expenses / largestValue;

    final balanceColor = balance >= 0
        ? const Color(0xFF1B5E20)
        : Colors.red.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            FinancialProgressRow(
              label: 'Receitas',
              value: income,
              progress: incomeProgress,
              color: const Color(0xFF1B5E20),
            ),
            const SizedBox(height: 20),
            FinancialProgressRow(
              label: 'Despesas',
              value: expenses,
              progress: expenseProgress,
              color: Colors.red.shade700,
            ),
            const Divider(height: 36),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resultado do período',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatCurrency(balance),
                  style: TextStyle(
                    color: balanceColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialProgressRow extends StatelessWidget {
  const FinancialProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    super.key,
  });

  final String label;
  final double value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              formatCurrency(value),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class ExpenseCategoriesCard extends StatelessWidget {
  const ExpenseCategoriesCard({
    required this.categories,
    required this.totalExpenses,
    super.key,
  });

  final List<CategoryReportData> categories;
  final double totalExpenses;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Row(
            children: [
              Icon(Icons.pie_chart_outline, color: Color(0xFF1B5E20), size: 38),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Nenhuma despesa foi encontrada no período selecionado.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleCategories = categories.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: List.generate(visibleCategories.length, (index) {
            final category = visibleCategories[index];

            final percentage = totalExpenses == 0
                ? 0.0
                : category.value / totalExpenses;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visibleCategories.length - 1 ? 0 : 18,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEF6C00,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFFEF6C00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(category.value),
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatPercentage(percentage * 100),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: percentage.clamp(0.0, 1.0),
                      backgroundColor: Colors.red.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class RankingCard extends StatelessWidget {
  const RankingCard({required this.reports, required this.type, super.key});

  final List<FarmReportData> reports;
  final RankingType type;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text('Nenhuma propriedade disponível para o ranking.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: List.generate(reports.length, (index) {
          final report = reports[index];

          final value = type == RankingType.finance
              ? report.balance
              : report.inventoryValue;

          final color = type == RankingType.finance && value < 0
              ? Colors.red.shade700
              : const Color(0xFF1B5E20);

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: rankingColor(index).withValues(alpha: 0.14),
                  child: Text(
                    '${index + 1}º',
                    style: TextStyle(
                      color: rankingColor(index),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  report.farm.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${report.farm.city} - '
                  '${report.farm.state}',
                ),
                trailing: Text(
                  formatCurrency(value),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class FarmReportCard extends StatelessWidget {
  const FarmReportCard({required this.report, super.key});

  final FarmReportData report;

  @override
  Widget build(BuildContext context) {
    final balanceColor = report.balance >= 0
        ? const Color(0xFF1B5E20)
        : Colors.red.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: Color(0xFF1B5E20),
                    size: 29,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.farm.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.farm.city} - '
                        '${report.farm.state} · '
                        '${formatNumber(report.farm.area.toDouble())} hectares',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: balanceColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Resultado',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                      Text(
                        formatCurrency(report.balance),
                        style: TextStyle(
                          color: balanceColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 22,
              runSpacing: 18,
              children: [
                FarmReportMetric(
                  label: 'Receitas',
                  value: formatCurrency(report.totalIncome),
                  color: const Color(0xFF1B5E20),
                ),
                FarmReportMetric(
                  label: 'Despesas',
                  value: formatCurrency(report.totalExpenses),
                  color: Colors.red.shade700,
                ),
                FarmReportMetric(
                  label: 'Estoque',
                  value: formatCurrency(report.inventoryValue),
                  color: const Color(0xFF1565C0),
                ),
                FarmReportMetric(
                  label: 'Produtos',
                  value: report.inventoryItems.length.toString(),
                ),
                FarmReportMetric(
                  label: 'Estoque baixo',
                  value: report.lowStockCount.toString(),
                  color: report.lowStockCount > 0
                      ? const Color(0xFFEF6C00)
                      : const Color(0xFF1B5E20),
                ),
                FarmReportMetric(
                  label: 'Vencidos',
                  value: report.expiredCount.toString(),
                  color: report.expiredCount > 0
                      ? Colors.red.shade700
                      : const Color(0xFF1B5E20),
                ),
                FarmReportMetric(
                  label: 'Pendentes',
                  value: report.pendingCount.toString(),
                  color: report.pendingCount > 0
                      ? const Color(0xFFEF6C00)
                      : const Color(0xFF1B5E20),
                ),
                FarmReportMetric(
                  label: 'Atrasadas',
                  value: report.overdueCount.toString(),
                  color: report.overdueCount > 0
                      ? Colors.red.shade700
                      : const Color(0xFF1B5E20),
                ),
                FarmReportMetric(
                  label: 'Urgentes',
                  value: report.urgentCount.toString(),
                  color: report.urgentCount > 0
                      ? Colors.red.shade700
                      : const Color(0xFF1B5E20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FarmReportMetric extends StatelessWidget {
  const FarmReportMetric({
    required this.label,
    required this.value,
    this.color = const Color(0xFF1B5E20),
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class EmptyReportsMessage extends StatelessWidget {
  const EmptyReportsMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined, size: 60, color: Color(0xFF1B5E20)),
            SizedBox(height: 16),
            Text(
              'Nenhum dado encontrado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Altere os filtros ou cadastre informações nas propriedades.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodFinancialTotals {
  const _PeriodFinancialTotals({required this.income, required this.expenses});

  final double income;
  final double expenses;
}

class _MonthlyChartAccumulator {
  double income = 0;
  double expenses = 0;
}

enum ReportExportType { pdf, excel }

class FarmReportData {
  const FarmReportData({
    required this.farm,
    required this.financeRecords,
    required this.inventoryItems,
    required this.agendaTasks,
  });

  final FarmData farm;
  final List<FarmFinanceData> financeRecords;
  final List<FarmInventoryData> inventoryItems;
  final List<FarmAgendaData> agendaTasks;

  FarmReportData copyWith({
    List<FarmFinanceData>? financeRecords,
    List<FarmInventoryData>? inventoryItems,
    List<FarmAgendaData>? agendaTasks,
  }) {
    return FarmReportData(
      farm: farm,
      financeRecords: financeRecords ?? this.financeRecords,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      agendaTasks: agendaTasks ?? this.agendaTasks,
    );
  }

  double get totalIncome {
    return financeRecords.where((record) => record.isIncome).fold<double>(0, (
      total,
      record,
    ) {
      return total + record.amount;
    });
  }

  double get totalExpenses {
    return financeRecords.where((record) => record.isExpense).fold<double>(0, (
      total,
      record,
    ) {
      return total + record.amount;
    });
  }

  double get balance {
    return totalIncome - totalExpenses;
  }

  double get inventoryValue {
    return inventoryItems.fold<double>(0, (total, item) {
      return total + item.totalValue;
    });
  }

  int get lowStockCount {
    return inventoryItems.where((item) {
      return item.hasLowStock;
    }).length;
  }

  int get expiredCount {
    return inventoryItems.where((item) {
      return isInventoryExpired(item);
    }).length;
  }

  int get pendingCount {
    return agendaTasks.where((task) {
      return task.status == 'Pendente' || task.status == 'Em andamento';
    }).length;
  }

  int get overdueCount {
    return agendaTasks.where((task) {
      return isAgendaOverdue(task);
    }).length;
  }

  int get urgentCount {
    return agendaTasks.where((task) {
      return task.priority == 'Urgente' &&
          !task.isCompleted &&
          !task.isCancelled;
    }).length;
  }
}

class CategoryReportData {
  const CategoryReportData({required this.name, required this.value});

  final String name;
  final double value;
}

enum RankingType { finance, inventory }

bool isInventoryExpired(FarmInventoryData item) {
  if (item.expirationDate.trim().isEmpty) {
    return false;
  }

  final date = parseReportDate(item.expirationDate);

  if (date == null) {
    return false;
  }

  return date.isBefore(reportToday());
}

bool isAgendaOverdue(FarmAgendaData task) {
  if (task.isCompleted || task.isCancelled) {
    return false;
  }

  final date = parseReportDate(task.date);

  if (date == null) {
    return false;
  }

  return date.isBefore(reportToday());
}

DateTime reportToday() {
  final now = DateTime.now();

  return DateTime(now.year, now.month, now.day);
}

DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime? parseReportDate(String value) {
  final parts = value.trim().split('/');

  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) {
    return null;
  }

  final date = DateTime(year, month, day);

  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }

  return date;
}

Color rankingColor(int index) {
  switch (index) {
    case 0:
      return const Color(0xFFC8A951);
    case 1:
      return const Color(0xFF607D8B);
    case 2:
      return const Color(0xFF8D6E63);
    default:
      return const Color(0xFF1B5E20);
  }
}

String formatComparisonRange(DateTimeRange range) {
  final sameDay =
      range.start.year == range.end.year &&
      range.start.month == range.end.month &&
      range.start.day == range.end.day;

  if (sameDay) {
    return formatDate(range.start);
  }

  return '${formatDate(range.start)} a ${formatDate(range.end)}';
}

String formatChartMonth(DateTime date) {
  const monthNames = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  final month = monthNames[date.month - 1];
  final year = date.year.toString().substring(2);

  return '$month/$year';
}

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
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

String formatCompactCurrency(double value) {
  final negative = value < 0;
  final absoluteValue = value.abs();

  String formatted;

  if (absoluteValue >= 1000000) {
    formatted =
        'R\$ ${(absoluteValue / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi';
  } else if (absoluteValue >= 1000) {
    formatted =
        'R\$ ${(absoluteValue / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil';
  } else {
    formatted = 'R\$ ${absoluteValue.toStringAsFixed(0)}';
  }

  return negative ? '-$formatted' : formatted;
}
