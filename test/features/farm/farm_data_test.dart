import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';

void main() {
  test('FarmData usa os valores retornados pela API como autoridade', () {
    final farm = FarmData.fromMap({
      'id': 'farm_1',
      'name': 'Fazenda Santa Helena',
      'city': 'Sobradinho',
      'state': 'GO',
      'animals': 87,
      'area': 312,
    });

    expect(farm.id, 'farm_1');
    expect(farm.animals, 87);
    expect(farm.area, 312);
  });
}
