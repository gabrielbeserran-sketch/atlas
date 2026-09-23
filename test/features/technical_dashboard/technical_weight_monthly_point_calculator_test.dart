import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/beef_production/domain/services/beef_weight_gain_calculator.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/services/technical_weight_monthly_point_calculator.dart';

void main() {
  const calculator = TechnicalWeightMonthlyPointCalculator();
  final month = DateTime(2026, 9);
  final today = DateTime(2026, 9, 23);

  BeefWeightMeasurement weight(String id, int day, double kg, {int month = 9}) {
    return BeefWeightMeasurement(
      animalId: id,
      date: DateTime(2026, month, day),
      weightKg: kg,
    );
  }

  test('média mensal usa última pesagem de cada animal, não cada registro', () {
    final point = calculator.calculate(
      periodStart: month,
      label: 'set/26',
      measurements: [
        weight('a', 2, 300),
        weight('a', 12, 320),
        weight('b', 4, 500),
      ],
      referenceDate: today,
    );

    expect(point, isNotNull);
    expect(point!.averageWeight, 410);
    expect(point.measurementCount, 3);
    expect(point.animalCount, 2);
    expect(point.latestMeasurementDate, DateTime.utc(2026, 9, 12));
  });

  test('exclui pesos inválidos, datas futuras e outro mês', () {
    final point = calculator.calculate(
      periodStart: month,
      label: 'set/26',
      measurements: [
        weight('a', 3, 420),
        weight('a', 24, 500),
        weight('b', 5, 0),
        weight('c', 5, -10),
        weight('d', 5, double.infinity),
        weight('e', 30, 300, month: 8),
        weight('', 6, 600),
      ],
      referenceDate: today,
    );

    expect(point, isNotNull);
    expect(point!.averageWeight, 420);
    expect(point.measurementCount, 1);
    expect(point.animalCount, 1);
    expect(point.latestMeasurementDate, DateTime.utc(2026, 9, 3));
  });

  test('sem medições válidas não inventa ponto mensal', () {
    final point = calculator.calculate(
      periodStart: month,
      label: 'set/26',
      measurements: [weight('a', 24, 420), weight('b', 1, 0)],
      referenceDate: today,
    );

    expect(point, isNull);
  });
}
