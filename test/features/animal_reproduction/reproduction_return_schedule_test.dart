import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_return_schedule.dart';

AnimalReproductionData event(
  String id,
  String expected, {
  String date = '01/09/2026',
  String animal = 'cow',
}) => AnimalReproductionData(
  id: id,
  expectedDate: expected,
  date: date,
  animalId: animal,
  type: '',
  result: '',
  bullOrSemen: '',
  responsible: '',
  notes: '',
);

void main() {
  test('separa passado hoje sete dias e posterior na virada de mês', () {
    final result = ReproductionReturnSchedule.calculate([
      event('past', '26/09/2026'),
      event('today', '27/09/2026'),
      event('next', '2026-10-04'),
      event('later', '05/10/2026'),
      event('absent', ''),
    ], referenceDate: DateTime(2026, 9, 27, 23));
    expect(
      [result.past, result.today, result.nextSevenDays, result.later],
      [1, 1, 1, 1],
    );
    expect(result.invalid, 0);
  });
  test(
    'previsão anterior à origem e evento futuro ou inválido não viram pendência',
    () {
      final result = ReproductionReturnSchedule.calculate([
        event('before', '01/08/2026'),
        event('invalid', '31/02/2026'),
        event('source', '01/10/2026', date: 'ilegível'),
        event('future', '02/10/2026', date: '01/10/2026'),
      ], referenceDate: DateTime(2026, 9, 27));
      expect(result.invalid, 4);
      expect(
        result.past + result.today + result.nextSevenDays + result.later,
        0,
      );
    },
  );
  test(
    'identidade repetida não duplica retorno, ID em outro animal é distinto',
    () {
      final result = ReproductionReturnSchedule.calculate([
        event('same', '27/09/2026'),
        event('same', '27/09/2026'),
        event('same', '27/09/2026', animal: 'other'),
        event('', '27/09/2026'),
      ], referenceDate: DateTime(2026, 9, 27));
      expect(result.ambiguous, 3);
      expect(result.today, 1);
    },
  );
  test('classificar não modifica nem fecha o histórico', () {
    final records = [event('past', '26/09/2026')];
    final before = records.first.toMap();
    ReproductionReturnSchedule.calculate(
      records,
      referenceDate: DateTime(2026, 9, 27),
    );
    expect(records.first.toMap(), before);
  });
  test('espaços nos IDs não tornam retornos repetidos em duas tarefas', () {
    final result = ReproductionReturnSchedule.calculate([
      event('retorno', '27/09/2026'),
      event(' retorno ', '27/09/2026', animal: ' cow '),
      event('outro', '27/09/2026'),
    ], referenceDate: DateTime(2026, 9, 27));
    expect(result.ambiguous, 2);
    expect(result.today, 1);
  });
}
