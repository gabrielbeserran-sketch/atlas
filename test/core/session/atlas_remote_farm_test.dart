import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';

void main() {
  test('converte fazenda remota com indicadores e localização', () {
    final farm = AtlasRemoteFarm.fromMap({
      'id': 'farm_1',
      'tenant_id': 'tenant_1',
      'company_id': 'company_1',
      'name': 'Fazenda Atlas',
      'city': 'Brasília',
      'state': 'DF',
      'animals': 120,
      'area': 250,
      'active': true,
    });

    expect(farm.id, 'farm_1');
    expect(farm.location, 'Brasília - DF');
    expect(farm.animals, 120);
    expect(farm.area, 250);
    expect(farm.active, isTrue);
  });
}
