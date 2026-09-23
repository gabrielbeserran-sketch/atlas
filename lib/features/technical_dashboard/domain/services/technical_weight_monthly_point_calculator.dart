import 'package:projeto_atlas/features/beef_production/domain/services/beef_weight_gain_calculator.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_weight_series_point.dart';

class TechnicalWeightMonthlyPointCalculator {
  const TechnicalWeightMonthlyPointCalculator();

  /// Um animal contribui uma vez à média mensal: sua última medição válida.
  /// A contagem de medições preserva o total de registros aceitos no mês.
  TechnicalWeightSeriesPoint? calculate({
    required DateTime periodStart,
    required String label,
    required List<BeefWeightMeasurement> measurements,
    required DateTime referenceDate,
  }) {
    final monthStart = DateTime.utc(periodStart.year, periodStart.month);
    final nextMonth = DateTime.utc(periodStart.year, periodStart.month + 1);
    final today = DateTime.utc(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final lastByAnimal = <String, BeefWeightMeasurement>{};
    var measurementCount = 0;
    DateTime? latestDate;

    for (final measurement in measurements) {
      final date = measurement.date;
      final day = DateTime.utc(date.year, date.month, date.day);
      if (measurement.animalId.isEmpty ||
          measurement.weightKg <= 0 ||
          !measurement.weightKg.isFinite ||
          day.isBefore(monthStart) ||
          !day.isBefore(nextMonth) ||
          day.isAfter(today)) {
        continue;
      }

      measurementCount++;
      if (latestDate == null || day.isAfter(latestDate)) {
        latestDate = day;
      }
      final previous = lastByAnimal[measurement.animalId];
      if (previous == null || !date.isBefore(previous.date)) {
        lastByAnimal[measurement.animalId] = measurement;
      }
    }

    if (lastByAnimal.isEmpty) return null;
    final total = lastByAnimal.values.fold<double>(
      0,
      (sum, measurement) => sum + measurement.weightKg,
    );
    return TechnicalWeightSeriesPoint(
      periodStart: periodStart,
      label: label,
      averageWeight: total / lastByAnimal.length,
      measurementCount: measurementCount,
      animalCount: lastByAnimal.length,
      latestMeasurementDate: latestDate!,
    );
  }
}
