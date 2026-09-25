import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Corte usa base confirmada separada da área total', () {
    final source = File(
      'lib/features/technical_dashboard/presentation/screens/'
      'technical_dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, contains('AtlasPastureGrazingScope.resolve('));
    expect(source, contains('return (basis, scope.area);'));
    expect(source, contains('basis.isCurrentAt(DateTime.now())'));
    expect(source, contains('Animais por hectare de pasto efetivo'));
    expect(source, contains('Base confirmada de pastejo'));
    expect(source, contains('Não informada neste dispositivo'));
    expect(source, contains('não equivale a UA/ha'));
  });
}
