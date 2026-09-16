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

  Map<String, dynamic> toMap() => {
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'eligible_cows': eligibleCows,
    'lactating_cows': lactatingCows,
    'dry_cows': dryCows,
    'pregnancies_monitored': pregnanciesMonitored,
    'pregnancy_losses': pregnancyLosses,
  };

  factory DairyHerdSnapshotData.fromMap(Map<String, dynamic> map) {
    final date = DateTime.tryParse('${map['date'] ?? ''}') ?? DateTime.now();
    int integer(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;
    return DairyHerdSnapshotData(
      date: date,
      eligibleCows: integer(map['eligible_cows']),
      lactatingCows: integer(map['lactating_cows']),
      dryCows: integer(map['dry_cows']),
      pregnanciesMonitored: integer(map['pregnancies_monitored']),
      pregnancyLosses: integer(map['pregnancy_losses']),
    );
  }
}
