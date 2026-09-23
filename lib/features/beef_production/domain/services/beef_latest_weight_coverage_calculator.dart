import 'package:projeto_atlas/features/beef_production/domain/services/beef_weight_gain_calculator.dart';

class BeefLatestWeightCoverage {
  const BeefLatestWeightCoverage({
    required this.activeAnimalCount,
    required this.weighedAnimalCount,
    required this.latestMeasurementDate,
  });

  final int activeAnimalCount;
  final int weighedAnimalCount;
  final DateTime? latestMeasurementDate;

  int get unweighedAnimalCount => activeAnimalCount - weighedAnimalCount;

  double? get percent => activeAnimalCount == 0
      ? null
      : weighedAnimalCount / activeAnimalCount * 100;
}

class BeefLatestWeightCoverageCalculator {
  const BeefLatestWeightCoverageCalculator();

  /// Conta animais ativos com pesagem válida nos últimos 90 dias corridos.
  /// A última data é independente da cobertura: mesmo uma pesagem antiga
  /// permanece visível para sinalizar dados desatualizados.
  BeefLatestWeightCoverage calculate({
    required List<BeefWeightMeasurement> measurements,
    required Set<String> activeAnimalIds,
    required DateTime referenceDate,
  }) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    final valid = measurements.where((measurement) {
      final date = DateTime(
        measurement.date.year,
        measurement.date.month,
        measurement.date.day,
      );
      return activeAnimalIds.contains(measurement.animalId) &&
          !date.isAfter(today) &&
          measurement.weightKg.isFinite &&
          measurement.weightKg > 0;
    }).toList();

    if (valid.isEmpty) {
      return BeefLatestWeightCoverage(
        activeAnimalCount: activeAnimalIds.length,
        weighedAnimalCount: 0,
        latestMeasurementDate: null,
      );
    }

    valid.sort((a, b) => a.date.compareTo(b.date));
    final latest = valid.last.date;
    final weighed = valid
        .where((measurement) {
          final date = measurement.date;
          final dayUtc = DateTime.utc(date.year, date.month, date.day);
          return todayUtc.difference(dayUtc).inDays <= 90;
        })
        .map((measurement) => measurement.animalId)
        .toSet();

    return BeefLatestWeightCoverage(
      activeAnimalCount: activeAnimalIds.length,
      weighedAnimalCount: weighed.length,
      latestMeasurementDate: latest,
    );
  }
}
