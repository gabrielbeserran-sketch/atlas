enum AtlasPrecisionLivestockModule {
  weightPrediction,
  dailyGainPrediction,
  estimatedIntake,
  feedEfficiency,
  feedConversion,
  animalWelfare,
  earlyDiseaseDetection,
  heatStress,
  mortalityRisk,
  generalEfficiencyIndex,
}

extension AtlasPrecisionLivestockModuleX on AtlasPrecisionLivestockModule {
  String get code => switch (this) {
    AtlasPrecisionLivestockModule.weightPrediction => 'weight_prediction',
    AtlasPrecisionLivestockModule.dailyGainPrediction =>
      'daily_gain_prediction',
    AtlasPrecisionLivestockModule.estimatedIntake => 'estimated_intake',
    AtlasPrecisionLivestockModule.feedEfficiency => 'feed_efficiency',
    AtlasPrecisionLivestockModule.feedConversion => 'feed_conversion',
    AtlasPrecisionLivestockModule.animalWelfare => 'animal_welfare',
    AtlasPrecisionLivestockModule.earlyDiseaseDetection =>
      'early_disease_detection',
    AtlasPrecisionLivestockModule.heatStress => 'heat_stress',
    AtlasPrecisionLivestockModule.mortalityRisk => 'mortality_risk',
    AtlasPrecisionLivestockModule.generalEfficiencyIndex =>
      'general_efficiency_index',
  };

  String get title => switch (this) {
    AtlasPrecisionLivestockModule.weightPrediction => 'Predição de Peso',
    AtlasPrecisionLivestockModule.dailyGainPrediction =>
      'Predição de Ganho Diário',
    AtlasPrecisionLivestockModule.estimatedIntake => 'Consumo Estimado',
    AtlasPrecisionLivestockModule.feedEfficiency => 'Eficiência Alimentar',
    AtlasPrecisionLivestockModule.feedConversion => 'Conversão Alimentar',
    AtlasPrecisionLivestockModule.animalWelfare => 'Bem-estar Animal',
    AtlasPrecisionLivestockModule.earlyDiseaseDetection =>
      'Detecção Precoce de Doenças',
    AtlasPrecisionLivestockModule.heatStress => 'Estresse Térmico',
    AtlasPrecisionLivestockModule.mortalityRisk => 'Mortalidade Prevista',
    AtlasPrecisionLivestockModule.generalEfficiencyIndex =>
      'Índice Geral de Eficiência',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasPrecisionLivestockModule.weightPrediction => const [
      'Peso atual',
      'Curva de crescimento',
      'Peso projetado',
      'Data-alvo',
      'Desvio e confiança',
    ],
    AtlasPrecisionLivestockModule.dailyGainPrediction => const [
      'GMD observado',
      'GMD projetado',
      'Tendência',
      'Meta de ganho',
      'Alertas de desempenho',
    ],
    AtlasPrecisionLivestockModule.estimatedIntake => const [
      'Consumo de matéria seca',
      'Consumo por peso vivo',
      'Disponibilidade de alimento',
      'Estimativa diária',
      'Desvios de consumo',
    ],
    AtlasPrecisionLivestockModule.feedEfficiency => const [
      'Ganho por consumo',
      'Eficiência individual',
      'Comparação de lote',
      'Tendência',
      'Classificação',
    ],
    AtlasPrecisionLivestockModule.feedConversion => const [
      'Conversão observada',
      'Conversão projetada',
      'Meta de conversão',
      'Custo por ganho',
      'Alertas de ineficiência',
    ],
    AtlasPrecisionLivestockModule.animalWelfare => const [
      'Comportamento',
      'Locomoção',
      'Conforto',
      'Interações sociais',
      'Score de bem-estar',
    ],
    AtlasPrecisionLivestockModule.earlyDiseaseDetection => const [
      'Sinais precoces',
      'Mudança comportamental',
      'Queda de consumo',
      'Prioridade de triagem',
      'Encaminhamento veterinário',
    ],
    AtlasPrecisionLivestockModule.heatStress => const [
      'Temperatura e umidade',
      'Índice térmico',
      'Risco por animal',
      'Resposta comportamental',
      'Ações preventivas',
    ],
    AtlasPrecisionLivestockModule.mortalityRisk => const [
      'Fatores de risco',
      'Probabilidade estimada',
      'Horizonte de risco',
      'Prioridade de intervenção',
      'Acompanhamento',
    ],
    AtlasPrecisionLivestockModule.generalEfficiencyIndex => const [
      'Peso e ganho',
      'Consumo e eficiência',
      'Sanidade e bem-estar',
      'Risco climático',
      'Score consolidado',
    ],
  };
}

class AtlasPrecisionLivestockRecord {
  const AtlasPrecisionLivestockRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.animalReference,
    required this.groupReference,
    required this.metricName,
    required this.currentValue,
    required this.projectedValue,
    required this.targetValue,
    required this.unit,
    required this.confidencePercent,
    required this.riskPercent,
    required this.financialImpact,
    required this.progressPercent,
    required this.alertCount,
    required this.horizonDays,
    required this.responsible,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasPrecisionLivestockModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String animalReference;
  final String groupReference;
  final String metricName;
  final double currentValue;
  final double projectedValue;
  final double targetValue;
  final String unit;
  final double confidencePercent;
  final double riskPercent;
  final double financialImpact;
  final int progressPercent;
  final int alertCount;
  final int horizonDays;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'animalReference': animalReference,
      'groupReference': groupReference,
      'metricName': metricName,
      'currentValue': currentValue,
      'projectedValue': projectedValue,
      'targetValue': targetValue,
      'unit': unit,
      'confidencePercent': confidencePercent,
      'riskPercent': riskPercent,
      'financialImpact': financialImpact,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'horizonDays': horizonDays,
      'responsible': responsible,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasPrecisionLivestockRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasPrecisionLivestockModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasPrecisionLivestockModule.weightPrediction,
    );

    return AtlasPrecisionLivestockRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      animalReference: map['animalReference']?.toString() ?? '',
      groupReference: map['groupReference']?.toString() ?? '',
      metricName: map['metricName']?.toString() ?? '',
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0.0,
      projectedValue: (map['projectedValue'] as num?)?.toDouble() ?? 0.0,
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? '',
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 0.0,
      riskPercent: (map['riskPercent'] as num?)?.toDouble() ?? 0.0,
      financialImpact: (map['financialImpact'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      horizonDays: (map['horizonDays'] as num?)?.toInt() ?? 0,
      responsible: map['responsible']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasPrecisionLivestockDate(String value) {
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

String formatAtlasPrecisionLivestockDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
