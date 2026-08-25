import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';

void main() {
  test('10C repara mojibake legado sem alterar texto correto', () {
    expect(AtlasTextNormalizer.repair('VacinaÃ§Ã£o'), 'Vacinação');
    expect(AtlasTextNormalizer.repair('NutriÃ§Ã£o'), 'Nutrição');
    expect(AtlasTextNormalizer.repair('HomologaÃ§Ã£o'), 'Homologação');
    expect(AtlasTextNormalizer.repair('ManutenÃ§Ã£o'), 'Manutenção');
    expect(AtlasTextNormalizer.repair('Reprodução'), 'Reprodução');
  });

  test('10C normaliza estruturas JSON legadas', () {
    final value = AtlasTextNormalizer.normalize(<String, dynamic>{
      'categoria': 'health',
      'descricao': 'VacinaÃ§Ã£o programada',
      'itens': <String>['NutriÃ§Ã£o', 'ManutenÃ§Ã£o'],
    }) as Map<dynamic, dynamic>;

    expect(value['descricao'], 'Vacinação programada');
    expect(value['itens'], <String>['Nutrição', 'Manutenção']);
  });

  test('10C apresenta categorias técnicas no vocabulário pecuário', () {
    expect(AtlasUiText.category('health'), 'Sanidade');
    expect(AtlasUiText.category('nutrition'), 'Nutrição');
    expect(AtlasUiText.category('maintenance'), 'Manutenção');
    expect(AtlasUiText.category('inventory'), 'Estoque');
    expect(AtlasUiText.category('reproduction'), 'Reprodução');
    expect(AtlasUiText.category('livestock'), 'Rebanho');
  });

  test('10C Central do Animal expõe cobertura de rastreabilidade', () {
    final source = File(
      'lib/features/animal/presentation/screens/animal_detail_screen.dart',
    ).readAsStringSync();

    expect(source, contains('int get traceabilityCoverage'));
    expect(source, contains("title: 'Rastreabilidade'"));
    expect(source, contains('enterpriseTimelineCount > 0'));
  });
}
