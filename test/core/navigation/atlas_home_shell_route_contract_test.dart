import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('menu routes resolve every specialized operational screen', () {
    final source = File(
      'lib/core/navigation/atlas_home_shell.dart',
    ).readAsStringSync();

    const expectedRoutes = <String, String>{
      'Realizar manejo': 'FarmHandlingScreen(farm: farm, embedded: true)',
      'Agenda': 'FarmAgendaListScreen(farm: farm, embedded: true)',
      'Dr. Beserra': 'DrBeserraScreen(',
      'Campo': 'FarmFieldCenterScreen(farm: farm, embedded: true)',
      'Relatórios': 'ReportsScreen(embedded: true)',
      'Consultoria': 'AtlasClientConsultancyCenterScreen(',
      'Inteligência': 'AtlasIntelligenceCenterScreen(onNavigateModule:',
    };

    for (final entry in expectedRoutes.entries) {
      expect(source, contains("selected.label == '${entry.key}'"));
      expect(source, contains(entry.value));
    }

    expect(
      source,
      contains('_AtlasSelectFarmMessage(onSelectFarm: () => _selectFarm(context))'),
      reason: 'rotas que exigem fazenda devem orientar a seleção, nunca renderizar vazias',
    );
  });
}
