enum AtlasPlatformResilienceModule {
  dataGovernance,
  integrationHub,
  cybersecurity,
  observability,
  digitalTwin,
}

extension AtlasPlatformResilienceModuleX on AtlasPlatformResilienceModule {
  String get code => switch (this) {
    AtlasPlatformResilienceModule.dataGovernance => 'data_governance',
    AtlasPlatformResilienceModule.integrationHub => 'integration_hub',
    AtlasPlatformResilienceModule.cybersecurity => 'cybersecurity',
    AtlasPlatformResilienceModule.observability => 'observability',
    AtlasPlatformResilienceModule.digitalTwin => 'digital_twin',
  };

  String get title => switch (this) {
    AtlasPlatformResilienceModule.dataGovernance => 'Governança de Dados',
    AtlasPlatformResilienceModule.integrationHub => 'Integration Hub',
    AtlasPlatformResilienceModule.cybersecurity => 'Cibersegurança Atlas',
    AtlasPlatformResilienceModule.observability => 'Observabilidade Enterprise',
    AtlasPlatformResilienceModule.digitalTwin => 'Gêmeo Digital da Fazenda',
  };

  String get packageLabel => switch (this) {
    AtlasPlatformResilienceModule.dataGovernance => 'Pacote 94',
    AtlasPlatformResilienceModule.integrationHub => 'Pacote 95',
    AtlasPlatformResilienceModule.cybersecurity => 'Pacote 96',
    AtlasPlatformResilienceModule.observability => 'Pacote 97',
    AtlasPlatformResilienceModule.digitalTwin => 'Pacote 98',
  };

  List<String> get features => switch (this) {
    AtlasPlatformResilienceModule.dataGovernance => const [
      'Catálogo de dados',
      'Qualidade e completude',
      'Responsáveis e domínios',
      'Linhas de origem',
      'Retenção e classificação',
    ],
    AtlasPlatformResilienceModule.integrationHub => const [
      'Conectores e APIs',
      'Filas e eventos',
      'Mapeamento de dados',
      'Sincronização e reprocessamento',
      'Status das integrações',
    ],
    AtlasPlatformResilienceModule.cybersecurity => const [
      'Identidades e acessos',
      'Riscos e vulnerabilidades',
      'Incidentes de segurança',
      'Controles e evidências',
      'Planos de resposta',
    ],
    AtlasPlatformResilienceModule.observability => const [
      'Métricas de serviço',
      'Logs e rastreamento',
      'Disponibilidade e latência',
      'Alertas e incidentes',
      'SLA e capacidade',
    ],
    AtlasPlatformResilienceModule.digitalTwin => const [
      'Modelo digital da fazenda',
      'Ativos e áreas',
      'Estados operacionais',
      'Cenários e simulações',
      'Sincronização físico-digital',
    ],
  };
}

class AtlasPlatformResilienceRecord {
  const AtlasPlatformResilienceRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.owner,
    required this.externalId,
    required this.primaryValue,
    required this.secondaryValue,
    required this.financialImpact,
    required this.quantity,
    required this.scoreValue,
    required this.progressPercent,
    required this.alertCount,
    required this.dueDate,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasPlatformResilienceModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String owner;
  final String externalId;
  final double primaryValue;
  final double secondaryValue;
  final double financialImpact;
  final int quantity;
  final double scoreValue;
  final int progressPercent;
  final int alertCount;
  final String dueDate;
  final String reference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Indisponível' ||
      status == 'Bloqueado' ||
      status == 'Atenção' ||
      status == 'Em risco';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Conforme' ||
      status == 'Disponível' ||
      status == 'Monitorado' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasPlatformDate(dueDate);
    if (parsed.year == 1900) return false;
    return parsed.isBefore(DateTime.now()) && status != 'Concluído';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'owner': owner,
      'externalId': externalId,
      'primaryValue': primaryValue,
      'secondaryValue': secondaryValue,
      'financialImpact': financialImpact,
      'quantity': quantity,
      'scoreValue': scoreValue,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'dueDate': dueDate,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasPlatformResilienceRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasPlatformResilienceModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasPlatformResilienceModule.dataGovernance,
    );

    return AtlasPlatformResilienceRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      owner: map['owner']?.toString() ?? '',
      externalId: map['externalId']?.toString() ?? '',
      primaryValue: (map['primaryValue'] as num?)?.toDouble() ?? 0.0,
      secondaryValue: (map['secondaryValue'] as num?)?.toDouble() ?? 0.0,
      financialImpact: (map['financialImpact'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      scoreValue: (map['scoreValue'] as num?)?.toDouble() ?? 0.0,
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

DateTime parseAtlasPlatformDate(String value) {
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

String formatAtlasPlatformDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
