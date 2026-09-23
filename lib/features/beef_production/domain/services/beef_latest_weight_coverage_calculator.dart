import 'package:projeto_atlas/features/beef_production/domain/services/beef_weight_gain_calculator.dart';

class BeefLatestWeightCoverage {
  const BeefLatestWeightCoverage({
    required this.activeAnimalCount,
    required this.weighedAnimalCount,
    required this.latestMeasurementDate,
    required this.pendingAnimalIds,
    required this.lastValidDateByAnimalId,
  });

  final int activeAnimalCount;
  final int weighedAnimalCount;
  final DateTime? latestMeasurementDate;
  final List<String> pendingAnimalIds;
  final Map<String, DateTime> lastValidDateByAnimalId;

  int get unweighedAnimalCount => pendingAnimalIds.length;

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

    final lastValidDateByAnimalId = <String, DateTime>{};
    for (final measurement in valid) {
      final old = lastValidDateByAnimalId[measurement.animalId];
      if (old == null || measurement.date.isAfter(old)) {
        lastValidDateByAnimalId[measurement.animalId] = measurement.date;
      }
    }
    final weighed = lastValidDateByAnimalId.entries
        .where((entry) {
          final date = entry.value;
          final dayUtc = DateTime.utc(date.year, date.month, date.day);
          return todayUtc.difference(dayUtc).inDays <= 90;
        })
        .map((entry) => entry.key)
        .toSet();
    final pendingAnimalIds = activeAnimalIds.difference(weighed).toList()
      ..sort();
    final latest = lastValidDateByAnimalId.values.fold<DateTime?>(
      null,
      (current, date) =>
          current == null || date.isAfter(current) ? date : current,
    );

    return BeefLatestWeightCoverage(
      activeAnimalCount: activeAnimalIds.length,
      weighedAnimalCount: weighed.length,
      latestMeasurementDate: latest,
      pendingAnimalIds: List.unmodifiable(pendingAnimalIds),
      lastValidDateByAnimalId: Map.unmodifiable(lastValidDateByAnimalId),
    );
  }
}
