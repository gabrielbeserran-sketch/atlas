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

  double? get percent => activeAnimalCount == 0
      ? null
      : weighedAnimalCount / activeAnimalCount * 100;
}

class BeefLatestWeightCoverageCalculator {
  const BeefLatestWeightCoverageCalculator();

  /// Conta animais ativos com pesagem válida no mês da última pesagem de um
  /// animal ainda ativo. Saídas e óbitos não deslocam a data da amostra.
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
        .where(
          (measurement) =>
              measurement.date.year == latest.year &&
              measurement.date.month == latest.month,
        )
        .map((measurement) => measurement.animalId)
        .toSet();

    return BeefLatestWeightCoverage(
      activeAnimalCount: activeAnimalIds.length,
      weighedAnimalCount: weighed.length,
      latestMeasurementDate: latest,
    );
  }
}
