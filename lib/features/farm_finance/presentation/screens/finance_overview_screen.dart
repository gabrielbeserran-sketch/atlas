import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_finance/presentation/screens/farm_finance_list_screen.dart';

class FinanceOverviewScreen extends StatefulWidget {
  const FinanceOverviewScreen({super.key});

  @override
  State<FinanceOverviewScreen> createState() => _FinanceOverviewScreenState();
}

class _FinanceOverviewScreenState extends State<FinanceOverviewScreen> {
  final FarmStorageService farmStorage = FarmStorageService();
  final FarmFinanceStorageService financeStorage = FarmFinanceStorageService();

  List<FinanceFarmContext> farmContexts = [];
  bool isLoading = true;
  String search = '';

  double get totalIncome => farmContexts.fold(
        0,
        (total, context) => total + context.totalIncome,
      );

  double get totalExpenses => farmContexts.fold(
        0,
        (total, context) => total + context.totalExpenses,
      );

  double get balance => totalIncome - totalExpenses;

  int get totalRecords => farmContexts.fold(
        0,
        (total, context) => total + context.records.length,
      );

  List<FinanceFarmContext> get filteredContexts {
    final query = search.trim().toLowerCase();

    if (query.isEmpty) {
      return farmContexts;
    }

    return farmContexts.where((context) {
      return context.farm.name.toLowerCase().contains(query) ||
          context.farm.city.toLowerCase().contains(query) ||
          context.farm.state.toLowerCase().contains(query) ||
          context.records.any(
            (record) =>
                record.description.toLowerCase().contains(query) ||
                record.category.toLowerCase().contains(query) ||
                record.type.toLowerCase().contains(query),
          );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final farms = await farmStorage.loadFarms();
    final contexts = <FinanceFarmContext>[];

    for (final farm in farms) {
      final records = await financeStorage.loadRecords(farm.name);
      contexts.add(FinanceFarmContext(farm: farm, records: records));
    }

    contexts.sort((first, second) {
      return first.farm.name.toLowerCase().compareTo(
            second.farm.name.toLowerCase(),
          );
    });

    if (!mounted) {
      return;
    }

    setState(() {
      farmContexts = contexts;
      isLoading = false;
    });
  }

  Future<void> openFarmFinance(FinanceFarmContext contextData) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return FarmFinanceListScreen(farm: contextData.farm);
        },
      ),
    );

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FinanceHeader(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _IndicatorCard(
                                  title: 'Receitas',
                                  value: formatCurrency(totalIncome),
                                  subtitle: 'Entradas de todas as fazendas',
                                  icon: Icons.trending_up_outlined,
                                  positive: true,
                                ),
                                _IndicatorCard(
                                  title: 'Despesas',
                                  value: formatCurrency(totalExpenses),
                                  subtitle: 'Saídas de todas as fazendas',
                                  icon: Icons.trending_down_outlined,
                                  positive: false,
                                ),
                                _IndicatorCard(
                                  title: 'Saldo geral',
                                  value: formatCurrency(balance),
                                  subtitle: balance >= 0
                                      ? 'Resultado consolidado positivo'
                                      : 'Resultado consolidado negativo',
                                  icon: balance >= 0
                                      ? Icons.account_balance_wallet_outlined
                                      : Icons.warning_amber_outlined,
                                  positive: balance >= 0,
                                ),
                                _IndicatorCard(
                                  title: 'Lançamentos',
                                  value: totalRecords.toString(),
                                  subtitle: '${farmContexts.length} fazenda(s)',
                                  icon: Icons.receipt_long_outlined,
                                  positive: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  search = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar por fazenda, cidade, categoria ou lançamento',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Resultado por fazenda',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Selecione uma fazenda para consultar, cadastrar, editar ou excluir lançamentos.',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 18),
                            if (farmContexts.isEmpty)
                              const _EmptyFinance()
                            else if (filteredContexts.isEmpty)
                              const _NoSearchResults()
                            else
                              ...filteredContexts.map(
                                (contextData) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _FarmFinanceCard(
                                    contextData: contextData,
                                    onOpen: () => openFarmFinance(contextData),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class FinanceFarmContext {
  const FinanceFarmContext({required this.farm, required this.records});

  final FarmData farm;
  final List<FarmFinanceData> records;

  double get totalIncome => records
      .where((record) => record.isIncome)
      .fold(0, (total, record) => total + record.amount);

  double get totalExpenses => records
      .where((record) => record.isExpense)
      .fold(0, (total, record) => total + record.amount);

  double get balance => totalIncome - totalExpenses;

  FarmFinanceData? get latestRecord {
    if (records.isEmpty) {
      return null;
    }

    final sorted = [...records]
      ..sort((first, second) {
        return _parseDate(second.date).compareTo(_parseDate(first.date));
      });

    return sorted.first;
  }

  static DateTime _parseDate(String value) {
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
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF1B5E20),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Central Financeira',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Acompanhe receitas, despesas e saldo de todas as propriedades.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.positive,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final accent = positive ? const Color(0xFF1B5E20) : Colors.red.shade700;

    return SizedBox(
      width: 270,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E8E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _FarmFinanceCard extends StatelessWidget {
  const _FarmFinanceCard({required this.contextData, required this.onOpen});

  final FinanceFarmContext contextData;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final latest = contextData.latestRecord;
    final isPositive = contextData.balance >= 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Icon(
                  Icons.home_work_outlined,
                  color: isPositive
                      ? const Color(0xFF1B5E20)
                      : Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contextData.farm.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${contextData.farm.city} - ${contextData.farm.state}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        Text(
                          'Receitas: ${formatCurrency(contextData.totalIncome)}',
                          style: const TextStyle(color: Color(0xFF1B5E20)),
                        ),
                        Text(
                          'Despesas: ${formatCurrency(contextData.totalExpenses)}',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        Text(
                          'Saldo: ${formatCurrency(contextData.balance)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isPositive
                                ? const Color(0xFF1B5E20)
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latest == null
                          ? 'Nenhum lançamento cadastrado.'
                          : 'Último: ${latest.description} • ${latest.date}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    contextData.records.length.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'registros',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFinance extends StatelessWidget {
  const _EmptyFinance();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Nenhuma fazenda cadastrada',
      message: 'Cadastre uma fazenda para começar o controle financeiro.',
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const _MessageCard(
      icon: Icons.search_off_outlined,
      title: 'Nenhum resultado encontrado',
      message: 'Tente utilizar outro nome, cidade, categoria ou lançamento.',
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.black38),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

String formatCurrency(double value) {
  final absoluteValue = value.abs();
  final fixedValue = absoluteValue.toStringAsFixed(2);
  final parts = fixedValue.split('.');
  final integerPart = parts.first;
  final decimalPart = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < integerPart.length; index++) {
    final remaining = integerPart.length - index;
    buffer.write(integerPart[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  final formatted = 'R\$ ${buffer.toString()},$decimalPart';
  return value < 0 ? '-$formatted' : formatted;
}
