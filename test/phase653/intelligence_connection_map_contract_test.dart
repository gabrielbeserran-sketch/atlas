import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_intelligence_center/domain/models/atlas_intelligence_capability.dart';

void main() {
  test('cada implementação auditada possui uma única responsabilidade', () {
    final canonicalRoots =
        AtlasIntelligenceCapabilityRegistry.centralImplementationRoots;
    final domainRoots = AtlasIntelligenceCapabilityRegistry
        .domainOwnedImplementationRoots
        .keys
        .toSet();

    expect(canonicalRoots.intersection(domainRoots), isEmpty);
    expect(
      AtlasIntelligenceCapabilityRegistry.auditedImplementationRoots,
      containsAll(<String>[
        'atlas_ai',
        'copilot',
        'diagnostics',
        'predictive',
        'scenario_simulator',
        'atlas_intelligence',
        'animal_intelligence_360',
        'atlas_reproductive_ai',
        'atlas_supply_chain',
      ]),
    );
  });

  test('menu principal expõe somente a Central para inteligência', () {
    final homeShell = File(
      'lib/core/navigation/atlas_home_shell.dart',
    ).readAsStringSync();

    expect(homeShell, contains("label: 'Inteligência'"));
    expect(homeShell, contains("menuLabel: 'Análises'"));
    expect(homeShell, contains('AtlasIntelligenceCenterScreen('));

    for (final legacyScreen in <String>[
      'AtlasAiScreen(',
      'AtlasPredictiveScreen(',
      'AtlasDiagnosticScreen(',
      'AtlasCopilotScreen(',
      'AtlasFarmIntelligenceScreen(',
    ]) {
      expect(homeShell, isNot(contains(legacyScreen)));
    }
  });

  test('Central prepara a conversação pelo contexto compartilhado', () {
    final center = File(
      'lib/features/atlas_intelligence_center/presentation/screens/'
      'atlas_intelligence_center_screen.dart',
    ).readAsStringSync();

    expect(center, contains('AtlasFarmIntelligenceSnapshotLoader'));
    expect(center, contains('openConversationFromCenter'));
    expect(
      center,
      contains('widget.onOpenAtlasAi ?? openConversationFromCenter'),
    );
    expect(center, contains('AtlasAiScreen('));
  });
}
