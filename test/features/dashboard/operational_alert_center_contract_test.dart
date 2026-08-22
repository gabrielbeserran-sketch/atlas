import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final center = File(
    'lib/features/dashboard/presentation/screens/'
    'operational_alert_center_screen.dart',
  ).readAsStringSync();

  test('central possui busca, criticidade, área e ordenação', () {
    expect(center.contains('Buscar alerta'), isTrue);
    expect(center.contains("labelText: 'Criticidade'"), isTrue);
    expect(center.contains("labelText: 'Área'"), isTrue);
    expect(center.contains("labelText: 'Ordenar por'"), isTrue);
  });

  test('resolver abre módulo de origem sem resolução artificial', () {
    expect(center.contains('widget.onOpenArea(alert.area)'), isTrue);
    expect(
      center.contains(
        'desaparece automaticamente quando a causa real é corrigida',
      ),
      isTrue,
    );
  });
}
