enum AtlasGovernancePeopleModule {
  peopleManagement,
  trainingAndQualification,
  occupationalHealthAndSafety,
  personalProtectiveEquipment,
  documentManagement,
  complianceControl,
  internalAudits,
  corporateRiskManagement,
  permissionMatrix,
  governanceCenter,
}

extension AtlasGovernancePeopleModuleX on AtlasGovernancePeopleModule {
  String get code => switch (this) {
    AtlasGovernancePeopleModule.peopleManagement => 'people_management',
    AtlasGovernancePeopleModule.trainingAndQualification =>
      'training_and_qualification',
    AtlasGovernancePeopleModule.occupationalHealthAndSafety =>
      'occupational_health_and_safety',
    AtlasGovernancePeopleModule.personalProtectiveEquipment =>
      'personal_protective_equipment',
    AtlasGovernancePeopleModule.documentManagement => 'document_management',
    AtlasGovernancePeopleModule.complianceControl => 'compliance_control',
    AtlasGovernancePeopleModule.internalAudits => 'internal_audits',
    AtlasGovernancePeopleModule.corporateRiskManagement =>
      'corporate_risk_management',
    AtlasGovernancePeopleModule.permissionMatrix => 'permission_matrix',
    AtlasGovernancePeopleModule.governanceCenter => 'governance_center',
  };

  String get title => switch (this) {
    AtlasGovernancePeopleModule.peopleManagement => 'Gestão de Pessoas',
    AtlasGovernancePeopleModule.trainingAndQualification =>
      'Treinamentos e Capacitações',
    AtlasGovernancePeopleModule.occupationalHealthAndSafety =>
      'Saúde e Segurança do Trabalho',
    AtlasGovernancePeopleModule.personalProtectiveEquipment =>
      'Equipamentos de Proteção Individual',
    AtlasGovernancePeopleModule.documentManagement => 'Gestão de Documentos',
    AtlasGovernancePeopleModule.complianceControl => 'Controle de Conformidade',
    AtlasGovernancePeopleModule.internalAudits => 'Auditorias Internas',
    AtlasGovernancePeopleModule.corporateRiskManagement =>
      'Gestão de Riscos Corporativos',
    AtlasGovernancePeopleModule.permissionMatrix => 'Matriz de Permissões',
    AtlasGovernancePeopleModule.governanceCenter =>
      'Central de Governança Atlas',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasGovernancePeopleModule.peopleManagement => const [
      'Colaboradores',
      'Cargos',
      'Contratos',
      'Documentos pessoais',
      'Histórico profissional',
    ],
    AtlasGovernancePeopleModule.trainingAndQualification => const [
      'Cursos',
      'Competências',
      'Certificados',
      'Validades',
      'Plano de capacitação',
    ],
    AtlasGovernancePeopleModule.occupationalHealthAndSafety => const [
      'Exames',
      'Riscos ocupacionais',
      'Acidentes',
      'Afastamentos',
      'Ações preventivas',
    ],
    AtlasGovernancePeopleModule.personalProtectiveEquipment => const [
      'Entrega',
      'Validade',
      'Substituição',
      'Devolução',
      'Responsabilidade',
    ],
    AtlasGovernancePeopleModule.documentManagement => const [
      'Cadastro documental',
      'Categorias',
      'Versões',
      'Validades',
      'Anexos e evidências',
    ],
    AtlasGovernancePeopleModule.complianceControl => const [
      'Requisitos legais',
      'Requisitos internos',
      'Evidências',
      'Não conformidades',
      'Plano corretivo',
    ],
    AtlasGovernancePeopleModule.internalAudits => const [
      'Planejamento',
      'Execução',
      'Achados',
      'Responsáveis',
      'Acompanhamento',
    ],
    AtlasGovernancePeopleModule.corporateRiskManagement => const [
      'Riscos identificados',
      'Probabilidade',
      'Impacto',
      'Controles',
      'Plano de resposta',
    ],
    AtlasGovernancePeopleModule.permissionMatrix => const [
      'Usuários',
      'Papéis',
      'Módulos',
      'Operações',
      'Níveis de acesso',
    ],
    AtlasGovernancePeopleModule.governanceCenter => const [
      'Pessoas',
      'Documentos',
      'Conformidade',
      'Riscos',
      'Painel executivo',
    ],
  };
}

class AtlasGovernancePeopleRecord {
  const AtlasGovernancePeopleRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.personName,
    required this.roleName,
    required this.departmentName,
    required this.documentName,
    required this.requirementName,
    required this.riskName,
    required this.responsible,
    required this.probabilityPercent,
    required this.impactPercent,
    required this.progressPercent,
    required this.compliancePercent,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasGovernancePeopleModule module;
  final String feature;
  final String title;
  final String date;
  final String dueDate;
  final String status;
  final String priority;
  final String personName;
  final String roleName;
  final String departmentName;
  final String documentName;
  final String requirementName;
  final String riskName;
  final String responsible;
  final double probabilityPercent;
  final double impactPercent;
  final int progressPercent;
  final double compliancePercent;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Não conforme' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Conforme' ||
      status == 'Validado' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasGovernancePeopleDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Conforme' &&
        status != 'Cancelado';
  }

  double get riskScore => probabilityPercent * impactPercent / 100;

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module.code,
    'feature': feature,
    'title': title,
    'date': date,
    'dueDate': dueDate,
    'status': status,
    'priority': priority,
    'personName': personName,
    'roleName': roleName,
    'departmentName': departmentName,
    'documentName': documentName,
    'requirementName': requirementName,
    'riskName': riskName,
    'responsible': responsible,
    'probabilityPercent': probabilityPercent,
    'impactPercent': impactPercent,
    'progressPercent': progressPercent,
    'compliancePercent': compliancePercent,
    'alertCount': alertCount,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AtlasGovernancePeopleRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasGovernancePeopleModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasGovernancePeopleModule.peopleManagement,
    );

    return AtlasGovernancePeopleRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      dueDate: map['dueDate']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      priority: map['priority']?.toString() ?? 'Média',
      personName: map['personName']?.toString() ?? '',
      roleName: map['roleName']?.toString() ?? '',
      departmentName: map['departmentName']?.toString() ?? '',
      documentName: map['documentName']?.toString() ?? '',
      requirementName: map['requirementName']?.toString() ?? '',
      riskName: map['riskName']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      probabilityPercent: (map['probabilityPercent'] as num?)?.toDouble() ?? 0,
      impactPercent: (map['impactPercent'] as num?)?.toDouble() ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      compliancePercent: (map['compliancePercent'] as num?)?.toDouble() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasGovernancePeopleDate(String value) {
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

String formatAtlasGovernancePeopleDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
