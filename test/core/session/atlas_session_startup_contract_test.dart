import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('a inicialização delega o limite de sessão ao controlador', () {
    final gate = read('lib/core/session/atlas_session_gate.dart');
    final controller = read('lib/core/session/atlas_session_controller.dart');

    expect(gate, contains('await controller.restore();'));
    expect(gate, isNot(contains('controller.restore().timeout')));
    expect(controller, contains('const _sessionValidationTimeout'));
    expect(
      controller,
      contains('_api.me().timeout(_sessionValidationTimeout)'),
    );
  });
}
