import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/navigation/atlas_worker_menu_policy.dart';
import 'package:projeto_atlas/core/subscription/atlas_subscription_profile.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

AtlasRemoteSession _session(String company, {String tenant = 'tenant-1'}) =>
    AtlasRemoteSession(
      accessToken: 'test',
      refreshToken: 'test',
      expiresInSeconds: 3600,
      userId: 'worker-1',
      userName: '',
      email: '',
      companyId: company,
      tenantId: tenant,
      role: 'operator',
      companies: const [],
      effectivePermissions: const {'herd.read'},
      farmIds: const ['farm-1'],
      savedAt: DateTime(2026, 9, 28),
    );

AtlasSubscriptionProfile _plan(String code, String status) =>
    AtlasSubscriptionProfile.fromMap({
      'code': code,
      'name': code,
      'status': status,
      'limits': const <String, dynamic>{},
      'features': code == 'consultancy' ? ['consultoria'] : <String>[],
      'consultancy_included': code == 'consultancy',
    });

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('menu compacto só vale para operador com Consultoria ativa', () {
    expect(
      AtlasWorkerMenuPolicy.compactFor(role: 'operator', consultancy: true),
      isTrue,
    );
    expect(
      AtlasWorkerMenuPolicy.compactFor(role: 'manager', consultancy: true),
      isFalse,
    );
    expect(
      AtlasWorkerMenuPolicy.compactFor(role: 'operator', consultancy: false),
      isFalse,
    );
    expect(AtlasWorkerMenuPolicy.isPrimary('Realizar manejo'), isTrue);
    expect(AtlasWorkerMenuPolicy.isPrimary('Offline'), isTrue);
    expect(AtlasWorkerMenuPolicy.isPrimary('Configurações'), isTrue);
    expect(AtlasWorkerMenuPolicy.isPrimary('Reprodução'), isFalse);
  });

  test('confirmação local não atravessa empresas', () async {
    final store = AtlasWorkerMenuEntitlement(
      preferences: SharedPreferencesAsync(),
      loadProfile: () async => _plan('consultancy', 'active'),
    );
    expect(await store.loadCached(_session('company-1')), isNull);
    final enabled = await store.fetchConfirmed();
    await store.saveFor(_session('company-1'), enabled);
    expect(enabled, isTrue);
    expect(await store.loadCached(_session('company-1')), isTrue);
    expect(await store.loadCached(_session('company-2')), isNull);
    expect(await store.loadCached(_session('b_c', tenant: 'a')), isNull);
    expect(
      store.scopeKey(_session('c', tenant: 'a_b')),
      isNot(store.scopeKey(_session('b_c', tenant: 'a'))),
    );
  });

  test(
    'plano não ativo substitui cache anterior sem simplificar menu',
    () async {
      var current = _plan('consultancy', 'active');
      final store = AtlasWorkerMenuEntitlement(
        preferences: SharedPreferencesAsync(),
        loadProfile: () async => current,
      );
      await store.saveFor(_session('company-1'), await store.fetchConfirmed());
      current = _plan('consultancy', 'not_configured');
      final disabled = await store.fetchConfirmed();
      await store.saveFor(_session('company-1'), disabled);
      expect(disabled, isFalse);
      expect(await store.loadCached(_session('company-1')), isFalse);
    },
  );

  test('falha de conexão preserva a última confirmação local', () async {
    final preferences = SharedPreferencesAsync();
    final online = AtlasWorkerMenuEntitlement(
      preferences: preferences,
      loadProfile: () async => _plan('consultancy', 'active'),
    );
    await online.saveFor(_session('company-1'), await online.fetchConfirmed());
    final offline = AtlasWorkerMenuEntitlement(
      preferences: preferences,
      loadProfile: () async => throw StateError('offline'),
    );
    await expectLater(offline.fetchConfirmed(), throwsStateError);
    expect(await offline.loadCached(_session('company-1')), isTrue);
  });

  test('resposta remota não grava cache antes de conferir a empresa', () async {
    final store = AtlasWorkerMenuEntitlement(
      preferences: SharedPreferencesAsync(),
      loadProfile: () async => _plan('consultancy', 'active'),
    );
    expect(await store.fetchConfirmed(), isTrue);
    expect(await store.loadCached(_session('company-1')), isNull);
    expect(await store.loadCached(_session('company-2')), isNull);
  });
}
