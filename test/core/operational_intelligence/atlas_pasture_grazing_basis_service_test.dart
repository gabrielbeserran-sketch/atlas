import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_grazing_basis_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

AtlasPastureGrazingBasis basis({
  String tenant = 'tenant-a',
  String company = 'company-a',
  String farm = 'farm-a',
  double area = 20,
  int animals = 30,
  bool confirmed = true,
  DateTime? at,
}) => AtlasPastureGrazingBasis(
  tenantId: tenant,
  companyId: company,
  farmId: farm,
  effectiveAreaHa: area,
  grazingAnimals: animals,
  uniqueAreaConfirmed: confirmed,
  recordedAt: at ?? DateTime.now(),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('armazenamento ilegível não é apagado por nova gravação', () async {
    final key =
        'atlas_pasture_grazing_basis_v1_${base64Url.encode(utf8.encode(jsonEncode(['tenant-a', 'company-a', 'farm-a'])))}';
    final preferences = SharedPreferencesAsync();
    for (final raw in [
      '{incompleto',
      '[42]',
      jsonEncode([basis(farm: 'outra').toMap()]),
    ]) {
      await preferences.setString(key, raw);
      final service = AtlasPastureGrazingBasisService();
      await expectLater(service.save(basis()), throwsFormatException);
      expect(await preferences.getString(key), raw);
    }
  });

  test(
    'salva histórico e calcula apenas animais realmente em pastejo',
    () async {
      final service = AtlasPastureGrazingBasisService();
      final first = basis(at: DateTime.now().subtract(const Duration(days: 2)));
      final second = basis(area: 10, animals: 15);
      await service.save(first, farmTotalAreaHa: 50);
      await service.save(second, farmTotalAreaHa: 50);

      final latest = await service.loadLatest(
        tenantId: 'tenant-a',
        companyId: 'company-a',
        farmId: 'farm-a',
      );
      expect(latest?.animalsPerHectare, 1.5);
      expect(latest?.effectiveAreaHa, 10);
      expect(
        await service.loadHistory(
          tenantId: 'tenant-a',
          companyId: 'company-a',
          farmId: 'farm-a',
        ),
        hasLength(2),
      );
    },
  );

  test('não mistura empresa, tenant ou fazenda no mesmo dispositivo', () async {
    final service = AtlasPastureGrazingBasisService();
    await service.save(basis());
    for (final scope in [
      ('tenant-b', 'company-a', 'farm-a'),
      ('tenant-a', 'company-b', 'farm-a'),
      ('tenant-a', 'company-a', 'farm-b'),
    ]) {
      expect(
        await service.loadLatest(
          tenantId: scope.$1,
          companyId: scope.$2,
          farmId: scope.$3,
        ),
        isNull,
      );
    }
  });

  test(
    'não aceita área sobreposta não confirmada, inválida ou acima da fazenda',
    () async {
      final service = AtlasPastureGrazingBasisService();
      for (final invalid in [
        basis(confirmed: false),
        basis(area: 0),
        basis(area: double.nan),
        basis(area: 51),
        basis(animals: 0),
      ]) {
        await expectLater(
          service.save(invalid, farmTotalAreaHa: 50),
          throwsArgumentError,
        );
      }
      expect(
        await service.loadHistory(
          tenantId: 'tenant-a',
          companyId: 'company-a',
          farmId: 'farm-a',
        ),
        isEmpty,
      );
    },
  );

  test('índice deixa de ser atual após sete dias', () {
    final current = basis(at: DateTime(2026, 9, 20));
    expect(current.isCurrentAt(DateTime(2026, 9, 27)), isTrue);
    expect(current.isCurrentAt(DateTime(2026, 9, 28)), isFalse);
    expect(current.isCurrentAt(DateTime(2026, 9, 19)), isFalse);
  });

  test(
    'gravações simultâneas por duas instâncias preservam todo histórico',
    () async {
      final records = List.generate(20, (i) => basis(animals: i + 1));
      await Future.wait(
        records.map((item) => AtlasPastureGrazingBasisService().save(item)),
      );
      final history = await AtlasPastureGrazingBasisService().loadHistory(
        tenantId: 'tenant-a',
        companyId: 'company-a',
        farmId: 'farm-a',
      );
      expect(history, hasLength(20));
      expect(history.map((item) => item.operationId).toSet(), hasLength(20));
    },
  );

  test('repetir operação não duplica e divergência não sobrescreve', () async {
    final service = AtlasPastureGrazingBasisService();
    final record = basis();
    await service.save(record);
    await service.save(record);
    final changed = AtlasPastureGrazingBasis.fromMap({
      ...record.toMap(),
      'grazingAnimals': 99,
    });
    await expectLater(service.save(changed), throwsStateError);
    final history = await service.loadHistory(
      tenantId: 'tenant-a',
      companyId: 'company-a',
      farmId: 'farm-a',
    );
    expect(history, hasLength(1));
    expect(history.single.grazingAnimals, 30);
    await service.save(basis(animals: 40));
    expect(
      await service.loadHistory(
        tenantId: 'tenant-a',
        companyId: 'company-a',
        farmId: 'farm-a',
      ),
      hasLength(2),
    );
  });

  test(
    'registro legado ganha identidade determinística sem perder valores',
    () {
      final map = basis().toMap()..remove('operationId');
      final first = AtlasPastureGrazingBasis.fromMap(map);
      final second = AtlasPastureGrazingBasis.fromMap(map);
      expect(first.operationId, second.operationId);
      expect(first.animalsPerHectare, 1.5);
      expect(
        AtlasPastureGrazingBasis.fromMap(first.toMap()).operationId,
        first.operationId,
      );
    },
  );
}
