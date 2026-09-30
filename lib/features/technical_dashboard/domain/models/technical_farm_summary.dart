import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_return_schedule.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/services/dairy_reproduction_indicator_calculator.dart';
import 'package:projeto_atlas/features/dairy_production/domain/services/dairy_indicator_calculator.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';
import 'package:projeto_atlas/features/beef_production/domain/services/beef_herd_indicator_calculator.dart';

class TechnicalFarmSummary {
  const TechnicalFarmSummary({
    required this.groupCount,
    required this.totalAnimals,
    required this.activeAnimals,
    required this.activeAnimalsWithValidWeight,
    required this.soldAnimals,
    required this.averageWeight,
    required this.reproductionRecords,
    required this.positivePregnancies,
    required this.pendingReproductionEvents,
    required this.overdueReproductionEvents,
    required this.healthRecords,
    required this.overdueHealthReturns,
    required this.activeWithdrawals,
    required this.quarantines,
    required this.healthCost,
    required this.nutritionPlans,
    required this.nutritionAnimals,
    required this.dailyFeedKg,
    required this.dailyFeedCost,
    required this.income,
    required this.expenses,
    required this.overdueAccounts,
    required this.inventoryItems,
    required this.inventoryValue,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.inventoryMovements,
    required this.dairyReproduction,
    required this.areaHectares,
    required this.stockingRate,
    required this.liveWeightPerHectare,
    required this.dairyProduction,
    required this.beefHerd,
    this.latestDairySnapshot,
  });

  final int groupCount;
  final int totalAnimals;
  final int activeAnimals;
  final int activeAnimalsWithValidWeight;
  final int soldAnimals;
  final double averageWeight;
  final int reproductionRecords;
  final int positivePregnancies;
  final int pendingReproductionEvents;
  final int overdueReproductionEvents;
  final int healthRecords;
  final int overdueHealthReturns;
  final int activeWithdrawals;
  final int quarantines;
  final double healthCost;
  final int nutritionPlans;
  final int nutritionAnimals;
  final double dailyFeedKg;
  final double dailyFeedCost;
  final double income;
  final double expenses;
  final int overdueAccounts;
  final int inventoryItems;
  final double inventoryValue;
  final int lowStockItems;
  final int outOfStockItems;
  final int inventoryMovements;
  final DairyReproductionIndicators dairyReproduction;

  /// Área total da fazenda cadastrada; não representa área efetiva de pasto.
  final double? areaHectares;
  final double? stockingRate;
  final double? liveWeightPerHectare;
  final DairyProductionSummary dairyProduction;
  final BeefHerdIndicators beefHerd;
  final DairyHerdSnapshotData? latestDairySnapshot;

  int get activeAnimalsWithoutValidWeight =>
      activeAnimals - activeAnimalsWithValidWeight;

  double get balance => income - expenses;

  /// Alertas de cobertura: não interpretam desempenho; indicam se a base
  /// registrada sustenta os índices exibidos no painel de Leite.
  List<String> get dairyOperationalDataAlerts {
    final alerts = [
      ...dairyReproduction.dataQualityAlerts,
      ...dairyProduction.dataQualityAlerts,
    ];
    if (dairyProduction.recordedDays == 0) {
      alerts.add(
        'Registre ordenhas diárias para iniciar o indicador de produção.',
      );
    } else if (dairyProduction.recordedDays < 20) {
      alerts.add(
        'Cobertura de ${dairyProduction.recordedDays}/30 dias de ordenha; faltam ${20 - dairyProduction.recordedDays} para uma média minimamente representativa.',
      );
    }
    return alerts;
  }

  double get costPerActiveAnimal =>
      activeAnimals == 0 ? 0 : expenses / activeAnimals;

  int get totalAlerts =>
      overdueReproductionEvents +
      overdueHealthReturns +
      activeWithdrawals +
      quarantines +
      overdueAccounts +
      lowStockItems;

