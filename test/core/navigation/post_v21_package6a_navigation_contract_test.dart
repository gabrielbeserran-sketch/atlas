import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final routeDefinition = File(
    'lib/core/navigation/atlas_route_definition.dart',
  ).readAsStringSync();
  final shell = File(
    'lib/core/navigation/atlas_home_shell.dart',
  ).readAsStringSync();
  final animal = File(
    'lib/features/animal/presentation/screens/animal_detail_screen.dart',
  ).readAsStringSync();

  test('menu principal é organizado pelo trabalho do usuário', () {
    expect(routeDefinition.contains("=> 'Hoje'"), isTrue);
    expect(routeDefinition.contains("=> 'Animais'"), isTrue);
    expect(routeDefinition.contains("=> 'Fazenda'"), isTrue);
    expect(routeDefinition.contains("=> 'Gestão'"), isTrue);
    expect(routeDefinition.contains("=> 'Apoio'"), isTrue);
    expect(shell.contains("'Mais recursos'"), isFalse);
  });

  test('nomes do menu são simples sem mudar identidade das rotas', () {
    expect(shell.contains("label: 'Dashboard'"), isTrue);
    expect(shell.contains("menuLabel: 'Início'"), isTrue);
    expect(shell.contains("label: 'Inteligência'"), isTrue);
    expect(shell.contains("menuLabel: 'Análises'"), isTrue);
    expect(shell.contains("label: 'Offline'"), isTrue);
    expect(shell.contains("menuLabel: 'Sem internet'"), isTrue);
  });

  test('vocabulário de produção não aparece no shell do produtor', () {
    for (final forbidden in [
      'V1 operacional',
      'Avançado em validação',
      'Pacote ',
      'Marco ',
    ]) {
      expect(shell.contains(forbidden), isFalse);
    }
    expect(shell.contains('_AtlasMaturityNotice'), isFalse);
  });

  test('Central do Animal mostra somente áreas individuais', () {
    final start = animal.indexOf(
      'class AnimalHubNavigation extends StatelessWidget',
    );
    final end = animal.indexOf('class NavigationModuleRow', start);
    final navigation = animal.substring(start, end);

    for (final required in [
      'Resumo',
      'Histórico',
      'Desempenho',
      'Sanidade',
      'Reprodução',
      'Genealogia',
      'Arquivos',
    ]) {
      expect(navigation.contains("'$required'"), isTrue);
    }

    for (final forbidden in [
      'Agenda',
      'Pendências',
      'Nutrição',
      'Financeiro',
      'Estoque',
      'Fazenda',
      'Empresa',
      'Mais recursos',
    ]) {
      expect(navigation.contains("'$forbidden'"), isFalse);
    }
  });

  test('Sanidade e Reprodução permanecem na própria Central do Animal', () {
    final start = animal.indexOf(
      'Future<void> selectSection(AnimalHubSection section)',
    );
    final end = animal.indexOf('  @override\n  Widget build', start);
    final selection = animal.substring(start, end);

    expect(
      selection.contains(
        'AnimalHubSection.healthEnterprise => AnimalHealthEnterpriseScreen',
      ),
      isFalse,
    );
    expect(
      selection.contains(
        'AnimalHubSection.reproductionEnterprise => '
        'AnimalReproductionEnterpriseScreen',
      ),
      isFalse,
    );
    expect(animal.contains('Widget buildHealthSection()'), isTrue);
    expect(animal.contains('Widget buildReproductionSection()'), isTrue);
  });
}
