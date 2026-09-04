import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_intelligence_center/domain/models/atlas_intelligence_capability.dart';

void main() {
  test('taxonomia de inteligencia possui cinco familias canonicas', () {
    final definitions = AtlasIntelligenceCapabilityRegistry.canonical;

    expect(definitions, hasLength(5));
    expect(
      definitions.map((item) => item.family).toSet(),
      AtlasIntelligenceCapabilityFamily.values.toSet(),
    );
    expect(
      definitions.map((item) => item.title).toSet(),
      hasLength(definitions.length),
    );
  });

  test('nomes historicos ficam como implementacoes e nao familias', () {
    final legacy = AtlasIntelligenceCapabilityRegistry.canonical
        .expand((item) => item.legacyImplementations)
        .toSet();

    expect(legacy, contains('Atlas IA'));
    expect(legacy, contains('Diagnóstico Inteligente'));
    expect(legacy, contains('Inteligência Preditiva'));
    expect(legacy, contains('Inteligência da Fazenda'));
  });
}
