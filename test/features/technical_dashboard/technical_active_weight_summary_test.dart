import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_farm_summary.dart';

void main() {
  AnimalData animal(String id, String status, double weight) => AnimalData(
    id: id,
    tag: id,
    name: id,
    sex: 'Fêmea',
    breed: 'Nelore',
    birthDate: '2024-01-01',
    weight: weight,
    status: status,
  );

  TechnicalFarmSummary summary(List<AnimalData> animals, {double? area = 10}) {
    return TechnicalFarmSummary.fromData(
      groups: const [],
      animals: animals,
      healthRecords: const [],
      reproductionRecords: const [],
      nutritionPlans: const [],
      finances: const [],
      inventory: const [],
      farmArea: area,
      referenceDate: DateTime(2026, 9, 23),
    );
  }

  test('ignora vendidos e mortos e não calcula kg/ha com peso faltante', () {
    final result = summary([
      animal('A', 'Ativo', 400),
      animal('B', 'Ativo', 0),
      animal('C', 'Vendido', 900),
      animal('D', 'Morto', 700),
    ]);

    expect(result.activeAnimals, 2);
    expect(result.activeAnimalsWithValidWeight, 1);
    expect(result.activeAnimalsWithoutValidWeight, 1);
    expect(result.averageWeight, 400);
    expect(result.stockingRate, 0.2);
    expect(result.areaHectares, 10);
    expect(result.liveWeightPerHectare, isNull);
  });

  test('calcula média e peso vivo por área somente com cobertura completa', () {
    final result = summary([
      animal('A', 'Ativo', 400),
      animal('B', 'Ativo', 500),
      animal('C', 'Vendido', 900),
    ]);

    expect(result.activeAnimalsWithValidWeight, 2);
    expect(result.activeAnimalsWithoutValidWeight, 0);
    expect(result.averageWeight, 450);
    expect(result.liveWeightPerHectare, 90);
  });

  test('rejeita pesos não finitos ou negativos e área não finita', () {
    final invalidWeights = summary([
      animal('A', 'Ativo', double.nan),
      animal('B', 'Ativo', double.infinity),
      animal('C', 'Ativo', -5),
    ]);
    expect(invalidWeights.activeAnimalsWithoutValidWeight, 3);
    expect(invalidWeights.averageWeight, 0);
    expect(invalidWeights.liveWeightPerHectare, isNull);

    final invalidArea = summary([
      animal('A', 'Ativo', 400),
    ], area: double.infinity);
    expect(invalidArea.stockingRate, isNull);
    expect(invalidArea.areaHectares, isNull);
    expect(invalidArea.liveWeightPerHectare, isNull);
  });

  test('área ausente ou zero não produz indicadores por hectare', () {
    final animals = [animal('A', 'Ativo', 400)];
    for (final area in <double?>[null, 0, -10]) {
      final result = summary(animals, area: area);
      expect(result.areaHectares, isNull);
      expect(result.stockingRate, isNull);
      expect(result.liveWeightPerHectare, isNull);
    }
  });

  test('não mostra peso vivo por área quando não há animais ativos', () {
    final result = summary([animal('C', 'Vendido', 900)]);
    expect(result.activeAnimals, 0);
    expect(result.activeAnimalsWithValidWeight, 0);
    expect(result.liveWeightPerHectare, isNull);
  });
}
