import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final policy = File(
    'lib/core/navigation/atlas_product_surface_policy.dart',
  ).readAsStringSync();
  final field = File(
    'lib/features/field_operations/presentation/screens/'
    'farm_field_center_screen.dart',
  ).readAsStringSync();
  final analysis = File(
    'lib/features/atlas_intelligence_center/presentation/screens/'
    'atlas_intelligence_center_screen.dart',
  ).readAsStringSync();
  final reports = File(
    'lib/features/reports/presentation/screens/reports_screen.dart',
  ).readAsStringSync();

  test('Campo executa e acompanha a operação', () {
    expect(field.contains('AtlasModuleDecisionPanel('), isTrue);
    expect(field.contains("moduleLabel: 'Campo'"), isTrue);
    expect(field.contains('openPaddocks'), isTrue);
    expect(field.contains('openOperations'), isTrue);
    expect(field.contains('openFieldTools'), isTrue);
  });

  test('Análises interpreta sem substituir módulos operacionais', () {
    expect(analysis.contains("moduleLabel: 'Análises'"), isTrue);
    expect(analysis.contains('loadContext(farmId)'), isTrue);
    expect(analysis.contains('loadRecommendations(farmId)'), isTrue);
    expect(analysis.contains('buildSimulator(context, farm.id)'), isTrue);
    expect(
      analysis.contains('widget.onNavigateModule!(area.moduleLabel)'),
      isTrue,
    );
  });

  test('Relatórios consolida, compara e exporta', () {
    expect(reports.contains("moduleLabel: 'Relatórios'"), isTrue);
    expect(reports.contains('selectedFarmName'), isTrue);
    expect(reports.contains('selectedPeriod'), isTrue);
    expect(reports.contains('exportPdfReport()'), isTrue);
    expect(reports.contains('exportExcelReport()'), isTrue);
    expect(reports.contains('periodComparisonData'), isTrue);
  });

  test('fronteiras funcionais ficam em política única', () {
    expect(policy.contains('moduleResponsibility'), isTrue);
    expect(policy.contains('moduleDoesNotReplace'), isTrue);
    expect(policy.contains("'Campo':"), isTrue);
    expect(policy.contains("'Análises':"), isTrue);
    expect(policy.contains("'Relatórios':"), isTrue);
  });
}
