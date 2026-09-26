import 'dart:convert';
import 'dart:io';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_panel_reader.dart';
import 'package:projeto_atlas/features/paddock/data/services/paddock_read_cache.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';
import 'package:projeto_atlas/features/farm_operations/data/services/atlas_operations_repository.dart';

const farm = AtlasRemoteFarm(
  id: 'f',
  tenantId: 't',
  companyId: 'c',
  name: 'Farm',
  city: '',
  state: '',
  animals: 0,
  area: 10,
  active: true,
);
const paddock = PaddockData(
  id: 'p',
  name: 'P',
  area: 2,
  status: 'Descanso',
  animals: 0,
);
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });
  test('painel abre cache sem consultar API', () async {
    final at = DateTime.now().subtract(const Duration(days: 1));
    await PaddockReadCache().save(farm, [paddock], at);
    var calls = 0;
    final reader = PaddockPanelReader(
      resolveFarm: () async => farm,
      fetch: (_) async {
        calls++;
        return [];
      },
    );
    final result = await reader.read();
    expect(result.snapshot!.loadedAt, at);
    expect(result.snapshot!.paddocks.single.id, 'p');
    expect(calls, 0);
  });
  test('ausência de cache não dispara rede nem vira zero confirmado', () async {
    var calls = 0;
    final result = await PaddockPanelReader(
      resolveFarm: () async => farm,
      fetch: (_) async {
        calls++;
        return [];
      },
    ).read();
    expect(result.snapshot, isNull);
    expect(result.notice, contains('ainda não consultados'));
    expect(calls, 0);
  });
  test('atualização explícita salva consulta e lista vazia válida', () async {
    var calls = 0;
    final reader = PaddockPanelReader(
      resolveFarm: () async => farm,
      fetch: (_) async {
        calls++;
        return [];
      },
    );
    expect((await reader.read(refresh: true)).snapshot!.paddocks, isEmpty);
    expect((await reader.read()).snapshot, isNotNull);
    expect(calls, 1);
  });
  test('falha de rede preserva cache e data', () async {
    final at = DateTime.now().subtract(const Duration(days: 1));
    await PaddockReadCache().save(farm, [paddock], at);
    final result = await PaddockPanelReader(
      resolveFarm: () async => farm,
      fetch: (_) async => throw StateError('offline'),
    ).read(refresh: true);
    expect(result.snapshot!.loadedAt, at);
    expect(result.notice, contains('preservadas'));
  });
  test('troca de contexto descarta resposta e não salva', () async {
    AtlasRemoteFarm? active = farm;
    final result = await PaddockPanelReader(
      resolveFarm: () async => active,
      fetch: (_) async {
        active = null;
        return [paddock];
      },
    ).read(refresh: true);
    expect(result.snapshot, isNull);
    expect(await PaddockReadCache().load(farm, DateTime.now()), isNull);
  });
  test('rejeição explícita não é falha de rede', () async {
    await PaddockReadCache().save(farm, [paddock], DateTime.now());
    for (final status in [401, 403]) {
      final result = await PaddockPanelReader(
        resolveFarm: () async => farm,
        fetch: (_) async =>
            throw AtlasEnterpriseApiException('Denied', statusCode: status),
      ).read(refresh: true);
      expect(result.snapshot, isNull);
      expect(result.notice, contains('recusado'));
    }
  });
  test(
    'operações read-only não criam exemplos nem gravam armazenamento',
    () async {
      expect(
        await AtlasOperationsRepository().loadReadOnly(farmId: 'f'),
        isEmpty,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('atlas_farm_operations_v1'), isNull);
    },
  );
  test(
    'operações sem proprietário ou de outra fazenda não entram no painel',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'atlas_farm_operations_v1',
        jsonEncode([
          {'id': 'a', 'farmId': 'f', 'title': 'Own'},
          {'id': 'b', 'farmId': 'other', 'title': 'Other'},
          {'id': 'c', 'title': 'Unassigned'},
        ]),
      );
      final before = prefs.getString('atlas_farm_operations_v1');
      final result = await AtlasOperationsRepository().loadReadOnly(
        farmId: 'f',
      );
      expect(result.map((e) => e.id), ['a']);
      expect(prefs.getString('atlas_farm_operations_v1'), before);
    },
  );
  test('painel conserva navegação e não usa spinner bloqueante', () {
    final source = File(
      'lib/features/field_operations/presentation/screens/farm_field_center_screen.dart',
    ).readAsStringSync();
    expect(source, contains('loadReadOnly'));
    expect(source, contains('Campo com dados parciais'));
    expect(source, contains('Piquetes não consultados'));
    expect(source, isNot(contains('CircularProgressIndicator')));
    expect(source, contains('generation != loadGeneration'));
    expect(source, contains('onTap: openPaddocks'));
  });
}
