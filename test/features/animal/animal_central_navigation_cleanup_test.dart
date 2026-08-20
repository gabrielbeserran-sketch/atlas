import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/animal/presentation/screens/animal_detail_screen.dart',
  ).readAsStringSync();

  test('Central mostra somente duas linhas de acesso rápido', () {
    final navigationStart = source.indexOf(
      'class AnimalHubNavigation extends StatelessWidget',
    );
    final navigationEnd = source.indexOf(
      'class NavigationModuleRow',
      navigationStart,
    );
    final navigation = source.substring(navigationStart, navigationEnd);

    expect(
      RegExp(r'NavigationModuleRow\(').allMatches(navigation).length,
      2,
    );
  });

  test('Recursos avançados ficam em catálogo pesquisável', () {
    expect(source.contains("'Mais recursos'"), isTrue);
    expect(source.contains("'Buscar recurso'"), isTrue);
    expect(source.contains('_advancedItems'), isTrue);
  });

  test('Painel não exibe versão Enterprise como dado do animal', () {
    final panelStart = source.indexOf('class AnimalInformationPanel');
    final panelEnd = source.indexOf('class EmptyHubState', panelStart);
    final panel = source.substring(panelStart, panelEnd);

    expect(panel.contains("'Versão Enterprise'"), isFalse);
    expect(panel.contains("'Mais informações'"), isTrue);
  });
}
