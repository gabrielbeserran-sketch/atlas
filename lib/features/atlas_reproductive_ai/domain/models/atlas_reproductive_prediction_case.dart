class AtlasReproductivePredictionCase {
  const AtlasReproductivePredictionCase({
    required this.id,
    required this.date,
    required this.title,
    required this.status,
    required this.category,
    required this.bodyConditionScore,
    required this.daysPostpartum,
    required this.daysSinceLastService,
    required this.serviceCount,
    required this.cycleRegular,
    required this.heatSigns,
    required this.previousPregnancyLoss,
    required this.protocolType,
    required this.semenQuality,
    required this.technicianExperience,
    required this.healthRisk,
    required this.notes,
    required this.responsible,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final String title;
  final String status;
  final String category;
  final double bodyConditionScore;
  final int daysPostpartum;
  final int daysSinceLastService;
  final int serviceCount;
  final bool cycleRegular;
  final bool heatSigns;
  final bool previousPregnancyLoss;
  final String protocolType;
  final String semenQuality;
  final String technicianExperience;
  final String healthRisk;
  final String notes;
  final String responsible;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'status': status,
      'category': category,
      'bodyConditionScore': bodyConditionScore,
      'daysPostpartum': daysPostpartum,
      'daysSinceLastService': daysSinceLastService,
      'serviceCount': serviceCount,
      'cycleRegular': cycleRegular,
      'heatSigns': heatSigns,
      'previousPregnancyLoss': previousPregnancyLoss,
      'protocolType': protocolType,
      'semenQuality': semenQuality,
      'technicianExperience': technicianExperience,
      'healthRisk': healthRisk,
      'notes': notes,
      'responsible': responsible,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasReproductivePredictionCase.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasReproductivePredictionCase(
      id: map['id']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Em avaliação',
      category: map['category']?.toString() ?? 'Matriz',
      bodyConditionScore:
          (map['bodyConditionScore'] as num?)?.toDouble() ?? 0,
      daysPostpartum:
          (map['daysPostpartum'] as num?)?.toInt() ?? 0,
      daysSinceLastService:
          (map['daysSinceLastService'] as num?)?.toInt() ?? 0,
      serviceCount:
          (map['serviceCount'] as num?)?.toInt() ?? 0,
      cycleRegular: map['cycleRegular'] == true,
      heatSigns: map['heatSigns'] == true,
      previousPregnancyLoss:
          map['previousPregnancyLoss'] == true,
      protocolType:
          map['protocolType']?.toString() ?? 'Não informado',
      semenQuality:
          map['semenQuality']?.toString() ?? 'Não informado',
      technicianExperience:
          map['technicianExperience']?.toString() ?? 'Intermediária',
      healthRisk:
          map['healthRisk']?.toString() ?? 'Baixo',
      notes: map['notes']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasReproductiveDate(String value) {
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

String formatAtlasReproductiveDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
