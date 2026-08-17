enum AtlasAutonomousEnterpriseModule { aiOrchestrator, enterpriseReleaseCenter }

extension AtlasAutonomousEnterpriseModuleX on AtlasAutonomousEnterpriseModule {
  String get code => switch (this) {
    AtlasAutonomousEnterpriseModule.aiOrchestrator => 'ai_orchestrator',
    AtlasAutonomousEnterpriseModule.enterpriseReleaseCenter =>
      'enterprise_release_center',
  };

  String get title => switch (this) {
    AtlasAutonomousEnterpriseModule.aiOrchestrator => 'Orquestrador Atlas AI',
    AtlasAutonomousEnterpriseModule.enterpriseReleaseCenter =>
      'Centro de Finalização Enterprise',
  };

  String get packageLabel => switch (this) {
    AtlasAutonomousEnterpriseModule.aiOrchestrator => 'Pacote 99',
    AtlasAutonomousEnterpriseModule.enterpriseReleaseCenter => 'Pacote 100',
  };

  List<String> get features => switch (this) {
    AtlasAutonomousEnterpriseModule.aiOrchestrator => const [
      'Fila de decisões',
      'Regras e políticas',
      'Aprovação humana',
      'Execução e acompanhamento',
      'Memória e aprendizado',
    ],
    AtlasAutonomousEnterpriseModule.enterpriseReleaseCenter => const [
      'Checklist de produção',
      'Qualidade e testes',
      'Segurança e conformidade',
      'Publicação e rollback',
      'Pós-lançamento e suporte',
    ],
  };
}

class AtlasAutonomousEnterpriseRecord {
  const AtlasAutonomousEnterpriseRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.owner,
    required this.externalId,
    required this.priority,
    required this.confidencePercent,
    required this.riskPercent,
    required this.financialImpact,
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
  final AtlasAutonomousEnterpriseModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String owner;
  final String externalId;
  final int priority;
  final double confidencePercent;
  final double riskPercent;
  final double financialImpact;
  final int quantity;
  final int progressPercent;
  final int alertCount;
  final String dueDate;
  final String reference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Bloqueado' ||
      status == 'Falhou' ||
      status == 'Crítico' ||
      status == 'Rollback' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Aprovado' ||
      status == 'Em execução' ||
      status == 'Publicado' ||
      status == 'Concluído' ||
      status == 'Monitorado';

  bool get isOverdue {
    final parsed = parseAtlasAutonomousDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Publicado';
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
      'priority': priority,
      'confidencePercent': confidencePercent,
      'riskPercent': riskPercent,
      'financialImpact': financialImpact,
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

  factory AtlasAutonomousEnterpriseRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasAutonomousEnterpriseModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasAutonomousEnterpriseModule.aiOrchestrator,
    );

    return AtlasAutonomousEnterpriseRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      owner: map['owner']?.toString() ?? '',
      externalId: map['externalId']?.toString() ?? '',
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 0.0,
      riskPercent: (map['riskPercent'] as num?)?.toDouble() ?? 0.0,
      financialImpact: (map['financialImpact'] as num?)?.toDouble() ?? 0.0,
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

DateTime parseAtlasAutonomousDate(String value) {
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

String formatAtlasAutonomousDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