  factory TechnicalFarmSummary.fromData({
    required List<HerdGroupData> groups,
    required List<AnimalData> animals,
    required List<AnimalHealthData> healthRecords,
    required List<AnimalReproductionData> reproductionRecords,
    required List<NutritionPlanData> nutritionPlans,
    required List<FarmFinanceData> finances,
    required List<FarmInventoryData> inventory,
    double? farmArea,
    List<DairyDailyProductionData> dairyRecords = const [],
    List<DairyHerdSnapshotData> dairySnapshots = const [],
    DateTime? referenceDate,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final today = referenceDate ?? DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final normalizedStart = periodStart == null
        ? null
        : DateTime(periodStart.year, periodStart.month, periodStart.day);
    final normalizedEnd = periodEnd == null
        ? null
        : DateTime(periodEnd.year, periodEnd.month, periodEnd.day);

    bool isInsidePeriod(String value) {
      if (normalizedStart == null && normalizedEnd == null) {
        return true;
      }
      final date = _parseDate(value);
      if (date == null) {
        return false;
      }
      if (normalizedStart != null && date.isBefore(normalizedStart)) {
        return false;
      }
      if (normalizedEnd != null && date.isAfter(normalizedEnd)) {
        return false;
      }
      return true;
    }

    final periodHealthRecords = healthRecords
        .where((record) => isInsidePeriod(record.date))
        .toList();
    final periodReproductionRecords = reproductionRecords
        .where((record) => isInsidePeriod(record.date))
        .toList();
    final periodNutritionPlans = nutritionPlans
        .where((plan) => isInsidePeriod(plan.startDate))
        .toList();
    final periodFinances = finances
        .where((record) => isInsidePeriod(record.date))
        .toList();
    final animalCounts = <String, int>{};
    for (final animal in animals) {
      final id = animal.id.trim();
      animalCounts.update(id, (count) => count + 1, ifAbsent: () => 1);
    }
    final identifiedAnimals = animals.where((animal) {
      final id = animal.id.trim();
      return id.isNotEmpty && animalCounts[id] == 1;
    }).toList();
    final activeAnimals = identifiedAnimals
        .where((animal) => animal.status == 'Ativo')
        .toList();
    final weightedAnimals = activeAnimals
        .where((animal) => animal.weight.isFinite && animal.weight > 0)
        .toList();
    final averageWeight = weightedAnimals.isEmpty
        ? 0.0
        : weightedAnimals.fold<double>(
            0,
            (sum, animal) => sum + animal.weight / weightedAnimals.length,
          );
    final validArea = farmArea != null && farmArea.isFinite && farmArea > 0
        ? farmArea
        : null;
    final animalsPerHectare = validArea == null
        ? null
        : activeAnimals.length / validArea;
    final weightPerHectare =
        validArea == null ||
            activeAnimals.isEmpty ||
            weightedAnimals.length != activeAnimals.length
        ? null
        : weightedAnimals.fold<double>(
            0,
            (sum, animal) => sum + animal.weight / validArea,
          );

    bool isPast(String value) {
      final date = _parseDate(value);
      return date != null && date.isBefore(current);
    }

    bool isFutureOrToday(String value) {
      final date = _parseDate(value);
      return date != null && !date.isBefore(current);
    }

    final income = periodFinances
        .where((record) => record.isIncome && record.status != 'Cancelado')
        .fold<double>(0, (sum, record) => sum + record.amount);
    final expenses = periodFinances
        .where((record) => record.isExpense && record.status != 'Cancelado')
        .fold<double>(0, (sum, record) => sum + record.amount);
    final dairyReproduction = DairyReproductionIndicatorCalculator().calculate(
      animals: animals,
      records: reproductionRecords,
      referenceDate: today,
    );
    final dairyProduction = DairyIndicatorCalculator().summarize(
      dairyRecords,
      hectares: validArea ?? 0,
      lactatingCows: dairySnapshots.isEmpty
          ? null
          : dairySnapshots.first.lactatingCows,
      referenceDate: today,
    );
    final beefHerd = BeefHerdIndicatorCalculator().calculate(
      animals: animals,
      referenceDate: today,
    );
    final returnSchedule = ReproductionReturnSchedule.calculate(
      reproductionRecords,
      referenceDate: today,
    );

    return TechnicalFarmSummary(
      groupCount: groups.length,
      totalAnimals: animals.length,
      activeAnimals: activeAnimals.length,
      activeAnimalsWithValidWeight: weightedAnimals.length,
      soldAnimals: identifiedAnimals
          .where((animal) => animal.status == 'Vendido')
          .length,
      averageWeight: averageWeight,
      reproductionRecords: periodReproductionRecords.length,
      positivePregnancies: periodReproductionRecords
          .where((record) => record.isPositivePregnancyDiagnosis)
          .length,
      pendingReproductionEvents:
          returnSchedule.today +
          returnSchedule.nextSevenDays +
          returnSchedule.later,
      overdueReproductionEvents: returnSchedule.past,
      healthRecords: periodHealthRecords.length,
      overdueHealthReturns: healthRecords
          .where((record) => isPast(record.nextDate))
          .length,
      activeWithdrawals: healthRecords
          .where((record) => isFutureOrToday(record.withdrawalEndDate))
          .length,
      quarantines: healthRecords.where((record) => record.isQuarantine).length,
      healthCost: periodHealthRecords.fold<double>(
        0,
        (sum, record) => sum + record.treatmentCost,
      ),
      nutritionPlans: periodNutritionPlans.length,
      nutritionAnimals: periodNutritionPlans.fold<int>(
        0,
        (sum, plan) => sum + plan.animalCount,
      ),
      dailyFeedKg: periodNutritionPlans.fold<double>(
        0,
        (sum, plan) => sum + plan.totalDailyKg,
      ),
      dailyFeedCost: periodNutritionPlans.fold<double>(
        0,
        (sum, plan) => sum + plan.dailyCost,
      ),
      income: income,
      expenses: expenses,
      overdueAccounts: periodFinances
          .where((record) => record.isOverdue)
          .length,
      inventoryItems: inventory.length,
      inventoryValue: inventory.fold<double>(
        0,
        (sum, item) => sum + item.totalValue,
      ),
      lowStockItems: inventory.where((item) => item.hasLowStock).length,
      outOfStockItems: inventory.where((item) => item.isOutOfStock).length,
      inventoryMovements: inventory.fold<int>(
        0,
        (sum, item) => sum + item.movements.length,
      ),
      dairyReproduction: dairyReproduction,
      areaHectares: validArea,
      stockingRate: animalsPerHectare?.isFinite == true
          ? animalsPerHectare
          : null,
      liveWeightPerHectare: weightPerHectare?.isFinite == true
          ? weightPerHectare
          : null,
      dairyProduction: dairyProduction,
      beefHerd: beefHerd,
      latestDairySnapshot: dairySnapshots.isEmpty ? null : dairySnapshots.first,
    );
  }
}

DateTime? _parseDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final iso = RegExp(
    r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T ].+)?$',
  ).firstMatch(trimmed);
  if (iso != null && DateTime.tryParse(trimmed) != null) {
    return _strictDate(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }
  final br = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(trimmed);
  if (br == null) return null;
  return _strictDate(
    int.parse(br.group(3)!),
    int.parse(br.group(2)!),
    int.parse(br.group(1)!),
  );
}

DateTime? _strictDate(int year, int month, int day) {
  if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}
