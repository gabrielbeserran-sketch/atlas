import 'dart:convert';
import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasActionPlanStorageService {
  AtlasActionPlanStorageService._();
  static final instance = AtlasActionPlanStorageService._();
  static const _key = 'atlas_action_plans_v1';

  Future<List<AtlasActionPlan>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      final plans = data.whereType<Map>().map((e) => AtlasActionPlan.fromJson(Map<String, dynamic>.from(e))).toList();
      plans.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return plans;
    } catch (_) { return []; }
  }

  Future<AtlasActionPlan?> latestForFarm(String farmId) async {
    final plans = await loadAll();
    for (final plan in plans) { if (plan.farmId == farmId) return plan; }
    return null;
  }

  Future<void> save(AtlasActionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final plans = await loadAll();
    plans.removeWhere((p) => p.id == plan.id || (p.farmId == plan.farmId && p.auditId == plan.auditId));
    plans.insert(0, plan);
    await prefs.setString(_key, jsonEncode(plans.take(50).map((p) => p.toJson()).toList()));
  }
}
