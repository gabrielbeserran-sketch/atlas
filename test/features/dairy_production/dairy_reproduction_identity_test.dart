import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/services/dairy_reproduction_indicator_calculator.dart';

AnimalData cow(String id) => AnimalData(
  id: id,
  tag: id,
  name: 'Matriz',
  sex: 'Fêmea',
  breed: 'G',
  birthDate: '01/01/2020',
  weight: 480,
  status: 'Ativo',
);
AnimalReproductionData event(
  String id, {
  String animal = 'cow',
  String date = '15/09/2026',
  String code = 'iatf',
  String status = '',
}) => AnimalReproductionData(
  id: id,
  animalId: animal,
  date: date,
  eventCode: code,
  reproductiveStatus: status,
  type: code,
  result: '',
  bullOrSemen: '',
  responsible: '',
  notes: '',
);
DairyReproductionIndicators calculate(
  List<AnimalReproductionData> records, {
  List<AnimalData>? animals,
}) => const DairyReproductionIndicatorCalculator().calculate(
  animals: animals ?? [cow('cow')],
  records: records,
  referenceDate: DateTime(2026, 9, 26),
);

void main() {
  test('situações do formulário em português equivalem às da API', () {
    final result = calculate([
      event('ai'),
      event('p', code: 'pregnancy_diagnosis', status: 'Prenhe'),
      event('p2', code: 'pregnancy_diagnosis', status: 'pregnant'),
    ]);
    expect(result.pregnancyRateFromLatestDiagnosis, 100);
    expect(result.conflictingDiagnoses, 0);
    expect(result.confirmedPregnancies, 2);
    final open = calculate([
      event('o', code: 'pregnancy_diagnosis', status: 'Vazia'),
    ]);
    expect(open.pregnancyRateFromLatestDiagnosis, 0);
    expect(open.conflictingDiagnoses, 0);
  });
  test('IDs de eventos repetidos excluem todas as cópias com aviso', () {
    final result = calculate([event('same'), event('same'), event('valid')]);
    expect(result.inseminationAttempts, 1);
    expect(result.excludedAmbiguousRecords, 2);
    expect(
      result.dataQualityAlerts.join(' '),
      contains('ID ausente ou repetido'),
    );
  });
  test('mesmo ID de evento em animais diferentes mantém ambos', () {
    final result = calculate(
      [event('same'), event('same', animal: 'other')],
      animals: [cow('cow'), cow('other')],
    );
    expect(result.inseminationAttempts, 2);
    expect(result.excludedAmbiguousRecords, 0);
  });
  test('matrizes sem ID ou com identidade repetida não entram na base', () {
    final result = calculate(
      [event('ai')],
      animals: [cow('cow'), cow('cow'), cow('')],
    );
    expect(result.activeFemaleCount, 0);
    expect(result.inseminationAttempts, 0);
    expect(result.excludedAmbiguousRecords, 3);
    expect(
      result.dataQualityAlerts.join(' '),
      contains('ID ausente ou repetido'),
    );
  });
  test('parto anterior ao nascimento não gera idade negativa nem DEL', () {
    final result = calculate([
      event('parto', date: '01/01/2019', code: 'calving'),
    ]);
    expect(result.averageAgeAtFirstCalvingDays, isNull);
    expect(result.averageDaysInMilk, isNull);
    expect(result.eventsBeforeBirth, 1);
  });
  test(
    'diagnósticos contraditórios no último dia não escolhem um resultado',
    () {
      final events = [
        event('p', code: 'pregnancy_diagnosis', status: 'pregnant'),
        event('o', code: 'pregnancy_diagnosis', status: 'open'),
      ];
      for (final ordered in [events, events.reversed.toList()]) {
        final result = calculate(ordered);
        expect(result.cowsWithPregnancyDiagnosis, 0);
        expect(result.pregnancyRateFromLatestDiagnosis, isNull);
        expect(result.conflictingDiagnoses, 1);
      }
    },
  );
  test('diagnóstico sem situação não vira negativo', () {
    final result = calculate([event('unknown', code: 'pregnancy_diagnosis')]);
    expect(result.pregnancyRateFromLatestDiagnosis, isNull);
    expect(result.conflictingDiagnoses, 1);
  });
  test(
    'diagnósticos acima das tentativas não geram concepção maior que 100%',
    () {
      final result = calculate([
        event('ai'),
        event('p1', code: 'pregnancy_diagnosis', status: 'pregnant'),
        event('p2', code: 'pregnancy_diagnosis', status: 'pregnant'),
      ]);
      expect(result.conceptionRate, isNull);
      expect(result.dataQualityAlerts.join(' '), contains('excedem'));
    },
  );
}
