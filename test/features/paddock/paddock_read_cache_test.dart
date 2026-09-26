import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_read_cache.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';

AtlasRemoteFarm farm({
  String tenant = 't',
  String company = 'c',
  String id = 'f',
}) => AtlasRemoteFarm(
  id: id,
  tenantId: tenant,
  companyId: company,
  name: 'Mesmo nome',
  city: '',
  state: '',
  animals: 0,
  area: 20,
  active: true,
);
const paddock = PaddockData(
  id: 'p',
  name: 'P1',
  area: 3.5,
  status: 'Descanso',
  animals: 2,
);
void main() {
  final now = DateTime(2026, 9, 26);
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test('preserva consulta e data após recriar serviço', () async {
    await PaddockReadCache().save(farm(), [paddock], now);
    final loaded = await PaddockReadCache().load(farm(), now);
    expect(loaded!.loadedAt, now);
    expect(loaded.paddocks.single.name, 'P1');
    expect(loaded.nominalAreaHa, 3.5);
  });
  test(
    'mesmo nome não compartilha dados entre tenant empresa e fazenda',
    () async {
      final cache = PaddockReadCache();
      await cache.save(farm(), [paddock], now);
      for (final scope in [
        farm(tenant: 'other'),
        farm(company: 'other'),
        farm(id: 'other'),
      ]) {
        expect(await cache.load(scope, now), isNull);
      }
    },
  );
  test('lista vazia confirmada não é ausência de cache', () async {
    final cache = PaddockReadCache();
    await cache.save(farm(), [], now);
    expect((await cache.load(farm(), now))!.paddocks, isEmpty);
  });
  test(
    'consulta futura e armazenamento ilegível não viram dados atuais',
    () async {
      final cache = PaddockReadCache();
      await cache.save(farm(), [paddock], now.add(const Duration(days: 1)));
      expect(await cache.load(farm(), now), isNull);
      final key =
          'atlas_paddocks_read_v1_${base64Url.encode(utf8.encode(jsonEncode(['t', 'c', 'f'])))}';
      await SharedPreferencesAsync().setString(key, 'corrompido');
      expect(await cache.load(farm(), now), isNull);
      expect(await SharedPreferencesAsync().getString(key), 'corrompido');
    },
  );
  test(
    'invalidação após alteração afeta só a fazenda correspondente',
    () async {
      final cache = PaddockReadCache();
      await cache.save(farm(), [paddock], now);
      await cache.save(farm(id: 'other'), [paddock], now);
      await cache.invalidate(farm());
      expect(await cache.load(farm(), now), isNull);
      expect(await cache.load(farm(id: 'other'), now), isNotNull);
    },
  );
  test('identidade incompleta é recusada antes da leitura', () async {
    expect(
      () => PaddockReadCache().load(farm(company: ''), now),
      throwsArgumentError,
    );
  });
  test(
    'tela prioriza cache e CRUD continua confirmando exclusivamente na API',
    () {
      final screen = File(
        'lib/features/paddock/presentation/screens/paddock_list_screen.dart',
      ).readAsStringSync();
      final repository = File(
        'lib/features/paddock/data/services/paddock_storage_service.dart',
      ).readAsStringSync();
      expect(screen, contains('if (!refresh)'));
      expect(
        screen.indexOf('await readCache.load'),
        lessThan(screen.indexOf('final savedPaddocks')),
      );
      expect(screen, contains('loadPaddocks(refresh: true)'));
      expect(screen, contains('Contexto alterado.'));
      expect(repository, isNot(contains('PaddockReadCache')));
      expect(repository, contains('return _verifyPaddock'));
      expect(
        repository,
        contains('final remaining = await loadPaddocks(farmId)'),
      );
    },
  );
}
