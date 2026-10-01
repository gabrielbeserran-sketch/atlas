import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';

class DairyProductionSummary {
  const DairyProductionSummary({
    required this.latestLiters,
    required this.latestRecordDate,
    required this.daysSinceLatestRecord,
    required this.averageLitersPerDay,
    required this.averageLitersPerHectare,
    required this.litersPerLactatingCow,
    required this.litersPerMilkedCow,
    required this.averageMilkedCows,
    required this.recordedDays,
    required this.futureRecords,
    required this.duplicateDays,
    required this.recordsWithoutMilkedCows,
    required this.invalidProductionRecords,
    required this.windowDays,
    required this.missingDays,
    required this.coveragePercent,
    required this.milkedCowsExceedLactatingSnapshot,
  });
  final double? latestLiters;
  final DateTime? latestRecordDate;
  final int? daysSinceLatestRecord;
  final double? averageLitersPerDay;
  final double? averageLitersPerHectare;
  final double? litersPerLactatingCow;
  final double? litersPerMilkedCow;
  final double? averageMilkedCows;
  final int recordedDays;
  final int futureRecords;
  final int duplicateDays;
  final int recordsWithoutMilkedCows;
  final int invalidProductionRecords;
  final int windowDays;
  final int missingDays;
  final double coveragePercent;
  final bool milkedCowsExceedLactatingSnapshot;

  bool get hasRepresentativeSample => recordedDays >= 20;
  bool get latestRecordIsStale => (daysSinceLatestRecord ?? 0) > 3;

  List<String> get dataQualityAlerts {
    final alerts = <String>[];
    if (latestRecordIsStale) {
      alerts.add(
        'A última ordenha válida foi registrada há $daysSinceLatestRecord dias; atualize a produção antes de usar os indicadores como retrato atual.',
      );
    }
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
    if (milkedCowsExceedLactatingSnapshot) {
      alerts.add(
        'A ordenha recente informa mais vacas ordenhadas que vacas em lactação no lote atual; confira as datas e o lote antes de usar litros por vaca em lactação.',
      );
    }
    return alerts;
  }
}

class DairyIndicatorCalculator {
  const DairyIndicatorCalculator();

  DairyProductionSummary summarize(
    List<DairyDailyProductionData> records, {
    required double hectares,
    int? lactatingCows,
    DateTime? referenceDate,
  }) {
    if (records.isEmpty) {
      return const DairyProductionSummary(
        latestLiters: null,
        latestRecordDate: null,
        daysSinceLatestRecord: null,
        averageLitersPerDay: null,
        averageLitersPerHectare: null,
        litersPerLactatingCow: null,
        litersPerMilkedCow: null,
        averageMilkedCows: null,
        recordedDays: 0,
        futureRecords: 0,
        duplicateDays: 0,
        recordsWithoutMilkedCows: 0,
        invalidProductionRecords: 0,
        windowDays: 30,
        missingDays: 30,
        coveragePercent: 0,
        milkedCowsExceedLactatingSnapshot: false,
      );
    }
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(today.year, today.month, today.day - 29);
    DateTime dayOf(DairyDailyProductionData record) =>
        DateTime(record.date.year, record.date.month, record.date.day);
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
        .where((item) => dayOf(item).isAfter(today))
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
          (item) => !dayOf(item).isBefore(start) && !dayOf(item).isAfter(today),
        )
        .toList();
    final source = window;
    final latest = valid.isEmpty
        ? null
        : (valid..sort((a, b) => b.date.compareTo(a.date))).first;
    final daysSinceLatestRecord = latest == null
        ? null
        : DateTime.utc(today.year, today.month, today.day)
              .difference(
                DateTime.utc(
                  latest.date.year,
                  latest.date.month,
                  latest.date.day,
                ),
              )
              .inDays;
    if (source.isEmpty) {
      return DairyProductionSummary(
        latestLiters: latest?.totalLiters,
        latestRecordDate: latest?.date,
        daysSinceLatestRecord: daysSinceLatestRecord,
        averageLitersPerDay: null,
        averageLitersPerHectare: null,
        litersPerLactatingCow: null,
        litersPerMilkedCow: null,
        averageMilkedCows: null,
        recordedDays: 0,
        futureRecords: futureRecords,
        duplicateDays: duplicateDays,
        recordsWithoutMilkedCows: recordsWithoutMilkedCows,
        invalidProductionRecords: invalidProductionRecords,
        windowDays: 30,
        missingDays: 30,
        coveragePercent: 0,
        milkedCowsExceedLactatingSnapshot: false,
      );
    }
    final totalMilkedCows = source.fold<double>(
      0,
      (sum, item) => sum + item.cowsMilked,
    );
    // Divide antes de somar para não transbordar uma média representável.
    final average = source.fold<double>(
      0,
      (sum, item) => sum + item.totalLiters / source.length,
    );
    final perMilkedCow = totalMilkedCows <= 0
        ? null
        : source.fold<double>(
            0,
            (sum, item) => sum + item.totalLiters / totalMilkedCows,
          );
    final perHectare = hectares.isFinite && hectares > 0 && average.isFinite
        ? average / hectares
        : null;
    final milkedCowsExceedLactatingSnapshot =
        lactatingCows != null &&
        latest != null &&
        daysSinceLatestRecord != null &&
        daysSinceLatestRecord <= 3 &&
        latest.cowsMilked > lactatingCows;
    return DairyProductionSummary(
      latestLiters: latest?.totalLiters,
      latestRecordDate: latest?.date,
      daysSinceLatestRecord: daysSinceLatestRecord,
      averageLitersPerDay: average.isFinite ? average : null,
      averageLitersPerHectare: perHectare != null && perHectare.isFinite
          ? perHectare
          : null,
      litersPerLactatingCow:
          lactatingCows == null ||
              lactatingCows <= 0 ||
              !average.isFinite ||
              milkedCowsExceedLactatingSnapshot
          ? null
          : average / lactatingCows,
      litersPerMilkedCow: perMilkedCow != null && perMilkedCow.isFinite
          ? perMilkedCow
          : null,
      averageMilkedCows: totalMilkedCows / source.length,
      recordedDays: source.length,
      futureRecords: futureRecords,
      duplicateDays: duplicateDays,
      recordsWithoutMilkedCows: recordsWithoutMilkedCows,
      invalidProductionRecords: invalidProductionRecords,
      windowDays: 30,
      missingDays: 30 - source.length,
      coveragePercent: source.length / 30 * 100,
      milkedCowsExceedLactatingSnapshot: milkedCowsExceedLactatingSnapshot,
    );
  }
}
