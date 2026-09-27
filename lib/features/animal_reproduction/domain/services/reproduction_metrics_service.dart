import '../models/animal_reproduction_data.dart';

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
          final date = _expectedDate(e.expectedDate);
          return date != null &&
              !date.isBefore(DateTime(now.year, now.month, now.day));
        }).toList()..sort((a, b) {
          final comparison = _expectedDate(
            a.expectedDate,
          )!.compareTo(_expectedDate(b.expectedDate)!);
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

  DateTime? _expectedDate(String value) {
    final normalized = value.trim();
    final br = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(normalized);
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(normalized);
    if (br == null && iso == null) return null;
    final year = int.parse(br?.group(3) ?? iso!.group(1)!);
    final month = int.parse(br?.group(2) ?? iso!.group(2)!);
    final day = int.parse(br?.group(1) ?? iso!.group(3)!);
    if (year < 1900 ||
        year > 9999 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}
