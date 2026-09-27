import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/beef_production/domain/services/beef_herd_indicator_calculator.dart';

AnimalData sale(
  String id,
  double value,
  double weight, {
  String date = '26/09/2026',
}) => AnimalData(
  id: id,
  tag: id,
  name: '',
  sex: 'Macho',
  breed: '',
  birthDate: '01/01/2024',
  weight: weight,
  status: 'Vendido',
  saleDate: date,
  saleValue: value,
);
BeefHerdIndicators calculate(List<AnimalData> animals) =>
    const BeefHerdIndicatorCalculator().calculate(
      animals: animals,
      referenceDate: DateTime(2026, 9, 26),
    );

void main() {
  test(
    'valores inválidos não contaminam receita e média das vendas válidas',
    () {
      final result = calculate([
        sale('valid', 5000, 500),
        sale('nan', double.nan, 500),
        sale('infinite', double.infinity, 500),
        sale('negative', -1000, 500),
        sale('zero', 0, 500),
      ]);
      expect(result.commercialExits, 5);
      expect(result.commercialExitsWithValue, 1);
      expect(result.salesWithoutValue, 4);
      expect(result.commercialRevenue, 5000);
      expect(result.averageSaleValue, 5000);
      expect(result.averageSalePricePerKg, 10);
      expect(result.commercialRevenueIsPartial, isTrue);
      expect(
        result.dataQualityAlerts.join(' '),
        contains('valor de venda válido'),
      );
    },
  );

  test('pesos inválidos não entram no preço por quilo nem no denominador', () {
    final result = calculate([
      sale('valid', 5000, 500),
      sale('nan', 9000, double.nan),
      sale('infinite', 9000, double.infinity),
      sale('negative', 9000, -1),
      sale('zero', 9000, 0),
    ]);
    expect(result.salesWithoutWeight, 4);
    expect(result.salesWithWeightAndValue, 1);
    expect(result.commercialRevenue, 41000);
    expect(result.averageSalePricePerKg, 10);
  });

  test('vendas sem valor válido não viram receita zero confirmada', () {
    final result = calculate([sale('a', 0, 500), sale('b', double.nan, 500)]);
    expect(result.commercialExits, 2);
    expect(result.commercialRevenue, isNull);
    expect(result.averageSaleValue, isNull);
    expect(result.averageSalePricePerKg, isNull);
  });

  test(r'soma não representável não impede média e R$/kg representáveis', () {
    final result = calculate([
      sale('a', 1e308, 1e308),
      sale('b', 1e308, 1e308),
    ]);
    expect(result.commercialRevenue, isNull);
    expect(result.averageSaleValue, closeTo(1e308, 1e294));
    expect(result.averageSalePricePerKg, closeTo(1, 1e-10));
    expect(result.hasUncalculableCommercialValues, isTrue);
    expect(
      result.dataQualityAlerts.join(' '),
      contains('intervalo calculável'),
    );
  });

  test('receita não duplica animais com identificação repetida ou vazia', () {
    final result = calculate([
      sale('a', 5000, 500),
      sale('a', 5000, 500),
      sale('', 5000, 500),
      sale('b', 2000, 200),
    ]);
    expect(result.commercialExits, 1);
    expect(result.commercialRevenue, 2000);
    expect(result.ambiguousAnimalRecords, 3);
    expect(
      result.dataQualityAlerts.join(' '),
      contains('identificação ausente/repetida'),
    );
  });

  test('preço por quilo é ponderado e considera somente vendas da janela', () {
    final result = calculate([
      sale('a', 1000, 100),
      sale('b', 9000, 300),
      sale('future', 999999, 1, date: '27/09/2026'),
      sale('old', 999999, 1, date: '25/09/2025'),
    ]);
    expect(result.commercialExits, 2);
    expect(result.commercialRevenue, 10000);
    expect(result.averageSalePricePerKg, 25);
  });

  test('sem vendas não confunde ausência de saída com venda sem valor', () {
    final result = calculate([]);
    expect(result.commercialExits, 0);
    expect(result.commercialRevenue, 0);
    expect(result.averageSaleValue, isNull);
    expect(result.commercialRevenueIsPartial, isFalse);
    expect(result.hasUncalculableCommercialValues, isFalse);
  });

  test('razão não representável não aparece como preço zero ou infinito', () {
    final tiny = calculate([sale('a', 5e-324, 1e308)]);
    final huge = calculate([sale('a', 1e308, 5e-324)]);
    for (final result in [tiny, huge]) {
      expect(result.averageSalePricePerKg, isNull);
      expect(result.hasUncalculableCommercialValues, isTrue);
    }
  });
}
