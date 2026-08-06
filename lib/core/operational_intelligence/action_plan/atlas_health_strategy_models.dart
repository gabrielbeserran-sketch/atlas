class AtlasHealthExecutiveSnapshot {
  const AtlasHealthExecutiveSnapshot({
    required this.totalEvents,
    required this.vaccinations,
    required this.dewormings,
    required this.treatments,
    required this.morbidityCases,
    required this.mortalityCases,
    required this.quarantineCases,
    required this.totalCost,
    required this.morbidityRatePercent,
    required this.mortalityRatePercent,
    required this.protocolCoveragePercent,
    required this.healthScore,
  });

  final int totalEvents;
  final int vaccinations;
  final int dewormings;
  final int treatments;
  final int morbidityCases;
  final int mortalityCases;
  final int quarantineCases;
  final double totalCost;
  final double morbidityRatePercent;
  final double mortalityRatePercent;
  final double protocolCoveragePercent;
  final double healthScore;
}

class AtlasEpidemiologicalCluster {
  const AtlasEpidemiologicalCluster({
    required this.key,
    required this.label,
    required this.caseCount,
    required this.mortalityCount,
    required this.totalCost,
    required this.riskScore,
  });

  final String key;
  final String label;
  final int caseCount;
  final int mortalityCount;
  final double totalCost;
  final double riskScore;
}

class AtlasHealthAnnualPlan {
  const AtlasHealthAnnualPlan({
    required this.id,
    required this.title,
    required this.year,
    required this.targetGroup,
    required this.budget,
    required this.targetCoveragePercent,
    required this.responsibleName,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String title;
  final int year;
  final String targetGroup;
  final double budget;
  final double targetCoveragePercent;
  final String responsibleName;
  final String? farmName;
  final String notes;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'year': year,
        'targetGroup': targetGroup,
        'budget': budget,
        'targetCoveragePercent': targetCoveragePercent,
        'responsibleName': responsibleName,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasHealthAnnualPlan.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasHealthAnnualPlan(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      year: (map['year'] as num?)?.toInt() ?? 0,
      targetGroup: map['targetGroup']?.toString() ?? '',
      budget: (map['budget'] as num?)?.toDouble() ?? 0,
      targetCoveragePercent:
          (map['targetCoveragePercent'] as num?)?.toDouble() ?? 0,
      responsibleName:
          map['responsibleName']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}
