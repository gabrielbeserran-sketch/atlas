import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('centraliza alertas técnicos de Leite e Corte no painel', () {
    final dashboard = File(
      'lib/features/technical_dashboard/presentation/screens/technical_dashboard_screen.dart',
    ).readAsStringSync();

    expect(dashboard, contains('_productionDataQualityAlerts'));
    expect(dashboard, contains('summary.dairyOperationalDataAlerts'));
    expect(dashboard, contains('summary.beefHerd.dataQualityAlerts'));
    expect(dashboard, contains('_beefOperationalDataAlerts'));
    expect(dashboard, contains('Cobertura da última pesagem'));
    expect(dashboard, contains('Base do ganho médio diário'));
    expect(dashboard, contains('Dados técnicos para revisar — Leite'));
    expect(dashboard, contains('Dados técnicos para revisar — Corte'));
    expect(dashboard, contains('Itens que precisam de revisão'));
  });
}
