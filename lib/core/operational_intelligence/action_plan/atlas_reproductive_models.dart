enum AtlasReproductiveEventType {
  heat,
  insemination,
  fixedTimeAi,
  naturalMating,
  pregnancyDiagnosis,
  embryoTransfer,
  calving,
  abortion,
  postpartumEvaluation,
}

String atlasReproductiveEventTypeLabel(AtlasReproductiveEventType type) {
  switch (type) {
    case AtlasReproductiveEventType.heat:
      return 'Cio';
    case AtlasReproductiveEventType.insemination:
      return 'Inseminação';
    case AtlasReproductiveEventType.fixedTimeAi:
      return 'IATF';
    case AtlasReproductiveEventType.naturalMating:
      return 'Monta natural';
    case AtlasReproductiveEventType.pregnancyDiagnosis:
      return 'Diagnóstico de gestação';
    case AtlasReproductiveEventType.embryoTransfer:
      return 'Transferência de embrião';
    case AtlasReproductiveEventType.calving:
      return 'Parto';
    case AtlasReproductiveEventType.abortion:
      return 'Aborto';
    case AtlasReproductiveEventType.postpartumEvaluation:
      return 'Avaliação pós-parto';
  }
}

class AtlasReproductiveProtocol {
  const AtlasReproductiveProtocol({
    required this.id,
    required this.name,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.farmName,
    required this.active,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final String? farmName;
  final bool active;
  final List<String> steps;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
    'farmName': farmName,
    'active': active,
    'steps': steps,
  };

  factory AtlasReproductiveProtocol.fromMap(Map<String, dynamic> map) {
    return AtlasReproductiveProtocol(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      startAt:
          DateTime.tryParse(map['startAt']?.toString() ?? '') ?? DateTime.now(),
      endAt:
          DateTime.tryParse(map['endAt']?.toString() ?? '') ?? DateTime.now(),
      farmName: map['farmName']?.toString(),
      active: map['active'] != false,
      steps: _strings(map['steps']),
    );
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) {
      return <String>[];
    }
    return value.map((item) => item.toString()).toList();
  }
}

class AtlasReproductiveEvent {
  const AtlasReproductiveEvent({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.type,
    required this.occurredAt,
    required this.protocolId,
    required this.sireId,
    required this.semenBatch,
    required this.professional,
    required this.result,
    required this.notes,
    required this.farmName,
  });

  final String id;
  final String animalId;
  final String animalName;
  final AtlasReproductiveEventType type;
  final DateTime occurredAt;
  final String? protocolId;
  final String sireId;
  final String semenBatch;
  final String professional;
  final String result;
  final String notes;
  final String? farmName;

  bool get isPositivePregnancy =>
      type == AtlasReproductiveEventType.pregnancyDiagnosis &&
      result.trim().toLowerCase().contains('posit');

  bool get isNegativePregnancy =>
      type == AtlasReproductiveEventType.pregnancyDiagnosis &&
      result.trim().toLowerCase().contains('negat');

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'animalId': animalId,
    'animalName': animalName,
    'type': type.name,
    'occurredAt': occurredAt.toIso8601String(),
    'protocolId': protocolId,
    'sireId': sireId,
    'semenBatch': semenBatch,
    'professional': professional,
    'result': result,
    'notes': notes,
    'farmName': farmName,
  };

  factory AtlasReproductiveEvent.fromMap(Map<String, dynamic> map) {
    return AtlasReproductiveEvent(
      id: map['id']?.toString() ?? '',
      animalId: map['animalId']?.toString() ?? '',
      animalName: map['animalName']?.toString() ?? '',
      type: AtlasReproductiveEventType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasReproductiveEventType.heat,
      ),
      occurredAt:
          DateTime.tryParse(map['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      protocolId: map['protocolId']?.toString(),
      sireId: map['sireId']?.toString() ?? '',
      semenBatch: map['semenBatch']?.toString() ?? '',
      professional: map['professional']?.toString() ?? '',
      result: map['result']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
    );
  }
}

class AtlasGeneticAnimal {
  const AtlasGeneticAnimal({
    required this.id,
    required this.name,
    required this.sex,
    required this.breed,
    required this.sireId,
    required this.damId,
    required this.geneticIndex,
    required this.fertilityScore,
    required this.calvingEaseScore,
    required this.maternalScore,
    required this.farmName,
  });

  final String id;
  final String name;
  final String sex;
  final String breed;
  final String sireId;
  final String damId;
  final double geneticIndex;
  final double fertilityScore;
  final double calvingEaseScore;
  final double maternalScore;
  final String? farmName;

  double get rankingScore =>
      geneticIndex * 0.35 +
      fertilityScore * 0.30 +
      calvingEaseScore * 0.15 +
      maternalScore * 0.20;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'sex': sex,
    'breed': breed,
    'sireId': sireId,
    'damId': damId,
    'geneticIndex': geneticIndex,
    'fertilityScore': fertilityScore,
    'calvingEaseScore': calvingEaseScore,
    'maternalScore': maternalScore,
    'farmName': farmName,
  };

  factory AtlasGeneticAnimal.fromMap(Map<String, dynamic> map) {
    return AtlasGeneticAnimal(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sex: map['sex']?.toString() ?? '',
      breed: map['breed']?.toString() ?? '',
      sireId: map['sireId']?.toString() ?? '',
      damId: map['damId']?.toString() ?? '',
      geneticIndex: _double(map['geneticIndex']),
      fertilityScore: _double(map['fertilityScore']),
      calvingEaseScore: _double(map['calvingEaseScore']),
      maternalScore: _double(map['maternalScore']),
      farmName: map['farmName']?.toString(),
    );
  }

  static double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasReproductiveSummary {
  const AtlasReproductiveSummary({
    required this.totalServices,
    required this.pregnancyDiagnoses,
    required this.positivePregnancies,
    required this.negativePregnancies,
    required this.calvings,
    required this.abortions,
    required this.pregnancyRatePercent,
    required this.conceptionRatePercent,
    required this.repeatRatePercent,
    required this.projectedCalvings,
  });

  final int totalServices;
  final int pregnancyDiagnoses;
  final int positivePregnancies;
  final int negativePregnancies;
  final int calvings;
  final int abortions;
  final double pregnancyRatePercent;
  final double conceptionRatePercent;
  final double repeatRatePercent;
  final int projectedCalvings;
}
