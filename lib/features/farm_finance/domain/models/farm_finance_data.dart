class FarmFinanceData {
  const FarmFinanceData({
    required this.id,
    required this.type,
    required this.category,
    required this.date,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.notes,
    this.status = 'Pago',
    this.dueDate = '',
    this.paymentDate = '',
    this.competence = '',
    this.costCenter = 'Geral',
    this.counterparty = '',
    this.documentNumber = '',
    this.lotName = '',
    this.animalIdentification = '',
    this.isRecurring = false,
  });

  final String id;
  final String type;
  final String category;
  final String date;
  final String description;
  final double amount;
  final String paymentMethod;
  final String notes;
  final String status;
  final String dueDate;
  final String paymentDate;
  final String competence;
  final String costCenter;
  final String counterparty;
  final String documentNumber;
  final String lotName;
  final String animalIdentification;
  final bool isRecurring;

  bool get isIncome => type == 'Receita';
  bool get isExpense => type == 'Despesa';
  bool get isPaid => status == 'Pago' || status == 'Recebido';
  bool get isPending => !isPaid && status != 'Cancelado';

  bool get isOverdue {
    if (!isPending || dueDate.isEmpty) return false;
    final parsed = _parseDate(dueDate);
    if (parsed == null) return false;
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    return parsed.isBefore(current);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'date': date,
      'description': description,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'status': status,
      'dueDate': dueDate,
      'paymentDate': paymentDate,
      'competence': competence,
      'costCenter': costCenter,
      'counterparty': counterparty,
      'documentNumber': documentNumber,
      'lotName': lotName,
      'animalIdentification': animalIdentification,
      'isRecurring': isRecurring,
    };
  }

  factory FarmFinanceData.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'Despesa';
    final legacyStatus = type == 'Receita' ? 'Recebido' : 'Pago';
    return FarmFinanceData(
      id: map['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      category: map['category'] as String? ?? 'Outros',
      date: map['date'] as String? ?? '',
      description: map['description'] as String? ?? 'Lançamento financeiro',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? 'Não informado',
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? legacyStatus,
      dueDate: map['dueDate'] as String? ?? map['date'] as String? ?? '',
      paymentDate: map['paymentDate'] as String? ?? map['date'] as String? ?? '',
      competence: map['competence'] as String? ?? '',
      costCenter: map['costCenter'] as String? ?? 'Geral',
      counterparty: map['counterparty'] as String? ?? '',
      documentNumber: map['documentNumber'] as String? ?? '',
      lotName: map['lotName'] as String? ?? '',
      animalIdentification: map['animalIdentification'] as String? ?? '',
      isRecurring: map['isRecurring'] as bool? ?? false,
    );
  }

  static DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
