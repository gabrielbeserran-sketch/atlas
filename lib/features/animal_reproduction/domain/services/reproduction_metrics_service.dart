import '../models/animal_reproduction_data.dart';
import 'reproduction_calendar.dart';

class ReproductionMetrics {
  const ReproductionMetrics({
    required this.services,
    required this.diagnoses,
    required this.pregnancies,
    required this.calvings,
    required this.abortions,
    required this.conceptionRate,
    required this.servicesPerConception,
    required this.upcoming,
  });
  final int services, diagnoses, pregnancies, calvings, abortions;
  final double conceptionRate, servicesPerConception;
  final List<AnimalReproductionData> upcoming;
}

class ReproductionMetricsService {
  const ReproductionMetricsService();
  ReproductionMetrics calculate(
    List<AnimalReproductionData> records, {
    DateTime? referenceDate,
  }) {
    final services = records
        .where((e) => {'ai', 'iatf', 'natural_service'}.contains(e.eventCode))
        .length;
    final diagnoses = records
        .where((e) => e.eventCode == 'pregnancy_diagnosis')
        .length;
    final pregnancies = records
        .where((e) => e.isPositivePregnancyDiagnosis)
        .length;
    final calvings = records.where((e) => e.eventCode == 'calving').length;
    final abortions = records.where((e) => e.eventCode == 'abortion').length;
    final now = referenceDate ?? DateTime.now();
    final upcoming =
        records.where((e) {
          final date = ReproductionCalendar.parse(e.expectedDate);
          return date != null &&
              !date.isBefore(DateTime(now.year, now.month, now.day));
        }).toList()..sort((a, b) {
          final comparison = ReproductionCalendar.parse(
            a.expectedDate,
          )!.compareTo(ReproductionCalendar.parse(b.expectedDate)!);
          if (comparison != 0) return comparison;
          final animalComparison = a.animalId.compareTo(b.animalId);
          return animalComparison != 0
              ? animalComparison
              : a.id.compareTo(b.id);
        });
    return ReproductionMetrics(
      services: services,
      diagnoses: diagnoses,
      pregnancies: pregnancies,
      calvings: calvings,
      abortions: abortions,
      conceptionRate: services == 0 ? 0 : pregnancies * 100 / services,
      servicesPerConception: pregnancies == 0 ? 0 : services / pregnancies,
      upcoming: upcoming,
    );
  }
}
