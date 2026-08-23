enum AtlasExecutiveIntelligenceModule {
  enterpriseCrm,
  financialCenter,
  businessIntelligence,
  strategicCenter,
  commandCenter,
}

extension AtlasExecutiveIntelligenceModuleX
    on AtlasExecutiveIntelligenceModule {
  String get code => switch (this) {
    AtlasExecutiveIntelligenceModule.enterpriseCrm => 'enterprise_crm',
    AtlasExecutiveIntelligenceModule.financialCenter => 'financial_center',
    AtlasExecutiveIntelligenceModule.businessIntelligence =>
      'business_intelligence',
    AtlasExecutiveIntelligenceModule.strategicCenter => 'strategic_center',
    AtlasExecutiveIntelligenceModule.commandCenter => 'command_center',
  };

  String get title => switch (this) {
    AtlasExecutiveIntelligenceModule.enterpriseCrm => 'CRM Enterprise',
    AtlasExecutiveIntelligenceModule.financialCenter => 'Central Financeira',
    AtlasExecutiveIntelligenceModule.businessIntelligence =>
      'Business Intelligence',
    AtlasExecutiveIntelligenceModule.strategicCenter =>
      'Central Estratégica Atlas AI',
    AtlasExecutiveIntelligenceModule.commandCenter =>
      'Enterprise Command Center',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasExecutiveIntelligenceModule.enterpriseCrm => const [
      'Clientes e propriedades',
      'Atendimentos e visitas',
      'Propostas e contratos',
      'Pipeline comercial',
      'Rentabilidade e fidelização',
    ],
    AtlasExecutiveIntelligenceModule.financialCenter => const [
      'Fluxo de caixa',
      'Contas a pagar e receber',
      'DRE e resultado',
      'Centros de custo',
      'Forecast e simulações',
    ],
    AtlasExecutiveIntelligenceModule.businessIntelligence => const [
      'KPIs e scorecards',
      'Dashboards executivos',
      'Benchmark entre fazendas',
      'Tendências e séries temporais',
      'Drill-down e exportações',
    ],
    AtlasExecutiveIntelligenceModule.strategicCenter => const [
      'Objetivos e OKRs',
      'Metas e indicadores',
      'Riscos estratégicos',
      'Cenários e simulações',
      'Planos de ação',
    ],
    AtlasExecutiveIntelligenceModule.commandCenter => const [
      'Saúde operacional',
      'Saúde financeira',
      'Saúde produtiva',
      'Alertas globais',
      'Radar de prioridades',
    ],
  };
}

class AtlasExecutiveIntelligenceRecord {
  const AtlasExecutiveIntelligenceRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.responsible,
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
  final AtlasExecutiveIntelligenceModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String responsible;
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
      status == 'Vencido' ||
      status == 'Bloqueado' ||
      status == 'Atenção' ||
      status == 'Em risco';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Aprovado' ||
      status == 'Em execução' ||
      status == 'Concluído' ||
      status == 'Saudável';

  bool get isOverdue {
    final parsed = parseAtlasExecutiveDate(dueDate);
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
      'responsible': responsible,
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

  factory AtlasExecutiveIntelligenceRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasExecutiveIntelligenceModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasExecutiveIntelligenceModule.enterpriseCrm,
    );

    return AtlasExecutiveIntelligenceRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      responsible: map['responsible']?.toString() ?? '',
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

DateTime parseAtlasExecutiveDate(String value) {
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

String formatAtlasExecutiveDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
