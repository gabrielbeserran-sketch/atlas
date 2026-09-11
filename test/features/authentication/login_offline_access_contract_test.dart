import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o login mantém uma entrada explícita para o contexto salvo', () {
    final source = File(
      'lib/features/authentication/presentation/screens/login_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Continuar com dados salvos'));
    expect(source, contains('Dados salvos disponíveis neste dispositivo'));
    expect(source, contains('canContinueOffline'));
  });
}
