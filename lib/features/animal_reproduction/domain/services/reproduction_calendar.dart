import '../models/animal_reproduction_data.dart';

/// Datas civis: não inventa uma data ao encontrar conteúdo ilegível.
class ReproductionCalendar {
  static DateTime? parse(String value) {
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

  static AnimalReproductionData? latest(
    List<AnimalReproductionData> records, {
    DateTime? referenceDate,
  }) {
    final reference = referenceDate ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final valid =
        records.where((record) {
          final date = parse(record.date);
          return date != null && !date.isAfter(today);
        }).toList()..sort((a, b) {
          final comparison = parse(b.date)!.compareTo(parse(a.date)!);
          return comparison != 0 ? comparison : a.id.compareTo(b.id);
        });
    return valid.isEmpty ? null : valid.first;
  }
}
