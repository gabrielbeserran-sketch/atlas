import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final shell = File(
    'lib/core/navigation/atlas_home_shell.dart',
  ).readAsStringSync();
  final screen = File(
    'lib/features/farm_handling/presentation/screens/'
    'farm_handling_screen.dart',
  ).readAsStringSync();
  final service = File(
    'lib/features/farm_handling/data/services/'
    'farm_handling_enterprise_service.dart',
  ).readAsStringSync();

  test('menu principal expõe manejo sem ferramentas de desenvolvimento', () {
    final start = shell.indexOf(
      'static final List<AtlasRouteDefinition> routes = [',
    );
    final end = shell.indexOf('\n  ];', start);
    final routes = shell.substring(start, end);

    expect(routes.contains("label: 'Realizar manejo'"), isTrue);
    expect(routes.contains("label: 'Offline'"), isTrue);

    for (final hidden in [
      "label: 'Precision Hub'",
      "label: 'Enterprise'",
      "label: 'SaaS'",
      "label: 'Dados'",
      "label: 'Segurança'",
      "label: 'Qualidade'",
      "label: 'Prontidão'",
      "label: 'Releases'",
      "label: 'Comercial'",
      "label: 'Piloto'",
      "label: 'Publicação'",
      "label: 'Escala'",
    ]) {
      expect(routes.contains(hidden), isFalse, reason: hidden);
    }
  });

  test('seleção coletiva possui três caminhos reais', () {
    expect(screen.contains('_SelectionMode.wholeLot'), isTrue);
    expect(screen.contains('_SelectionMode.earringRange'), isTrue);
    expect(screen.contains('_SelectionMode.manualSelection'), isTrue);
    expect(screen.contains('_SelectionMode.rfid'), isFalse);
  });

  test('manejo exige revisão e confirmação', () {
    expect(screen.contains("'Revisar e realizar manejo'"), isTrue);
    expect(screen.contains("'Confirmar manejo'"), isTrue);
    expect(screen.contains('selectedAnimalIds.isEmpty'), isTrue);
  });

  test('seis tipos de manejo usam o mesmo motor transacional', () {
    for (final action in [
      '_HandlingAction.saleOrExit',
      '_HandlingAction.lotMovement',
      '_HandlingAction.weighing',
      '_HandlingAction.health',
      '_HandlingAction.reproduction',
      '_HandlingAction.categoryChange',
    ]) {
      expect(screen.contains(action), isTrue, reason: action);
    }
    expect(service.contains("'/livestock/handling/batch'"), isTrue);
  });
  test('formulários do manejo usam API Flutter atual', () {
    expect(
      RegExp(
        r'DropdownButtonFormField<[^>]+>\(\s*\n\s*value:',
        multiLine: true,
      ).hasMatch(screen),
      isFalse,
    );
    expect(
      RegExp(
        r'DropdownButtonFormField<[^>]+>\(\s*\n\s*initialValue:',
        multiLine: true,
      ).allMatches(screen).length,
      4,
    );
    expect(
      RegExp(r'\bString\s+get\s+_selectionLabel\b').hasMatch(screen),
      isFalse,
    );
  });

}
