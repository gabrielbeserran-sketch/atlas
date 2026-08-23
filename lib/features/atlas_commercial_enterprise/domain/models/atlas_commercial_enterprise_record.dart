enum AtlasCommercialEnterpriseModule {
  premiumCrm,
  intelligentPipeline,
  digitalContracts,
  electronicSignature,
  customerManagement,
  afterSales,
  commercialIndicators,
  servicesMarketplace,
  auctions,
  commercialCenter,
}

extension AtlasCommercialEnterpriseModuleX on AtlasCommercialEnterpriseModule {
  String get code => switch (this) {
    AtlasCommercialEnterpriseModule.premiumCrm => 'premium_crm',
    AtlasCommercialEnterpriseModule.intelligentPipeline =>
      'intelligent_pipeline',
    AtlasCommercialEnterpriseModule.digitalContracts => 'digital_contracts',
    AtlasCommercialEnterpriseModule.electronicSignature =>
      'electronic_signature',
    AtlasCommercialEnterpriseModule.customerManagement => 'customer_management',
    AtlasCommercialEnterpriseModule.afterSales => 'after_sales',
    AtlasCommercialEnterpriseModule.commercialIndicators =>
      'commercial_indicators',
    AtlasCommercialEnterpriseModule.servicesMarketplace =>
      'services_marketplace',
    AtlasCommercialEnterpriseModule.auctions => 'auctions',
    AtlasCommercialEnterpriseModule.commercialCenter => 'commercial_center',
  };

  String get title => switch (this) {
    AtlasCommercialEnterpriseModule.premiumCrm => 'CRM Premium',
    AtlasCommercialEnterpriseModule.intelligentPipeline =>
      'Pipeline Inteligente',
    AtlasCommercialEnterpriseModule.digitalContracts => 'Contratos Digitais',
    AtlasCommercialEnterpriseModule.electronicSignature =>
      'Assinatura Eletrônica',
    AtlasCommercialEnterpriseModule.customerManagement => 'Gestão de Clientes',
    AtlasCommercialEnterpriseModule.afterSales => 'Pós-venda',
    AtlasCommercialEnterpriseModule.commercialIndicators =>
      'Indicadores Comerciais',
    AtlasCommercialEnterpriseModule.servicesMarketplace =>
      'Marketplace de Serviços',
    AtlasCommercialEnterpriseModule.auctions => 'Leilões',
    AtlasCommercialEnterpriseModule.commercialCenter => 'Central Comercial',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasCommercialEnterpriseModule.premiumCrm => const [
      'Leads e oportunidades',
      'Interações',
      'Tarefas comerciais',
      'Segmentação',
      'Histórico do relacionamento',
    ],
    AtlasCommercialEnterpriseModule.intelligentPipeline => const [
      'Etapas do funil',
      'Probabilidade de fechamento',
      'Valor potencial',
      'Próxima ação',
      'Previsão comercial',
    ],
    AtlasCommercialEnterpriseModule.digitalContracts => const [
      'Minutas',
      'Partes e condições',
      'Versões',
      'Aprovação',
      'Vigência e renovação',
    ],
    AtlasCommercialEnterpriseModule.electronicSignature => const [
      'Signatários',
      'Ordem de assinatura',
      'Envio',
      'Evidências',
      'Conclusão e auditoria',
    ],
    AtlasCommercialEnterpriseModule.customerManagement => const [
      'Cadastro de clientes',
      'Classificação',
      'Documentos',
      'Preferências',
      'Risco e crédito',
    ],
    AtlasCommercialEnterpriseModule.afterSales => const [
      'Acompanhamento',
      'Solicitações',
      'Satisfação',
      'Renovação',
      'Oportunidades adicionais',
    ],
    AtlasCommercialEnterpriseModule.commercialIndicators => const [
      'Receita comercial',
      'Ticket médio',
      'Conversão',
      'Ciclo de vendas',
      'Previsão versus realizado',
    ],
    AtlasCommercialEnterpriseModule.servicesMarketplace => const [
      'Oferta de serviços',
      'Solicitações',
      'Propostas',
      'Contratações',
      'Avaliações',
    ],
    AtlasCommercialEnterpriseModule.auctions => const [
      'Eventos',
      'Lotes',
      'Lances',
      'Arremates',
      'Liquidação',
    ],
    AtlasCommercialEnterpriseModule.commercialCenter => const [
      'Indicadores consolidados',
      'Pipeline',
      'Contratos',
      'Alertas',
      'Painel executivo',
    ],
  };
}

class AtlasCommercialEnterpriseRecord {
  const AtlasCommercialEnterpriseRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.customerName,
    required this.companyName,
    required this.referenceId,
    required this.stage,
    required this.owner,
    required this.potentialValue,
    required this.actualValue,
    required this.probabilityPercent,
    required this.progressPercent,
    required this.satisfactionPercent,
    required this.alertCount,
    required this.dueDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasCommercialEnterpriseModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String customerName;
  final String companyName;
  final String referenceId;
  final String stage;
  final String owner;
  final double potentialValue;
  final double actualValue;
  final double probabilityPercent;
  final int progressPercent;
  final double satisfactionPercent;
  final int alertCount;
  final String dueDate;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Perdido' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Aprovado' ||
      status == 'Assinado' ||
      status == 'Concluído' ||
      status == 'Ganho';

  bool get isOverdue {
    final parsed = parseAtlasCommercialDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Assinado' &&
        status != 'Ganho';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'customerName': customerName,
      'companyName': companyName,
      'referenceId': referenceId,
      'stage': stage,
      'owner': owner,
      'potentialValue': potentialValue,
      'actualValue': actualValue,
      'probabilityPercent': probabilityPercent,
      'progressPercent': progressPercent,
      'satisfactionPercent': satisfactionPercent,
      'alertCount': alertCount,
      'dueDate': dueDate,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasCommercialEnterpriseRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasCommercialEnterpriseModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasCommercialEnterpriseModule.premiumCrm,
    );

    return AtlasCommercialEnterpriseRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      customerName: map['customerName']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      referenceId: map['referenceId']?.toString() ?? '',
      stage: map['stage']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      potentialValue: (map['potentialValue'] as num?)?.toDouble() ?? 0.0,
      actualValue: (map['actualValue'] as num?)?.toDouble() ?? 0.0,
      probabilityPercent:
          (map['probabilityPercent'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      satisfactionPercent:
          (map['satisfactionPercent'] as num?)?.toDouble() ?? 0.0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      dueDate: map['dueDate']?.toString() ?? '',
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
