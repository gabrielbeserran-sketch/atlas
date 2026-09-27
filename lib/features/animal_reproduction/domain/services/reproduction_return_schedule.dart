import '../models/animal_reproduction_data.dart';
import 'reproduction_calendar.dart';

class ReproductionReturnSchedule {
  const ReproductionReturnSchedule({
    this.past = 0,
    this.today = 0,
    this.nextSevenDays = 0,
    this.later = 0,
    this.invalid = 0,
    this.ambiguous = 0,
  });
  final int past, today, nextSevenDays, later, invalid, ambiguous;

  /// Previsões, não tarefas abertas: o modelo não registra baixa/cancelamento.
  static ReproductionReturnSchedule calculate(
    List<AnimalReproductionData> records, {
    DateTime? referenceDate,
  }) {
    final reference = referenceDate ?? DateTime.now();
    final date = DateTime(reference.year, reference.month, reference.day);
    final limit = DateTime(date.year, date.month, date.day + 7);
    final planned = records
        .where((e) => e.expectedDate.trim().isNotEmpty)
        .toList();
    final identities = <(String, String), int>{};
    for (final record in planned) {
      identities.update(
        (record.animalId, record.id),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    var past = 0, today = 0, next = 0, later = 0, invalid = 0, ambiguous = 0;
    for (final record in planned) {
      if (record.animalId.trim().isEmpty ||
          record.id.trim().isEmpty ||
          identities[(record.animalId, record.id)] != 1) {
        ambiguous++;
        continue;
      }
      if (record.returnResolutionStatus != null) continue;
      final expected = ReproductionCalendar.parse(record.expectedDate);
      final occurred = ReproductionCalendar.parse(record.date);
      if (expected == null ||
          occurred == null ||
          occurred.isAfter(date) ||
          expected.isBefore(occurred)) {
        invalid++;
        continue;
      }
      if (expected.isBefore(date)) {
        past++;
      } else if (expected == date) {
        today++;
      } else if (!expected.isAfter(limit)) {
        next++;
      } else {
        later++;
      }
    }
    return ReproductionReturnSchedule(
      past: past,
      today: today,
      nextSevenDays: next,
      later: later,
      invalid: invalid,
      ambiguous: ambiguous,
    );
  }
}
