import 'package:flutter_test/flutter_test.dart';
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
}
