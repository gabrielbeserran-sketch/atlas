import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/auth/atlas_offline_pin_service.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('PIN e sessão usam o mesmo modo criptografado no Android', () {
    final pin = File(
      'lib/core/auth/atlas_offline_pin_service.dart',
    ).readAsStringSync();
    final session = File(
      'lib/features/enterprise_platform/data/services/'
      'atlas_enterprise_remote_auth_store.dart',
    ).readAsStringSync();

    expect(pin, contains('AndroidOptions(encryptedSharedPreferences: true)'));
    expect(
      session,
      contains('AndroidOptions(encryptedSharedPreferences: true)'),
    );
    expect(session, isNot(contains('deleteAll(')));
  });

  test('recuperação de sessão inválida conserva PIN já salvo', () async {
    await AtlasOfflinePinService.instance.save('123456');
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.write(
      key: 'atlas_enterprise_secure_remote_session',
      value: '{invalido',
    );

    expect(await AtlasEnterpriseRemoteAuthStore.instance.loadSession(), isNull);
    expect(await AtlasOfflinePinService.instance.isConfigured, isTrue);
    expect(await AtlasOfflinePinService.instance.verify('123456'), isTrue);
  });
}
