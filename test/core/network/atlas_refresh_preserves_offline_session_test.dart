import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> saveExpiredSession() async {
    await AtlasEnterpriseRemoteAuthStore.instance.saveSession(
      AtlasRemoteSession.fromMap({
        'access_token': 'expirado',
        'refresh_token': 'refresh-valido',
        'expires_in_seconds': 60,
        'savedAt': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'user_id': 'user-a',
        'company_id': 'company-a',
        'tenant_id': 'tenant-a',
        'role': 'owner',
        'farm_ids': ['farm-a'],
      }),
    );
    await AtlasEnterpriseRemoteAuthStore.instance.saveActiveFarm('farm-a');
  }

  test('indisponibilidade na renovação preserva sessão e fazenda', () async {
    await saveExpiredSession();
    final client = AtlasHttpClient(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/auth/refresh'));
        return http.Response('indisponível', 503);
      }),
    );

    await expectLater(
      client.send('GET', '/farms', transientRetries: 0),
      throwsA(
        isA<AtlasHttpException>().having((e) => e.retryable, 'retryable', true),
      ),
    );
    expect(
      await AtlasEnterpriseRemoteAuthStore.instance.loadSession(),
      isNotNull,
    );
    expect(
      await AtlasEnterpriseRemoteAuthStore.instance.loadActiveFarm(),
      'farm-a',
    );
  });

  test('rejeição explícita do refresh invalida sessão', () async {
    await saveExpiredSession();
    final client = AtlasHttpClient(
      client: MockClient((request) async => http.Response('rejeitado', 401)),
    );

    await expectLater(
      client.send('GET', '/farms', transientRetries: 0),
      throwsA(
        isA<AtlasHttpException>().having(
          (e) => e.code,
          'code',
          'expired_session',
        ),
      ),
    );
    expect(await AtlasEnterpriseRemoteAuthStore.instance.loadSession(), isNull);
    expect(
      await AtlasEnterpriseRemoteAuthStore.instance.loadActiveFarm(),
      isNull,
    );
  });
}
