import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final policy = File(
    'lib/core/navigation/atlas_product_surface_policy.dart',
  ).readAsStringSync();
  final analysis = File(
    'lib/features/atlas_intelligence_center/presentation/screens/'
    'atlas_intelligence_center_screen.dart',
  ).readAsStringSync();

  test('recursos especializados possuem política central de propriedade', () {
    expect(
      policy.contains('specializedCapabilityCountByOwner'),
      isTrue,
    );
    expect(policy.contains('moduleWorkflows'), isTrue);
    expect(policy.contains('internalOnlyCapabilityRoots'), isTrue);
  });

  test('áreas oficiais mostram tarefas em vez de nomes técnicos', () {
    for (final label in <String>[
      'Rebanho',
      'Reprodução',
      'Sanidade',
      'Nutrição',
      'Estoque',
      'Financeiro',
      'Campo',
    ]) {
      expect(policy.contains("'$label': ["), isTrue);
    }
  });

  test('Análises reutiliza a política e mantém navegação direta', () {
    expect(
      analysis.contains(
        'AtlasProductSurfacePolicy.moduleWorkflows[area.title]',
      ),
      isTrue,
    );
    expect(
      analysis.contains(
        'specializedCapabilityCountByOwner[area.title]',
      ),
      isTrue,
    );
    expect(
      analysis.contains(
        'widget.onNavigateModule!(area.moduleLabel)',
      ),
      isTrue,
    );
  });
}
