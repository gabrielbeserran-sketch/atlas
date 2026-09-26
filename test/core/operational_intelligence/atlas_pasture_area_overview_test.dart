import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_area_overview.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_models.dart';

AtlasPaddock paddock({
  required String id,
  required double area,
  double dryMatter = 1000,
  double support = 1,
}) => AtlasPaddock(
  id: id,
  name: id,
  areaHectares: area,
  forageSpecies: 'Braquiária',
  status: AtlasPaddockStatus.available,
  latitude: 0,
  longitude: 0,
  targetHeightCm: 30,
  currentHeightCm: 30,
  dryMatterKgHa: dryMatter,
  supportCapacityAuHa: support,
  irrigated: false,
  farmName: 'Fazenda teste',
);

void main() {
  test('sem piquetes não inventa área, matéria seca ou capacidade', () {
    final result = AtlasPastureAreaOverview.fromPaddocks(const []);
    expect(result.nominalAreaHa, isNull);
    expect(result.totalDryMatterKg, isNull);
    expect(result.weightedSupportAuHa, isNull);
  });

  test(
    'capacidade é ponderada pela área e não pela quantidade de piquetes',
    () {
      final result = AtlasPastureAreaOverview.fromPaddocks([
        paddock(id: 'a', area: 10, support: 2),
        paddock(id: 'b', area: 30, support: 4),
      ]);
      expect(result.nominalAreaHa, 40);
      expect(result.weightedSupportAuHa, 3.5);
      expect(result.totalDryMatterKg, 40000);
      expect(result.validPaddockCount, 2);
    },
  );

  test('áreas e medidas inválidas não contaminam os indicadores', () {
    final result = AtlasPastureAreaOverview.fromPaddocks([
      paddock(id: 'zero', area: 0),
      paddock(id: 'negativa', area: -2),
      paddock(id: 'infinita', area: double.infinity),
      paddock(id: 'válida', area: 5, dryMatter: -1, support: double.nan),
    ]);
    expect(result.nominalAreaHa, 5);
    expect(result.totalDryMatterKg, isNull);
    expect(result.weightedSupportAuHa, isNull);
    expect(result.invalidPaddockCount, 3);
  });

  test('IDs repetidos e vazios não duplicam área ou medidas', () {
    final result = AtlasPastureAreaOverview.fromPaddocks([
      paddock(id: 'a', area: 10),
      paddock(id: 'a', area: 20),
      paddock(id: '', area: 30),
      paddock(id: 'b', area: 5),
    ]);
    expect(result.nominalAreaHa, 5);
    expect(result.totalDryMatterKg, 5000);
    expect(result.hasUncalculableValues, isFalse);
    expect(result.validPaddockCount, 1);
    expect(result.ambiguousPaddockCount, 3);
  });

  test('overflow de área e medidas não produz infinito ou NaN', () {
    final result = AtlasPastureAreaOverview.fromPaddocks([
      paddock(id: 'a', area: 1e308, dryMatter: 100, support: 100),
      paddock(id: 'b', area: 1e308, dryMatter: 100, support: 100),
    ]);
    expect(result.nominalAreaHa, isNull);
    expect(result.totalDryMatterKg, isNull);
    expect(result.weightedSupportAuHa, isNull);
    expect(result.hasUncalculableValues, isTrue);
  });

  test('base parcial usa apenas a área com medida e informa cobertura', () {
    final result = AtlasPastureAreaOverview.fromPaddocks([
      paddock(id: 'a', area: 10, dryMatter: 1000, support: 2),
      paddock(id: 'b', area: 30, dryMatter: -1, support: double.nan),
    ]);
    expect(result.nominalAreaHa, 40);
    expect(result.totalDryMatterKg, 10000);
    expect(result.weightedSupportAuHa, 2);
    expect(result.dryMatterPaddockCount, 1);
    expect(result.supportPaddockCount, 1);
    expect(result.hasPartialDryMatter, isTrue);
    expect(result.hasPartialSupport, isTrue);
  });

  test('zero medido é válido e não significa ausência de medida', () {
    final result = AtlasPastureAreaOverview.fromPaddocks([
      paddock(id: 'a', area: 10, dryMatter: 0, support: 0),
    ]);
    expect(result.totalDryMatterKg, 0);
    expect(result.weightedSupportAuHa, 0);
    expect(result.dryMatterPaddockCount, 1);
    expect(result.supportPaddockCount, 1);
    expect(result.hasPartialDryMatter, isFalse);
    expect(result.hasPartialSupport, isFalse);
  });

  test('produto fora do intervalo não afeta a soma nominal válida', () {
    final result = AtlasPastureAreaOverview.fromPaddocks([
      paddock(id: 'a', area: 2, dryMatter: 1e308, support: 1e308),
    ]);
    expect(result.nominalAreaHa, 2);
    expect(result.totalDryMatterKg, isNull);
    expect(result.weightedSupportAuHa, isNull);
  });
}
