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
    final rawDate = '${map['date'] ?? ''}'.trim();
    final parts = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[T ].*)?$',
    ).firstMatch(rawDate);
    if (parts == null || DateTime.tryParse(rawDate) == null) {
      throw const FormatException('Data da ordenha ausente ou inválida.');
    }
    final year = int.parse(parts[1]!);
    final month = int.parse(parts[2]!);
    final day = int.parse(parts[3]!);
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const FormatException('Data da ordenha impossível.');
    }
    double number(dynamic value) {
      if (value == null) return 0;
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse('$value'.replaceAll(',', '.'));
      if (parsed == null || !parsed.isFinite) {
        throw const FormatException('Valor numérico da ordenha inválido.');
      }
      return parsed;
    }

    final cows = number(map['cows_milked']);
    if (cows.toInt().toDouble() != cows) {
      throw const FormatException('Quantidade de vacas deve ser inteira.');
    }
    return DairyDailyProductionData(
      date: DateTime(parsed.year, parsed.month, parsed.day),
      morningLiters: number(map['morning_liters']),
      afternoonLiters: number(map['afternoon_liters']),
      cowsMilked: cows.toInt(),
      notes: '${map['notes'] ?? ''}',
    );
  }
}
