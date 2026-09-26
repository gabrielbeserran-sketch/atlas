class BeefWeightMeasurement {
  const BeefWeightMeasurement({
    required this.animalId,
    required this.date,
    required this.weightKg,
  });

  final String animalId;
  final DateTime date;
  final double weightKg;
}

class BeefWeightGain {
  const BeefWeightGain({
    required this.averageKgPerDay,
    required this.animalCount,
  });

  final double? averageKgPerDay;
  final int animalCount;
}

class BeefWeightGainCalculator {
  const BeefWeightGainCalculator();

  /// Média dos ganhos individuais de animais com duas pesagens válidas
  /// nos últimos 12 meses. Animais distintos nunca formam um par.
  BeefWeightGain calculate({
    required List<BeefWeightMeasurement> measurements,
    required Set<String> activeAnimalIds,
    required DateTime referenceDate,
  }) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final start = DateTime(today.year - 1, today.month, today.day);
    final byAnimal = <String, List<BeefWeightMeasurement>>{};
    for (final measurement in measurements) {
      final day = DateTime(
        measurement.date.year,
        measurement.date.month,
        measurement.date.day,
      );
      if (!activeAnimalIds.contains(measurement.animalId) ||
          day.isBefore(start) ||
          day.isAfter(today) ||
          !measurement.weightKg.isFinite ||
          measurement.weightKg <= 0) {
        continue;
      }
      (byAnimal[measurement.animalId] ??= []).add(measurement);
    }

    final gains = <double>[];
    for (final records in byAnimal.values) {
      records.sort((a, b) => a.date.compareTo(b.date));
      if (records.length < 2) continue;
      final first = records.first;
      final last = records.last;
      final days = DateTime(last.date.year, last.date.month, last.date.day)
          .difference(
            DateTime(first.date.year, first.date.month, first.date.day),
          )
          .inDays;
      if (days <= 0) continue;
      gains.add((last.weightKg - first.weightKg) / days);
    }
    if (gains.isEmpty) {
      return const BeefWeightGain(averageKgPerDay: null, animalCount: 0);
    }
    return BeefWeightGain(
      averageKgPerDay: gains.reduce((a, b) => a + b) / gains.length,
      animalCount: gains.length,
    );
  }
}
