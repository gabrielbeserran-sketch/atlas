import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final herd = File(
    'lib/features/herd/presentation/screens/herd_overview_screen.dart',
  ).readAsStringSync();
  final reproduction = File(
    'lib/features/animal_reproduction/presentation/screens/'
    'reproduction_overview_screen.dart',
  ).readAsStringSync();
  final health = File(
    'lib/features/animal_health/presentation/screens/'
    'health_overview_screen.dart',
  ).readAsStringSync();

  test('Rebanho virou central de decisão e trabalho', () {
    expect(herd.contains('AtlasModuleDecisionPanel('), isTrue);
    expect(herd.contains("moduleLabel: 'Rebanho'"), isTrue);
    expect(herd.contains('animalsWithoutWeight'), isTrue);
  });

  test('Reprodução mantém indicadores, decisão e ações no mesmo módulo', () {
    expect(reproduction.contains('AtlasModuleDecisionPanel('), isTrue);
    expect(reproduction.contains("moduleLabel: 'Reprodução'"), isTrue);
    expect(reproduction.contains('AtlasOperationalActionBar('), isTrue);
  });

  test('Sanidade mantém indicadores, decisão e ações no mesmo módulo', () {
    expect(health.contains('AtlasModuleDecisionPanel('), isTrue);
    expect(health.contains("moduleLabel: 'Sanidade'"), isTrue);
    expect(health.contains('AtlasOperationalActionBar('), isTrue);
  });
}
