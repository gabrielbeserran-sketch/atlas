import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('centraliza a sincronização na Central offline', () {
    final settings = read('lib/core/settings/atlas_settings_screen.dart');
    final offlineCenter = read(
      'lib/core/offline/presentation/atlas_offline_center_screen.dart',
    );
    final homeShell = read('lib/core/navigation/atlas_home_shell.dart');
    final sessionController = read(
      'lib/core/session/atlas_session_controller.dart',
    );
    final pinService = read('lib/core/auth/atlas_offline_pin_service.dart');
    final loginScreen = read(
      'lib/features/authentication/presentation/screens/login_screen.dart',
    );

    expect(settings, contains('Segurança e acesso'));
    expect(settings, isNot(contains('Conexão e sincronização')));
    expect(settings, isNot(contains('retryConnection')));
    expect(offlineCenter, contains('Central offline'));
    expect(offlineCenter, contains('Sincronizar agora'));
    expect(offlineCenter, contains('Conflitos pendentes'));
    expect(homeShell, contains("label: 'Configurações'"));
    expect(homeShell, isNot(contains('onConfigureOfflinePin')));
    expect(homeShell, isNot(contains("value: 'offlinePin'")));
    expect(sessionController, contains('_offlinePinConfigured'));
    expect(sessionController, contains('refreshOfflineAccess() async'));
    expect(pinService, contains('static const _maxFailedAttempts = 5'));
    expect(
      pinService,
      contains('static const _lockDuration = Duration(minutes: 5)'),
    );
    expect(pinService, contains('verifyForUnlock'));
    expect(loginScreen, contains('Muitas tentativas. Tente novamente em'));
  });
}
