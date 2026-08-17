import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_financial_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_financial_service.dart';

class AtlasFinancialManagementScreen extends StatefulWidget {
  const AtlasFinancialManagementScreen({
    required this.actionController,
    super.key,
  });

  final AtlasCommandCenterActionController actionController;

  @override
  State<AtlasFinancialManagementScreen> createState() =>
      _AtlasFinancialManagementScreenState();
}

class _AtlasFinancialManagementScreenState
    extends State<AtlasFinancialManagementScreen> {
  final AtlasFinancialService service = AtlasFinancialService.instance;

  List<AtlasFinancialAccount> accounts = <AtlasFinancialAccount>[];
  List<AtlasFinancialTransaction> transactions = <AtlasFinancialTransaction>[];
  List<AtlasCostCenter> costCenters = <AtlasCostCenter>[];
  bool isLoading = false;

  AtlasFinancialSummary get summary => service.buildSummary(transactions);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    accounts = await service.loadAccounts();
    transactions = await service.loadTransactions(
      farmName: widget.actionController.farmName,
    );
    costCenters = await service.loadCostCenters(
      farmName: widget.actionController.farmName,
    );

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editTransaction({
    AtlasFinancialTransaction? transaction,
    AtlasFinancialTransactionType? initialType,
  }) async {
    final description = TextEditingController(
      text: transaction?.description ?? '',
    );
    final amount = TextEditingController(
      text: transaction == null ? '' : transaction.amount.toStringAsFixed(2),
    );
    final counterparty = TextEditingController(
      text: transaction?.counterparty ?? '',
    );
    final lot = TextEditingController(text: transaction?.lotName ?? '');
    final animal = TextEditingController(text: transaction?.animalId ?? '');
    final notes = TextEditingController(text: transaction?.notes ?? '');

    var type =
        transaction?.type ??
        initialType ??
        AtlasFinancialTransactionType.expense;
    var status = transaction?.status ?? AtlasFinancialTransactionStatus.pending;
    var dueAt = transaction?.dueAt ?? DateTime.now();
    var accountId = transaction?.accountId;
    var costCenterId = transaction?.costCenterId;

    final result = await showDialog<AtlasFinancialTransaction>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                transaction == null ? 'Novo lançamento' : 'Editar lançamento',
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: description,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child:
                                DropdownButtonFormField<
                                  AtlasFinancialTransactionType
                                >(
                                  initialValue: type,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value:
                                          AtlasFinancialTransactionType.income,
                                      child: Text('Receita'),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          AtlasFinancialTransactionType.expense,
                                      child: Text('Despesa'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() => type = value);
                                    }
                                  },
                                ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Valor',
                                prefixText: 'R\$ ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<AtlasFinancialTransactionStatus>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Situação',
                          border: OutlineInputBorder(),
                        ),
                        items: AtlasFinancialTransactionStatus.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: accountId,
                        decoration: const InputDecoration(
                          labelText: 'Conta contábil',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sem conta'),
                          ),
                          ...accounts.map(
                            (account) => DropdownMenuItem<String?>(
                              value: account.id,
                              child: Text('${account.code} — ${account.name}'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => accountId = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: costCenterId,
                        decoration: const InputDecoration(
                          labelText: 'Centro de custos',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sem centro'),
                          ),
                          ...costCenters.map(
                            (center) => DropdownMenuItem<String?>(
                              value: center.id,
                              child: Text(center.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => costCenterId = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vencimento'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(dueAt)),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: dialogContext,
                            initialDate: dueAt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (selected != null) {
                            setDialogState(() => dueAt = selected);
                          }
                        },
                      ),
                      TextField(
                        controller: counterparty,
                        decoration: const InputDecoration(
                          labelText: 'Cliente, fornecedor ou contraparte',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: lot,
                              decoration: const InputDecoration(
                                labelText: 'Lote',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: animal,
                              decoration: const InputDecoration(
                                labelText: 'Animal',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (description.text.trim().isEmpty) {
                      return;
                    }

                    final now = DateTime.now();
                    final paidAt =
                        status == AtlasFinancialTransactionStatus.paid ||
                            status == AtlasFinancialTransactionStatus.received
                        ? now
                        : null;

                    Navigator.of(dialogContext).pop(
                      AtlasFinancialTransaction(
                        id:
                            transaction?.id ??
                            'financial_transaction_'
                                '${now.microsecondsSinceEpoch}',
                        description: description.text.trim(),
                        type: type,
                        status: status,
                        amount: _parseMoney(amount.text),
                        dueAt: dueAt,
                        paidAt: paidAt,
                        accountId: accountId,
                        costCenterId: costCenterId,
                        lotName: lot.text.trim(),
                        animalId: animal.text.trim(),
                        counterparty: counterparty.text.trim(),
                        farmName: widget.actionController.farmName,
                        notes: notes.text.trim(),
                        createdAt: transaction?.createdAt ?? now,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    description.dispose();
    amount.dispose();
    counterparty.dispose();
    lot.dispose();
    animal.dispose();
    notes.dispose();

    if (result == null) {
      return;
    }

    await service.saveTransaction(result);
    await _load();
  }

  Future<void> _editAccount({AtlasFinancialAccount? account}) async {
    final code = TextEditingController(text: account?.code ?? '');
    final name = TextEditingController(text: account?.name ?? '');
    var type = account?.type ?? AtlasFinancialAccountType.expense;

    final result = await showDialog<AtlasFinancialAccount>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(account == null ? 'Nova conta' : 'Editar conta'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: code,
                      decoration: const InputDecoration(
                        labelText: 'Código',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<AtlasFinancialAccountType>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: AtlasFinancialAccountType.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                atlasFinancialAccountTypeLabel(value),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => type = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (name.text.trim().isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      AtlasFinancialAccount(
                        id:
                            account?.id ??
                            'account_'
                                '${DateTime.now().microsecondsSinceEpoch}',
                        code: code.text.trim(),
                        name: name.text.trim(),
                        type: type,
                        parentId: account?.parentId,
                        active: true,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    code.dispose();
    name.dispose();

    if (result != null) {
      await service.saveAccount(result);
      await _load();
    }
  }

  Future<void> _editCostCenter({AtlasCostCenter? center}) async {
    final name = TextEditingController(text: center?.name ?? '');
    final description = TextEditingController(text: center?.description ?? '');

    final result = await showDialog<AtlasCostCenter>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            center == null
                ? 'Novo centro de custos'
                : 'Editar centro de custos',
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  AtlasCostCenter(
                    id:
                        center?.id ??
                        'cost_center_'
                            '${DateTime.now().microsecondsSinceEpoch}',
                    name: name.text.trim(),
                    description: description.text.trim(),
                    farmName: widget.actionController.farmName,
                    active: true,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    name.dispose();
    description.dispose();

    if (result != null) {
      await service.saveCostCenter(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financeiro profissional'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Resumo', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Plano de contas', icon: Icon(Icons.account_tree)),
              Tab(text: 'Fluxo de caixa', icon: Icon(Icons.sync_alt)),
              Tab(text: 'A pagar', icon: Icon(Icons.payments_outlined)),
              Tab(text: 'A receber', icon: Icon(Icons.request_quote_outlined)),
              Tab(text: 'Custos', icon: Icon(Icons.pie_chart_outline)),
              Tab(text: 'DRE', icon: Icon(Icons.description_outlined)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _editTransaction(),
          icon: const Icon(Icons.add),
          label: const Text('Novo lançamento'),
        ),
        body: isLoading && accounts.isEmpty && transactions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _FinancialSummaryTab(summary: summary),
                  _AccountsTab(
                    accounts: accounts,
                    onAdd: () => _editAccount(),
                    onEdit: (account) => _editAccount(account: account),
                    onDelete: (account) async {
                      await service.deleteAccount(account.id);
                      await _load();
                    },
                  ),
                  _CashFlowTab(
                    transactions: transactions,
                    onEdit: (transaction) =>
                        _editTransaction(transaction: transaction),
                  ),
                  _TransactionsTab(
                    title: 'Contas a pagar',
                    transactions: transactions
                        .where(
                          (item) =>
                              item.type ==
                              AtlasFinancialTransactionType.expense,
                        )
                        .toList(growable: false),
                    onAdd: () => _editTransaction(
                      initialType: AtlasFinancialTransactionType.expense,
                    ),
                    onEdit: (transaction) =>
                        _editTransaction(transaction: transaction),
                  ),
                  _TransactionsTab(
                    title: 'Contas a receber',
                    transactions: transactions
                        .where(
                          (item) =>
                              item.type == AtlasFinancialTransactionType.income,
                        )
                        .toList(growable: false),
                    onAdd: () => _editTransaction(
                      initialType: AtlasFinancialTransactionType.income,
                    ),
                    onEdit: (transaction) =>
                        _editTransaction(transaction: transaction),
                  ),
                  _CostsTab(
                    costCenters: costCenters,
                    byLot: service.buildCostByLot(transactions),
                    byAnimal: service.buildCostByAnimal(transactions),
                    onAddCenter: () => _editCostCenter(),
                    onEditCenter: (center) => _editCostCenter(center: center),
                  ),
                  _IncomeStatementTab(
                    lines: service.buildIncomeStatement(transactions),
                  ),
                ],
              ),
      ),
    );
  }

  static double _parseMoney(String value) {
    var normalized = value.trim();

    if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }
}

class _FinancialSummaryTab extends StatelessWidget {
  const _FinancialSummaryTab({required this.summary});

  final AtlasFinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FinancialCard(title: 'Saldo de caixa', value: summary.cashBalance),
            _FinancialCard(
              title: 'Contas a pagar',
              value: summary.accountsPayable,
            ),
            _FinancialCard(
              title: 'Contas a receber',
              value: summary.accountsReceivable,
            ),
            _FinancialCard(title: 'Receitas', value: summary.totalRevenue),
            _FinancialCard(title: 'Despesas', value: summary.totalExpense),
            _FinancialCard(
              title: 'Margem de contribuição',
              value: summary.contributionMargin,
            ),
            _FinancialCard(title: 'Lucro líquido', value: summary.netProfit),
          ],
        ),
      ],
    );
  }
}

class _AccountsTab extends StatelessWidget {
  const _AccountsTab({
    required this.accounts,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AtlasFinancialAccount> accounts;
  final VoidCallback onAdd;
  final ValueChanged<AtlasFinancialAccount> onEdit;
  final ValueChanged<AtlasFinancialAccount> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Nova conta'),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final account = accounts[index];

              return Card(
                child: ListTile(
                  title: Text('${account.code} — ${account.name}'),
                  subtitle: Text(atlasFinancialAccountTypeLabel(account.type)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(account);
                      } else if (value == 'delete') {
                        onDelete(account);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CashFlowTab extends StatelessWidget {
  const _CashFlowTab({required this.transactions, required this.onEdit});

  final List<AtlasFinancialTransaction> transactions;
  final ValueChanged<AtlasFinancialTransaction> onEdit;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Nenhum lançamento financeiro.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = transactions[index];

        return Card(
          child: ListTile(
            onTap: () => onEdit(item),
            leading: CircleAvatar(
              child: Icon(
                item.type == AtlasFinancialTransactionType.income
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
              ),
            ),
            title: Text(item.description),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy').format(item.dueAt)} • '
              '${item.status.name} • '
              '${item.counterparty}',
            ),
            trailing: Text(
              '${item.type == AtlasFinancialTransactionType.expense ? '-' : '+'}'
              'R\$ ${item.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );
      },
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({
    required this.title,
    required this.transactions,
    required this.onAdd,
    required this.onEdit,
  });

  final String title;
  final List<AtlasFinancialTransaction> transactions;
  final VoidCallback onAdd;
  final ValueChanged<AtlasFinancialTransaction> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          trailing: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar'),
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? const Center(child: Text('Nenhum lançamento nesta categoria.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = transactions[index];

                    return Card(
                      child: ListTile(
                        onTap: () => onEdit(item),
                        title: Text(item.description),
                        subtitle: Text(
                          '${item.status.name} • '
                          '${DateFormat('dd/MM/yyyy').format(item.dueAt)}',
                        ),
                        trailing: Text(
                          'R\$ ${item.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CostsTab extends StatelessWidget {
  const _CostsTab({
    required this.costCenters,
    required this.byLot,
    required this.byAnimal,
    required this.onAddCenter,
    required this.onEditCenter,
  });

  final List<AtlasCostCenter> costCenters;
  final Map<String, double> byLot;
  final Map<String, double> byAnimal;
  final VoidCallback onAddCenter;
  final ValueChanged<AtlasCostCenter> onEditCenter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Centros de custos',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddCenter,
              icon: const Icon(Icons.add),
              label: const Text('Novo centro'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...costCenters.map(
          (center) => Card(
            child: ListTile(
              onTap: () => onEditCenter(center),
              title: Text(center.name),
              subtitle: Text(center.description),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Custos por lote',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 8),
        ...byLot.entries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(entry.key),
              trailing: Text('R\$ ${entry.value.toStringAsFixed(2)}'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Custos por animal',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 8),
        ...byAnimal.entries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(entry.key),
              trailing: Text('R\$ ${entry.value.toStringAsFixed(2)}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _IncomeStatementTab extends StatelessWidget {
  const _IncomeStatementTab({required this.lines});

  final List<AtlasIncomeStatementLine> lines;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final line = lines[index];

        return ListTile(
          title: Text(
            line.label,
            style: TextStyle(
              fontWeight: line.highlight ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
          trailing: Text(
            'R\$ ${line.value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: line.highlight ? FontWeight.w900 : FontWeight.normal,
              fontSize: line.highlight ? 17 : 14,
            ),
          ),
        );
      },
    );
  }
}

class _FinancialCard extends StatelessWidget {
  const _FinancialCard({required this.title, required this.value});

  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                'R\$ ${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
