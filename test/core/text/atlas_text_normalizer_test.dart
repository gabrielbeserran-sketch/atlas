import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/core/text/atlas_ui_text.dart';

void main() {
  group('AtlasTextNormalizer', () {
    test('repara mojibake de textos portugueses', () {
      expect(
        AtlasTextNormalizer.repair('Plano HomologaÃ§Ã£o V18 Matrizes'),
        'Plano Homologação V18 Matrizes',
      );
      expect(AtlasTextNormalizer.repair('NutriÃ§Ã£o'), 'Nutrição');
      expect(AtlasTextNormalizer.repair('ManutenÃ§Ã£o'), 'Manutenção');
    });

    test('não altera texto UTF-8 já correto', () {
      expect(AtlasTextNormalizer.repair('Nutrição'), 'Nutrição');
      expect(AtlasTextNormalizer.repair('São Paulo'), 'São Paulo');
    });

    test('normaliza objetos JSON aninhados', () {
      final normalized =
          AtlasTextNormalizer.normalize({
                'name': 'Concentrado HomologaÃ§Ã£o V18',
                'items': ['NutriÃ§Ã£o', 'Sanidade'],
              })
              as Map;

      expect(normalized['name'], 'Concentrado Homologação V18');
      expect(normalized['items'], ['Nutrição', 'Sanidade']);
    });
  });

  group('AtlasUiText', () {
    test('traduz status técnicos sem alterar o código de backend', () {
      expect(AtlasUiText.status('registered'), 'Registrado');
      expect(AtlasUiText.status('active'), 'Ativo');
      expect(AtlasUiText.status('pending'), 'Pendente');
    });

    test('padroniza categorias operacionais', () {
      expect(AtlasUiText.category('health'), 'Sanidade');
      expect(AtlasUiText.category('nutrition'), 'Nutrição');
      expect(AtlasUiText.category('maintenance'), 'Manutenção');
    });
  });
}
