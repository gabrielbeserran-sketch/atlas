import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'o login aquece a API sem enviar credenciais e bloqueia o botão até ela estar pronta',
    () {
      final login = read(
        'lib/features/authentication/presentation/screens/login_screen.dart',
      );
      final api = read(
        'lib/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart',
      );

      expect(api, contains("'/health/ready'"));
      expect(api, contains('authenticated: false'));
      expect(login, contains('unawaited(_warmBackend());'));
      expect(login, contains('const _backendReadinessTimeout'));
      expect(
        login,
        contains('healthReady().timeout(\n        _backendReadinessTimeout,'),
      );
      expect(
        login,
        contains('backendConnection != _BackendConnectionState.ready'),
      );
      expect(login, contains('Tentar conexão'));
    },
  );
}
