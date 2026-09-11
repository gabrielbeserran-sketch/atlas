import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o login não concede acesso local sem autenticação', () {
    final source = File(
      'lib/features/authentication/presentation/screens/login_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('Continuar com dados salvos')));
    expect(source, isNot(contains('canContinueOffline')));
  });
}
