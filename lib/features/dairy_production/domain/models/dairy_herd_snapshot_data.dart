class DairyHerdSnapshotData {
  const DairyHerdSnapshotData({
    required this.date,
    required this.eligibleCows,
    required this.lactatingCows,
    required this.dryCows,
    this.pregnanciesMonitored = 0,
    this.pregnancyLosses = 0,
  });

  final DateTime date;
  final int eligibleCows;
  final int lactatingCows;
  final int dryCows;

  /// Gestações em acompanhamento no fechamento do lote.
  /// É o denominador declarado para a taxa de perdas do mesmo registro.
  final int pregnanciesMonitored;
  final int pregnancyLosses;

  double? get lactatingPercent =>
      eligibleCows == 0 ? null : lactatingCows / eligibleCows * 100;
  double? get dryPercent =>
      eligibleCows == 0 ? null : dryCows / eligibleCows * 100;
  double? get pregnancyLossPercent => pregnanciesMonitored == 0
      ? null
      : pregnancyLosses / pregnanciesMonitored * 100;

  void validate() {
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    if (day.year < 1900 ||
        day.isAfter(DateTime(today.year, today.month, today.day))) {
      throw const FormatException('Data do estado do lote inválida.');
    }
    if (eligibleCows < 0 ||
        lactatingCows < 0 ||
        dryCows < 0 ||
        lactatingCows + dryCows > eligibleCows ||
        pregnanciesMonitored < 0 ||
        pregnancyLosses < 0 ||
        pregnancyLosses > pregnanciesMonitored) {
      throw const FormatException('Quantidades do lote inconsistentes.');
    }
  }

  Map<String, dynamic> toMap() => {
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'eligible_cows': eligibleCows,
    'lactating_cows': lactatingCows,
    'dry_cows': dryCows,
    'pregnancies_monitored': pregnanciesMonitored,
    'pregnancy_losses': pregnancyLosses,
  };

  factory DairyHerdSnapshotData.fromMap(Map<String, dynamic> map) {
    final rawDate = '${map['date'] ?? ''}'.trim();
    final parts = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[T ].*)?$',
    ).firstMatch(rawDate);
    if (parts == null || DateTime.tryParse(rawDate) == null) {
      throw const FormatException('Data do estado do lote ilegível.');
    }
    final year = int.parse(parts[1]!);
    final month = int.parse(parts[2]!);
    final day = int.parse(parts[3]!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw const FormatException('Data do estado do lote impossível.');
    }
    int integer(dynamic value) {
      final parsed = value is int ? value : int.tryParse('$value');
      if (parsed == null) {
        throw const FormatException('Quantidade do lote ilegível.');
      }
      return parsed;
    }

    final snapshot = DairyHerdSnapshotData(
      date: date,
      eligibleCows: integer(map['eligible_cows']),
      lactatingCows: integer(map['lactating_cows']),
      dryCows: integer(map['dry_cows']),
      pregnanciesMonitored: map['pregnancies_monitored'] == null
          ? 0
          : integer(map['pregnancies_monitored']),
      pregnancyLosses: map['pregnancy_losses'] == null
          ? 0
          : integer(map['pregnancy_losses']),
    );
    snapshot.validate();
    return snapshot;
  }
}
