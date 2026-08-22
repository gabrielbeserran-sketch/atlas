import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_action_bar.dart';
import 'package:projeto_atlas/core/widgets/atlas_feedback.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';
import 'package:projeto_atlas/core/widgets/atlas_empty_state.dart';
import 'package:projeto_atlas/core/widgets/atlas_operational_feedback.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_finance/domain/services/farm_finance_event_service.dart';
import 'package:projeto_atlas/features/farm_finance/presentation/screens/farm_finance_form_screen.dart';

class FarmFinanceListScreen extends StatefulWidget {
  const FarmFinanceListScreen({
    required this.farm,
    this.autoOpenCreate = false,
    this.embedded = false,
    super.key,
  });

  final FarmData farm;
  final bool autoOpenCreate;
  final bool embedded;

  @override
  State<FarmFinanceListScreen> createState() {
    return _FarmFinanceListScreenState();
  }
}

class _FarmFinanceListScreenState extends State<FarmFinanceListScreen> {
  final FarmFinanceStorageService storage = FarmFinanceStorageService();

  final FarmFinanceEventService eventService = const FarmFinanceEventService();

  List<FarmFinanceData> records = [];

  bool isLoading = true;
  String? loadError;

  String selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await loadRecords();
    if (widget.autoOpenCreate && mounted) {
      await openFinanceForm();
    }
  }

  List<FarmFinanceData> get filteredRecords {
    if (selectedFilter == 'Todos') {
      return records;
    }
    if (selectedFilter == 'Receita' || selectedFilter == 'Despesa') {
      return records.where((record) => record.type == selectedFilter).toList();
    }
    if (selectedFilter == 'Pendentes') {
      return records.where((record) => record.isPending).toList();
    }
    if (selectedFilter == 'Vencidos') {
      return records.where((record) => record.isOverdue).toList();
    }
    return records;
  }

  double get totalIncome {
    return records
        .where((record) => record.isIncome)
        .fold<double>(0, (total, record) => total + record.amount);
  }

  double get totalExpenses {
    return records
        .where((record) => record.isExpense)
        .fold<double>(0, (total, record) => total + record.amount);
  }

  double get balance => totalIncome - totalExpenses;

  double get accountsReceivable => records
      .where((record) => record.isIncome && record.isPending)
      .fold<double>(0, (total, record) => total + record.amount);

  double get accountsPayable => records
      .where((record) => record.isExpense && record.isPending)
      .fold<double>(0, (total, record) => total + record.amount);

  double get overdueAmount => records
      .where((record) => record.isOverdue)
      .fold<double>(0, (total, record) => total + record.amount);

  double get operatingResult {
    final paidIncome = records
        .where((r) => r.isIncome && r.isPaid)
        .fold<double>(0, (t, r) => t + r.amount);
    final paidExpenses = records
        .where((r) => r.isExpense && r.isPaid)
        .fold<double>(0, (t, r) => t + r.amount);
    return paidIncome - paidExpenses;
  }

  Future<void> loadRecords() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }
    try {
      final savedRecords = await storage
          .loadRecords(widget.farm.name, farmId: widget.farm.id ?? '')
          .timeout(const Duration(seconds: 8));
      if (!mounted) {
        return;
      }
      setState(() {
        records = savedRecords;
        sortRecords();
      });
    } catch (error) {
      if (mounted) {
        setState(() => loadError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> saveRecords() async {
    await storage.saveRecords(farmName: widget.farm.name, records: records);
  }

  void sortRecords() {
    records.sort((first, second) {
      final dateComparison = parseDate(
        second.date,
      ).compareTo(parseDate(first.date));

      if (dateComparison != 0) {
        return dateComparison;
      }

      return second.id.compareTo(first.id);
    });
  }

  DateTime parseDate(String value) {
    final parts = value.split('/');

    if (parts.length != 3) {
      return DateTime(1900);
    }

    return DateTime(
      int.tryParse(parts[2]) ?? 1900,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[0]) ?? 1,
    );
  }

  Future<void> openFinanceForm() async {
    final newRecord = await Navigator.push<FarmFinanceData>(
      context,
      MaterialPageRoute<FarmFinanceData>(
        builder: (context) {
          return const FarmFinanceFormScreen();
        },
      ),
    );

    if (newRecord == null || !mounted) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    final savedRecord = farmId.isEmpty
        ? newRecord
        : await storage.createRecord(
            farmName: widget.farm.name,
            farmId: farmId,
            record: newRecord,
          );

    if (!mounted) {
      return;
    }
    setState(() {
      records.add(savedRecord);
      sortRecords();
    });

    if (farmId.isEmpty) {
      await saveRecords();
    }

    await eventService.publishEntryCreated(
      farmName: widget.farm.name,
      record: newRecord,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lançamento salvo com sucesso.')),
    );
  }

  Future<void> editRecord(FarmFinanceData record) async {
    final editedRecord = await Navigator.push<FarmFinanceData>(
      context,
      MaterialPageRoute<FarmFinanceData>(
        builder: (context) {
          return FarmFinanceFormScreen(record: record);
        },
      ),
    );

    if (editedRecord == null || !mounted) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    final savedRecord = farmId.isEmpty
        ? editedRecord
        : await storage.updateRecord(
            farmName: widget.farm.name,
            farmId: farmId,
            record: editedRecord,
          );

    final recordIndex = records.indexWhere((item) => item.id == record.id);
    if (recordIndex == -1 || !mounted) {
      return;
    }

    setState(() {
      records[recordIndex] = savedRecord;
      sortRecords();
    });

    if (farmId.isEmpty) {
      await saveRecords();
    }

    await eventService.publishEntryUpdated(
      farmName: widget.farm.name,
      previousRecord: record,
      updatedRecord: savedRecord,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lançamento atualizado.')));
  }

  Future<void> deleteRecord(FarmFinanceData record) async {
    final shouldDelete = await AtlasFeedback.confirmDelete(
      context,
      title: 'Excluir lançamento',
      message:
          'Deseja excluir ${record.description} no valor de ${formatCurrency(record.amount)}? Essa ação não pode ser desfeita.',
    );

    if (!shouldDelete) {
      return;
    }

    final farmId = widget.farm.id ?? '';
    if (farmId.isNotEmpty) {
      await storage.deleteRecord(
        farmName: widget.farm.name,
        entryId: record.id,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      records.removeWhere((item) => item.id == record.id);
    });

    if (farmId.isEmpty) {
      await saveRecords();
    }

    await eventService.publishEntryDeleted(
      farmName: widget.farm.name,
      deletedRecord: record,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lançamento excluído.')));
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = filteredRecords;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Financeiro'),
              actions: [
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: isLoading ? null : loadRecords,
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ],
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : loadError != null && records.isEmpty
                ? AtlasLoadErrorState(
                    message: 'Verifique sua conexão e tente novamente.',
                    onRetry: loadRecords,
                  )
                : RefreshIndicator(
                    onRefresh: loadRecords,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        FinanceHeader(farm: widget.farm, balance: balance),
                        const SizedBox(height: 12),
                        AtlasOperationalActionBar(
                          primaryLabel: 'Novo lançamento',
                          onPrimary: openFinanceForm,
                          onRefresh: loadRecords,
                          busy: isLoading,
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            FinanceSummaryCard(
                              title: 'Receitas',
                              value: formatCurrency(totalIncome),
                              icon: Icons.trending_up_outlined,
                              positive: true,
                            ),
                            FinanceSummaryCard(
                              title: 'Despesas',
                              value: formatCurrency(totalExpenses),
                              icon: Icons.trending_down_outlined,
                              positive: false,
                            ),
                            FinanceSummaryCard(
                              title: 'Saldo',
                              value: formatCurrency(balance),
                              icon: balance >= 0
                                  ? Icons.account_balance_wallet_outlined
                                  : Icons.warning_amber_outlined,
                              positive: balance >= 0,
                            ),
                            FinanceSummaryCard(
                              title: 'Lançamentos',
                              value: records.length.toString(),
                              icon: Icons.receipt_long_outlined,
                              positive: true,
                            ),
                            FinanceSummaryCard(
                              title: 'A receber',
                              value: formatCurrency(accountsReceivable),
                              icon: Icons.savings_outlined,
                              positive: true,
                            ),
                            FinanceSummaryCard(
                              title: 'A pagar',
                              value: formatCurrency(accountsPayable),
                              icon: Icons.pending_actions_outlined,
                              positive: accountsPayable == 0,
                            ),
                            FinanceSummaryCard(
                              title: 'Vencidos',
                              value: formatCurrency(overdueAmount),
                              icon: Icons.warning_amber_outlined,
                              positive: overdueAmount == 0,
                            ),
                            FinanceSummaryCard(
                              title: 'Resultado realizado',
                              value: formatCurrency(operatingResult),
                              icon: Icons.analytics_outlined,
                              positive: operatingResult >= 0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ChoiceChip(
                              label: const Text('Todos'),
                              selected: selectedFilter == 'Todos',
                              onSelected: (_) {
                                setState(() {
                                  selectedFilter = 'Todos';
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Receitas'),
                              selected: selectedFilter == 'Receita',
                              onSelected: (_) {
                                setState(() {
                                  selectedFilter = 'Receita';
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Despesas'),
                              selected: selectedFilter == 'Despesa',
                              onSelected: (_) {
                                setState(() {
                                  selectedFilter = 'Despesa';
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Pendentes'),
                              selected: selectedFilter == 'Pendentes',
                              onSelected: (_) =>
                                  setState(() => selectedFilter = 'Pendentes'),
                            ),
                            ChoiceChip(
                              label: const Text('Vencidos'),
                              selected: selectedFilter == 'Vencidos',
                              onSelected: (_) =>
                                  setState(() => selectedFilter = 'Vencidos'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Lançamentos financeiros',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${visibleRecords.length} registros',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Receitas e despesas organizadas por data.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        if (visibleRecords.isEmpty)
                          EmptyFinanceMessage(
                            hasFilter: selectedFilter != 'Todos',
                            onCreate: openFinanceForm,
                            onClear: () =>
                                setState(() => selectedFilter = 'Todos'),
                          )
                        else
                          ...visibleRecords.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FinanceRecordCard(
                                record: record,
                                onEdit: () {
                                  editRecord(record);
                                },
                                onDelete: () {
                                  deleteRecord(record);
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class FinanceHeader extends StatelessWidget {
  const FinanceHeader({required this.farm, required this.balance, super.key});

  final FarmData farm;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestão financeira',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  farm.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${farm.city} - ${farm.state}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Saldo atual',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  formatCurrency(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.positive,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFF1B5E20) : Colors.red.shade700;

    return SizedBox(
      width: 245,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
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
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(color: Colors.black54)),
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

class FinanceRecordCard extends StatelessWidget {
  const FinanceRecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final FarmFinanceData record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = record.isIncome
        ? const Color(0xFF1B5E20)
        : Colors.red.shade700;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  record.isIncome
                      ? Icons.trending_up_outlined
                      : Icons.trending_down_outlined,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AtlasUiText.clean(record.description),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      AtlasUiText.category(record.category),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        FinanceInformation(
                          icon: Icons.calendar_month_outlined,
                          text: record.date,
                        ),
                        FinanceInformation(
                          icon: Icons.payments_outlined,
                          text: record.paymentMethod,
                        ),
                      ],
                    ),
                    if (record.counterparty.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        AtlasUiText.clean(record.counterparty),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (record.lotName.isNotEmpty ||
                        record.animalIdentification.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        [record.lotName, record.animalIdentification]
                            .where((e) => e.isNotEmpty)
                            .map(AtlasUiText.clean)
                            .join(' • '),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        AtlasUiText.clean(record.notes),
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${record.isIncome ? '+' : '-'} '
                '${formatCurrency(record.amount)}',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Color(0xFF1B5E20)),
                          SizedBox(width: 10),
                          Text('Editar lançamento'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Excluir lançamento'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinanceInformation extends StatelessWidget {
  const FinanceInformation({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class EmptyFinanceMessage extends StatelessWidget {
  const EmptyFinanceMessage({
    required this.hasFilter,
    required this.onCreate,
    required this.onClear,
    super.key,
  });

  final bool hasFilter;
  final VoidCallback onCreate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AtlasEmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: hasFilter
          ? 'Nenhum lançamento neste filtro'
          : 'Nenhum lançamento financeiro',
      message: hasFilter
          ? 'O filtro atual não encontrou lançamentos. Limpe o filtro para ver todos.'
          : 'Registre a primeira receita ou despesa da fazenda.',
      actionLabel: hasFilter ? 'Limpar filtro' : 'Novo lançamento',
      onAction: hasFilter ? onClear : onCreate,
    );
  }
}

String formatCurrency(double value) {
  final isNegative = value < 0;
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

  return isNegative ? '-$formatted' : formatted;
}
