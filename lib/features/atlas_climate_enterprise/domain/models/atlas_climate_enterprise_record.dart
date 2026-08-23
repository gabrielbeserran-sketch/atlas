enum AtlasClimateEnterpriseModule {
  climateIntelligence,
  advancedMeteorology,
  intelligentForagePlanning,
  aiPastureManagement,
  climateEnvironmentalIndicators,
  climateRiskManagement,
  predictiveClimateSimulations,
  intelligentClimateAlerts,
  agroclimateDecisionCenter,
  climateIntelligenceCenter,
}

extension AtlasClimateEnterpriseModuleX on AtlasClimateEnterpriseModule {
  String get code => switch (this) {
    AtlasClimateEnterpriseModule.climateIntelligence => 'climate_intelligence',
    AtlasClimateEnterpriseModule.advancedMeteorology => 'advanced_meteorology',
    AtlasClimateEnterpriseModule.intelligentForagePlanning =>
      'intelligent_forage_planning',
    AtlasClimateEnterpriseModule.aiPastureManagement => 'ai_pasture_management',
    AtlasClimateEnterpriseModule.climateEnvironmentalIndicators =>
      'climate_environmental_indicators',
    AtlasClimateEnterpriseModule.climateRiskManagement =>
      'climate_risk_management',
    AtlasClimateEnterpriseModule.predictiveClimateSimulations =>
      'predictive_climate_simulations',
    AtlasClimateEnterpriseModule.intelligentClimateAlerts =>
      'intelligent_climate_alerts',
    AtlasClimateEnterpriseModule.agroclimateDecisionCenter =>
      'agroclimate_decision_center',
    AtlasClimateEnterpriseModule.climateIntelligenceCenter =>
      'climate_intelligence_center',
  };

  String get title => switch (this) {
    AtlasClimateEnterpriseModule.climateIntelligence =>
      'Inteligência Climática',
    AtlasClimateEnterpriseModule.advancedMeteorology => 'Meteorologia Avançada',
    AtlasClimateEnterpriseModule.intelligentForagePlanning =>
      'Planejamento Forrageiro Inteligente',
    AtlasClimateEnterpriseModule.aiPastureManagement =>
      'Gestão de Pastagens com IA',
    AtlasClimateEnterpriseModule.climateEnvironmentalIndicators =>
      'Indicadores Climáticos e Ambientais',
    AtlasClimateEnterpriseModule.climateRiskManagement =>
      'Gestão de Riscos Climáticos',
    AtlasClimateEnterpriseModule.predictiveClimateSimulations =>
      'Simulações Climáticas Preditivas',
    AtlasClimateEnterpriseModule.intelligentClimateAlerts =>
      'Alertas Climáticos Inteligentes',
    AtlasClimateEnterpriseModule.agroclimateDecisionCenter =>
      'Central de Decisão Agroclimática',
    AtlasClimateEnterpriseModule.climateIntelligenceCenter =>
      'Atlas Climate Intelligence Center',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasClimateEnterpriseModule.climateIntelligence => const [
      'Contexto climático',
      'Histórico meteorológico',
      'Tendências',
      'Impactos produtivos',
      'Recomendações operacionais',
    ],
    AtlasClimateEnterpriseModule.advancedMeteorology => const [
      'Temperatura e umidade',
      'Precipitação',
      'Vento e pressão',
      'Evapotranspiração',
      'Previsão e observação',
    ],
    AtlasClimateEnterpriseModule.intelligentForagePlanning => const [
      'Demanda do rebanho',
      'Oferta de forragem',
      'Sazonalidade',
      'Reserva estratégica',
      'Plano por período',
    ],
    AtlasClimateEnterpriseModule.aiPastureManagement => const [
      'Condição da pastagem',
      'Lotação recomendada',
      'Entrada e saída',
      'Descanso',
      'Ações de manejo',
    ],
    AtlasClimateEnterpriseModule.climateEnvironmentalIndicators => const [
      'Índice térmico',
      'Balanço hídrico',
      'Déficit de chuva',
      'Umidade do solo',
      'Pressão ambiental',
    ],
    AtlasClimateEnterpriseModule.climateRiskManagement => const [
      'Riscos identificados',
      'Probabilidade',
      'Impacto',
      'Mitigação',
      'Plano de contingência',
    ],
    AtlasClimateEnterpriseModule.predictiveClimateSimulations => const [
      'Cenário base',
      'Cenário seco',
      'Cenário chuvoso',
      'Impacto produtivo',
      'Sensibilidade',
    ],
    AtlasClimateEnterpriseModule.intelligentClimateAlerts => const [
      'Gatilhos',
      'Nível de severidade',
      'Área afetada',
      'Ação recomendada',
      'Confirmação e encerramento',
    ],
    AtlasClimateEnterpriseModule.agroclimateDecisionCenter => const [
      'Decisões prioritárias',
      'Janelas operacionais',
      'Riscos',
      'Planos de ação',
      'Painel executivo',
    ],
    AtlasClimateEnterpriseModule.climateIntelligenceCenter => const [
      'Indicadores consolidados',
      'Previsões',
      'Alertas',
      'Cenários',
      'Governança climática',
    ],
  };
}

class AtlasClimateEnterpriseRecord {
  const AtlasClimateEnterpriseRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.farmName,
    required this.areaName,
    required this.metricName,
    required this.currentValue,
    required this.projectedValue,
    required this.referenceValue,
    required this.unit,
    required this.probabilityPercent,
    required this.confidencePercent,
    required this.riskPercent,
    required this.progressPercent,
    required this.alertCount,
    required this.horizonDays,
    required this.source,
    required this.responsible,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasClimateEnterpriseModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String farmName;
  final String areaName;
  final String metricName;
  final double currentValue;
  final double projectedValue;
  final double referenceValue;
  final String unit;
  final double probabilityPercent;
  final double confidencePercent;
  final double riskPercent;
  final int progressPercent;
  final int alertCount;
  final int horizonDays;
  final String source;
  final String responsible;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Alto risco' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Validado' ||
      status == 'Monitorado' ||
      status == 'Concluído';

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module.code,
    'feature': feature,
    'title': title,
    'date': date,
    'status': status,
    'farmName': farmName,
    'areaName': areaName,
    'metricName': metricName,
    'currentValue': currentValue,
    'projectedValue': projectedValue,
    'referenceValue': referenceValue,
    'unit': unit,
    'probabilityPercent': probabilityPercent,
    'confidencePercent': confidencePercent,
    'riskPercent': riskPercent,
    'progressPercent': progressPercent,
    'alertCount': alertCount,
    'horizonDays': horizonDays,
    'source': source,
    'responsible': responsible,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AtlasClimateEnterpriseRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasClimateEnterpriseModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasClimateEnterpriseModule.climateIntelligence,
    );

    return AtlasClimateEnterpriseRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      farmName: map['farmName']?.toString() ?? '',
      areaName: map['areaName']?.toString() ?? '',
      metricName: map['metricName']?.toString() ?? '',
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0,
      projectedValue: (map['projectedValue'] as num?)?.toDouble() ?? 0,
      referenceValue: (map['referenceValue'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      probabilityPercent: (map['probabilityPercent'] as num?)?.toDouble() ?? 0,
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 0,
      riskPercent: (map['riskPercent'] as num?)?.toDouble() ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      horizonDays: (map['horizonDays'] as num?)?.toInt() ?? 0,
      source: map['source']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasClimateDate(String value) {
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

String formatAtlasClimateDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
