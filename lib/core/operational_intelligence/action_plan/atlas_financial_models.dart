enum AtlasFinancialAccountType {
  asset,
  liability,
  revenue,
  expense,
  equity,
}

String atlasFinancialAccountTypeLabel(
  AtlasFinancialAccountType type,
) {
  switch (type) {
    case AtlasFinancialAccountType.asset:
      return 'Ativo';
    case AtlasFinancialAccountType.liability:
      return 'Passivo';
    case AtlasFinancialAccountType.revenue:
      return 'Receita';
    case AtlasFinancialAccountType.expense:
      return 'Despesa';
    case AtlasFinancialAccountType.equity:
      return 'Patrimônio';
  }
}

class AtlasFinancialAccount {
  const AtlasFinancialAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.parentId,
    required this.active,
  });

  final String id;
  final String code;
  final String name;
  final AtlasFinancialAccountType type;
  final String? parentId;
  final bool active;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'type': type.name,
      'parentId': parentId,
      'active': active,
    };
  }

  factory AtlasFinancialAccount.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasFinancialAccount(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: AtlasFinancialAccountType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasFinancialAccountType.expense,
      ),
      parentId: map['parentId']?.toString(),
      active: map['active'] != false,
    );
  }
}

enum AtlasFinancialTransactionType {
  income,
  expense,
}

enum AtlasFinancialTransactionStatus {
  pending,
  paid,
  received,
  overdue,
  cancelled,
}

class AtlasFinancialTransaction {
  const AtlasFinancialTransaction({
    required this.id,
    required this.description,
    required this.type,
    required this.status,
    required this.amount,
    required this.dueAt,
    required this.paidAt,
    required this.accountId,
    required this.costCenterId,
    required this.lotName,
    required this.animalId,
    required this.counterparty,
    required this.farmName,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String description;
  final AtlasFinancialTransactionType type;
  final AtlasFinancialTransactionStatus status;
  final double amount;
  final DateTime dueAt;
  final DateTime? paidAt;
  final String? accountId;
  final String? costCenterId;
  final String lotName;
  final String animalId;
  final String counterparty;
  final String? farmName;
  final String notes;
  final DateTime createdAt;

  bool get isSettled =>
      status == AtlasFinancialTransactionStatus.paid ||
      status == AtlasFinancialTransactionStatus.received;

  bool get isOverdue =>
      !isSettled &&
      status != AtlasFinancialTransactionStatus.cancelled &&
      dueAt.isBefore(DateTime.now());

  AtlasFinancialTransaction copyWith({
    String? description,
    AtlasFinancialTransactionType? type,
    AtlasFinancialTransactionStatus? status,
    double? amount,
    DateTime? dueAt,
    DateTime? paidAt,
    bool clearPaidAt = false,
    String? accountId,
    bool clearAccountId = false,
    String? costCenterId,
    bool clearCostCenterId = false,
    String? lotName,
    String? animalId,
    String? counterparty,
    String? notes,
  }) {
    return AtlasFinancialTransaction(
      id: id,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      dueAt: dueAt ?? this.dueAt,
      paidAt:
          clearPaidAt ? null : paidAt ?? this.paidAt,
      accountId: clearAccountId
          ? null
          : accountId ?? this.accountId,
      costCenterId: clearCostCenterId
          ? null
          : costCenterId ?? this.costCenterId,
      lotName: lotName ?? this.lotName,
      animalId: animalId ?? this.animalId,
      counterparty: counterparty ?? this.counterparty,
      farmName: farmName,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'description': description,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'dueAt': dueAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'accountId': accountId,
      'costCenterId': costCenterId,
      'lotName': lotName,
      'animalId': animalId,
      'counterparty': counterparty,
      'farmName': farmName,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AtlasFinancialTransaction.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasFinancialTransaction(
      id: map['id']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      type: AtlasFinancialTransactionType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasFinancialTransactionType.expense,
      ),
      status:
          AtlasFinancialTransactionStatus.values.firstWhere(
        (value) =>
            value.name == map['status']?.toString(),
        orElse: () =>
            AtlasFinancialTransactionStatus.pending,
      ),
      amount: _readDouble(map['amount']),
      dueAt: DateTime.tryParse(
            map['dueAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      paidAt: DateTime.tryParse(
        map['paidAt']?.toString() ?? '',
      ),
      accountId: map['accountId']?.toString(),
      costCenterId: map['costCenterId']?.toString(),
      lotName: map['lotName']?.toString() ?? '',
      animalId: map['animalId']?.toString() ?? '',
      counterparty:
          map['counterparty']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            map['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasCostCenter {
  const AtlasCostCenter({
    required this.id,
    required this.name,
    required this.description,
    required this.farmName,
    required this.active,
  });

  final String id;
  final String name;
  final String description;
  final String? farmName;
  final bool active;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'farmName': farmName,
      'active': active,
    };
  }

  factory AtlasCostCenter.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasCostCenter(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description:
          map['description']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      active: map['active'] != false,
    );
  }
}

class AtlasFinancialSummary {
  const AtlasFinancialSummary({
    required this.cashBalance,
    required this.accountsPayable,
    required this.accountsReceivable,
    required this.totalRevenue,
    required this.totalExpense,
    required this.contributionMargin,
    required this.netProfit,
  });

  final double cashBalance;
  final double accountsPayable;
  final double accountsReceivable;
  final double totalRevenue;
  final double totalExpense;
  final double contributionMargin;
  final double netProfit;
}

class AtlasIncomeStatementLine {
  const AtlasIncomeStatementLine({
    required this.label,
    required this.value,
    required this.level,
    required this.highlight,
  });

  final String label;
  final double value;
  final int level;
  final bool highlight;
}
