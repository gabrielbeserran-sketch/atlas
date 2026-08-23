enum AtlasPredictiveAiModule { nutrition, economics, commercialization }

extension AtlasPredictiveAiModuleX on AtlasPredictiveAiModule {
  String get code => switch (this) {
    AtlasPredictiveAiModule.nutrition => 'nutrition',
    AtlasPredictiveAiModule.economics => 'economics',
    AtlasPredictiveAiModule.commercialization => 'commercialization',
  };

  String get title => switch (this) {
    AtlasPredictiveAiModule.nutrition => 'IA Nutricional',
    AtlasPredictiveAiModule.economics => 'IA Econômica',
    AtlasPredictiveAiModule.commercialization => 'IA de Comercialização',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasPredictiveAiModule.nutrition => const [
      'Formulação inteligente de dietas',
      'Ajuste automático conforme peso',
      'Consumo previsto',
      'Eficiência alimentar',
      'Alerta de desperdício',
    ],
    AtlasPredictiveAiModule.economics => const [
      'Previsão de lucro',
      'Fluxo de caixa preditivo',
      'Simulação financeira',
      'Payback automático',
      'ROI em tempo real',
    ],
    AtlasPredictiveAiModule.commercialization => const [
      'Predição do preço da arroba',
      'Melhor momento para venda',
      'Comparação de frigoríficos',
      'Ranking de compradores',
      'Simulador de negociação',
    ],
  };
}

class AtlasPredictiveAiRecord {
  const AtlasPredictiveAiRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.primaryInput,
    required this.secondaryInput,
    required this.tertiaryInput,
    required this.costValue,
    required this.revenueValue,
    required this.periodDays,
    required this.referenceName,
    required this.unit,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasPredictiveAiModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final double primaryInput;
  final double secondaryInput;
  final double tertiaryInput;
  final double costValue;
  final double revenueValue;
  final int periodDays;
  final String referenceName;
  final String unit;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical => status == 'Crítico' || status == 'Atenção';

  bool get isCompleted => status == 'Concluído' || status == 'Ativo';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'primaryInput': primaryInput,
      'secondaryInput': secondaryInput,
      'tertiaryInput': tertiaryInput,
      'costValue': costValue,
      'revenueValue': revenueValue,
      'periodDays': periodDays,
      'referenceName': referenceName,
      'unit': unit,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasPredictiveAiRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasPredictiveAiModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasPredictiveAiModule.nutrition,
    );

    return AtlasPredictiveAiRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      primaryInput: (map['primaryInput'] as num?)?.toDouble() ?? 0,
      secondaryInput: (map['secondaryInput'] as num?)?.toDouble() ?? 0,
      tertiaryInput: (map['tertiaryInput'] as num?)?.toDouble() ?? 0,
      costValue: (map['costValue'] as num?)?.toDouble() ?? 0,
      revenueValue: (map['revenueValue'] as num?)?.toDouble() ?? 0,
      periodDays: (map['periodDays'] as num?)?.toInt() ?? 0,
      referenceName: map['referenceName']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasPredictiveDate(String value) {
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

String formatAtlasPredictiveDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
