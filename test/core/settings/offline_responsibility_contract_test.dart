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

    expect(settings, contains('Segurança e acesso'));
    expect(settings, isNot(contains('Conexão e sincronização')));
    expect(settings, isNot(contains('retryConnection')));
    expect(offlineCenter, contains('Central offline'));
    expect(offlineCenter, contains('Sincronizar agora'));
    expect(offlineCenter, contains('Conflitos pendentes'));
    expect(homeShell, contains("label: 'Configurações'"));
    expect(homeShell, isNot(contains('onConfigureOfflinePin')));
    expect(homeShell, isNot(contains("value: 'offlinePin'")));
  });
}
