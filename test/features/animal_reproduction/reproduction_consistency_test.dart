import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_metrics_service.dart';

AnimalReproductionData event(
  String id, {
  String status = '',
  String expected = '',
  String code = 'pregnancy_diagnosis',
}) => AnimalReproductionData(
  id: id,
  type: '',
  date: '01/09/2026',
  result: '',
  bullOrSemen: '',
  responsible: '',
  notes: '',
  eventCode: code,
  reproductiveStatus: status,
  expectedDate: expected,
  animalId: 'cow',
);

void main() {
  test('modelo compartilha situações PT/API sem mudar serialização', () {
    for (final status in ['Prenhe', ' pregnant ', 'PRENHE']) {
      final record = event('p', status: status);
      expect(record.normalizedDiagnosisStatus, 'pregnant');
      expect(record.isPositivePregnancyDiagnosis, isTrue);
      expect(record.toMap()['reproductiveStatus'], status);
    }
    for (final status in ['Vazia', 'open']) {
      expect(event('o', status: status).normalizedDiagnosisStatus, 'open');
      expect(event('o', status: status).isPositivePregnancyDiagnosis, isFalse);
    }
    for (final status in ['', 'Inconclusivo', 'não prenhe']) {
      expect(event('u', status: status).normalizedDiagnosisStatus, isNull);
      expect(event('u', status: status).isPositivePregnancyDiagnosis, isFalse);
    }
    expect(
      event(
        'observation',
        status: 'Prenhe',
        code: 'observation',
      ).isPositivePregnancyDiagnosis,
      isFalse,
    );
  });
  test('métricas contam português e API igualmente', () {
    final result = const ReproductionMetricsService().calculate([
      event('p', status: 'Prenhe'),
      event('p2', status: 'pregnant'),
      event('o', status: 'Vazia'),
      event('u', status: 'Inconclusivo'),
    ]);
    expect(result.diagnoses, 4);
    expect(result.pregnancies, 2);
  });
  test('agenda não quebra com texto ou datas impossíveis', () {
    final result = const ReproductionMetricsService().calculate([
      for (final value in [
        '',
        'x/y/z',
        '31/02/2026',
        '29/02/2026',
        '2026-13-01',
        '0/09/2026',
        '01/01/0000',
      ])
        event(value, expected: value),
      event('valid', expected: '27/09/2026'),
    ], referenceDate: DateTime(2026, 9, 27));
    expect(result.upcoming.map((e) => e.id), ['valid']);
  });
  test('agenda ordena datas reais através de mês e ano', () {
    final result = const ReproductionMetricsService().calculate([
      event('jan', expected: '01/01/2027'),
      event('oct', expected: '01/10/2026'),
      event('today', expected: '2026-09-27'),
      event('old', expected: '26/09/2026'),
    ], referenceDate: DateTime(2026, 9, 27, 23));
    expect(result.upcoming.map((e) => e.id), ['today', 'oct', 'jan']);
  });
  test('agenda aceita bissexto e desempata independentemente da entrada', () {
    final events = [
      event('b', expected: '29/02/2028'),
      event('a', expected: '2028-02-29'),
    ];
    for (final ordered in [events, events.reversed.toList()]) {
      final result = const ReproductionMetricsService().calculate(
        ordered,
        referenceDate: DateTime(2028, 2, 29),
      );
      expect(result.upcoming.map((e) => e.id), ['a', 'b']);
    }
  });
}
