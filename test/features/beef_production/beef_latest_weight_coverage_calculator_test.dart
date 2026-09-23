import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/beef_production/domain/services/beef_latest_weight_coverage_calculator.dart';
import 'package:projeto_atlas/features/beef_production/domain/services/beef_weight_gain_calculator.dart';

void main() {
  const calculator = BeefLatestWeightCoverageCalculator();
  final today = DateTime(2026, 9, 23);

  BeefWeightMeasurement weight(String id, int day, double kg, {int month = 9}) {
    return BeefWeightMeasurement(
      animalId: id,
      date: DateTime(2026, month, day),
      weightKg: kg,
    );
  }

  test('animal vendido mais recente não desloca a amostra dos ativos', () {
    final result = calculator.calculate(
      measurements: [
        weight('ativo-a', 5, 410),
        weight('ativo-b', 7, 420),
        weight('vendido', 22, 500),
      ],
      activeAnimalIds: {'ativo-a', 'ativo-b', 'ativo-c'},
      referenceDate: today,
    );

    expect(result.latestMeasurementDate, DateTime(2026, 9, 7));
    expect(result.weighedAnimalCount, 2);
    expect(result.activeAnimalCount, 3);
    expect(result.percent, closeTo(66.67, 0.01));
  });

  test(
    'duplicidades não inflam cobertura; datas futuras e pesos inválidos saem',
    () {
      final result = calculator.calculate(
        measurements: [
          weight('a', 3, 390),
          weight('a', 10, 400),
          weight('b', 24, 420),
          weight('b', 18, 0),
          weight('c', 20, double.nan),
        ],
        activeAnimalIds: {'a', 'b', 'c'},
        referenceDate: today,
      );

      expect(result.latestMeasurementDate, DateTime(2026, 9, 10));
      expect(result.weighedAnimalCount, 1);
      expect(result.percent, closeTo(33.33, 0.01));
    },
  );

  test('não perde cobertura na virada do mês dentro dos 90 dias', () {
    final result = calculator.calculate(
      measurements: [weight('a', 30, 400, month: 8), weight('b', 1, 430)],
      activeAnimalIds: {'a', 'b'},
      referenceDate: today,
    );

    expect(result.latestMeasurementDate, DateTime(2026, 9, 1));
    expect(result.weighedAnimalCount, 2);
    expect(result.percent, 100);
  });

  test('inclui o 90º dia e exclui o 91º sem apagar a última data', () {
    final reference = DateTime(2026, 9, 23);
    final onBoundary = reference.subtract(const Duration(days: 90));
    final beforeBoundary = reference.subtract(const Duration(days: 91));
    final result = calculator.calculate(
      measurements: [
        BeefWeightMeasurement(animalId: 'a', date: onBoundary, weightKg: 410),
        BeefWeightMeasurement(
          animalId: 'b',
          date: beforeBoundary,
          weightKg: 420,
        ),
      ],
      activeAnimalIds: {'a', 'b'},
      referenceDate: reference,
    );

    expect(result.weighedAnimalCount, 1);
    expect(result.percent, 50);
    expect(result.latestMeasurementDate, onBoundary);
  });

  test('pesagem antiga preserva data mas não conta como cobertura atual', () {
    final result = calculator.calculate(
      measurements: [weight('ativo', 1, 400, month: 1)],
      activeAnimalIds: {'ativo'},
      referenceDate: today,
    );

    expect(result.latestMeasurementDate, DateTime(2026, 1, 1));
    expect(result.weighedAnimalCount, 0);
    expect(result.percent, 0);
  });

  test('distingue sem pesagens de ausência de animais ativos', () {
    final missingWeights = calculator.calculate(
      measurements: [weight('vendido', 20, 500)],
      activeAnimalIds: {'ativo'},
      referenceDate: today,
    );
    expect(missingWeights.latestMeasurementDate, isNull);
    expect(missingWeights.weighedAnimalCount, 0);
    expect(missingWeights.percent, 0);

    final noActiveAnimals = calculator.calculate(
      measurements: [weight('vendido', 20, 500)],
      activeAnimalIds: {},
      referenceDate: today,
    );
    expect(noActiveAnimals.percent, isNull);
  });
}
