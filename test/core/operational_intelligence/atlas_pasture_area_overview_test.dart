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
}
