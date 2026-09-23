import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/beef_production/domain/services/beef_herd_indicator_calculator.dart';

void main() {
  test('calcula desfrute apenas com vendas datadas nos últimos 12 meses', () {
    const calculator = BeefHerdIndicatorCalculator();
    final result = calculator.calculate(
      referenceDate: DateTime(2026, 9, 16),
      animals: [
        AnimalData(
          id: 'a',
          tag: '1',
          name: '',
          sex: 'Macho',
          breed: '',
          birthDate: '',
          weight: 400,
          status: 'Ativo',
        ),
        AnimalData(
          id: 's',
          tag: '2',
          name: '',
          sex: 'Macho',
          breed: '',
          birthDate: '10/09/2024',
          weight: 500,
          status: 'Vendido',
          saleDate: '10/09/2026',
          saleValue: 5200,
        ),
        AnimalData(
          id: 'old',
          tag: '3',
          name: '',
          sex: 'Macho',
          breed: '',
          birthDate: '',
          weight: 500,
          status: 'Vendido',
          saleDate: '10/09/2024',
        ),
      ],
    );
    expect(result.commercialExits, 1);
    expect(result.offtakeRate, 50);
    expect(result.commercialRevenue, 5200);
    expect(result.averageSaleValue, 5200);
    expect(result.averageSaleAgeMonths, closeTo(24, 0.1));
    expect(result.salesWithKnownAge, 1);
    expect(result.salesWithoutKnownAge, 0);
    expect(result.commercialExitsWithValue, 1);
    expect(result.dataQualityAlerts, isEmpty);
    expect(result.salesWithWeightAndValue, 1);
    expect(result.averageSalePricePerKg, 10.4);
    expect(result.commercialExitsWithoutDate, 0);
    expect(result.salesWithoutValue, 0);
    expect(result.salesWithoutWeight, 0);
    expect(result.mortalities, 0);
    expect(result.mortalitiesWithoutDate, 0);
    expect(result.mortalitiesWithoutCause, 0);
    expect(result.mortalityRate, 0);
    expect(result.primaryMortalityCause, isNull);
  });

  test('separa lacunas de dados dos indicadores calculados', () {
    const calculator = BeefHerdIndicatorCalculator();
    final result = calculator.calculate(
      referenceDate: DateTime(2026, 9, 16),
      animals: [
        AnimalData(
          id: 'sold-no-date',
          tag: '1',
          name: '',
          sex: 'Macho',
          breed: '',
          birthDate: '',
          weight: 420,
          status: 'Vendido',
          saleValue: 3500,
        ),
        AnimalData(
          id: 'sold-no-value',
          tag: '2',
          name: '',
          sex: 'Macho',
          breed: '',
          birthDate: '',
          weight: 430,
          status: 'Vendido',
          saleDate: '10/09/2026',
        ),
        AnimalData(
          id: 'sold-no-weight',
          tag: '3',
          name: '',
          sex: 'Macho',
          breed: '',
          birthDate: '',
          weight: 0,
          status: 'Vendido',
          saleDate: '10/09/2026',
          saleValue: 3600,
        ),
        AnimalData(
          id: 'dead-no-date',
          tag: '4',
          name: '',
          sex: 'Fêmea',
          breed: '',
          birthDate: '',
          weight: 0,
          status: 'Morto',
          deathCause: 'Doença',
        ),
        AnimalData(
          id: 'dead-no-cause',
          tag: '5',
          name: '',
          sex: 'Fêmea',
          breed: '',
          birthDate: '',
          weight: 0,
          status: 'Morto',
          deathDate: '11/09/2026',
          deathCause: 'Não informada',
        ),
      ],
    );

    expect(result.commercialExits, 2);
    expect(result.commercialExitsWithoutDate, 1);
    expect(result.salesWithoutValue, 1);
    expect(result.salesWithoutWeight, 1);
    expect(result.salesWithKnownAge, 0);
    expect(result.salesWithoutKnownAge, 2);
    expect(result.mortalities, 1);
    expect(result.mortalitiesWithoutDate, 1);
    expect(result.mortalitiesWithoutCause, 1);
    expect(result.dataQualityAlerts, hasLength(6));
  });

  test('exclui datas impossíveis sem normalizá-las para outro mês', () {
    const calculator = BeefHerdIndicatorCalculator();
    final result = calculator.calculate(
      referenceDate: DateTime(2026, 9, 16),
      animals: [
        AnimalData(
          id: 'sale-invalid-date',
          tag: '1',
          name: '',
          sex: 'Macho',
          breed: '',
          birthDate: '',
          weight: 450,
          status: 'Vendido',
          saleDate: '31/02/2026',
          saleValue: 4200,
        ),
        AnimalData(
          id: 'death-invalid-date',
          tag: '2',
          name: '',
          sex: 'Fêmea',
          breed: '',
          birthDate: '',
          weight: 0,
          status: 'Morto',
          deathDate: '2026-02-30',
          deathCause: 'Doença',
        ),
      ],
    );

    expect(result.commercialExits, 0);
    expect(result.commercialRevenue, 0);
    expect(result.mortalities, 0);
    expect(result.commercialExitsWithoutDate, 1);
    expect(result.mortalitiesWithoutDate, 1);
    expect(result.dataQualityAlerts.join(' '), contains('data válida'));
  });

  test('idade na venda usa apenas nascimentos válidos anteriores à saída', () {
    const calculator = BeefHerdIndicatorCalculator();
    AnimalData sold(String id, String birthDate, String saleDate) => AnimalData(
      id: id,
      tag: id,
      name: '',
      sex: 'Macho',
      breed: '',
      birthDate: birthDate,
      weight: 400,
      status: 'Vendido',
      saleDate: saleDate,
      saleValue: 4000,
    );
    final result = calculator.calculate(
      referenceDate: DateTime(2026, 9, 16),
      animals: [
        sold('a', '01/08/2024', '01/08/2026'),
        sold('b', '2025-07-01', '2026-07-01'),
        sold('c', '', '2026-08-02'),
        sold('d', '31/02/2025', '2026-08-03'),
        sold('e', '2026-09-01', '2026-08-04'),
        sold('old', '2020-01-01', '2024-01-01'),
      ],
    );

    final expectedDays =
        (DateTime.utc(2026, 8, 1).difference(DateTime.utc(2024, 8, 1)).inDays +
            DateTime.utc(
              2026,
              7,
              1,
            ).difference(DateTime.utc(2025, 7, 1)).inDays) /
        2;
    expect(result.commercialExits, 5);
    expect(result.salesWithKnownAge, 2);
    expect(result.salesWithoutKnownAge, 3);
    expect(result.averageSaleAgeMonths, closeTo(expectedDays / 30.4375, 0.001));
    expect(
      result.dataQualityAlerts.join(' '),
      contains('3 venda(s) datada(s)'),
    );
  });

  test('sem nascimento válido não inventa idade média', () {
    const calculator = BeefHerdIndicatorCalculator();
    final result = calculator.calculate(
      referenceDate: DateTime(2026, 9, 16),
      animals: const [
        AnimalData(
          id: 's',
          tag: 's',
          name: '',
          sex: 'Fêmea',
          breed: '',
          birthDate: '',
          weight: 400,
          status: 'Vendido',
          saleDate: '2026-09-01',
        ),
      ],
    );

    expect(result.averageSaleAgeMonths, isNull);
    expect(result.salesWithKnownAge, 0);
    expect(result.salesWithoutKnownAge, 1);
  });
}
