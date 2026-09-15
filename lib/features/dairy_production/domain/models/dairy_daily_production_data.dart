class DairyDailyProductionData {
  const DairyDailyProductionData({
    required this.date,
    required this.morningLiters,
    required this.afternoonLiters,
    required this.cowsMilked,
    this.notes = '',
  });

  final DateTime date;
  final double morningLiters;
  final double afternoonLiters;
  final int cowsMilked;
  final String notes;

  double get totalLiters => morningLiters + afternoonLiters;
  double? get litersPerCow => cowsMilked > 0 ? totalLiters / cowsMilked : null;

  Map<String, dynamic> toMap() => {
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'morning_liters': morningLiters,
    'afternoon_liters': afternoonLiters,
    'cows_milked': cowsMilked,
    'notes': notes,
  };

  factory DairyDailyProductionData.fromMap(Map<String, dynamic> map) {
    final parsed = DateTime.tryParse('${map['date'] ?? ''}') ?? DateTime.now();
    double number(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse('${value ?? ''}'.replaceAll(',', '.')) ?? 0;
    return DairyDailyProductionData(
      date: DateTime(parsed.year, parsed.month, parsed.day),
      morningLiters: number(map['morning_liters']),
      afternoonLiters: number(map['afternoon_liters']),
      cowsMilked: (map['cows_milked'] as num?)?.toInt() ?? 0,
      notes: '${map['notes'] ?? ''}',
    );
  }
}
