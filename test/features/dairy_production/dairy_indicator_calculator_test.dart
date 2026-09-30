import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/services/dairy_indicator_calculator.dart';

void main() {
  test(
    'calcula litros/dia e litros/hectare somente a partir dos registros',
    () {
      const calculator = DairyIndicatorCalculator();
      final summary = calculator.summarize(
        [
          DairyDailyProductionData(
            date: DateTime(2026, 9, 14),
            morningLiters: 80,
            afternoonLiters: 40,
            cowsMilked: 10,
          ),
          DairyDailyProductionData(
            date: DateTime(2026, 9, 15),
            morningLiters: 100,
            afternoonLiters: 60,
            cowsMilked: 12,
          ),
        ],
        hectares: 20,
        lactatingCows: 10,
        referenceDate: DateTime(2026, 9, 15),
      );
      expect(summary.latestLiters, 160);
      expect(summary.latestRecordDate, DateTime(2026, 9, 15));
      expect(summary.daysSinceLatestRecord, 0);
      expect(summary.averageLitersPerDay, 140);
      expect(summary.averageLitersPerHectare, 7);
      expect(summary.recordedDays, 2);
      expect(summary.windowDays, 30);
      expect(summary.missingDays, 28);
      expect(summary.coveragePercent, closeTo(6.67, 0.01));
      expect(summary.hasRepresentativeSample, isFalse);
      expect(summary.litersPerLactatingCow, 14);
      expect(summary.litersPerMilkedCow, closeTo(280 / 22, 0.001));
      expect(summary.averageMilkedCows, 11);
    },
  );

  test('exclui ordenhas futuras, duplicadas ou sem vacas da média', () {
    const calculator = DairyIndicatorCalculator();
    final summary = calculator.summarize(
      [
        DairyDailyProductionData(
          date: DateTime(2026, 9, 15),
          morningLiters: 100,
          afternoonLiters: 50,
          cowsMilked: 10,
        ),
        DairyDailyProductionData(
          date: DateTime(2026, 9, 14),
          morningLiters: 90,
          afternoonLiters: 40,
          cowsMilked: 10,
        ),
        DairyDailyProductionData(
          date: DateTime(2026, 9, 14),
          morningLiters: 80,
          afternoonLiters: 30,
          cowsMilked: 10,
        ),
        DairyDailyProductionData(
          date: DateTime(2026, 9, 16),
          morningLiters: 130,
          afternoonLiters: 70,
          cowsMilked: 10,
        ),
        DairyDailyProductionData(
          date: DateTime(2026, 9, 13),
          morningLiters: 80,
          afternoonLiters: 40,
          cowsMilked: 0,
        ),
      ],
      hectares: 10,
      lactatingCows: 10,
      referenceDate: DateTime(2026, 9, 15),
    );

    expect(summary.recordedDays, 1);
    expect(summary.averageLitersPerDay, 150);
    expect(summary.averageLitersPerHectare, 15);
    expect(summary.litersPerLactatingCow, 15);
    expect(summary.litersPerMilkedCow, 15);
    expect(summary.averageMilkedCows, 10);
    expect(summary.futureRecords, 1);
    expect(summary.duplicateDays, 1);
    expect(summary.recordsWithoutMilkedCows, 1);
    expect(summary.dataQualityAlerts, hasLength(3));
    expect(summary.missingDays, 29);
    expect(summary.coveragePercent, closeTo(3.33, 0.01));
  });

  test('sinaliza quando a última ordenha válida está desatualizada', () {
    const calculator = DairyIndicatorCalculator();
    final summary = calculator.summarize(
      [
        DairyDailyProductionData(
          date: DateTime(2026, 9, 1),
          morningLiters: 100,
          afternoonLiters: 50,
          cowsMilked: 10,
        ),
      ],
      hectares: 10,
      referenceDate: DateTime(2026, 9, 8),
    );

    expect(summary.daysSinceLatestRecord, 7);
    expect(summary.latestRecordIsStale, isTrue);
    expect(summary.dataQualityAlerts.join(' '), contains('há 7 dias'));
  });

  test('área fracionária usa hectares exatos e rejeita base inválida', () {
    final records = [
      DairyDailyProductionData(
        date: DateTime(2026, 9, 15),
        morningLiters: 80,
        afternoonLiters: 40,
        cowsMilked: 10,
      ),
    ];
    DairyProductionSummary summary(double area) =>
        const DairyIndicatorCalculator().summarize(
          records,
          hectares: area,
          referenceDate: DateTime(2026, 9, 15),
        );
    expect(summary(1.6).averageLitersPerHectare, closeTo(75, 0.001));
    expect(summary(0.4).averageLitersPerHectare, closeTo(300, 0.001));
    for (final invalid in [0.0, -1.0, 1e-320, double.nan, double.infinity]) {
      expect(summary(invalid).averageLitersPerHectare, isNull);
    }
  });

  test('idade da ordenha usa dias civis inclusive na virada do mês', () {
    final summary = const DairyIndicatorCalculator().summarize(
      [
        DairyDailyProductionData(
          date: DateTime(2026, 8, 31, 23),
          morningLiters: 120,
          afternoonLiters: 0,
          cowsMilked: 10,
        ),
      ],
      hectares: 1.6,
      referenceDate: DateTime(2026, 9, 4, 1),
    );
    expect(summary.daysSinceLatestRecord, 4);
    expect(summary.latestRecordIsStale, isTrue);
  });
}
