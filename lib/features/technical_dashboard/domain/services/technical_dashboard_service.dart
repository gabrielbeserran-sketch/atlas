import 'package:projeto_atlas/features/animal/data/services/animal_storage_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/farm_finance/data/services/farm_finance_storage_service.dart';
import 'package:projeto_atlas/features/farm_finance/domain/models/farm_finance_data.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_storage_service.dart';
import 'package:projeto_atlas/features/nutrition/data/services/nutrition_storage_service.dart';
import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_dashboard_analysis.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_dashboard_period.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_financial_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_farm_summary.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_health_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_inventory_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_nutrition_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_reproduction_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_weight_series_point.dart';

class TechnicalDashboardService {
  TechnicalDashboardService({
    HerdStorageService? herdStorage,
    AnimalStorageService? animalStorage,
    AnimalHealthStorageService? healthStorage,
    AnimalReproductionStorageService? reproductionStorage,
    NutritionStorageService? nutritionStorage,
    FarmFinanceStorageService? financeStorage,
    FarmInventoryStorageService? inventoryStorage,
    AnimalWeightStorageService? weightStorage,
  })  : _herdStorage = herdStorage ?? HerdStorageService(),
        _animalStorage = animalStorage ?? AnimalStorageService(),
        _healthStorage = healthStorage ?? AnimalHealthStorageService(),
        _reproductionStorage =
            reproductionStorage ?? AnimalReproductionStorageService(),
        _nutritionStorage = nutritionStorage ?? NutritionStorageService(),
        _financeStorage = financeStorage ?? FarmFinanceStorageService(),
        _inventoryStorage = inventoryStorage ?? FarmInventoryStorageService(),
        _weightStorage = weightStorage ?? AnimalWeightStorageService();

  final HerdStorageService _herdStorage;
  final AnimalStorageService _animalStorage;
  final AnimalHealthStorageService _healthStorage;
  final AnimalReproductionStorageService _reproductionStorage;
  final NutritionStorageService _nutritionStorage;
  final FarmFinanceStorageService _financeStorage;
  final FarmInventoryStorageService _inventoryStorage;
  final AnimalWeightStorageService _weightStorage;

