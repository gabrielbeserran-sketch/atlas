import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_strategy_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasNutritionStrategyService {
  AtlasNutritionStrategyService._();

  static final AtlasNutritionStrategyService instance =
      AtlasNutritionStrategyService._();

  static const String _plansKey =
      'atlas_nutrition_annual_plans_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasNutritionAnnualPlan>> loadPlans({
    String? farmName,
  }) async {
    final raw = await _preferences.getString(_plansKey);
    if (raw == null || raw.trim().isEmpty) {
      return <AtlasNutritionAnnualPlan>[];
    }
    try {
      final values = (jsonDecode(raw) as List)
          .map(
            (item) => AtlasNutritionAnnualPlan.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final normalized = farmName?.trim().toLowerCase();
      if (normalized == null || normalized.isEmpty) {
        return values;
      }
      return values
          .where(
            (item) =>
                item.farmName?.trim().toLowerCase() ==
                normalized,
          )
          .toList();
    } catch (_) {
      return <AtlasNutritionAnnualPlan>[];
    }
  }

  Future<void> savePlan(
    AtlasNutritionAnnualPlan plan,
  ) async {
    final raw = await _preferences.getString(_plansKey);
    final values = raw == null || raw.trim().isEmpty
        ? <AtlasNutritionAnnualPlan>[]
        : (jsonDecode(raw) as List)
            .map(
              (item) => AtlasNutritionAnnualPlan.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

    final index =
        values.indexWhere((item) => item.id == plan.id);
    if (index == -1) {
      values.add(plan);
    } else {
      values[index] = plan;
    }

    await _preferences.setString(
      _plansKey,
      jsonEncode(values.map((item) => item.toMap()).toList()),
    );
  }

  Future<AtlasNutritionExecutiveSnapshot> buildSnapshot({
    String? farmName,
  }) async {
    final service = AtlasNutritionService.instance;
    final ingredients =
        await service.loadIngredients(farmName: farmName);
    final diets =
        await service.loadDiets(farmName: farmName);
    final records =
        await service.loadConsumption(farmName: farmName);

    final activeDiets =
        diets.where((item) => item.active).toList();
    final animals = activeDiets.fold<int>(
      0,
      (total, item) => total + item.animalCount,
    );
    final dailyCost = activeDiets.fold<double>(
      0,
      (total, item) =>
          total +
          service.dietCost(item, ingredients) *
              item.animalCount,
    );

    final avgGain = records.isEmpty
        ? 0.0
        : records
                .map((item) => item.averageDailyGainKg)
                .fold<double>(0, (a, b) => a + b) /
            records.length;

    final validConversion = records
        .where((item) => item.feedConversion > 0)
        .toList();
    final avgConversion = validConversion.isEmpty
        ? 0.0
        : validConversion
                .map((item) => item.feedConversion)
                .fold<double>(0, (a, b) => a + b) /
            validConversion.length;

    final avgConsumption = records.isEmpty
        ? 0.0
        : records
                .map((item) => item.consumptionPerAnimalKg)
                .fold<double>(0, (a, b) => a + b) /
            records.length;

    final offered = records.fold<double>(
      0,
      (total, item) => total + item.offeredKg,
    );
    final leftovers = records.fold<double>(
      0,
      (total, item) => total + item.leftoverKg,
    );
    final waste =
        offered <= 0 ? 0.0 : leftovers / offered * 100;

    final lowStock =
        ingredients.where((item) => item.needsRestock).length;

    var score = 70.0;
    if (avgGain > 0) {
      score += (avgGain - 0.8) * 15;
    }
    if (avgConversion > 0) {
      score -= (avgConversion - 8).clamp(0, 8) * 3;
    }
    score -= waste.clamp(0, 20);
    score -= lowStock * 4;

    return AtlasNutritionExecutiveSnapshot(
      activeDiets: activeDiets.length,
      totalAnimals: animals,
      dailyFeedCost: dailyCost,
      monthlyFeedCost: dailyCost * 30,
      averageDailyGainKg: avgGain,
      averageFeedConversion: avgConversion,
      averageConsumptionKg: avgConsumption,
      lowStockIngredients: lowStock,
      wastePercent: waste,
      nutritionScore: score.clamp(0, 100),
    );
  }

  Future<List<AtlasNutritionProjection>> buildProjections({
    String? farmName,
  }) async {
    final service = AtlasNutritionService.instance;
    final ingredients =
        await service.loadIngredients(farmName: farmName);
    final diets =
        await service.loadDiets(farmName: farmName);
    final records =
        await service.loadConsumption(farmName: farmName);

    final result = <AtlasNutritionProjection>[];

    for (final diet in diets.where((item) => item.active)) {
      final dietRecords =
          records.where((item) => item.dietId == diet.id).toList();

      final consumption = dietRecords.isEmpty
          ? diet.ingredients.fold<double>(
              0,
              (total, item) =>
                  total + item.quantityKgPerAnimalDay,
            )
          : dietRecords
                  .map((item) => item.consumptionPerAnimalKg)
                  .fold<double>(0, (a, b) => a + b) /
              dietRecords.length;

      final gain = dietRecords.isEmpty
          ? diet.targetDailyGainKg
          : dietRecords
                  .map((item) => item.averageDailyGainKg)
                  .fold<double>(0, (a, b) => a + b) /
              dietRecords.length;

      final dailyCost =
          service.dietCost(diet, ingredients) *
              diet.animalCount;

      var coverageDays = double.infinity;
      final ingredientMap = {
        for (final item in ingredients) item.id: item,
      };
      for (final item in diet.ingredients) {
        final stock = ingredientMap[item.ingredientId];
        final dailyUse =
            item.quantityKgPerAnimalDay * diet.animalCount;
        if (stock != null && dailyUse > 0) {
          final days = stock.stockKg / dailyUse;
          if (days < coverageDays) {
            coverageDays = days;
          }
        }
      }
      if (coverageDays == double.infinity) {
        coverageDays = 0;
      }

      result.add(
        AtlasNutritionProjection(
          lotName: diet.lotName,
          projectedConsumption30DaysKg:
              consumption * diet.animalCount * 30,
          projectedCost30Days: dailyCost * 30,
          projectedWeightGain30DaysKg:
              gain * diet.animalCount * 30,
          stockCoverageDays: coverageDays,
          riskLevel: coverageDays > 30
              ? 'Baixo'
              : coverageDays > 15
                  ? 'Moderado'
                  : 'Alto',
        ),
      );
    }

    return result;
  }

  Future<List<String>> buildRecommendations({
    required String? farmName,
    required AtlasNutritionExecutiveSnapshot snapshot,
  }) async {
    final recommendations = <String>[];

    if (snapshot.averageFeedConversion > 12) {
      recommendations.add(
        'Conversão alimentar elevada. Reavalie composição, adaptação e manejo de cocho.',
      );
    }
    if (snapshot.averageDailyGainKg > 0 &&
        snapshot.averageDailyGainKg < 0.7) {
      recommendations.add(
        'Ganho médio diário abaixo de 0,7 kg. Verifique energia, proteína, consumo e sanidade.',
      );
    }
    if (snapshot.wastePercent > 5) {
      recommendations.add(
        'Sobras acima de 5%. Ajuste oferta, frequência e leitura de cocho.',
      );
    }
    if (snapshot.lowStockIngredients > 0) {
      recommendations.add(
        '${snapshot.lowStockIngredients} ingrediente(s) estão abaixo do estoque mínimo.',
      );
    }
    if (snapshot.dailyFeedCost > 0 &&
        snapshot.totalAnimals > 0) {
      final perAnimal =
          snapshot.dailyFeedCost / snapshot.totalAnimals;
      if (perAnimal > 15) {
        recommendations.add(
          'Custo nutricional superior a R\$ 15 por animal/dia. Simule substituições de ingredientes.',
        );
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'A operação nutricional está equilibrada. Preserve leitura de cocho, controle de estoque e monitoramento de desempenho.',
      );
    }
    return recommendations;
  }
}
