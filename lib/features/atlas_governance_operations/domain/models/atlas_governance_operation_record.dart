enum AtlasGovernanceOperationModule {
  qualityManagement,
  compliance,
  projectPortfolio,
  workforceManagement,
  trainingAcademy,
}

extension AtlasGovernanceOperationModuleX on AtlasGovernanceOperationModule {
  String get code => switch (this) {
    AtlasGovernanceOperationModule.qualityManagement => 'quality_management',
    AtlasGovernanceOperationModule.compliance => 'compliance',
    AtlasGovernanceOperationModule.projectPortfolio => 'project_portfolio',
    AtlasGovernanceOperationModule.workforceManagement =>
      'workforce_management',
    AtlasGovernanceOperationModule.trainingAcademy => 'training_academy',
  };

  String get title => switch (this) {
    AtlasGovernanceOperationModule.qualityManagement => 'Gestão da Qualidade',
    AtlasGovernanceOperationModule.compliance => 'Compliance Enterprise',
    AtlasGovernanceOperationModule.projectPortfolio => 'Portfólio de Projetos',
    AtlasGovernanceOperationModule.workforceManagement => 'Gestão de Equipes',
    AtlasGovernanceOperationModule.trainingAcademy => 'Academia Atlas',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasGovernanceOperationModule.qualityManagement => const [
      'Padrões e procedimentos',
      'Inspeções e auditorias',
      'Não conformidades',
      'Ações corretivas',
      'Indicadores da qualidade',
    ],
    AtlasGovernanceOperationModule.compliance => const [
      'Políticas e controles',
      'Mapa de riscos',
      'Evidências e auditoria',
      'Planos de adequação',
      'Canal de ocorrências',
    ],
    AtlasGovernanceOperationModule.projectPortfolio => const [
      'Ideias e demandas',
      'Planejamento de projetos',
      'Marcos e entregas',
      'Orçamento e recursos',
      'Riscos e benefícios',
    ],
    AtlasGovernanceOperationModule.workforceManagement => const [
      'Cadastro de equipes',
      'Escalas e jornadas',
      'Metas e desempenho',
      'Ocorrências e feedback',
      'Capacidade operacional',
    ],
    AtlasGovernanceOperationModule.trainingAcademy => const [
      'Trilhas de aprendizagem',
      'Cursos e conteúdos',
      'Avaliações e provas',
      'Certificados',
      'Plano de desenvolvimento',
    ],
  };
}

class AtlasGovernanceOperationRecord {
  const AtlasGovernanceOperationRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.responsible,
    required this.externalId,
    required this.amount,
    required this.costAmount,
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
  final AtlasGovernanceOperationModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String responsible;
  final String externalId;
  final double amount;
  final double costAmount;
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
      status == 'Rejeitado' ||
      status == 'Vencido' ||
      status == 'Cancelado' ||
      status == 'Atenção' ||
      status == 'Não conforme' ||
      status == 'Bloqueado';

  bool get isOperational =>
      status == 'Aprovado' ||
      status == 'Conforme' ||
      status == 'Em execução' ||
      status == 'Certificado' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasGovernanceDate(dueDate);
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
      'responsible': responsible,
      'externalId': externalId,
      'amount': amount,
      'costAmount': costAmount,
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

  factory AtlasGovernanceOperationRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasGovernanceOperationModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasGovernanceOperationModule.qualityManagement,
    );

    return AtlasGovernanceOperationRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      responsible: map['responsible']?.toString() ?? '',
      externalId: map['externalId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      costAmount: (map['costAmount'] as num?)?.toDouble() ?? 0.0,
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

DateTime parseAtlasGovernanceDate(String value) {
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

String formatAtlasGovernanceDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
