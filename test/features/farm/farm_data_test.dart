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
    expect(farm.productionProfile, 'mixed');
    expect(farm.hasBeefProduction, isTrue);
    expect(farm.hasDairyProduction, isTrue);
  });

  test('FarmData preserva perfil e sistema produtivo retornados pela API', () {
    final farm = FarmData.fromMap({
      'id': 'farm_dairy',
      'name': 'Leite Atlas',
      'city': 'Sobradinho',
      'state': 'GO',
      'animals': 45,
      'area': 50,
      'production_profile': 'dairy',
      'production_system': 'Semi-intensivo',
    });

    expect(farm.productionProfileLabel, 'Leite');
    expect(farm.hasBeefProduction, isFalse);
    expect(farm.hasDairyProduction, isTrue);
    expect(farm.toMap()['production_system'], 'Semi-intensivo');
  });

  test('FarmData trata perfil remoto desconhecido como misto seguro', () {
    final farm = FarmData.fromMap({
      'name': 'Cadastro legado',
      'production_profile': 'legacy',
    });

    expect(farm.productionProfile, 'mixed');
  });
}