  Future<TechnicalDashboardAnalysis> loadAnalysis(
    FarmData farm, {
    TechnicalDashboardPeriod period = TechnicalDashboardPeriod.last30Days,
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final groups = await _herdStorage.loadGroups(farm.name);
    final animals = <AnimalData>[];
    final healthRecords = <AnimalHealthData>[];
    final reproductionRecords = <AnimalReproductionData>[];
    final weightEntries = <_WeightEntry>[];

    for (final group in groups) {
      final groupAnimals = await _animalStorage.loadAnimals(
        farmName: farm.name,
        groupName: group.name,
      );
      animals.addAll(groupAnimals);

      for (final animal in groupAnimals) {
        healthRecords.addAll(
          await _healthStorage.loadRecords(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
          ),
        );
        reproductionRecords.addAll(
          await _reproductionStorage.loadRecords(
            farmName: farm.name,
            groupName: group.name,
            animalId: animal.id,
          ),
        );

        final weights = await _weightStorage.loadWeights(
          farmName: farm.name,
          groupName: group.name,
          animalId: animal.id,
        );
        for (final weight in weights) {
          weightEntries.add(
            _WeightEntry(animalId: animal.id, data: weight),
          );
        }
      }
    }

    final allPlans = await _nutritionStorage.loadPlans();
    final plans = allPlans.where((plan) => plan.farmName == farm.name).toList();
    final finances = await _financeStorage.loadRecords(farm.name);
    final inventory = await _inventoryStorage.loadItems(farm.name);

    TechnicalFarmSummary buildSummary(DateTime? start, DateTime? end) {
      return TechnicalFarmSummary.fromData(
        groups: groups,
        animals: animals,
        healthRecords: healthRecords,
        reproductionRecords: reproductionRecords,
        nutritionPlans: plans,
        finances: finances,
        inventory: inventory,
        referenceDate: now,
        periodStart: start,
        periodEnd: end,
      );
    }

    final current = buildSummary(period.startDate(now), period.endDate(now));
    final previousRange = period.previousRange(now);
    final previous = previousRange == null
        ? null
        : buildSummary(previousRange.start, previousRange.end);

    final financialSeries = _buildFinancialSeries(
      finances: finances,
      period: period,
      referenceDate: now,
    );

    final weightSeries = _buildWeightSeries(
      entries: weightEntries,
      period: period,
      referenceDate: now,
    );

    final reproductionSeries = _buildReproductionSeries(
      records: reproductionRecords,
      period: period,
      referenceDate: now,
    );

    final healthSeries = _buildHealthSeries(
      records: healthRecords,
      period: period,
      referenceDate: now,
    );

    final inventorySeries = _buildInventorySeries(
      items: inventory,
      period: period,
      referenceDate: now,
    );

    final nutritionSeries = _buildNutritionSeries(
      plans: plans,
      period: period,
      referenceDate: now,
    );

    return TechnicalDashboardAnalysis(
      period: period,
      generatedAt: now,
      current: current,
      financialSeries: financialSeries,
      weightSeries: weightSeries,
      reproductionSeries: reproductionSeries,
      healthSeries: healthSeries,
      inventorySeries: inventorySeries,
      nutritionSeries: nutritionSeries,
      previous: previous,
    );
  }

  Future<TechnicalFarmSummary> loadSummary(FarmData farm) async {
    final analysis = await loadAnalysis(
      farm,
      period: TechnicalDashboardPeriod.allHistory,
    );
    return analysis.current;
  }

  List<TechnicalFinancialSeriesPoint> _buildFinancialSeries({
    required List<FarmFinanceData> finances,
    required TechnicalDashboardPeriod period,
    required DateTime referenceDate,
  }) {
    final now = DateTime(referenceDate.year, referenceDate.month, 1);
    final firstMonth = switch (period) {
      TechnicalDashboardPeriod.last30Days =>
        DateTime(now.year, now.month - 5, 1),
      TechnicalDashboardPeriod.last90Days =>
        DateTime(now.year, now.month - 5, 1),
      TechnicalDashboardPeriod.currentYear => DateTime(now.year, 1, 1),
      TechnicalDashboardPeriod.allHistory =>
        _firstVisibleHistoryMonth(finances, now),
    };

    final points = <TechnicalFinancialSeriesPoint>[];
    var cursor = firstMonth;
    while (!cursor.isAfter(now)) {
      final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
      double income = 0;
      double expenses = 0;

      for (final record in finances) {
        if (record.status == 'Cancelado') continue;
        final date = _parseFinanceDate(record.date);
        if (date == null || date.isBefore(cursor) || !date.isBefore(nextMonth)) {
          continue;
        }
        if (record.isIncome) {
          income += record.amount;
        } else if (record.isExpense) {
          expenses += record.amount;
        }
      }

      points.add(
        TechnicalFinancialSeriesPoint(
          periodStart: cursor,
          label: _monthLabel(cursor),
          income: income,
          expenses: expenses,
        ),
      );
      cursor = nextMonth;
    }

    return points;
  }

  List<TechnicalWeightSeriesPoint> _buildWeightSeries({
    required List<_WeightEntry> entries,
    required TechnicalDashboardPeriod period,
    required DateTime referenceDate,
  }) {
    final validEntries = entries
        .map((entry) => (entry: entry, date: _parseWeightDate(entry.data.date)))
        .where((item) => item.date != null)
        .map((item) => (entry: item.entry, date: item.date!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (validEntries.isEmpty) return const [];

    final currentMonth = DateTime(referenceDate.year, referenceDate.month, 1);
    final firstMonth = switch (period) {
      TechnicalDashboardPeriod.last30Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.last90Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.currentYear => DateTime(currentMonth.year, 1, 1),
      TechnicalDashboardPeriod.allHistory =>
        _firstVisibleWeightMonth(validEntries.first.date, currentMonth),
    };

    final points = <TechnicalWeightSeriesPoint>[];
    var cursor = firstMonth;
    while (!cursor.isAfter(currentMonth)) {
      final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
      final monthEntries = validEntries
          .where((item) =>
              !item.date.isBefore(cursor) && item.date.isBefore(nextMonth))
          .toList();

      if (monthEntries.isNotEmpty) {
        final total = monthEntries.fold<double>(
          0,
          (sum, item) => sum + item.entry.data.weight,
        );
        final animalIds = monthEntries
            .map((item) => item.entry.animalId)
            .toSet();
        points.add(
          TechnicalWeightSeriesPoint(
            periodStart: cursor,
            label: _monthLabel(cursor),
            averageWeight: total / monthEntries.length,
            measurementCount: monthEntries.length,
            animalCount: animalIds.length,
          ),
        );
      }
      cursor = nextMonth;
    }

    return points;
  }


  List<TechnicalReproductionSeriesPoint> _buildReproductionSeries({
    required List<AnimalReproductionData> records,
    required TechnicalDashboardPeriod period,
    required DateTime referenceDate,
  }) {
    final validRecords = records
        .map((record) => (record: record, date: _parseReproductionDate(record.date)))
        .where((item) => item.date != null)
        .map((item) => (record: item.record, date: item.date!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (validRecords.isEmpty) return const [];

    final currentMonth = DateTime(referenceDate.year, referenceDate.month, 1);
    final firstMonth = switch (period) {
      TechnicalDashboardPeriod.last30Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.last90Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.currentYear => DateTime(currentMonth.year, 1, 1),
      TechnicalDashboardPeriod.allHistory =>
        _firstVisibleReproductionMonth(validRecords.first.date, currentMonth),
    };

    final points = <TechnicalReproductionSeriesPoint>[];
    var cursor = firstMonth;
    while (!cursor.isAfter(currentMonth)) {
      final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
      final monthRecords = validRecords
          .where((item) =>
              !item.date.isBefore(cursor) && item.date.isBefore(nextMonth))
          .map((item) => item.record)
          .toList();

      final inseminations = monthRecords.where((record) => record.isInsemination).length;
      final positivePregnancies =
          monthRecords.where((record) => record.isPositivePregnancyDiagnosis).length;
      final births = monthRecords.where((record) {
        final type = record.type.toLowerCase();
        return type.contains('parto') || type.contains('nascimento');
      }).length;

      points.add(
        TechnicalReproductionSeriesPoint(
          periodStart: cursor,
          label: _monthLabel(cursor),
          totalRecords: monthRecords.length,
          inseminations: inseminations,
          positivePregnancies: positivePregnancies,
          births: births,
        ),
      );
      cursor = nextMonth;
    }

    return points;
  }

  List<TechnicalHealthSeriesPoint> _buildHealthSeries({
    required List<AnimalHealthData> records,
    required TechnicalDashboardPeriod period,
    required DateTime referenceDate,
  }) {
    final validRecords = records
        .map((record) => (record: record, date: _parseHealthDate(record.date)))
        .where((item) => item.date != null)
        .map((item) => (record: item.record, date: item.date!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (validRecords.isEmpty) return const [];

    final currentMonth = DateTime(referenceDate.year, referenceDate.month, 1);
    final firstMonth = switch (period) {
      TechnicalDashboardPeriod.last30Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.last90Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.currentYear => DateTime(currentMonth.year, 1, 1),
      TechnicalDashboardPeriod.allHistory =>
        _firstVisibleHealthMonth(validRecords.first.date, currentMonth),
    };

    final points = <TechnicalHealthSeriesPoint>[];
    var cursor = firstMonth;
    while (!cursor.isAfter(currentMonth)) {
      final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
      final monthRecords = validRecords
          .where((item) =>
              !item.date.isBefore(cursor) && item.date.isBefore(nextMonth))
          .map((item) => item.record)
          .toList();

      int countType(String type) => monthRecords
          .where((record) => record.type.trim().toLowerCase() == type)
          .length;

      final mortalities = monthRecords.where((record) {
        final type = record.type.trim().toLowerCase();
        return record.isMortality || type == 'mortalidade';
      }).length;

      points.add(
        TechnicalHealthSeriesPoint(
          periodStart: cursor,
          label: _monthLabel(cursor),
          totalRecords: monthRecords.length,
          vaccinations: countType('vacinação'),
          treatments: countType('tratamento'),
          exams: countType('exame'),
          mortalities: mortalities,
        ),
      );
      cursor = nextMonth;
    }

    return points;
  }

  List<TechnicalInventorySeriesPoint> _buildInventorySeries({
    required List<FarmInventoryData> items,
    required TechnicalDashboardPeriod period,
    required DateTime referenceDate,
  }) {
    final movements = <_InventoryMovementEntry>[];
    for (final item in items) {
      for (final movement in item.movements) {
        final date = _parseInventoryDate(movement.date);
        if (date != null) {
          movements.add(_InventoryMovementEntry(data: movement, date: date));
        }
      }
    }
    movements.sort((a, b) => a.date.compareTo(b.date));

    if (movements.isEmpty) return const [];

    final currentMonth = DateTime(referenceDate.year, referenceDate.month, 1);
    final firstMonth = switch (period) {
      TechnicalDashboardPeriod.last30Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.last90Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.currentYear => DateTime(currentMonth.year, 1, 1),
      TechnicalDashboardPeriod.allHistory =>
        _firstVisibleInventoryMonth(movements.first.date, currentMonth),
    };

    final points = <TechnicalInventorySeriesPoint>[];
    var cursor = firstMonth;
    while (!cursor.isAfter(currentMonth)) {
      final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
      final monthMovements = movements.where((entry) {
        return !entry.date.isBefore(cursor) && entry.date.isBefore(nextMonth);
      }).toList();

      double entries = 0;
      double exits = 0;
      double entryValue = 0;
      double exitValue = 0;

      for (final entry in monthMovements) {
        final movement = entry.data;
        final type = movement.type.trim().toLowerCase();
        final value = movement.quantity * movement.unitValue;
        if (type.contains('entrada')) {
          entries += movement.quantity;
          entryValue += value;
        } else if (type.contains('saída') || type.contains('saida')) {
          exits += movement.quantity;
          exitValue += value;
        }
      }

      points.add(
        TechnicalInventorySeriesPoint(
          periodStart: cursor,
          label: _monthLabel(cursor),
          entries: entries,
          exits: exits,
          entryValue: entryValue,
          exitValue: exitValue,
        ),
      );
      cursor = nextMonth;
    }

    return points;
  }


  List<TechnicalNutritionSeriesPoint> _buildNutritionSeries({
    required List<NutritionPlanData> plans,
    required TechnicalDashboardPeriod period,
    required DateTime referenceDate,
  }) {
    final datedPlans = plans
        .map((plan) => (plan: plan, date: _parseNutritionDate(plan.startDate)))
        .where((item) => item.date != null)
        .map((item) => (plan: item.plan, date: item.date!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (datedPlans.isEmpty) return const [];

    final currentMonth = DateTime(referenceDate.year, referenceDate.month, 1);
    final firstMonth = switch (period) {
      TechnicalDashboardPeriod.last30Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.last90Days =>
        DateTime(currentMonth.year, currentMonth.month - 5, 1),
      TechnicalDashboardPeriod.currentYear => DateTime(currentMonth.year, 1, 1),
      TechnicalDashboardPeriod.allHistory =>
        _firstVisibleNutritionMonth(datedPlans.first.date, currentMonth),
    };

    final points = <TechnicalNutritionSeriesPoint>[];
    var cursor = firstMonth;
    while (!cursor.isAfter(currentMonth)) {
      final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
      final activePlans = datedPlans.where((item) => item.date.isBefore(nextMonth));
      var planCount = 0;
      var animalCount = 0;
      var dailyFeedKg = 0.0;
      var dailyCost = 0.0;

      for (final item in activePlans) {
        planCount++;
        animalCount += item.plan.animalCount;
        dailyFeedKg += item.plan.totalDailyKg;
        dailyCost += item.plan.dailyCost;
      }

      points.add(
        TechnicalNutritionSeriesPoint(
          periodStart: cursor,
          label: _monthLabel(cursor),
          planCount: planCount,
          animalCount: animalCount,
          dailyFeedKg: dailyFeedKg,
          dailyCost: dailyCost,
        ),
      );
      cursor = nextMonth;
    }

    return points;
  }

  DateTime _firstVisibleNutritionMonth(
    DateTime oldestPlan,
    DateTime currentMonth,
  ) {
    final twelveMonthsAgo =
        DateTime(currentMonth.year, currentMonth.month - 11, 1);
    final oldest = DateTime(oldestPlan.year, oldestPlan.month, 1);
    return oldest.isBefore(twelveMonthsAgo) ? twelveMonthsAgo : oldest;
  }

  DateTime? _parseNutritionDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = trimmed.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _firstVisibleInventoryMonth(
    DateTime oldestMovement,
    DateTime currentMonth,
  ) {
    final twelveMonthsAgo =
        DateTime(currentMonth.year, currentMonth.month - 11, 1);
    final oldest = DateTime(oldestMovement.year, oldestMovement.month, 1);
    return oldest.isBefore(twelveMonthsAgo) ? twelveMonthsAgo : oldest;
  }

  DateTime? _parseInventoryDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = trimmed.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _firstVisibleHealthMonth(
    DateTime oldestRecord,
    DateTime currentMonth,
  ) {
    final twelveMonthsAgo =
        DateTime(currentMonth.year, currentMonth.month - 11, 1);
    final oldest = DateTime(oldestRecord.year, oldestRecord.month, 1);
    return oldest.isBefore(twelveMonthsAgo) ? twelveMonthsAgo : oldest;
  }

  DateTime? _parseHealthDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = trimmed.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _firstVisibleReproductionMonth(
    DateTime oldestRecord,
    DateTime currentMonth,
  ) {
    final twelveMonthsAgo =
        DateTime(currentMonth.year, currentMonth.month - 11, 1);
    final oldest = DateTime(oldestRecord.year, oldestRecord.month, 1);
    return oldest.isBefore(twelveMonthsAgo) ? twelveMonthsAgo : oldest;
  }

  DateTime? _parseReproductionDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = trimmed.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _firstVisibleWeightMonth(
    DateTime oldestWeight,
    DateTime currentMonth,
  ) {
    final twelveMonthsAgo =
        DateTime(currentMonth.year, currentMonth.month - 11, 1);
    final oldest = DateTime(oldestWeight.year, oldestWeight.month, 1);
    return oldest.isBefore(twelveMonthsAgo) ? twelveMonthsAgo : oldest;
  }

  DateTime? _parseWeightDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = trimmed.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _firstVisibleHistoryMonth(
    List<FarmFinanceData> finances,
    DateTime currentMonth,
  ) {
    final validDates = finances
        .map((record) => _parseFinanceDate(record.date))
        .whereType<DateTime>()
        .toList()
      ..sort();
    final twelveMonthsAgo =
        DateTime(currentMonth.year, currentMonth.month - 11, 1);
    if (validDates.isEmpty) return twelveMonthsAgo;
    final oldest = DateTime(validDates.first.year, validDates.first.month, 1);
    return oldest.isBefore(twelveMonthsAgo) ? twelveMonthsAgo : oldest;
  }

  DateTime? _parseFinanceDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = trimmed.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _monthLabel(DateTime date) {
    const months = <String>[
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return '${months[date.month - 1]}/${date.year.toString().substring(2)}';
  }


}

class _WeightEntry {
  const _WeightEntry({required this.animalId, required this.data});

  final String animalId;
  final AnimalWeightData data;
}

class _InventoryMovementEntry {
  const _InventoryMovementEntry({required this.data, required this.date});

  final FarmInventoryMovement data;
  final DateTime date;
}
