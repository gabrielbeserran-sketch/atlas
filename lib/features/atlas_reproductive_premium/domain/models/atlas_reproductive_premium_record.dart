enum AtlasReproductivePremiumModule {
  advancedIatf,
  individualFertility,
  embryos,
  ivf,
  embryoTransfer,
  geneticCatalog,
  intelligentMating,
  geneticPrediction,
  continuousBreeding,
  reproductiveCenter,
}

extension AtlasReproductivePremiumModuleX on AtlasReproductivePremiumModule {
  String get code => switch (this) {
    AtlasReproductivePremiumModule.advancedIatf => 'advanced_iatf',
    AtlasReproductivePremiumModule.individualFertility =>
      'individual_fertility',
    AtlasReproductivePremiumModule.embryos => 'embryos',
    AtlasReproductivePremiumModule.ivf => 'ivf',
    AtlasReproductivePremiumModule.embryoTransfer => 'embryo_transfer',
    AtlasReproductivePremiumModule.geneticCatalog => 'genetic_catalog',
    AtlasReproductivePremiumModule.intelligentMating => 'intelligent_mating',
    AtlasReproductivePremiumModule.geneticPrediction => 'genetic_prediction',
    AtlasReproductivePremiumModule.continuousBreeding => 'continuous_breeding',
    AtlasReproductivePremiumModule.reproductiveCenter => 'reproductive_center',
  };

  String get title => switch (this) {
    AtlasReproductivePremiumModule.advancedIatf => 'IATF Avançada',
    AtlasReproductivePremiumModule.individualFertility =>
      'Fertilidade Individual',
    AtlasReproductivePremiumModule.embryos => 'Gestão de Embriões',
    AtlasReproductivePremiumModule.ivf => 'Fertilização in Vitro',
    AtlasReproductivePremiumModule.embryoTransfer =>
      'Transferência de Embriões',
    AtlasReproductivePremiumModule.geneticCatalog => 'Catálogo Genético',
    AtlasReproductivePremiumModule.intelligentMating =>
      'Acasalamento Inteligente',
    AtlasReproductivePremiumModule.geneticPrediction => 'Predição Genética',
    AtlasReproductivePremiumModule.continuousBreeding =>
      'Melhoramento Contínuo',
    AtlasReproductivePremiumModule.reproductiveCenter => 'Central Reprodutiva',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasReproductivePremiumModule.advancedIatf => const [
      'Protocolos avançados',
      'Elegibilidade de matrizes',
      'Cronograma hormonal',
      'Inseminações',
      'Resultados e auditoria',
    ],
    AtlasReproductivePremiumModule.individualFertility => const [
      'Histórico reprodutivo',
      'Taxa de concepção',
      'Intervalo entre partos',
      'Risco reprodutivo',
      'Score de fertilidade',
    ],
    AtlasReproductivePremiumModule.embryos => const [
      'Cadastro de embriões',
      'Origem genética',
      'Classificação',
      'Armazenamento',
      'Destino e rastreabilidade',
    ],
    AtlasReproductivePremiumModule.ivf => const [
      'Aspiração folicular',
      'Produção de oócitos',
      'Fertilização',
      'Cultivo embrionário',
      'Resultado laboratorial',
    ],
    AtlasReproductivePremiumModule.embryoTransfer => const [
      'Receptoras',
      'Sincronização',
      'Transferências',
      'Diagnóstico de gestação',
      'Taxa de sucesso',
    ],
    AtlasReproductivePremiumModule.geneticCatalog => const [
      'Touros e doadoras',
      'Características avaliadas',
      'Índices genéticos',
      'Disponibilidade',
      'Custos e condições',
    ],
    AtlasReproductivePremiumModule.intelligentMating => const [
      'Objetivos de acasalamento',
      'Compatibilidade genética',
      'Consanguinidade',
      'Defeitos recessivos',
      'Recomendação de pares',
    ],
    AtlasReproductivePremiumModule.geneticPrediction => const [
      'DEP e PTA',
      'Índices compostos',
      'Projeções de progênie',
      'Confiabilidade',
      'Cenários genéticos',
    ],
    AtlasReproductivePremiumModule.continuousBreeding => const [
      'Metas por geração',
      'Evolução genética',
      'Seleção e descarte',
      'Ganho genético',
      'Revisão do programa',
    ],
    AtlasReproductivePremiumModule.reproductiveCenter => const [
      'Indicadores consolidados',
      'Agenda reprodutiva',
      'Alertas críticos',
      'Prioridades',
      'Painel executivo',
    ],
  };
}

class AtlasReproductivePremiumRecord {
  const AtlasReproductivePremiumRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.animalReference,
    required this.protocol,
    required this.geneticReference,
    required this.metricName,
    required this.metricValue,
    required this.unit,
    required this.confidencePercent,
    required this.successPercent,
    required this.cost,
    required this.progressPercent,
    required this.alertCount,
    required this.responsible,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasReproductivePremiumModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String animalReference;
  final String protocol;
  final String geneticReference;
  final String metricName;
  final double metricValue;
  final String unit;
  final double confidencePercent;
  final double successPercent;
  final double cost;
  final int progressPercent;
  final int alertCount;
  final String responsible;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Falhou' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Validado' ||
      status == 'Em execução' ||
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
      'protocol': protocol,
      'geneticReference': geneticReference,
      'metricName': metricName,
      'metricValue': metricValue,
      'unit': unit,
      'confidencePercent': confidencePercent,
      'successPercent': successPercent,
      'cost': cost,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'responsible': responsible,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasReproductivePremiumRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasReproductivePremiumModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasReproductivePremiumModule.advancedIatf,
    );

    return AtlasReproductivePremiumRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      animalReference: map['animalReference']?.toString() ?? '',
      protocol: map['protocol']?.toString() ?? '',
      geneticReference: map['geneticReference']?.toString() ?? '',
      metricName: map['metricName']?.toString() ?? '',
      metricValue: (map['metricValue'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? '',
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 0.0,
      successPercent: (map['successPercent'] as num?)?.toDouble() ?? 0.0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      responsible: map['responsible']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasReproductivePremiumDate(String value) {
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

String formatAtlasReproductivePremiumDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
