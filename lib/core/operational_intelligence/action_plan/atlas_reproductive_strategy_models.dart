enum AtlasReproductivePlanStatus { planned, active, completed, cancelled }

String atlasReproductivePlanStatusLabel(AtlasReproductivePlanStatus value) {
  switch (value) {
    case AtlasReproductivePlanStatus.planned:
      return 'Planejado';
    case AtlasReproductivePlanStatus.active:
      return 'Ativo';
    case AtlasReproductivePlanStatus.completed:
      return 'Concluído';
    case AtlasReproductivePlanStatus.cancelled:
      return 'Cancelado';
  }
}

class AtlasReproductiveAnnualPlan {
  const AtlasReproductiveAnnualPlan({
    required this.id,
    required this.title,
    required this.year,
    required this.targetFemales,
    required this.targetPregnancyRatePercent,
    required this.targetCalves,
    required this.budget,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.team,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String title;
  final int year;
  final int targetFemales;
  final double targetPregnancyRatePercent;
  final int targetCalves;
  final double budget;
  final DateTime startAt;
  final DateTime endAt;
  final AtlasReproductivePlanStatus status;
  final String team;
  final String? farmName;
  final String notes;

  int get projectedPregnancies =>
      (targetFemales * targetPregnancyRatePercent / 100).round();

  double get costPerTargetFemale =>
      targetFemales <= 0 ? 0 : budget / targetFemales;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'title': title,
    'year': year,
    'targetFemales': targetFemales,
    'targetPregnancyRatePercent': targetPregnancyRatePercent,
    'targetCalves': targetCalves,
    'budget': budget,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
    'status': status.name,
    'team': team,
    'farmName': farmName,
    'notes': notes,
  };

  factory AtlasReproductiveAnnualPlan.fromMap(Map<String, dynamic> map) {
    return AtlasReproductiveAnnualPlan(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      year: _readInt(map['year']),
      targetFemales: _readInt(map['targetFemales']),
      targetPregnancyRatePercent: _readDouble(
        map['targetPregnancyRatePercent'],
      ),
      targetCalves: _readInt(map['targetCalves']),
      budget: _readDouble(map['budget']),
      startAt:
          DateTime.tryParse(map['startAt']?.toString() ?? '') ?? DateTime.now(),
      endAt:
          DateTime.tryParse(map['endAt']?.toString() ?? '') ?? DateTime.now(),
      status: AtlasReproductivePlanStatus.values.firstWhere(
        (value) => value.name == map['status']?.toString(),
        orElse: () => AtlasReproductivePlanStatus.planned,
      ),
      team: map['team']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasReproductiveSimulation {
  const AtlasReproductiveSimulation({
    required this.id,
    required this.title,
    required this.females,
    required this.expectedPregnancyRatePercent,
    required this.expectedCalfSurvivalPercent,
    required this.costPerFemale,
    required this.expectedCalfValue,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String title;
  final int females;
  final double expectedPregnancyRatePercent;
  final double expectedCalfSurvivalPercent;
  final double costPerFemale;
  final double expectedCalfValue;
  final String? farmName;
  final String notes;

  int get expectedPregnancies =>
      (females * expectedPregnancyRatePercent / 100).round();

  int get expectedCalves =>
      (expectedPregnancies * expectedCalfSurvivalPercent / 100).round();

  double get totalCost => females * costPerFemale;
  double get expectedRevenue => expectedCalves * expectedCalfValue;
  double get expectedResult => expectedRevenue - totalCost;
  double get roiPercent =>
      totalCost <= 0 ? 0 : expectedResult / totalCost * 100;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'title': title,
    'females': females,
    'expectedPregnancyRatePercent': expectedPregnancyRatePercent,
    'expectedCalfSurvivalPercent': expectedCalfSurvivalPercent,
    'costPerFemale': costPerFemale,
    'expectedCalfValue': expectedCalfValue,
    'farmName': farmName,
    'notes': notes,
  };

  factory AtlasReproductiveSimulation.fromMap(Map<String, dynamic> map) {
    return AtlasReproductiveSimulation(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      females: _readInt(map['females']),
      expectedPregnancyRatePercent: _readDouble(
        map['expectedPregnancyRatePercent'],
      ),
      expectedCalfSurvivalPercent: _readDouble(
        map['expectedCalfSurvivalPercent'],
      ),
      costPerFemale: _readDouble(map['costPerFemale']),
      expectedCalfValue: _readDouble(map['expectedCalfValue']),
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AtlasReproductiveExecutiveSnapshot {
  const AtlasReproductiveExecutiveSnapshot({
    required this.totalEvents,
    required this.inseminations,
    required this.pregnancyDiagnoses,
    required this.positivePregnancies,
    required this.negativePregnancies,
    required this.births,
    required this.abortions,
    required this.pregnancyRatePercent,
    required this.conceptionRatePercent,
    required this.lossRatePercent,
    required this.projectedBirths,
    required this.reproductiveScore,
  });

  final int totalEvents;
  final int inseminations;
  final int pregnancyDiagnoses;
  final int positivePregnancies;
  final int negativePregnancies;
  final int births;
  final int abortions;
  final double pregnancyRatePercent;
  final double conceptionRatePercent;
  final double lossRatePercent;
  final int projectedBirths;
  final double reproductiveScore;
}
