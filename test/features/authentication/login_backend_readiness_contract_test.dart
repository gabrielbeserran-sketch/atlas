import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'o login aquece a API sem bloquear a entrada nem o desbloqueio offline',
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
      expect(login, contains('return _backendWarmup ??='));
      expect(login, contains('await _warmBackend();'));
      expect(
        login,
        contains('healthReady().timeout(\n        _backendReadinessTimeout,'),
      );
      expect(login, isNot(contains('if (!backendReady)')));
      expect(login, contains('isLoading ? null : onLogin'));
      expect(login, contains('Tentar conexão'));
      expect(login, contains('Entrar offline com PIN'));
      expect(login, contains('canUnlockOffline: canUnlockOffline'));
      expect(login, contains('modo offline é liberado após configurar um PIN'));
    },
  );
}
