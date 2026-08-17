enum AtlasHealthEventType {
  vaccination,
  deworming,
  treatment,
  examination,
  surgery,
  mortality,
  morbidity,
  quarantine,
  biosecurity,
}

String atlasHealthEventTypeLabel(AtlasHealthEventType type) {
  switch (type) {
    case AtlasHealthEventType.vaccination:
      return 'Vacinação';
    case AtlasHealthEventType.deworming:
      return 'Vermifugação';
    case AtlasHealthEventType.treatment:
      return 'Tratamento';
    case AtlasHealthEventType.examination:
      return 'Exame';
    case AtlasHealthEventType.surgery:
      return 'Cirurgia';
    case AtlasHealthEventType.mortality:
      return 'Mortalidade';
    case AtlasHealthEventType.morbidity:
      return 'Morbidade';
    case AtlasHealthEventType.quarantine:
      return 'Quarentena';
    case AtlasHealthEventType.biosecurity:
      return 'Biosseguridade';
  }
}

class AtlasHealthProtocol {
  const AtlasHealthProtocol({
    required this.id,
    required this.name,
    required this.description,
    required this.targetGroup,
    required this.frequencyDays,
    required this.nextDueAt,
    required this.active,
    required this.farmName,
  });

  final String id;
  final String name;
  final String description;
  final String targetGroup;
  final int frequencyDays;
  final DateTime nextDueAt;
  final bool active;
  final String? farmName;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
    'targetGroup': targetGroup,
    'frequencyDays': frequencyDays,
    'nextDueAt': nextDueAt.toIso8601String(),
    'active': active,
    'farmName': farmName,
  };

  factory AtlasHealthProtocol.fromMap(Map<String, dynamic> map) {
    return AtlasHealthProtocol(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      targetGroup: map['targetGroup']?.toString() ?? '',
      frequencyDays: _int(map['frequencyDays']),
      nextDueAt:
          DateTime.tryParse(map['nextDueAt']?.toString() ?? '') ??
          DateTime.now(),
      active: map['active'] != false,
      farmName: map['farmName']?.toString(),
    );
  }

  static int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasMedication {
  const AtlasMedication({
    required this.id,
    required this.name,
    required this.activeIngredient,
    required this.batch,
    required this.expirationAt,
    required this.quantity,
    required this.unit,
    required this.withdrawalDays,
    required this.farmName,
  });

  final String id;
  final String name;
  final String activeIngredient;
  final String batch;
  final DateTime expirationAt;
  final double quantity;
  final String unit;
  final int withdrawalDays;
  final String? farmName;

  bool get isExpired => expirationAt.isBefore(DateTime.now());

  bool get expiresSoon =>
      !isExpired && expirationAt.difference(DateTime.now()).inDays <= 30;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'activeIngredient': activeIngredient,
    'batch': batch,
    'expirationAt': expirationAt.toIso8601String(),
    'quantity': quantity,
    'unit': unit,
    'withdrawalDays': withdrawalDays,
    'farmName': farmName,
  };

  factory AtlasMedication.fromMap(Map<String, dynamic> map) {
    return AtlasMedication(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      activeIngredient: map['activeIngredient']?.toString() ?? '',
      batch: map['batch']?.toString() ?? '',
      expirationAt:
          DateTime.tryParse(map['expirationAt']?.toString() ?? '') ??
          DateTime.now(),
      quantity: _double(map['quantity']),
      unit: map['unit']?.toString() ?? '',
      withdrawalDays: _int(map['withdrawalDays']),
      farmName: map['farmName']?.toString(),
    );
  }

  static double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasHealthEvent {
  const AtlasHealthEvent({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.lotName,
    required this.paddockName,
    required this.type,
    required this.occurredAt,
    required this.diagnosis,
    required this.symptoms,
    required this.medicationId,
    required this.dose,
    required this.professional,
    required this.outcome,
    required this.cost,
    required this.notes,
    required this.farmName,
  });

  final String id;
  final String animalId;
  final String animalName;
  final String lotName;
  final String paddockName;
  final AtlasHealthEventType type;
  final DateTime occurredAt;
  final String diagnosis;
  final String symptoms;
  final String? medicationId;
  final String dose;
  final String professional;
  final String outcome;
  final double cost;
  final String notes;
  final String? farmName;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'animalId': animalId,
    'animalName': animalName,
    'lotName': lotName,
    'paddockName': paddockName,
    'type': type.name,
    'occurredAt': occurredAt.toIso8601String(),
    'diagnosis': diagnosis,
    'symptoms': symptoms,
    'medicationId': medicationId,
    'dose': dose,
    'professional': professional,
    'outcome': outcome,
    'cost': cost,
    'notes': notes,
    'farmName': farmName,
  };

  factory AtlasHealthEvent.fromMap(Map<String, dynamic> map) {
    return AtlasHealthEvent(
      id: map['id']?.toString() ?? '',
      animalId: map['animalId']?.toString() ?? '',
      animalName: map['animalName']?.toString() ?? '',
      lotName: map['lotName']?.toString() ?? '',
      paddockName: map['paddockName']?.toString() ?? '',
      type: AtlasHealthEventType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => AtlasHealthEventType.examination,
      ),
      occurredAt:
          DateTime.tryParse(map['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      diagnosis: map['diagnosis']?.toString() ?? '',
      symptoms: map['symptoms']?.toString() ?? '',
      medicationId: map['medicationId']?.toString(),
      dose: map['dose']?.toString() ?? '',
      professional: map['professional']?.toString() ?? '',
      outcome: map['outcome']?.toString() ?? '',
      cost: _double(map['cost']),
      notes: map['notes']?.toString() ?? '',
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

class AtlasHealthSummary {
  const AtlasHealthSummary({
    required this.totalEvents,
    required this.vaccinations,
    required this.treatments,
    required this.morbidityCases,
    required this.mortalityCases,
    required this.morbidityRatePercent,
    required this.mortalityRatePercent,
    required this.totalCost,
    required this.activeAlerts,
  });

  final int totalEvents;
  final int vaccinations;
  final int treatments;
  final int morbidityCases;
  final int mortalityCases;
  final double morbidityRatePercent;
  final double mortalityRatePercent;
  final double totalCost;
  final int activeAlerts;
}
