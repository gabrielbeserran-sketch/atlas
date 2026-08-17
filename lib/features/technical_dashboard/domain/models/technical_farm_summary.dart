import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';

class TechnicalFarmSummary {
  const TechnicalFarmSummary({
    required this.groupCount,
    required this.totalAnimals,
    required this.activeAnimals,
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
  });

  final int groupCount;
  final int totalAnimals;
  final int activeAnimals;
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

  double get balance => income - expenses;

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
    final weightedAnimals = animals
        .where((animal) => animal.weight > 0)
        .toList();
    final averageWeight = weightedAnimals.isEmpty
        ? 0.0
        : weightedAnimals.fold<double>(
                0,
                (sum, animal) => sum + animal.weight,
              ) /
              weightedAnimals.length;

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

    return TechnicalFarmSummary(
      groupCount: groups.length,
      totalAnimals: animals.length,
      activeAnimals: animals.where((animal) => animal.status == 'Ativo').length,
      soldAnimals: animals.where((animal) => animal.status == 'Vendido').length,
      averageWeight: averageWeight,
      reproductionRecords: periodReproductionRecords.length,
      positivePregnancies: periodReproductionRecords
          .where((record) => record.isPositivePregnancyDiagnosis)
          .length,
      pendingReproductionEvents: reproductionRecords
          .where((record) => isFutureOrToday(record.expectedDate))
          .length,
      overdueReproductionEvents: reproductionRecords
          .where((record) => isPast(record.expectedDate))
          .length,
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
    );
  }
}

DateTime? _parseDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final iso = DateTime.tryParse(trimmed);
  if (iso != null) {
    return DateTime(iso.year, iso.month, iso.day);
  }

  final parts = trimmed.split('/');
  if (parts.length != 3) {
    return null;
  }

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }

  return DateTime(year, month, day);
}
