import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_field_paddock_snapshot.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_panel_reader.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_read_cache.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';

AtlasRemoteFarm scope({String company = 'c', String id = 'f'}) =>
    AtlasRemoteFarm(
      id: id,
      tenantId: 't',
      companyId: company,
      name: 'Teste',
      city: '',
      state: '',
      animals: 0,
      area: 10,
      active: true,
    );
const paddock = PaddockData(
  id: 'p',
  name: 'Teste',
  area: 2,
  status: 'Descanso',
  animals: 3,
);

class FailingCache extends PaddockReadCache {
  FailingCache({
    this.failRead = false,
    this.failWrite = false,
    this.afterRead,
    this.afterWrite,
  });
  final bool failRead;
  final bool failWrite;
  final void Function()? afterRead;
  final void Function()? afterWrite;
  int writes = 0;
  @override
  Future<AtlasFieldPaddockSnapshot?> load(
    AtlasRemoteFarm farm,
    DateTime now,
  ) async {
    afterRead?.call();
    if (failRead) throw StateError('storage unavailable');
    return null;
  }

  @override
  Future<void> save(
    AtlasRemoteFarm farm,
    List<PaddockData> rows,
    DateTime at,
  ) async {
    writes++;
    afterWrite?.call();
    if (failWrite) throw StateError('storage unavailable');
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test(
    'falha local abre estado parcial sem disparar rede nem apagar dados',
    () async {
      var calls = 0;
      final cache = FailingCache(failRead: true);
      final result = await PaddockPanelReader(
        resolveFarm: () async => scope(),
        cache: cache,
        fetch: (_) async {
          calls++;
          return [paddock];
        },
      ).read();
      expect(result.snapshot, isNull);
      expect(result.notice, contains('Cópia local'));
      expect(result.notice, contains('não foram apagados'));
      expect(calls, 0);
      expect(cache.writes, 0);
    },
  );

  test(
    'atualizar consulta servidor mesmo quando leitura local falha',
    () async {
      var calls = 0;
      final cache = FailingCache(failRead: true);
      final result = await PaddockPanelReader(
        resolveFarm: () async => scope(),
        cache: cache,
        fetch: (_) async {
          calls++;
          return [paddock];
        },
      ).read(refresh: true);
      expect(result.snapshot!.paddocks.single.id, 'p');
      expect(result.notice, 'Piquetes consultados no servidor.');
      expect(calls, 1);
      expect(cache.writes, 1);
    },
  );

  test(
    'falhas local e remota não inventam snapshot vazio confirmado',
    () async {
      final result = await PaddockPanelReader(
        resolveFarm: () async => scope(),
        cache: FailingCache(failRead: true),
        fetch: (_) async => throw StateError('offline'),
      ).read(refresh: true);
      expect(result.snapshot, isNull);
      expect(result.notice, contains('também não pôde ser lida'));
    },
  );

  test('falha ao salvar mantém consulta remota disponível com aviso', () async {
    final cache = FailingCache(failWrite: true);
    final result = await PaddockPanelReader(
      resolveFarm: () async => scope(),
      cache: cache,
      fetch: (_) async => [paddock],
    ).read(refresh: true);
    expect(result.snapshot!.paddocks.single.animals, 3);
    expect(result.notice, contains('cópia offline não foi salva'));
    expect(cache.writes, 1);
  });

  test(
    'troca de empresa durante leitura falha impede consulta e gravação',
    () async {
      var active = scope();
      var calls = 0;
      final cache = FailingCache(
        failRead: true,
        afterRead: () => active = scope(company: 'other'),
      );
      final result = await PaddockPanelReader(
        resolveFarm: () async => active,
        cache: cache,
        fetch: (_) async {
          calls++;
          return [paddock];
        },
      ).read(refresh: true);
      expect(result.snapshot, isNull);
      expect(result.notice, contains('Contexto alterado'));
      expect(calls, 0);
      expect(cache.writes, 0);
    },
  );

  test('troca de fazenda ao tentar salvar impede exibição remota', () async {
    var active = scope();
    final cache = FailingCache(
      failWrite: true,
      afterWrite: () => active = scope(id: 'other'),
    );
    final result = await PaddockPanelReader(
      resolveFarm: () async => active,
      cache: cache,
      fetch: (_) async => [paddock],
    ).read(refresh: true);
    expect(result.snapshot, isNull);
    expect(result.notice, contains('Contexto alterado'));
  });
}
