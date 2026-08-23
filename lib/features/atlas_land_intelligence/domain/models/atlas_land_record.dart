enum AtlasLandModule { genetics, pasture, agriculture }

extension AtlasLandModuleX on AtlasLandModule {
  String get code => switch (this) {
    AtlasLandModule.genetics => 'genetics',
    AtlasLandModule.pasture => 'pasture',
    AtlasLandModule.agriculture => 'agriculture',
  };

  String get title => switch (this) {
    AtlasLandModule.genetics => 'Genética Enterprise',
    AtlasLandModule.pasture => 'Pastagens Enterprise',
    AtlasLandModule.agriculture => 'Agricultura Integrada',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasLandModule.genetics => const [
      'Cadastro genético completo',
      'Acasalamento inteligente',
      'Seleção genética automática',
      'Projeção genética das progênies',
      'Ranking genético do rebanho',
    ],
    AtlasLandModule.pasture => const [
      'Cadastro de piquetes',
      'Taxa de lotação',
      'Oferta de forragem',
      'Rotação de pastagens',
      'IA para manejo de pasto',
    ],
    AtlasLandModule.agriculture => const [
      'Cadastro de culturas',
      'Planejamento agrícola',
      'Custos agrícolas',
      'Integração lavoura-pecuária',
      'Calendário agrícola',
    ],
  };
}

class AtlasLandRecord {
  const AtlasLandRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.primaryValue,
    required this.secondaryValue,
    required this.unit,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasLandModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final double primaryValue;
  final double secondaryValue;
  final String unit;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical => status == 'Crítico' || status == 'Atenção';

  bool get isCompleted => status == 'Concluído';

  AtlasLandRecord copyWith({
    String? id,
    AtlasLandModule? module,
    String? feature,
    String? title,
    String? date,
    String? status,
    double? primaryValue,
    double? secondaryValue,
    String? unit,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return AtlasLandRecord(
      id: id ?? this.id,
      module: module ?? this.module,
      feature: feature ?? this.feature,
      title: title ?? this.title,
      date: date ?? this.date,
      status: status ?? this.status,
      primaryValue: primaryValue ?? this.primaryValue,
      secondaryValue: secondaryValue ?? this.secondaryValue,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'primaryValue': primaryValue,
      'secondaryValue': secondaryValue,
      'unit': unit,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasLandRecord.fromMap(Map<String, dynamic> map) {
    final moduleCode = map['module']?.toString() ?? '';

    final module = AtlasLandModule.values.firstWhere(
      (item) => item.code == moduleCode,
      orElse: () => AtlasLandModule.genetics,
    );

    return AtlasLandRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      primaryValue: (map['primaryValue'] as num?)?.toDouble() ?? 0,
      secondaryValue: (map['secondaryValue'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasLandDate(String value) {
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

String formatAtlasLandDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
