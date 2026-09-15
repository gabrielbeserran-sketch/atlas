import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';

class DairyReproductionIndicators {
  const DairyReproductionIndicators({
    required this.averageDaysInMilk,
    required this.lactatingCowsWithKnownCalving,
    required this.conceptionRate,
    required this.inseminationAttempts,
    required this.confirmedPregnancies,
  });
  final double? averageDaysInMilk;
  final int lactatingCowsWithKnownCalving;
  final double? conceptionRate;
  final int inseminationAttempts;
  final int confirmedPregnancies;
}

/// Calcula somente métricas cuja origem pode ser comprovada por animal e data.
/// A taxa de prenhez, vacas secas e período de serviço exigem estados de lote
/// ainda não registrados pelo Atlas e permanecem indisponíveis até essa etapa.
class DairyReproductionIndicatorCalculator {
  const DairyReproductionIndicatorCalculator();

  DairyReproductionIndicators calculate({
    required List<AnimalData> animals,
    required List<AnimalReproductionData> records,
    DateTime? referenceDate,
  }) {
    final today = referenceDate ?? DateTime.now();
    final activeFemales = animals
        .where((animal) => animal.status == 'Ativo' && animal.sex == 'Fêmea')
        .map((animal) => animal.id)
        .toSet();
    final recordsByAnimal = <String, List<AnimalReproductionData>>{};
    for (final record in records) {
      if (record.animalId.isEmpty || !activeFemales.contains(record.animalId)) {
        continue;
      }
      (recordsByAnimal[record.animalId] ??= []).add(record);
    }
    final del = <int>[];
    for (final events in recordsByAnimal.values) {
      final calvings =
          events
              .where((event) => event.eventCode == 'calving')
              .map((event) => _date(event.date))
              .whereType<DateTime>()
              .where((date) => !date.isAfter(today))
              .toList()
            ..sort();
      if (calvings.isEmpty) continue;
      final days = today.difference(calvings.last).inDays;
      if (days >= 0) del.add(days);
    }
    final inseminations = records
        .where(
          (event) =>
              activeFemales.contains(event.animalId) && event.isInsemination,
        )
        .length;
    final pregnancies = records
        .where(
          (event) =>
              activeFemales.contains(event.animalId) &&
              event.isPositivePregnancyDiagnosis,
        )
        .length;
    return DairyReproductionIndicators(
      averageDaysInMilk: del.isEmpty
          ? null
          : del.reduce((a, b) => a + b) / del.length,
      lactatingCowsWithKnownCalving: del.length,
      conceptionRate: inseminations == 0
          ? null
          : pregnancies / inseminations * 100,
      inseminationAttempts: inseminations,
      confirmedPregnancies: pregnancies,
    );
  }

  DateTime? _date(String value) {
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    return day == null || month == null || year == null
        ? null
        : DateTime(year, month, day);
  }
}
