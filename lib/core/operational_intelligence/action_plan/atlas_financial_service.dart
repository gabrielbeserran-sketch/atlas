import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_financial_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasFinancialService {
  AtlasFinancialService._();

  static final AtlasFinancialService instance =
      AtlasFinancialService._();

  static const String _accountsKey =
      'atlas_financial_accounts_v1';
  static const String _transactionsKey =
      'atlas_financial_transactions_v1';
  static const String _costCentersKey =
      'atlas_cost_centers_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasFinancialAccount>> loadAccounts() async {
    final encoded =
        await _preferences.getString(_accountsKey);

    if (encoded == null || encoded.trim().isEmpty) {
      final defaults = _defaultAccounts();
      await _saveAccounts(defaults);
      return defaults;
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasFinancialAccount.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return _defaultAccounts();
    }
  }

  Future<void> saveAccount(
    AtlasFinancialAccount account,
  ) async {
    final all = await loadAccounts();
    final index = all.indexWhere(
      (item) => item.id == account.id,
    );

    if (index == -1) {
      all.add(account);
    } else {
      all[index] = account;
    }

    await _saveAccounts(all);
  }

  Future<void> deleteAccount(String id) async {
    final all = await loadAccounts()
      ..removeWhere((item) => item.id == id);

    await _saveAccounts(all);
  }

  Future<List<AtlasFinancialTransaction>> loadTransactions({
    String? farmName,
  }) async {
    final encoded =
        await _preferences.getString(_transactionsKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasFinancialTransaction>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final all = decoded
          .map(
            (item) => AtlasFinancialTransaction.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final normalizedFarm =
          farmName?.trim().toLowerCase();

      final filtered = all.where((transaction) {
        if (normalizedFarm == null ||
            normalizedFarm.isEmpty) {
          return true;
        }

        return transaction.farmName
                ?.trim()
                .toLowerCase() ==
            normalizedFarm;
      }).toList()
        ..sort(
          (first, second) =>
              second.dueAt.compareTo(first.dueAt),
        );

      return filtered;
    } catch (_) {
      return <AtlasFinancialTransaction>[];
    }
  }

  Future<void> saveTransaction(
    AtlasFinancialTransaction transaction,
  ) async {
    final all = await _loadAllTransactions();
    final index = all.indexWhere(
      (item) => item.id == transaction.id,
    );

    if (index == -1) {
      all.add(transaction);
    } else {
      all[index] = transaction;
    }

    await _preferences.setString(
      _transactionsKey,
      jsonEncode(
        all.map((item) => item.toMap()).toList(),
      ),
    );
  }

  Future<void> deleteTransaction(String id) async {
    final all = await _loadAllTransactions()
      ..removeWhere((item) => item.id == id);

    await _preferences.setString(
      _transactionsKey,
      jsonEncode(
        all.map((item) => item.toMap()).toList(),
      ),
    );
  }

  Future<List<AtlasCostCenter>> loadCostCenters({
    String? farmName,
  }) async {
    final encoded =
        await _preferences.getString(_costCentersKey);

    if (encoded == null || encoded.trim().isEmpty) {
      final defaults = <AtlasCostCenter>[
        AtlasCostCenter(
          id: 'cost_center_reproduction',
          name: 'Reprodução',
          description: 'Custos reprodutivos.',
          farmName: farmName,
          active: true,
        ),
        AtlasCostCenter(
          id: 'cost_center_health',
          name: 'Sanidade',
          description: 'Custos sanitários.',
          farmName: farmName,
          active: true,
        ),
        AtlasCostCenter(
          id: 'cost_center_nutrition',
          name: 'Nutrição',
          description: 'Custos nutricionais.',
          farmName: farmName,
          active: true,
        ),
      ];
      await _saveCostCenters(defaults);
      return defaults;
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final all = decoded
          .map(
            (item) => AtlasCostCenter.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final normalizedFarm =
          farmName?.trim().toLowerCase();

      return all.where((item) {
        if (normalizedFarm == null ||
            normalizedFarm.isEmpty) {
          return true;
        }

        return item.farmName?.trim().toLowerCase() ==
            normalizedFarm;
      }).toList();
    } catch (_) {
      return <AtlasCostCenter>[];
    }
  }

  Future<void> saveCostCenter(
    AtlasCostCenter center,
  ) async {
    final all = await _loadAllCostCenters();
    final index = all.indexWhere(
      (item) => item.id == center.id,
    );

    if (index == -1) {
      all.add(center);
    } else {
      all[index] = center;
    }

    await _saveCostCenters(all);
  }

  Future<void> deleteCostCenter(String id) async {
    final all = await _loadAllCostCenters()
      ..removeWhere((item) => item.id == id);

    await _saveCostCenters(all);
  }

  AtlasFinancialSummary buildSummary(
    List<AtlasFinancialTransaction> transactions,
  ) {
    final settledIncome = transactions
        .where(
          (item) =>
              item.type ==
                  AtlasFinancialTransactionType.income &&
              item.isSettled,
        )
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );
    final settledExpense = transactions
        .where(
          (item) =>
              item.type ==
                  AtlasFinancialTransactionType.expense &&
              item.isSettled,
        )
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );
    final payable = transactions
        .where(
          (item) =>
              item.type ==
                  AtlasFinancialTransactionType.expense &&
              !item.isSettled &&
              item.status !=
                  AtlasFinancialTransactionStatus.cancelled,
        )
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );
    final receivable = transactions
        .where(
          (item) =>
              item.type ==
                  AtlasFinancialTransactionType.income &&
              !item.isSettled &&
              item.status !=
                  AtlasFinancialTransactionStatus.cancelled,
        )
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );

    final contributionMargin =
        settledIncome - settledExpense;
    final netProfit = contributionMargin;

    return AtlasFinancialSummary(
      cashBalance: settledIncome - settledExpense,
      accountsPayable: payable,
      accountsReceivable: receivable,
      totalRevenue: settledIncome,
      totalExpense: settledExpense,
      contributionMargin: contributionMargin,
      netProfit: netProfit,
    );
  }

  List<AtlasIncomeStatementLine> buildIncomeStatement(
    List<AtlasFinancialTransaction> transactions,
  ) {
    final summary = buildSummary(transactions);

    return <AtlasIncomeStatementLine>[
      AtlasIncomeStatementLine(
        label: 'Receita bruta',
        value: summary.totalRevenue,
        level: 0,
        highlight: true,
      ),
      AtlasIncomeStatementLine(
        label: '(-) Custos e despesas',
        value: -summary.totalExpense,
        level: 0,
        highlight: false,
      ),
      AtlasIncomeStatementLine(
        label: 'Margem de contribuição',
        value: summary.contributionMargin,
        level: 0,
        highlight: true,
      ),
      AtlasIncomeStatementLine(
        label: 'Lucro líquido',
        value: summary.netProfit,
        level: 0,
        highlight: true,
      ),
    ];
  }

  Map<String, double> buildCostByLot(
    List<AtlasFinancialTransaction> transactions,
  ) {
    final result = <String, double>{};

    for (final transaction in transactions.where(
      (item) =>
          item.type ==
          AtlasFinancialTransactionType.expense,
    )) {
      final key = transaction.lotName.trim().isEmpty
          ? 'Sem lote'
          : transaction.lotName.trim();
      result[key] = (result[key] ?? 0) + transaction.amount;
    }

    return result;
  }

  Map<String, double> buildCostByAnimal(
    List<AtlasFinancialTransaction> transactions,
  ) {
    final result = <String, double>{};

    for (final transaction in transactions.where(
      (item) =>
          item.type ==
          AtlasFinancialTransactionType.expense,
    )) {
      final key = transaction.animalId.trim().isEmpty
          ? 'Sem animal'
          : transaction.animalId.trim();
      result[key] = (result[key] ?? 0) + transaction.amount;
    }

    return result;
  }

  Future<List<AtlasFinancialTransaction>>
      _loadAllTransactions() async {
    final encoded =
        await _preferences.getString(_transactionsKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasFinancialTransaction>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasFinancialTransaction.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasFinancialTransaction>[];
    }
  }

  Future<List<AtlasCostCenter>>
      _loadAllCostCenters() async {
    final encoded =
        await _preferences.getString(_costCentersKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasCostCenter>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasCostCenter.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasCostCenter>[];
    }
  }

  Future<void> _saveAccounts(
    List<AtlasFinancialAccount> accounts,
  ) async {
    await _preferences.setString(
      _accountsKey,
      jsonEncode(
        accounts.map((item) => item.toMap()).toList(),
      ),
    );
  }

  Future<void> _saveCostCenters(
    List<AtlasCostCenter> centers,
  ) async {
    await _preferences.setString(
      _costCentersKey,
      jsonEncode(
        centers.map((item) => item.toMap()).toList(),
      ),
    );
  }

  List<AtlasFinancialAccount> _defaultAccounts() {
    return const <AtlasFinancialAccount>[
      AtlasFinancialAccount(
        id: 'account_cash',
        code: '1.1.01',
        name: 'Caixa e bancos',
        type: AtlasFinancialAccountType.asset,
        parentId: null,
        active: true,
      ),
      AtlasFinancialAccount(
        id: 'account_receivable',
        code: '1.1.02',
        name: 'Contas a receber',
        type: AtlasFinancialAccountType.asset,
        parentId: null,
        active: true,
      ),
      AtlasFinancialAccount(
        id: 'account_payable',
        code: '2.1.01',
        name: 'Contas a pagar',
        type: AtlasFinancialAccountType.liability,
        parentId: null,
        active: true,
      ),
      AtlasFinancialAccount(
        id: 'account_sales',
        code: '3.1.01',
        name: 'Receita de vendas',
        type: AtlasFinancialAccountType.revenue,
        parentId: null,
        active: true,
      ),
      AtlasFinancialAccount(
        id: 'account_operational_expense',
        code: '4.1.01',
        name: 'Despesas operacionais',
        type: AtlasFinancialAccountType.expense,
        parentId: null,
        active: true,
      ),
    ];
  }
}
