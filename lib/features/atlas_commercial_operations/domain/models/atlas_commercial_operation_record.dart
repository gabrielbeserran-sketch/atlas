enum AtlasCommercialOperationModule {
  digitalAuction,
  livestockLogistics,
  originCertification,
  ruralCrm,
}

extension AtlasCommercialOperationModuleX on AtlasCommercialOperationModule {
  String get code => switch (this) {
    AtlasCommercialOperationModule.digitalAuction => 'digital_auction',
    AtlasCommercialOperationModule.livestockLogistics => 'livestock_logistics',
    AtlasCommercialOperationModule.originCertification =>
      'origin_certification',
    AtlasCommercialOperationModule.ruralCrm => 'rural_crm',
  };

  String get title => switch (this) {
    AtlasCommercialOperationModule.digitalAuction => 'Leilão Digital',
    AtlasCommercialOperationModule.livestockLogistics => 'Logística Pecuária',
    AtlasCommercialOperationModule.originCertification =>
      'Certificação de Origem',
    AtlasCommercialOperationModule.ruralCrm => 'CRM Pecuário',
  };

  String get packageLabel => switch (this) {
    AtlasCommercialOperationModule.digitalAuction => 'Pacote 75',
    AtlasCommercialOperationModule.livestockLogistics => 'Pacote 76',
    AtlasCommercialOperationModule.originCertification => 'Pacote 77',
    AtlasCommercialOperationModule.ruralCrm => 'Pacote 78',
  };

  List<String> get features => switch (this) {
    AtlasCommercialOperationModule.digitalAuction => const [
      'Cadastro de lotes',
      'Lances e propostas',
      'Comissões e condições',
      'Arrematação e pagamento',
      'Documentação pós-leilão',
    ],
    AtlasCommercialOperationModule.livestockLogistics => const [
      'Planejamento de embarque',
      'Transportadores e veículos',
      'Rotas e custos',
      'Bem-estar no transporte',
      'Comprovantes de entrega',
    ],
    AtlasCommercialOperationModule.originCertification => const [
      'Origem e propriedade',
      'Identificação do lote',
      'Evidências de produção',
      'Auditoria e conformidade',
      'Certificados e validade',
    ],
    AtlasCommercialOperationModule.ruralCrm => const [
      'Leads e contatos',
      'Oportunidades comerciais',
      'Atividades e follow-up',
      'Propostas e fechamento',
      'Pós-venda e relacionamento',
    ],
  };
}

class AtlasCommercialOperationRecord {
  const AtlasCommercialOperationRecord({
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
    required this.distanceKm,
    required this.progressPercent,
    required this.alertCount,
    required this.dueDate,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasCommercialOperationModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String counterparty;
  final String externalId;
  final double amount;
  final double costAmount;
  final int quantity;
  final double distanceKm;
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
      status == 'Falhou';

  bool get isOperational =>
      status == 'Publicado' ||
      status == 'Arrematado' ||
      status == 'Em transporte' ||
      status == 'Certificado' ||
      status == 'Fechado' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasCommercialDate(dueDate);
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
      'distanceKm': distanceKm,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'dueDate': dueDate,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasCommercialOperationRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasCommercialOperationModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasCommercialOperationModule.digitalAuction,
    );

    return AtlasCommercialOperationRecord(
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
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
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

DateTime parseAtlasCommercialDate(String value) {
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

String formatAtlasCommercialDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
