enum AtlasSustainabilityEnterpriseModule {
  carbonFootprint,
  greenhouseGasInventory,
  waterManagement,
  energyEfficiency,
  wasteManagement,
  biodiversity,
  environmentalCompliance,
  sustainabilityCertifications,
  sustainableTraceability,
  esgCenter,
}

extension AtlasSustainabilityEnterpriseModuleX
    on AtlasSustainabilityEnterpriseModule {
  String get code => switch (this) {
    AtlasSustainabilityEnterpriseModule.carbonFootprint => 'carbon_footprint',
    AtlasSustainabilityEnterpriseModule.greenhouseGasInventory =>
      'greenhouse_gas_inventory',
    AtlasSustainabilityEnterpriseModule.waterManagement => 'water_management',
    AtlasSustainabilityEnterpriseModule.energyEfficiency => 'energy_efficiency',
    AtlasSustainabilityEnterpriseModule.wasteManagement => 'waste_management',
    AtlasSustainabilityEnterpriseModule.biodiversity => 'biodiversity',
    AtlasSustainabilityEnterpriseModule.environmentalCompliance =>
      'environmental_compliance',
    AtlasSustainabilityEnterpriseModule.sustainabilityCertifications =>
      'sustainability_certifications',
    AtlasSustainabilityEnterpriseModule.sustainableTraceability =>
      'sustainable_traceability',
    AtlasSustainabilityEnterpriseModule.esgCenter => 'esg_center',
  };

  String get title => switch (this) {
    AtlasSustainabilityEnterpriseModule.carbonFootprint => 'Pegada de Carbono',
    AtlasSustainabilityEnterpriseModule.greenhouseGasInventory =>
      'Inventário de Gases de Efeito Estufa',
    AtlasSustainabilityEnterpriseModule.waterManagement => 'Gestão Hídrica',
    AtlasSustainabilityEnterpriseModule.energyEfficiency =>
      'Eficiência Energética',
    AtlasSustainabilityEnterpriseModule.wasteManagement => 'Gestão de Resíduos',
    AtlasSustainabilityEnterpriseModule.biodiversity => 'Biodiversidade',
    AtlasSustainabilityEnterpriseModule.environmentalCompliance =>
      'Conformidade Ambiental',
    AtlasSustainabilityEnterpriseModule.sustainabilityCertifications =>
      'Certificações de Sustentabilidade',
    AtlasSustainabilityEnterpriseModule.sustainableTraceability =>
      'Rastreabilidade Sustentável',
    AtlasSustainabilityEnterpriseModule.esgCenter => 'Central ESG',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasSustainabilityEnterpriseModule.carbonFootprint => const [
      'Fontes de emissão',
      'Emissões por atividade',
      'Emissões por animal',
      'Compensações',
      'Meta de redução',
    ],
    AtlasSustainabilityEnterpriseModule.greenhouseGasInventory => const [
      'Escopo 1',
      'Escopo 2',
      'Escopo 3',
      'Fatores de emissão',
      'Relatório consolidado',
    ],
    AtlasSustainabilityEnterpriseModule.waterManagement => const [
      'Captação',
      'Consumo',
      'Qualidade da água',
      'Reuso',
      'Meta de eficiência hídrica',
    ],
    AtlasSustainabilityEnterpriseModule.energyEfficiency => const [
      'Consumo total',
      'Consumo por atividade',
      'Fontes renováveis',
      'Eficiência operacional',
      'Plano de redução',
    ],
    AtlasSustainabilityEnterpriseModule.wasteManagement => const [
      'Resíduos orgânicos',
      'Resíduos recicláveis',
      'Resíduos perigosos',
      'Destino final',
      'Economia circular',
    ],
    AtlasSustainabilityEnterpriseModule.biodiversity => const [
      'Áreas conservadas',
      'Espécies observadas',
      'Corredores ecológicos',
      'Riscos ambientais',
      'Plano de conservação',
    ],
    AtlasSustainabilityEnterpriseModule.environmentalCompliance => const [
      'Licenças',
      'Condicionantes',
      'Prazos',
      'Evidências',
      'Não conformidades',
    ],
    AtlasSustainabilityEnterpriseModule.sustainabilityCertifications => const [
      'Certificações',
      'Requisitos',
      'Auditorias',
      'Validade',
      'Plano de adequação',
    ],
    AtlasSustainabilityEnterpriseModule.sustainableTraceability => const [
      'Origem',
      'Cadeia de custódia',
      'Evidências ambientais',
      'Fornecedores',
      'Destino comercial',
    ],
    AtlasSustainabilityEnterpriseModule.esgCenter => const [
      'Indicadores ambientais',
      'Indicadores sociais',
      'Indicadores de governança',
      'Metas e alertas',
      'Painel executivo',
    ],
  };
}

class AtlasSustainabilityEnterpriseRecord {
  const AtlasSustainabilityEnterpriseRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.companyName,
    required this.farmName,
    required this.scope,
    required this.metricName,
    required this.currentValue,
    required this.baselineValue,
    required this.targetValue,
    required this.unit,
    required this.qualityPercent,
    required this.progressPercent,
    required this.alertCount,
    required this.dueDate,
    required this.responsible,
    required this.evidence,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasSustainabilityEnterpriseModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String companyName;
  final String farmName;
  final String scope;
  final String metricName;
  final double currentValue;
  final double baselineValue;
  final double targetValue;
  final String unit;
  final double qualityPercent;
  final int progressPercent;
  final int alertCount;
  final String dueDate;
  final String responsible;
  final String evidence;
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
      status == 'Validado' ||
      status == 'Conforme' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasSustainabilityDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Conforme';
  }

  double get changePercent {
    if (baselineValue == 0) return 0.0;
    return (currentValue - baselineValue) * 100 / baselineValue.abs();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'companyName': companyName,
      'farmName': farmName,
      'scope': scope,
      'metricName': metricName,
      'currentValue': currentValue,
      'baselineValue': baselineValue,
      'targetValue': targetValue,
      'unit': unit,
      'qualityPercent': qualityPercent,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'dueDate': dueDate,
      'responsible': responsible,
      'evidence': evidence,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasSustainabilityEnterpriseRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasSustainabilityEnterpriseModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasSustainabilityEnterpriseModule.carbonFootprint,
    );

    return AtlasSustainabilityEnterpriseRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      companyName: map['companyName']?.toString() ?? '',
      farmName: map['farmName']?.toString() ?? '',
      scope: map['scope']?.toString() ?? '',
      metricName: map['metricName']?.toString() ?? '',
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0.0,
      baselineValue: (map['baselineValue'] as num?)?.toDouble() ?? 0.0,
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? '',
      qualityPercent: (map['qualityPercent'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      dueDate: map['dueDate']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      evidence: map['evidence']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasSustainabilityDate(String value) {
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

String formatAtlasSustainabilityDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
