import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fase 6.5.3 preserva porta unica e taxonomia canonica de inteligencia', () {
    final farm = File(
      'lib/features/farm/presentation/screens/farm_detail_screen.dart',
    ).readAsStringSync();
    final center = File(
      'lib/features/atlas_intelligence_center/presentation/screens/'
      'atlas_intelligence_center_screen.dart',
    ).readAsStringSync();

    expect(farm, contains("tooltip: 'Central de Inteligência Atlas'"));
    expect(farm, contains('FarmUnifiedIntelligenceAccessCard('));
    expect(farm, contains('AtlasIntelligenceCenterScreen('));

    for (final legacyTooltip in <String>[
      "tooltip: 'Conversar com Atlas IA'",
      "tooltip: 'Simular Decisões'",
      "tooltip: 'Diagnóstico Inteligente'",
      "tooltip: 'Copiloto Atlas'",
      "tooltip: 'Inteligência da Fazenda'",
    ]) {
      expect(farm, isNot(contains(legacyTooltip)));
    }

    for (final oldCard in <String>[
      'FarmAtlasAiAccessCard(',
      'FarmPredictiveAccessCard(',
      'FarmDiagnosticAccessCard(',
      'FarmIntelligenceAccessCard(',
    ]) {
      expect(farm, isNot(contains(oldCard)));
    }

    expect(center, contains('Inteligência Atlas'));
    expect(center, contains('Cinco capacidades organizam as inteligências existentes.'));
    expect(center, isNot(contains('Capacidades especializadas')));
    expect(center, contains('onOpenAtlasAi'));
    expect(center, contains('onOpenPredictive'));
    expect(center, contains('onOpenDiagnostic'));
    expect(center, contains('onOpenCopilot'));
    expect(center, contains('onOpenFarmIntelligence'));
  });
}
