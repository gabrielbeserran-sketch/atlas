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
          birthDate: '',
          weight: 500,
          status: 'Vendido',
          saleDate: '10/09/2026',
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
  });
}
