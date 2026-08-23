import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final shell = File(
    'lib/core/navigation/atlas_home_shell.dart',
  ).readAsStringSync();
  final field = File(
    'lib/features/field_operations/presentation/screens/'
    'farm_field_center_screen.dart',
  ).readAsStringSync();
  final inventory = File(
    'lib/features/farm_inventory/presentation/screens/'
    'inventory_overview_screen.dart',
  ).readAsStringSync();
  final finance = File(
    'lib/features/farm_finance/presentation/screens/'
    'finance_overview_screen.dart',
  ).readAsStringSync();
  final intelligence = File(
    'lib/features/atlas_intelligence_center/presentation/screens/'
    'atlas_intelligence_center_screen.dart',
  ).readAsStringSync();

  test('menu abre as centrais da fazenda sem tela intermediária', () {
    expect(
      shell.contains('FarmFieldCenterScreen(farm: farm, embedded: true)'),
      isTrue,
    );
    expect(
      shell.contains('InventoryOverviewScreen(farm: farm, embedded: true)'),
      isTrue,
    );
    expect(
      shell.contains('FinanceOverviewScreen(farm: farm, embedded: true)'),
      isTrue,
    );
  });

  test('Campo reúne piquetes operações equipe e ferramentas', () {
    expect(field.contains('PaddockStorageService'), isTrue);
    expect(field.contains('AtlasOperationsRepository'), isTrue);
    expect(field.contains('activeTeam'), isTrue);
    expect(field.contains('openOperationsCount'), isTrue);
    expect(field.contains('Future<void> openOperations()'), isTrue);
    expect(field.contains('AtlasFieldOperationsScreen'), isTrue);
  });

  test('Estoque prioriza indisponibilidade e validade', () {
    expect(inventory.contains('outOfStockCount'), isTrue);
    expect(inventory.contains('expiredCount'), isTrue);
    expect(inventory.contains('lowStockCount'), isTrue);
    expect(inventory.contains('AtlasModuleDecisionPanel('), isTrue);
  });

  test('Financeiro respeita ciclo produtivo pecuário', () {
    expect(finance.contains('pendingIncome'), isTrue);
    expect(finance.contains('pendingExpenses'), isTrue);
    expect(finance.contains('overdueRecords'), isTrue);
    expect(
      finance.contains(
        'saldo negativo isolado não significa falha operacional',
      ),
      isTrue,
    );
  });

  test('Inteligência e relatórios permanecem conectados', () {
    expect(intelligence.contains('void openReports()'), isTrue);
    expect(intelligence.contains('onPressed: openReports'), isTrue);
    expect(intelligence.contains('ReportsScreen()'), isTrue);
  });
}
