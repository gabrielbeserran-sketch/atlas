enum AtlasRuralBusinessModule {
  ruralCredit,
  ruralInsurance,
  digitalContracts,
  livestockMarketplace,
}

extension AtlasRuralBusinessModuleX on AtlasRuralBusinessModule {
  String get code => switch (this) {
    AtlasRuralBusinessModule.ruralCredit => 'rural_credit',
    AtlasRuralBusinessModule.ruralInsurance => 'rural_insurance',
    AtlasRuralBusinessModule.digitalContracts => 'digital_contracts',
    AtlasRuralBusinessModule.livestockMarketplace => 'livestock_marketplace',
  };

  String get title => switch (this) {
    AtlasRuralBusinessModule.ruralCredit => 'Crédito Rural',
    AtlasRuralBusinessModule.ruralInsurance => 'Seguro Rural',
    AtlasRuralBusinessModule.digitalContracts => 'Contratos Digitais',
    AtlasRuralBusinessModule.livestockMarketplace => 'Marketplace Pecuário',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasRuralBusinessModule.ruralCredit => const [
      'Linhas de crédito',
      'Propostas e simulações',
      'Garantias e documentos',
      'Cronograma de parcelas',
      'Acompanhamento da contratação',
    ],
    AtlasRuralBusinessModule.ruralInsurance => const [
      'Cotações e propostas',
      'Coberturas e franquias',
      'Apólices',
      'Sinistros',
      'Renovações e vencimentos',
    ],
    AtlasRuralBusinessModule.digitalContracts => const [
      'Minutas e modelos',
      'Partes e responsabilidades',
      'Assinaturas e aprovações',
      'Obrigações e prazos',
      'Aditivos e encerramento',
    ],
    AtlasRuralBusinessModule.livestockMarketplace => const [
      'Anúncios de animais',
      'Ofertas e negociações',
      'Compradores e vendedores',
      'Logística e documentos',
      'Avaliação pós-negócio',
    ],
  };
}

class AtlasRuralBusinessRecord {
  const AtlasRuralBusinessRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.counterparty,
    required this.externalId,
    required this.amount,
    required this.costAmount,
    required this.quantity,
    required this.termDays,
    required this.progressPercent,
    required this.alertCount,
    required this.dueDate,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasRuralBusinessModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String counterparty;
  final String externalId;
  final double amount;
  final double costAmount;
  final int quantity;
  final int termDays;
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
      status == 'Cancelado' ||
      status == 'Atenção' ||
      status == 'Sinistro';

  bool get isOperational =>
      status == 'Aprovado' ||
      status == 'Contratado' ||
      status == 'Assinado' ||
      status == 'Publicado' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasRuralBusinessDate(dueDate);
    if (parsed.year == 1900) return false;
    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Cancelado';
  }

  double get netAmount => amount - costAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'counterparty': counterparty,
      'externalId': externalId,
      'amount': amount,
      'costAmount': costAmount,
      'quantity': quantity,
      'termDays': termDays,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'dueDate': dueDate,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasRuralBusinessRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasRuralBusinessModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasRuralBusinessModule.ruralCredit,
    );

    return AtlasRuralBusinessRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      counterparty: map['counterparty']?.toString() ?? '',
      externalId: map['externalId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      costAmount: (map['costAmount'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      termDays: (map['termDays'] as num?)?.toInt() ?? 0,
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

DateTime parseAtlasRuralBusinessDate(String value) {
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

String formatAtlasRuralBusinessDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
