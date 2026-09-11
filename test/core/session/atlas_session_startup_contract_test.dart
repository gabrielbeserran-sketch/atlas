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

  test('abre a sessão local antes de validar a conexão em segundo plano', () {
    final controller = read('lib/core/session/atlas_session_controller.dart');
    final store = read(
      'lib/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart',
    );

    expect(controller, contains('_farms = await _store.loadFarmPortfolio();'));
    expect(controller, contains('_session = stored;'));
    expect(controller, contains('unawaited(_refreshContextAfterStartup());'));
    expect(controller, contains('_offlineMode = true;'));
    expect(controller, contains('Future<void> retryConnection() async'));
    expect(controller, isNot(contains('await _store.clearSession();')));
    expect(store, contains('saveFarmPortfolio'));
    expect(store, contains('loadFarmPortfolio'));
  });
}
