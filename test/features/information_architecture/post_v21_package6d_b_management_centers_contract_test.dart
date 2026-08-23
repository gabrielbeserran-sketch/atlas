import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final nutrition = File(
    'lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart',
  ).readAsStringSync();
  final inventory = File(
    'lib/features/farm_inventory/presentation/screens/'
    'inventory_overview_screen.dart',
  ).readAsStringSync();
  final finance = File(
    'lib/features/farm_finance/presentation/screens/'
    'finance_overview_screen.dart',
  ).readAsStringSync();

  test('Nutrição concentra decisão, ações e integração com estoque', () {
    expect(nutrition.contains('AtlasModuleDecisionPanel('), isTrue);
    expect(nutrition.contains("moduleLabel: 'Nutrição'"), isTrue);
    expect(
      nutrition.contains('inventoryIntegration.deductDailyConsumption'),
      isTrue,
    );
  });

  test('Estoque concentra risco, valor e gestão no mesmo módulo', () {
    expect(inventory.contains('AtlasModuleDecisionPanel('), isTrue);
    expect(inventory.contains("moduleLabel: 'Estoque'"), isTrue);
    expect(inventory.contains('outOfStockCount'), isTrue);
    expect(inventory.contains('nearExpirationCount'), isTrue);
  });

  test('Financeiro interpreta resultado dentro do ciclo pecuário', () {
    expect(finance.contains('AtlasModuleDecisionPanel('), isTrue);
    expect(finance.contains("moduleLabel: 'Financeiro'"), isTrue);
    expect(
      finance.contains('Leia o financeiro dentro do ciclo da pecuária'),
      isTrue,
    );
    expect(finance.contains('openFinancialSimulation'), isTrue);
  });
}
