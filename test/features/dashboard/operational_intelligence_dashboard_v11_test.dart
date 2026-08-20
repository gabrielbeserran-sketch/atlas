import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dashboard V11 carrega inteligência operacional do backend', () {
    final dashboard = File(
      'lib/features/dashboard/presentation/screens/dashboard_screen.dart',
    ).readAsStringSync();
    final service = File(
      'lib/features/dashboard/data/services/atlas_operational_intelligence_service.dart',
    ).readAsStringSync();

    expect(dashboard.contains('OperationalIntelligenceCard('), isTrue);
    expect(dashboard.contains('_loadOperationalIntelligence'), isTrue);
    expect(service.contains('/livestock/intelligence/operational-summary'), isTrue);
    expect(service.contains('/livestock/intelligence/operational-alerts'), isTrue);
  });

  test('Ações recomendadas possuem navegação por área', () {
    final dashboard = File(
      'lib/features/dashboard/presentation/screens/dashboard_screen.dart',
    ).readAsStringSync();

    expect(dashboard.contains('void openOperationalArea(String area)'), isTrue);
    expect(dashboard.contains('openHealth();'), isTrue);
    expect(dashboard.contains('openReproduction();'), isTrue);
    expect(dashboard.contains('openNutrition();'), isTrue);
    expect(dashboard.contains('openFinance();'), isTrue);
    expect(dashboard.contains('openInventory();'), isTrue);
  });
}
