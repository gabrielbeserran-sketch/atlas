import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final panel = File(
    'lib/core/widgets/atlas_module_decision_panel.dart',
  ).readAsStringSync();
  final health = File(
    'lib/features/animal_health/presentation/screens/'
    'health_overview_screen.dart',
  ).readAsStringSync();
  final reproduction = File(
    'lib/features/animal_reproduction/presentation/screens/'
    'reproduction_overview_screen.dart',
  ).readAsStringSync();
  final nutrition = File(
    'lib/features/nutrition/presentation/screens/'
    'nutrition_overview_screen.dart',
  ).readAsStringSync();

  test('centrais usam padrão ver entender decidir agir', () {
    expect(panel.contains("'Situação do módulo'"), isTrue);
    expect(panel.contains("'O que precisa de atenção'"), isTrue);
    for (final source in [health, reproduction, nutrition]) {
      expect(source.contains('AtlasModuleDecisionPanel('), isTrue);
      expect(source.contains('AtlasOperationalActionBar('), isTrue);
    }
  });

  test('sanidade expõe situação e manejo coletivo', () {
    expect(health.contains('quarantineAnimals'), isTrue);
    expect(health.contains('activeWithdrawalAnimals'), isTrue);
    expect(health.contains('scheduledReturns'), isTrue);
    expect(health.contains("'Manejo coletivo'"), isTrue);
  });

  test('reprodução expõe indicadores decisórios', () {
    expect(reproduction.contains('pregnancyRate'), isTrue);
    expect(reproduction.contains('conceptionRate'), isTrue);
    expect(reproduction.contains('inseminations'), isTrue);
    expect(reproduction.contains("'Manejo coletivo'"), isTrue);
  });

  test('nutrição cruza desempenho e estoque', () {
    expect(nutrition.contains('belowTargetPlans'), isTrue);
    expect(nutrition.contains('pendingInventoryIntegrations'), isTrue);
    expect(nutrition.contains('plansWithoutObservedPerformance'), isTrue);
  });
}
