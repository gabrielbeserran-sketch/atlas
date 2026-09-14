import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('a Central de Análises é a única superfície de inteligência no menu', () {
    final shell = read('lib/core/navigation/atlas_home_shell.dart');
    final policy = read('lib/core/navigation/atlas_product_surface_policy.dart');
    final center = read(
      'lib/features/atlas_intelligence_center/presentation/screens/atlas_intelligence_center_screen.dart',
    );

    expect(shell, contains("label: 'Inteligência'"));
    expect(shell, contains("menuLabel: 'Análises'"));
    expect(shell, isNot(contains("label: 'Copilot'")));
    expect(shell, isNot(contains("label: 'Predictive'")));
    expect(shell, isNot(contains("label: 'Diagnóstico Inteligente'")));
    expect(policy, contains("'business intelligence': 'Inteligência'"));
    expect(policy, contains("'análise preditiva': 'Inteligência'"));
    expect(policy, contains("'simulação de cenários': 'Inteligência'"));
    expect(center, contains("text: 'Resumo'"));
    expect(center, contains("text: 'O que fazer'"));
    expect(center, contains("text: 'Por área'"));
    expect(center, contains("text: 'Simular'"));
    expect(center, contains("text: 'Decisões'"));
    expect(center, contains('Copiloto operacional'));
  });
}
