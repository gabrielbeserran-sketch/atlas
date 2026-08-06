import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_nutrition_models.dart';

class AtlasNutritionService {
  AtlasNutritionService._();
  static final instance = AtlasNutritionService._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const _ingredientsKey = 'atlas_feed_ingredients_v1';
  static const _dietsKey = 'atlas_diet_plans_v1';
  static const _consumptionKey = 'atlas_feed_consumption_v1';

  Future<List<AtlasFeedIngredient>> loadIngredients({String? farmName}) async {
    final raw = await _prefs.getString(_ingredientsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => AtlasFeedIngredient.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return _farm(list, farmName, (e) => e.farmName);
  }

  Future<void> saveIngredient(AtlasFeedIngredient value) async {
    final all = await loadIngredients();
    final index = all.indexWhere((e) => e.id == value.id);
    if (index < 0) {
      all.add(value);
    } else {
      all[index] = value;
    }
    await _prefs.setString(
      _ingredientsKey,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  Future<List<AtlasDietPlan>> loadDiets({String? farmName}) async {
    final raw = await _prefs.getString(_dietsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => AtlasDietPlan.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return _farm(list, farmName, (e) => e.farmName);
  }

  Future<void> saveDiet(AtlasDietPlan value) async {
    final all = await loadDiets();
    final index = all.indexWhere((e) => e.id == value.id);
    if (index < 0) {
      all.add(value);
    } else {
      all[index] = value;
    }
    await _prefs.setString(
      _dietsKey,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  Future<List<AtlasFeedConsumptionRecord>> loadConsumption({
    String? farmName,
  }) async {
    final raw = await _prefs.getString(_consumptionKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => AtlasFeedConsumptionRecord.fromMap(
              Map<String, dynamic>.from(e)))
        .toList();
    final result = _farm(list, farmName, (e) => e.farmName);
    result.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return result;
  }

  Future<void> saveConsumption(AtlasFeedConsumptionRecord value) async {
    final all = await loadConsumption();
    final index = all.indexWhere((e) => e.id == value.id);
    if (index < 0) {
      all.add(value);
    } else {
      all[index] = value;
    }
    await _prefs.setString(
      _consumptionKey,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  double dietCost(
    AtlasDietPlan diet,
    List<AtlasFeedIngredient> ingredients,
  ) {
    final map = {for (final e in ingredients) e.id: e};
    return diet.ingredients.fold(
      0,
      (sum, item) =>
          sum +
          item.quantityKgPerAnimalDay *
              (map[item.ingredientId]?.costPerKg ?? 0),
    );
  }

  List<String> alerts(
    List<AtlasFeedIngredient> ingredients,
    List<AtlasFeedConsumptionRecord> records,
  ) {
    final result = <String>[
      for (final item in ingredients)
        if (item.needsRestock)
          '${item.name}: estoque baixo (${item.stockKg.toStringAsFixed(1)} kg).',
      for (final item in records)
        if (item.feedConversion > 12)
          '${item.lotName}: conversão alimentar elevada.',
    ];
    return result.isEmpty
        ? ['Nenhum alerta nutricional crítico.']
        : result.toSet().toList();
  }

  List<T> _farm<T>(
    List<T> values,
    String? farmName,
    String? Function(T) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return values;
    return values
        .where((e) => readFarm(e)?.trim().toLowerCase() == normalized)
        .toList();
  }
}
