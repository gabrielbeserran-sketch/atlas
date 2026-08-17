enum AtlasEnvironmentalAiModule { climate, pasture, satellite }

extension AtlasEnvironmentalAiModuleX on AtlasEnvironmentalAiModule {
  String get code => switch (this) {
    AtlasEnvironmentalAiModule.climate => 'climate',
    AtlasEnvironmentalAiModule.pasture => 'pasture',
    AtlasEnvironmentalAiModule.satellite => 'satellite',
  };

  String get title => switch (this) {
    AtlasEnvironmentalAiModule.climate => 'IA Climática',
    AtlasEnvironmentalAiModule.pasture => 'IA de Pastagens',
    AtlasEnvironmentalAiModule.satellite => 'Monitoramento por Satélite',
  };

  String get packageLabel => switch (this) {
    AtlasEnvironmentalAiModule.climate => 'Pacote 56',
    AtlasEnvironmentalAiModule.pasture => 'Pacote 57',
    AtlasEnvironmentalAiModule.satellite => 'Pacote 58',
  };

  List<String> get features => switch (this) {
    AtlasEnvironmentalAiModule.climate => const [
      'Previsão climática integrada',
      'Impacto no ganho de peso',
      'Impacto na reprodução',
      'Impacto na pastagem',
      'Plano preventivo automático',
    ],
    AtlasEnvironmentalAiModule.pasture => const [
      'Índice de degradação',
      'Recuperação automática',
      'Lotação ideal',
      'Rotação recomendada',
      'Predição de disponibilidade',
    ],
    AtlasEnvironmentalAiModule.satellite => const [
      'Imagens Sentinel',
      'NDVI',
      'Biomassa',
      'Umidade',
      'Alertas ambientais',
    ],
  };
}

class AtlasEnvironmentalAiRecord {
  const AtlasEnvironmentalAiRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.temperatureCelsius,
    required this.rainfallMillimeters,
    required this.humidityPercent,
    required this.primaryValue,
    required this.secondaryValue,
    required this.areaHectares,
    required this.stockingRateUaHa,
    required this.referenceName,
    required this.unit,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasEnvironmentalAiModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final double temperatureCelsius;
  final double rainfallMillimeters;
  final double humidityPercent;
  final double primaryValue;
  final double secondaryValue;
  final double areaHectares;
  final double stockingRateUaHa;
  final String referenceName;
  final String unit;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Atenção' ||
      status == 'Seca' ||
      status == 'Alagado';

  bool get isCompleted =>
      status == 'Ativo' || status == 'Concluído' || status == 'Monitorado';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'temperatureCelsius': temperatureCelsius,
      'rainfallMillimeters': rainfallMillimeters,
      'humidityPercent': humidityPercent,
      'primaryValue': primaryValue,
      'secondaryValue': secondaryValue,
      'areaHectares': areaHectares,
      'stockingRateUaHa': stockingRateUaHa,
      'referenceName': referenceName,
      'unit': unit,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasEnvironmentalAiRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasEnvironmentalAiModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasEnvironmentalAiModule.climate,
    );

    return AtlasEnvironmentalAiRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      temperatureCelsius: (map['temperatureCelsius'] as num?)?.toDouble() ?? 0,
      rainfallMillimeters:
          (map['rainfallMillimeters'] as num?)?.toDouble() ?? 0,
      humidityPercent: (map['humidityPercent'] as num?)?.toDouble() ?? 0,
      primaryValue: (map['primaryValue'] as num?)?.toDouble() ?? 0,
      secondaryValue: (map['secondaryValue'] as num?)?.toDouble() ?? 0,
      areaHectares: (map['areaHectares'] as num?)?.toDouble() ?? 0,
      stockingRateUaHa: (map['stockingRateUaHa'] as num?)?.toDouble() ?? 0,
      referenceName: map['referenceName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasEnvironmentalDate(String value) {
  final iso = DateTime.tryParse(value.trim());
  if (iso != null) return iso;

  final parts = value.trim().split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasEnvironmentalDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
