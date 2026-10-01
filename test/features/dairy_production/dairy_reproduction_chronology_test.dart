import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/services/dairy_reproduction_indicator_calculator.dart';

AnimalReproductionData event(String id, String date, String code) =>
    AnimalReproductionData(
      id: id,
      date: date,
      eventCode: code,
      animalId: 'cow',
      type: code == 'dry' ? 'Início do período seco' : code,
      result: '',
      bullOrSemen: '',
      responsible: '',
      notes: '',
    );

DairyReproductionIndicators calculate(List<AnimalReproductionData> events) =>
    const DairyReproductionIndicatorCalculator().calculate(
      animals: [
        AnimalData(
          id: 'cow',
          tag: '1',
          name: 'Matriz',
          sex: 'Fêmea',
          breed: 'G',
          birthDate: '01/01/2020',
          weight: 480,
          status: 'Ativo',
        ),
      ],
      records: events,
      referenceDate: DateTime(2026, 9, 26),
    );

void main() {
  test('DEL usa dias civis na virada do horário de verão', () {
    final result = const DairyReproductionIndicatorCalculator().calculate(
      animals: [
        AnimalData(
          id: 'cow',
          tag: '1',
          name: 'Matriz',
          sex: 'Fêmea',
          breed: 'G',
          birthDate: '01/01/2016',
          weight: 480,
          status: 'Ativo',
        ),
      ],
      records: [event('parto', '03/11/2018', 'calving')],
      referenceDate: DateTime(2018, 11, 4),
    );
    expect(result.averageDaysInMilk, 1);
    expect(
      result.averageAgeAtFirstCalvingDays,
      DateTime.utc(2018, 11, 3).difference(DateTime.utc(2016, 1, 1)).inDays,
    );
  });

  test(
    'secagem e primeira inseminação contam dias civis; bissexto conta dois',
    () {
      final calculator = const DairyReproductionIndicatorCalculator();
      final animals = [
        AnimalData(
          id: 'cow',
          tag: '1',
          name: 'Matriz',
          sex: 'Fêmea',
          breed: 'G',
          birthDate: '01/01/2016',
          weight: 480,
          status: 'Ativo',
        ),
      ];
      final dry = calculator.calculate(
        animals: animals,
        records: [
          event('seca', '03/11/2018', 'dry'),
          event('parto', '04/11/2018', 'calving'),
        ],
        referenceDate: DateTime(2018, 11, 4),
      );
      expect(dry.averageDryPeriodDays, 1);

      final service = calculator.calculate(
        animals: animals,
        records: [
          event('parto', '03/11/2018', 'calving'),
          event('ai', '04/11/2018', 'iatf'),
        ],
        referenceDate: DateTime(2018, 11, 4),
      );
      expect(service.averageServicePeriodDays, 1);

      final leap = calculator.calculate(
        animals: animals,
        records: [
          event('seca', '28/02/2024', 'dry'),
          event('parto', '01/03/2024', 'calving'),
        ],
        referenceDate: DateTime(2024, 3, 1),
      );
      expect(leap.averageDryPeriodDays, 2);
    },
  );

  test('ordem de entrada não muda secagem nem primeira inseminação', () {
    final events = [
      event('parto', '01/09/2026', 'calving'),
      event('seca2', '01/08/2026', 'dry'),
      event('seca1', '01/07/2026', 'dry'),
      event('ai2', '10/09/2026', 'iatf'),
      event('ai1', '05/09/2026', 'iatf'),
    ];
    for (final ordered in [events, events.reversed.toList()]) {
      final result = calculate(ordered);
      expect(result.averageDryPeriodDays, 31);
      expect(result.averageServicePeriodDays, 4);
      expect(result.averageDaysInMilk, 25);
    }
  });

  test('inseminação não é emprestada ao ciclo anterior', () {
    final result = calculate([
      event('parto1', '01/01/2026', 'calving'),
      event('parto2', '01/09/2026', 'calving'),
      event('ai', '05/09/2026', 'iatf'),
    ]);
    expect(result.averageServicePeriodDays, 4);
  });

  test('secagem antiga não é reutilizada em outro parto', () {
    final result = calculate([
      event('seca', '01/12/2025', 'dry'),
      event('parto1', '01/01/2026', 'calving'),
      event('parto2', '01/09/2026', 'calving'),
    ]);
    expect(result.averageDryPeriodDays, 31);
  });

  test('secagem após último parto retira vaca da base do DEL', () {
    final result = calculate([
      event('parto', '01/09/2026', 'calving'),
      event('seca', '20/09/2026', 'dry'),
    ]);
    expect(result.averageDaysInMilk, isNull);
    expect(result.lactatingCowsWithKnownCalving, 0);
  });

  test('secagem futura não retira vaca em lactação', () {
    final result = calculate([
      event('parto', '01/09/2026', 'calving'),
      event('seca', '01/10/2026', 'dry'),
    ]);
    expect(result.averageDaysInMilk, 25);
    expect(result.reproductiveEventsInFuture, 1);
  });
}
