class AnimalNutritionPlan {
  const AnimalNutritionPlan({
    required this.id,
    required this.date,
    required this.dietName,
    required this.dailyIntakeKg,
    required this.dryMatterPercent,
    required this.dailyCost,
    required this.targetGainKg,
    required this.status,
    required this.notes,
  });
  final String id, date, dietName, status, notes;
  final double dailyIntakeKg, dryMatterPercent, dailyCost, targetGainKg;
  double get dryMatterKg => dailyIntakeKg * dryMatterPercent / 100;
  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'dietName': dietName,
    'dailyIntakeKg': dailyIntakeKg,
    'dryMatterPercent': dryMatterPercent,
    'dailyCost': dailyCost,
    'targetGainKg': targetGainKg,
    'status': status,
    'notes': notes,
  };
  factory AnimalNutritionPlan.fromMap(Map<String, dynamic> m) =>
      AnimalNutritionPlan(
        id: m['id']?.toString() ?? '',
        date: m['date']?.toString() ?? '',
        dietName: m['dietName']?.toString() ?? '',
        dailyIntakeKg: (m['dailyIntakeKg'] as num?)?.toDouble() ?? 0,
        dryMatterPercent: (m['dryMatterPercent'] as num?)?.toDouble() ?? 0,
        dailyCost: (m['dailyCost'] as num?)?.toDouble() ?? 0,
        targetGainKg: (m['targetGainKg'] as num?)?.toDouble() ?? 0,
        status: m['status']?.toString() ?? 'Ativa',
        notes: m['notes']?.toString() ?? '',
      );
}
