enum AtlasOfficialIntegrationModule { sisbov, gta, mapa, esocialRural }

extension AtlasOfficialIntegrationModuleX on AtlasOfficialIntegrationModule {
  String get code => switch (this) {
    AtlasOfficialIntegrationModule.sisbov => 'sisbov',
    AtlasOfficialIntegrationModule.gta => 'gta',
    AtlasOfficialIntegrationModule.mapa => 'mapa',
    AtlasOfficialIntegrationModule.esocialRural => 'esocial_rural',
  };

  String get title => switch (this) {
    AtlasOfficialIntegrationModule.sisbov => 'SISBOV Enterprise',
    AtlasOfficialIntegrationModule.gta => 'GTA Digital',
    AtlasOfficialIntegrationModule.mapa => 'Integração MAPA',
    AtlasOfficialIntegrationModule.esocialRural => 'eSocial Rural',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasOfficialIntegrationModule.sisbov => const [
      'Identificação individual',
      'Rastreabilidade animal',
      'Eventos de movimentação',
      'Conferência documental',
      'Pendências de conformidade',
    ],
    AtlasOfficialIntegrationModule.gta => const [
      'Solicitação de GTA',
      'Origem e destino',
      'Animais e finalidade',
      'Validade e situação',
      'Anexos e comprovantes',
    ],
    AtlasOfficialIntegrationModule.mapa => const [
      'Cadastros regulatórios',
      'Obrigações sanitárias',
      'Documentos oficiais',
      'Protocolos e processos',
      'Alertas de vencimento',
    ],
    AtlasOfficialIntegrationModule.esocialRural => const [
      'Trabalhadores rurais',
      'Eventos periódicos',
      'Eventos não periódicos',
      'Saúde e segurança',
      'Pendências de envio',
    ],
  };
}

class AtlasOfficialIntegrationRecord {
  const AtlasOfficialIntegrationRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.externalId,
    required this.origin,
    required this.destination,
    required this.responsible,
    required this.quantity,
    required this.progressPercent,
    required this.alertCount,
    required this.expirationDate,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasOfficialIntegrationModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String externalId;
  final String origin;
  final String destination;
  final String responsible;
  final int quantity;
  final int progressPercent;
  final int alertCount;
  final String expirationDate;
  final String reference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Rejeitado' ||
      status == 'Vencido' ||
      status == 'Bloqueado' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Transmitido' ||
      status == 'Autorizado' ||
      status == 'Concluído' ||
      status == 'Válido';

  bool get isExpired {
    final parsed = parseAtlasOfficialDate(expirationDate);
    if (parsed.year == 1900) return false;
    return parsed.isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'externalId': externalId,
      'origin': origin,
      'destination': destination,
      'responsible': responsible,
      'quantity': quantity,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'expirationDate': expirationDate,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasOfficialIntegrationRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasOfficialIntegrationModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasOfficialIntegrationModule.sisbov,
    );

    return AtlasOfficialIntegrationRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Rascunho',
      externalId: map['externalId']?.toString() ?? '',
      origin: map['origin']?.toString() ?? '',
      destination: map['destination']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      expirationDate: map['expirationDate']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasOfficialDate(String value) {
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

String formatAtlasOfficialDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
