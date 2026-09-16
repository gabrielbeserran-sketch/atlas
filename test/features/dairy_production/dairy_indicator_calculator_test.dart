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
      expect(summary.latestLiters, 120);
      expect(summary.averageLitersPerDay, 140);
      expect(summary.averageLitersPerHectare, 7);
      expect(summary.recordedDays, 2);
      expect(summary.litersPerLactatingCow, 14);
    },
  );
}
