enum AtlasFinancialIntegrationModule { receitaFederal, bancoBrasil, pix, nfe }

extension AtlasFinancialIntegrationModuleX on AtlasFinancialIntegrationModule {
  String get code => switch (this) {
    AtlasFinancialIntegrationModule.receitaFederal => 'receita_federal',
    AtlasFinancialIntegrationModule.bancoBrasil => 'banco_brasil',
    AtlasFinancialIntegrationModule.pix => 'pix',
    AtlasFinancialIntegrationModule.nfe => 'nfe',
  };

  String get title => switch (this) {
    AtlasFinancialIntegrationModule.receitaFederal => 'Receita Federal',
    AtlasFinancialIntegrationModule.bancoBrasil => 'Banco do Brasil',
    AtlasFinancialIntegrationModule.pix => 'Pagamentos Pix',
    AtlasFinancialIntegrationModule.nfe => 'NF-e Rural',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasFinancialIntegrationModule.receitaFederal => const [
      'Cadastro fiscal',
      'Obrigações tributárias',
      'Documentos e declarações',
      'Protocolos de atendimento',
      'Pendências fiscais',
    ],
    AtlasFinancialIntegrationModule.bancoBrasil => const [
      'Contas e convênios',
      'Cobranças e recebimentos',
      'Pagamentos e transferências',
      'Conciliação bancária',
      'Extratos e comprovantes',
    ],
    AtlasFinancialIntegrationModule.pix => const [
      'Chaves Pix',
      'Cobrança imediata',
      'Cobrança com vencimento',
      'Recebimentos e devoluções',
      'Conciliação Pix',
    ],
    AtlasFinancialIntegrationModule.nfe => const [
      'Emissão de NF-e',
      'Itens e tributação',
      'Destinatário e transporte',
      'Autorização e cancelamento',
      'XML, DANFE e eventos',
    ],
  };
}

class AtlasFinancialIntegrationRecord {
  const AtlasFinancialIntegrationRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.externalId,
    required this.counterparty,
    required this.documentNumber,
    required this.amount,
    required this.feeAmount,
    required this.quantity,
    required this.progressPercent,
    required this.alertCount,
    required this.dueDate,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasFinancialIntegrationModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String externalId;
  final String counterparty;
  final String documentNumber;
  final double amount;
  final double feeAmount;
  final int quantity;
  final int progressPercent;
  final int alertCount;
  final String dueDate;
  final String reference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Rejeitado' ||
      status == 'Vencido' ||
      status == 'Bloqueado' ||
      status == 'Atenção' ||
      status == 'Falhou';

  bool get isOperational =>
      status == 'Processado' ||
      status == 'Pago' ||
      status == 'Recebido' ||
      status == 'Autorizado' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasFinancialDate(dueDate);
    if (parsed.year == 1900) return false;
    return parsed.isBefore(DateTime.now()) &&
        status != 'Pago' &&
        status != 'Recebido' &&
        status != 'Concluído';
  }

  double get netAmount => amount - feeAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'externalId': externalId,
      'counterparty': counterparty,
      'documentNumber': documentNumber,
      'amount': amount,
      'feeAmount': feeAmount,
      'quantity': quantity,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'dueDate': dueDate,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasFinancialIntegrationRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasFinancialIntegrationModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasFinancialIntegrationModule.receitaFederal,
    );

    return AtlasFinancialIntegrationRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Rascunho',
      externalId: map['externalId']?.toString() ?? '',
      counterparty: map['counterparty']?.toString() ?? '',
      documentNumber: map['documentNumber']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      feeAmount: (map['feeAmount'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      dueDate: map['dueDate']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasFinancialDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return DateTime(1900);

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  final parts = text.split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasFinancialDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
