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

  test('preserva contexto local e mantém a entrada como ação explícita', () {
    final controller = read('lib/core/session/atlas_session_controller.dart');
    final gate = read('lib/core/session/atlas_session_gate.dart');
    final store = read(
      'lib/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart',
    );

    expect(controller, contains('_farms = await _store.loadFarmPortfolio();'));
    expect(controller, contains('_session = stored;'));
    expect(
      controller,
      contains('_setStatus(AtlasSessionStatus.unauthenticated);'),
    );
    expect(controller, contains('Future<void> retryConnection() async'));
    expect(gate, contains('autoRestoreSession: false'));
    expect(controller, isNot(contains('await _store.clearSession();')));
    expect(store, contains('saveFarmPortfolio'));
    expect(store, contains('loadFarmPortfolio'));
  });
}
