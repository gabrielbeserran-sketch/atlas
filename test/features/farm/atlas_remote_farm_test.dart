import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';

void main() {
  test('preserva o perfil produtivo no contexto remoto da fazenda', () {
    final farm = AtlasRemoteFarm.fromMap({
      'id': 'farm_dairy',
      'name': 'Leite Atlas',
      'production_profile': 'dairy',
      'production_system': 'Semi-intensivo',
    });

    expect(farm.productionProfile, 'dairy');
    expect(farm.productionSystem, 'Semi-intensivo');
    expect(farm.hasDairyProduction, isTrue);
    expect(farm.hasBeefProduction, isFalse);
  });

  test('mantém fazendas de sessões anteriores como mistas', () {
    final farm = AtlasRemoteFarm.fromMap({'id': 'legacy', 'name': 'Legado'});

    expect(farm.productionProfile, 'mixed');
    expect(farm.hasDairyProduction, isTrue);
    expect(farm.hasBeefProduction, isTrue);
  });
}
