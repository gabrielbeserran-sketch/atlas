import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';

class DairyProductionSummary {
  const DairyProductionSummary({
    required this.latestLiters,
    required this.averageLitersPerDay,
    required this.averageLitersPerHectare,
    required this.recordedDays,
  });
  final double? latestLiters;
  final double? averageLitersPerDay;
  final double? averageLitersPerHectare;
  final int recordedDays;
}

class DairyIndicatorCalculator {
  const DairyIndicatorCalculator();

  DairyProductionSummary summarize(
    List<DairyDailyProductionData> records, {
    required int hectares,
    DateTime? referenceDate,
  }) {
    if (records.isEmpty) {
      return const DairyProductionSummary(
        latestLiters: null,
        averageLitersPerDay: null,
        averageLitersPerHectare: null,
        recordedDays: 0,
      );
    }
    final now = referenceDate ?? DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final window = records
        .where((item) => !item.date.isBefore(start) && !item.date.isAfter(now))
        .toList();
    final source = window.isEmpty ? records : window;
    final total = source.fold<double>(0, (sum, item) => sum + item.totalLiters);
    final average = total / source.length;
    return DairyProductionSummary(
      latestLiters: records.first.totalLiters,
      averageLitersPerDay: average,
      averageLitersPerHectare: hectares > 0 ? average / hectares : null,
      recordedDays: source.length,
    );
  }
}
