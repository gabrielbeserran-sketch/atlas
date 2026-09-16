import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';

class DairyReproductionIndicators {
  const DairyReproductionIndicators({
    required this.averageDaysInMilk,
    required this.lactatingCowsWithKnownCalving,
    required this.conceptionRate,
    required this.inseminationAttempts,
    required this.confirmedPregnancies,
    required this.averageDryPeriodDays,
    required this.averageServicePeriodDays,
    required this.averageAgeAtFirstCalvingDays,
    required this.pregnancyRateFromLatestDiagnosis,
    required this.cowsWithPregnancyDiagnosis,
    required this.replacementCoverageRate,
    required this.femaleEntries,
    required this.femaleExits,
    required this.reproductiveCulls,
    required this.activeFemaleCount,
  });
  final double? averageDaysInMilk;
  final int lactatingCowsWithKnownCalving;
  final double? conceptionRate;
  final int inseminationAttempts;
  final int confirmedPregnancies;
  final double? averageDryPeriodDays;
  final double? averageServicePeriodDays;
  final double? averageAgeAtFirstCalvingDays;
  final double? pregnancyRateFromLatestDiagnosis;
  final int cowsWithPregnancyDiagnosis;

  /// Entradas de fêmeas divididas pelas saídas no período de 12 meses.
  final double? replacementCoverageRate;
  final int femaleEntries;
  final int femaleExits;
  final int reproductiveCulls;
  final int activeFemaleCount;

  int get dataCoveragePercent {
    if (activeFemaleCount == 0) return 0;
    final sources = [
      lactatingCowsWithKnownCalving > 0,
      inseminationAttempts > 0,
      cowsWithPregnancyDiagnosis > 0,
      femaleEntries > 0 || femaleExits > 0 || reproductiveCulls > 0,
    ].where((available) => available).length;
    return (sources / 4 * 100).round();
  }

  String get recommendationConfidenceLabel {
    final coverage = dataCoveragePercent;
    if (coverage == 0) return 'Sem base reprodutiva';
    if (coverage < 50) return 'Confiança limitada';
    if (coverage < 100) return 'Confiança parcial';
    return 'Confiança sustentada';
  }

  List<String> get dataQualityAlerts {
    final alerts = <String>[];
    if (activeFemaleCount == 0) {
      alerts.add('Cadastre as matrizes ativas para iniciar os indicadores.');
      return alerts;
    }
    if (lactatingCowsWithKnownCalving == 0) {
      alerts.add(
        'Registre partos para calcular DEL e idade ao primeiro parto.',
      );
    }
    if (inseminationAttempts == 0) {
      alerts.add('Registre inseminações para acompanhar a concepção.');
    }
    if (cowsWithPregnancyDiagnosis == 0) {
      alerts.add('Registre diagnósticos para acompanhar a taxa de prenhez.');
    }
    if (femaleEntries == 0 && femaleExits == 0 && reproductiveCulls == 0) {
      alerts.add(
        'Registre entradas, saídas ou descartes para cobrir reposição.',
      );
    }
    return alerts;
  }
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
    final periodStart = DateTime(today.year - 1, today.month, today.day);
    final femaleAnimals = animals.where((animal) => animal.sex == 'Fêmea');
    final femaleAnimalIds = femaleAnimals.map((animal) => animal.id).toSet();
    final femaleEntries = femaleAnimals.where((animal) {
      final entryDate = _date(animal.acquisitionDate);
      final birthDate = _date(animal.birthDate);
      return _inPeriod(entryDate, periodStart, today) ||
          _inPeriod(birthDate, periodStart, today);
    }).length;
    final femaleExits = femaleAnimals.where((animal) {
      if (animal.status == 'Ativo') return false;
      return _inPeriod(_date(animal.saleDate), periodStart, today);
    }).length;
    final recordsByAnimal = <String, List<AnimalReproductionData>>{};
    for (final record in records) {
      if (record.animalId.isEmpty || !activeFemales.contains(record.animalId)) {
        continue;
      }
      (recordsByAnimal[record.animalId] ??= []).add(record);
    }
    final del = <int>[];
    final dryPeriods = <int>[];
    final servicePeriods = <int>[];
    final firstCalvingAges = <int>[];
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
      final animal = animals.firstWhere(
        (item) => item.id == events.first.animalId,
      );
      final birth = _date(animal.birthDate);
      if (birth != null) {
        firstCalvingAges.add(calvings.first.difference(birth).inDays);
      }
      final days = today.difference(calvings.last).inDays;
      if (days >= 0) del.add(days);
      final dryStarts = events
          .where((event) => event.type == 'Início do período seco')
          .map((event) => _date(event.date))
          .whereType<DateTime>()
          .toList();
      for (final calving in calvings) {
        final matches = dryStarts
            .where((date) => !date.isAfter(calving))
            .toList();
        if (matches.isNotEmpty) {
          dryPeriods.add(calving.difference(matches.last).inDays);
        }
      }
      final services = events
          .where((event) => event.isInsemination)
          .map((event) => _date(event.date))
          .whereType<DateTime>()
          .toList();
      for (final calving in calvings) {
        final candidates = services
            .where((date) => !date.isBefore(calving))
            .toList();
        if (candidates.isNotEmpty) {
          servicePeriods.add(candidates.first.difference(calving).inDays);
        }
      }
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
              femaleAnimalIds.contains(event.animalId) &&
              event.isPositivePregnancyDiagnosis,
        )
        .length;
    var diagnosedCows = 0;
    var currentlyPregnant = 0;
    final reproductiveCulls = records
        .where(
          (event) =>
              activeFemales.contains(event.animalId) &&
              event.eventCode == 'reproductive_cull' &&
              _inPeriod(_date(event.date), periodStart, today),
        )
        .map((event) => event.animalId)
        .toSet()
        .length;
    final totalExits = femaleExits + reproductiveCulls;
    for (final events in recordsByAnimal.values) {
      final diagnoses =
          events
              .where((event) => event.eventCode == 'pregnancy_diagnosis')
              .where((event) => _date(event.date) != null)
              .toList()
            ..sort((a, b) => _date(a.date)!.compareTo(_date(b.date)!));
      if (diagnoses.isNotEmpty) {
        diagnosedCows++;
        if (diagnoses.last.reproductiveStatus == 'pregnant') {
          currentlyPregnant++;
        }
      }
    }
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
      averageDryPeriodDays: dryPeriods.isEmpty
          ? null
          : dryPeriods.reduce((a, b) => a + b) / dryPeriods.length,
      averageServicePeriodDays: servicePeriods.isEmpty
          ? null
          : servicePeriods.reduce((a, b) => a + b) / servicePeriods.length,
      averageAgeAtFirstCalvingDays: firstCalvingAges.isEmpty
          ? null
          : firstCalvingAges.reduce((a, b) => a + b) / firstCalvingAges.length,
      pregnancyRateFromLatestDiagnosis: diagnosedCows == 0
          ? null
          : currentlyPregnant / diagnosedCows * 100,
      cowsWithPregnancyDiagnosis: diagnosedCows,
      replacementCoverageRate: totalExits == 0
          ? null
          : femaleEntries / totalExits * 100,
      femaleEntries: femaleEntries,
      femaleExits: femaleExits,
      reproductiveCulls: reproductiveCulls,
      activeFemaleCount: activeFemales.length,
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

  bool _inPeriod(DateTime? date, DateTime start, DateTime end) =>
      date != null && !date.isBefore(start) && !date.isAfter(end);
}
