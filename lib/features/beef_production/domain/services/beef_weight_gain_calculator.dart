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
    required this.excludedAmbiguousAnimals,
  });

  final double? averageKgPerDay;
  final int animalCount;
  final int excludedAmbiguousAnimals;
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
    var excludedAmbiguousAnimals = 0;
    for (final records in byAnimal.values) {
      records.sort((a, b) => a.date.compareTo(b.date));
      if (records.length < 2) continue;
      final first = records.first;
      final last = records.last;
      final firstDay = DateTime.utc(
        first.date.year,
        first.date.month,
        first.date.day,
      );
      final lastDay = DateTime.utc(
        last.date.year,
        last.date.month,
        last.date.day,
      );
      final days = lastDay.difference(firstDay).inDays;
      if (days <= 0) continue;
      final firstWeights = records
          .where(
            (item) =>
                item.date.year == first.date.year &&
                item.date.month == first.date.month &&
                item.date.day == first.date.day,
          )
          .map((item) => item.weightKg)
          .toSet();
      final lastWeights = records
          .where(
            (item) =>
                item.date.year == last.date.year &&
                item.date.month == last.date.month &&
                item.date.day == last.date.day,
          )
          .map((item) => item.weightKg)
          .toSet();
      if (firstWeights.length != 1 || lastWeights.length != 1) {
        excludedAmbiguousAnimals++;
        continue;
      }
      final gain = (lastWeights.single - firstWeights.single) / days;
      if (gain.isFinite) gains.add(gain);
    }
    if (gains.isEmpty) {
      return BeefWeightGain(
        averageKgPerDay: null,
        animalCount: 0,
        excludedAmbiguousAnimals: excludedAmbiguousAnimals,
      );
    }
    return BeefWeightGain(
      averageKgPerDay: gains.fold<double>(
        0,
        (sum, gain) => sum + gain / gains.length,
      ),
      animalCount: gains.length,
      excludedAmbiguousAnimals: excludedAmbiguousAnimals,
    );
  }
}
