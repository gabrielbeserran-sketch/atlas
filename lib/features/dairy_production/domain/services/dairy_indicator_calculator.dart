import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';

class DairyProductionSummary {
  const DairyProductionSummary({
    required this.latestLiters,
    required this.averageLitersPerDay,
    required this.averageLitersPerHectare,
    required this.litersPerLactatingCow,
    required this.recordedDays,
    required this.futureRecords,
    required this.duplicateDays,
    required this.recordsWithoutMilkedCows,
    required this.invalidProductionRecords,
    required this.windowDays,
    required this.missingDays,
    required this.coveragePercent,
  });
  final double? latestLiters;
  final double? averageLitersPerDay;
  final double? averageLitersPerHectare;
  final double? litersPerLactatingCow;
  final int recordedDays;
  final int futureRecords;
  final int duplicateDays;
  final int recordsWithoutMilkedCows;
  final int invalidProductionRecords;
  final int windowDays;
  final int missingDays;
  final double coveragePercent;

  bool get hasRepresentativeSample => recordedDays >= 20;

  List<String> get dataQualityAlerts {
    final alerts = <String>[];
    if (futureRecords > 0) {
      alerts.add(
        '$futureRecords ordenha(s) com data futura ficaram fora dos indicadores.',
      );
    }
    if (duplicateDays > 0) {
      alerts.add(
        '$duplicateDays dia(s) têm ordenhas duplicadas e ficaram fora da média até a revisão.',
      );
    }
    if (recordsWithoutMilkedCows > 0) {
      alerts.add(
        '$recordsWithoutMilkedCows ordenha(s) não informam vacas ordenhadas e ficaram fora dos indicadores.',
      );
    }
    if (invalidProductionRecords > 0) {
      alerts.add(
        '$invalidProductionRecords ordenha(s) têm produção inválida e ficaram fora dos indicadores.',
      );
    }
    return alerts;
  }
}

class DairyIndicatorCalculator {
  const DairyIndicatorCalculator();

  DairyProductionSummary summarize(
    List<DairyDailyProductionData> records, {
    required int hectares,
    int? lactatingCows,
    DateTime? referenceDate,
  }) {
    if (records.isEmpty) {
      return const DairyProductionSummary(
        latestLiters: null,
        averageLitersPerDay: null,
        averageLitersPerHectare: null,
        litersPerLactatingCow: null,
        recordedDays: 0,
        futureRecords: 0,
        duplicateDays: 0,
        recordsWithoutMilkedCows: 0,
        invalidProductionRecords: 0,
        windowDays: 30,
        missingDays: 30,
        coveragePercent: 0,
      );
    }
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 29));
    final dates = <DateTime, List<DairyDailyProductionData>>{};
    for (final record in records) {
      final day = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      (dates[day] ??= []).add(record);
    }
    final duplicateDays = dates.values
        .where((items) => items.length > 1)
        .length;
    final futureRecords = records
        .where((item) => item.date.isAfter(today))
        .length;
    final recordsWithoutMilkedCows = records
        .where((item) => item.cowsMilked <= 0)
        .length;
    final invalidProductionRecords = records
        .where(
          (item) =>
              item.morningLiters < 0 ||
              item.afternoonLiters < 0 ||
              !item.totalLiters.isFinite,
        )
        .length;
    final valid = records.where((item) {
      final day = DateTime(item.date.year, item.date.month, item.date.day);
      return !day.isAfter(today) &&
          dates[day]!.length == 1 &&
          item.cowsMilked > 0 &&
          item.morningLiters >= 0 &&
          item.afternoonLiters >= 0 &&
          item.totalLiters.isFinite;
    }).toList();
    final window = valid
        .where(
          (item) => !item.date.isBefore(start) && !item.date.isAfter(today),
        )
        .toList();
    final source = window;
    final latest = valid.isEmpty
        ? null
        : (valid..sort((a, b) => b.date.compareTo(a.date))).first;
    if (source.isEmpty) {
      return DairyProductionSummary(
        latestLiters: latest?.totalLiters,
        averageLitersPerDay: null,
        averageLitersPerHectare: null,
        litersPerLactatingCow: null,
        recordedDays: 0,
        futureRecords: futureRecords,
        duplicateDays: duplicateDays,
        recordsWithoutMilkedCows: recordsWithoutMilkedCows,
        invalidProductionRecords: invalidProductionRecords,
        windowDays: 30,
        missingDays: 30,
        coveragePercent: 0,
      );
    }
    final total = source.fold<double>(0, (sum, item) => sum + item.totalLiters);
    final average = total / source.length;
    return DairyProductionSummary(
      latestLiters: latest?.totalLiters,
      averageLitersPerDay: average,
      averageLitersPerHectare: hectares > 0 ? average / hectares : null,
      litersPerLactatingCow: lactatingCows == null || lactatingCows <= 0
          ? null
          : average / lactatingCows,
      recordedDays: source.length,
      futureRecords: futureRecords,
      duplicateDays: duplicateDays,
      recordsWithoutMilkedCows: recordsWithoutMilkedCows,
      invalidProductionRecords: invalidProductionRecords,
      windowDays: 30,
      missingDays: 30 - source.length,
      coveragePercent: source.length / 30 * 100,
    );
  }
}
