enum AtlasGeospatialModule {
  gisMaps,
  smartPaddocks,
  automaticRotation,
  pasturePlanning,
  ndvi,
  biomass,
  soil,
  slope,
  irrigation,
  territorialPlanning,
}

extension AtlasGeospatialModuleX on AtlasGeospatialModule {
  String get code => switch (this) {
    AtlasGeospatialModule.gisMaps => 'gis_maps',
    AtlasGeospatialModule.smartPaddocks => 'smart_paddocks',
    AtlasGeospatialModule.automaticRotation => 'automatic_rotation',
    AtlasGeospatialModule.pasturePlanning => 'pasture_planning',
    AtlasGeospatialModule.ndvi => 'ndvi',
    AtlasGeospatialModule.biomass => 'biomass',
    AtlasGeospatialModule.soil => 'soil',
    AtlasGeospatialModule.slope => 'slope',
    AtlasGeospatialModule.irrigation => 'irrigation',
    AtlasGeospatialModule.territorialPlanning => 'territorial_planning',
  };

  String get title => switch (this) {
    AtlasGeospatialModule.gisMaps => 'Mapas GIS',
    AtlasGeospatialModule.smartPaddocks => 'Piquetes Inteligentes',
    AtlasGeospatialModule.automaticRotation => 'Rotação Automática',
    AtlasGeospatialModule.pasturePlanning => 'Planejamento de Pastagens',
    AtlasGeospatialModule.ndvi => 'Inteligência NDVI',
    AtlasGeospatialModule.biomass => 'Estimativa de Biomassa',
    AtlasGeospatialModule.soil => 'Inteligência de Solo',
    AtlasGeospatialModule.slope => 'Análise de Declividade',
    AtlasGeospatialModule.irrigation => 'Gestão de Irrigação',
    AtlasGeospatialModule.territorialPlanning => 'Planejamento Territorial',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasGeospatialModule.gisMaps => const [
      'Camadas geográficas',
      'Limites e áreas',
      'Pontos de interesse',
      'Medições',
      'Importação e exportação',
    ],
    AtlasGeospatialModule.smartPaddocks => const [
      'Cadastro de piquetes',
      'Capacidade de suporte',
      'Disponibilidade de forragem',
      'Lotação',
      'Alertas operacionais',
    ],
    AtlasGeospatialModule.automaticRotation => const [
      'Sequência de rotação',
      'Entrada e saída',
      'Dias de ocupação',
      'Dias de descanso',
      'Recomendações de movimentação',
    ],
    AtlasGeospatialModule.pasturePlanning => const [
      'Espécies forrageiras',
      'Calendário de manejo',
      'Reforma e recuperação',
      'Adubação',
      'Metas produtivas',
    ],
    AtlasGeospatialModule.ndvi => const [
      'Índice de vegetação',
      'Mapas por período',
      'Comparativos',
      'Anomalias',
      'Alertas de cobertura',
    ],
    AtlasGeospatialModule.biomass => const [
      'Massa de forragem',
      'Matéria seca',
      'Oferta por hectare',
      'Tendência',
      'Validação de campo',
    ],
    AtlasGeospatialModule.soil => const [
      'Amostras de solo',
      'Fertilidade',
      'Textura',
      'Correção e adubação',
      'Zonas de manejo',
    ],
    AtlasGeospatialModule.slope => const [
      'Classes de declividade',
      'Risco de erosão',
      'Acessibilidade',
      'Uso recomendado',
      'Restrições operacionais',
    ],
    AtlasGeospatialModule.irrigation => const [
      'Setores irrigados',
      'Lâmina aplicada',
      'Demanda hídrica',
      'Programação',
      'Eficiência e alertas',
    ],
    AtlasGeospatialModule.territorialPlanning => const [
      'Zoneamento',
      'Infraestrutura',
      'Áreas produtivas',
      'Áreas de proteção',
      'Cenários territoriais',
    ],
  };
}

class AtlasGeospatialRecord {
  const AtlasGeospatialRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.areaName,
    required this.areaHectares,
    required this.latitude,
    required this.longitude,
    required this.metricName,
    required this.metricValue,
    required this.unit,
    required this.qualityPercent,
    required this.progressPercent,
    required this.alertCount,
    required this.referenceDate,
    required this.source,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasGeospatialModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String areaName;
  final double areaHectares;
  final double latitude;
  final double longitude;
  final String metricName;
  final double metricValue;
  final String unit;
  final double qualityPercent;
  final int progressPercent;
  final int alertCount;
  final String referenceDate;
  final String source;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Inconsistente' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Validado' ||
      status == 'Monitorado' ||
      status == 'Concluído';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'areaName': areaName,
      'areaHectares': areaHectares,
      'latitude': latitude,
      'longitude': longitude,
      'metricName': metricName,
      'metricValue': metricValue,
      'unit': unit,
      'qualityPercent': qualityPercent,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'referenceDate': referenceDate,
      'source': source,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasGeospatialRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasGeospatialModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasGeospatialModule.gisMaps,
    );

    return AtlasGeospatialRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      areaName: map['areaName']?.toString() ?? '',
      areaHectares: (map['areaHectares'] as num?)?.toDouble() ?? 0.0,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      metricName: map['metricName']?.toString() ?? '',
      metricValue: (map['metricValue'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? '',
      qualityPercent: (map['qualityPercent'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      referenceDate: map['referenceDate']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasGeospatialDate(String value) {
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

String formatAtlasGeospatialDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
