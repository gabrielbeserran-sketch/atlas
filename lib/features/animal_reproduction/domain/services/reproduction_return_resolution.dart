import '../models/animal_reproduction_data.dart';
import 'reproduction_calendar.dart';

class ReproductionReturnResolution {
  static AnimalReproductionData resolve(
    AnimalReproductionData record, {
    required String status,
    required String responsible,
    required DateTime at,
    String reason = '',
  }) {
    final expected = ReproductionCalendar.parse(record.expectedDate);
    final occurred = ReproductionCalendar.parse(record.date);
    if (record.id.trim().isEmpty ||
        expected == null ||
        occurred == null ||
        expected.isBefore(occurred) ||
        occurred.isAfter(DateTime(at.year, at.month, at.day)) ||
        at.isAfter(DateTime.now()) ||
        responsible.trim().isEmpty ||
        !{'completed', 'cancelled'}.contains(status) ||
        (status == 'cancelled' && reason.trim().isEmpty)) {
      throw ArgumentError(
        'Resolução exige identidade, previsão/origem válidas, responsável, data não futura e motivo para cancelamento.',
      );
    }
    if (record.returnResolutionStatus != null) {
      throw StateError('Retorno já resolvido; não sobrescrever a auditoria.');
    }
    final normalized = AnimalReproductionData.fromMap(record.toMap());
    return AnimalReproductionData.fromMap({
      ...normalized.toMap(),
      'metadata': {
        ...record.metadata,
        'atlas_return_resolution': {
          'event_id': record.id,
          'occurred_date': normalized.date,
          'expected_date': normalized.expectedDate,
          'status': status,
          'responsible': responsible.trim(),
          'resolved_at': at.toUtc().toIso8601String(),
          'reason': reason.trim(),
        },
      },
    });
  }
}
