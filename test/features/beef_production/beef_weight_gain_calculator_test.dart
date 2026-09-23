import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/beef_production/domain/services/beef_weight_gain_calculator.dart';

void main() {
  const calculator = BeefWeightGainCalculator();

  test(
    'calcula média de ganhos individuais sem comparar animais diferentes',
    () {
      final result = calculator.calculate(
        measurements: [
          BeefWeightMeasurement(
            animalId: 'a',
            date: DateTime(2026, 1, 1),
            weightKg: 300,
          ),
          BeefWeightMeasurement(
            animalId: 'a',
            date: DateTime(2026, 1, 11),
            weightKg: 310,
          ),
          BeefWeightMeasurement(
            animalId: 'b',
            date: DateTime(2026, 1, 1),
            weightKg: 500,
          ),
          BeefWeightMeasurement(
            animalId: 'b',
            date: DateTime(2026, 1, 11),
            weightKg: 520,
          ),
          BeefWeightMeasurement(
            animalId: 'c',
            date: DateTime(2026, 1, 11),
            weightKg: 900,
          ),
        ],
        activeAnimalIds: {'a', 'b', 'c'},
        referenceDate: DateTime(2026, 1, 12),
      );
      expect(result.animalCount, 2);
      expect(result.averageKgPerDay, 1.5);
    },
  );

  test('ignora datas iguais, futuro, pesos inválidos e animais inativos', () {
    final result = calculator.calculate(
      measurements: [
        BeefWeightMeasurement(
          animalId: 'a',
          date: DateTime(2026, 1, 1),
          weightKg: 300,
        ),
        BeefWeightMeasurement(
          animalId: 'a',
          date: DateTime(2026, 1, 1),
          weightKg: 310,
        ),
        BeefWeightMeasurement(
          animalId: 'b',
          date: DateTime(2026, 1, 1),
          weightKg: 300,
        ),
        BeefWeightMeasurement(
          animalId: 'b',
          date: DateTime(2026, 1, 15),
          weightKg: 320,
        ),
        BeefWeightMeasurement(
          animalId: 'c',
          date: DateTime(2026, 1, 1),
          weightKg: 300,
        ),
        BeefWeightMeasurement(
          animalId: 'c',
          date: DateTime(2026, 1, 5),
          weightKg: 0,
        ),
        BeefWeightMeasurement(
          animalId: 'd',
          date: DateTime(2026, 1, 1),
          weightKg: 300,
        ),
        BeefWeightMeasurement(
          animalId: 'd',
          date: DateTime(2026, 1, 5),
          weightKg: 320,
        ),
      ],
      activeAnimalIds: {'a', 'b', 'c'},
      referenceDate: DateTime(2026, 1, 10),
    );
    expect(result.animalCount, 0);
    expect(result.averageKgPerDay, isNull);
  });
}
