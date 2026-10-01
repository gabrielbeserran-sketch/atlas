import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/nutrition/data/services/nutrition_storage_service.dart';
import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/services/technical_dashboard_service.dart';

class _EmptyHerd extends HerdStorageService {
  @override
  Future<List<HerdGroupData>> loadGroups(
    String farmName, {
    String farmId = '',
  }) async => const [];
}

class _EmptyNutrition extends NutritionStorageService {
  @override
  Future<List<NutritionPlanData>> loadPlans({
    String farmId = '',
    String farmName = '',
  }) async => const [];
}

class _EmptyFinance extends FarmFinanceStorageService {
  @override
  Future<List<FarmFinanceData>> loadRecords(
    String farmName, {
    String farmId = '',
  }) async => const [];
}

class _EmptyInventory extends FarmInventoryStorageService {
  @override
  Future<List<FarmInventoryData>> loadItems(
    String farmName, {
    String farmId = '',
  }) async => const [];
}

void main() {
  const farm = FarmData(
    id: 'f',
    name: 'Teste',
    city: '',
    state: '',
    animals: 10,
    area: 20,
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  TechnicalDashboardService service() => TechnicalDashboardService(
    herdStorage: _EmptyHerd(),
    nutritionStorage: _EmptyNutrition(),
    financeStorage: _EmptyFinance(),
    inventoryStorage: _EmptyInventory(),
  );

  test(
    'painel não transforma ordenhas ilegíveis em produção ausente',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('atlas_dairy_daily_production_f', 'corrompido');

      await expectLater(
        service().loadAnalysis(farm, referenceDate: DateTime(2026, 9, 26)),
        throwsFormatException,
      );
      expect(
        await prefs.getString('atlas_dairy_daily_production_f'),
        'corrompido',
      );
    },
  );

  test('painel mantém leitura normal da ordenha válida', () async {
    await DairyProductionStorageService().upsert(
      'f',
      DairyDailyProductionData(
        date: DateTime(2026, 9, 26),
        morningLiters: 100,
        afternoonLiters: 20,
        cowsMilked: 10,
      ),
    );

    final analysis = await service().loadAnalysis(
      farm,
      referenceDate: DateTime(2026, 9, 26),
    );
    expect(analysis.current.dairyProduction.recordedDays, 1);
    expect(analysis.current.dairyProduction.latestLiters, 120);
  });

  test('painel também recusa estado do lote ilegível sem apagá-lo', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(
      'atlas_dairy_herd_snapshot_f',
      '[{"date":"2026-02-30"}]',
    );

    await expectLater(
      service().loadAnalysis(farm, referenceDate: DateTime(2026, 9, 26)),
      throwsFormatException,
    );
    expect(
      await prefs.getString('atlas_dairy_herd_snapshot_f'),
      '[{"date":"2026-02-30"}]',
    );
  });
}
