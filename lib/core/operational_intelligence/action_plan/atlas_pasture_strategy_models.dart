class AtlasPastureExecutiveSnapshot {
  const AtlasPastureExecutiveSnapshot({
    required this.totalPaddocks,
    required this.totalAreaHectares,
    required this.availablePaddocks,
    required this.occupiedPaddocks,
    required this.restingPaddocks,
    required this.averageHeightCm,
    required this.averageDryMatterKgHa,
    required this.averageSupportCapacityAuHa,
    required this.totalSupportedAu,
    required this.overdueOperations,
    required this.pastureScore,
  });

  final int totalPaddocks;
  final double totalAreaHectares;
  final int availablePaddocks;
  final int occupiedPaddocks;
  final int restingPaddocks;
  final double averageHeightCm;
  final double averageDryMatterKgHa;
  final double averageSupportCapacityAuHa;
  final double totalSupportedAu;
  final int overdueOperations;
  final double pastureScore;
}

class AtlasPastureOccupationRecommendation {
  const AtlasPastureOccupationRecommendation({
    required this.paddockId,
    required this.paddockName,
    required this.recommendedAnimalCount,
    required this.recommendedOccupationDays,
    required this.recommendedRestDays,
    required this.riskLevel,
    required this.reason,
  });

  final String paddockId;
  final String paddockName;
  final int recommendedAnimalCount;
  final int recommendedOccupationDays;
  final int recommendedRestDays;
  final String riskLevel;
  final String reason;
}

class AtlasPastureRecoveryPlan {
  const AtlasPastureRecoveryPlan({
    required this.id,
    required this.paddockId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.estimatedCost,
    required this.expectedDryMatterGainKgHa,
    required this.expectedSupportGainAuHa,
    required this.responsibleName,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String paddockId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final double estimatedCost;
  final double expectedDryMatterGainKgHa;
  final double expectedSupportGainAuHa;
  final String responsibleName;
  final String? farmName;
  final String notes;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'paddockId': paddockId,
        'title': title,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'estimatedCost': estimatedCost,
        'expectedDryMatterGainKgHa':
            expectedDryMatterGainKgHa,
        'expectedSupportGainAuHa':
            expectedSupportGainAuHa,
        'responsibleName': responsibleName,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasPastureRecoveryPlan.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasPastureRecoveryPlan(
      id: map['id']?.toString() ?? '',
      paddockId: map['paddockId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      startAt: DateTime.tryParse(
            map['startAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      endAt: DateTime.tryParse(
            map['endAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      estimatedCost:
          (map['estimatedCost'] as num?)?.toDouble() ?? 0,
      expectedDryMatterGainKgHa:
          (map['expectedDryMatterGainKgHa'] as num?)
                  ?.toDouble() ??
              0,
      expectedSupportGainAuHa:
          (map['expectedSupportGainAuHa'] as num?)
                  ?.toDouble() ??
              0,
      responsibleName:
          map['responsibleName']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}
