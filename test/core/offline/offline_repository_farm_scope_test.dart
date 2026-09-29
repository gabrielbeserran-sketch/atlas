import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/offline/services/offline_repository.dart';

void main() {
  test('leitura geral conserva a fazenda indicada pelo servidor', () {
    expect(
      OfflineRepository.farmIdForChange(<String, dynamic>{
        'farm_id': 'farm-B',
      }, null),
      'farm-B',
    );
  });

  test('registro geral explícito não vira registro da fazenda filtrada', () {
    expect(
      OfflineRepository.farmIdForChange(<String, dynamic>{
        'farm_id': null,
      }, 'farm-A'),
      isNull,
    );
  });

  test('servidor antigo sem farm_id mantém filtro solicitado', () {
    expect(
      OfflineRepository.farmIdForChange(<String, dynamic>{}, 'farm-A'),
      'farm-A',
    );
  });
}
