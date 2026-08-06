import 'dart:convert';

import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NutritionStorageService {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static const String _storageKey = 'atlas_nutrition_plans';

  Future<List<NutritionPlanData>> loadPlans() async {
    final savedData = await _preferences.getString(_storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(savedData) as List<dynamic>;
      return decoded
          .map(
            (item) => NutritionPlanData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlans(List<NutritionPlanData> plans) async {
    final encoded = jsonEncode(plans.map((plan) => plan.toMap()).toList());
    await _preferences.setString(_storageKey, encoded);
  }
}
