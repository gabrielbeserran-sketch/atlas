import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_calendar.dart';

AnimalReproductionData event(String id, String date) => AnimalReproductionData(
  id: id,
  date: date,
  type: '',
  result: '',
  bullOrSemen: '',
  responsible: '',
  notes: '',
);

void main() {
  test('datas civis BR e ISO são equivalentes sem normalizar inválidas', () {
    expect(ReproductionCalendar.parse(' 29/02/2028 '), DateTime(2028, 2, 29));
    expect(ReproductionCalendar.parse('2028-02-29'), DateTime(2028, 2, 29));
    for (final value in [
      '31/02/2026',
      '2026-02-29',
      '00/09/2026',
      '2026-13-01',
      'x/y/z',
      '',
      '01/01/0000',
    ]) {
      expect(ReproductionCalendar.parse(value), isNull, reason: value);
    }
  });
  test('último evento ordena calendário, exclui futuro e não altera lista', () {
    final records = [
      event('old', '30/12/2025'),
      event('new', '2026-01-02'),
      event('invalid', '32/12/2025'),
      event('future', '01/02/2026'),
    ];
    final original = records.map((e) => e.id).toList();
    expect(
      ReproductionCalendar.latest(
        records,
        referenceDate: DateTime(2026, 1, 2, 22),
      )!.id,
      'new',
    );
    expect(records.map((e) => e.id), original);
  });
  test('ausência de data válida realizada não vira 1900', () {
    expect(
      ReproductionCalendar.latest([
        event('invalid', 'inválida'),
        event('future', '01/01/2027'),
      ], referenceDate: DateTime(2026, 1, 1)),
      isNull,
    );
  });
  test('empate tem resultado estável independente da ordem de entrada', () {
    final records = [event('b', '01/01/2026'), event('a', '2026-01-01')];
    for (final ordered in [records, records.reversed.toList()]) {
      expect(
        ReproductionCalendar.latest(
          ordered,
          referenceDate: DateTime(2026, 1, 1),
        )!.id,
        'a',
      );
    }
  });
}
