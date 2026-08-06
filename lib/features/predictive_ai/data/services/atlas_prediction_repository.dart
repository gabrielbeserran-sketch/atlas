import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_predictive_scenario.dart';

class AtlasPredictionRepository {
  AtlasPredictionRepository._();
  static final AtlasPredictionRepository instance = AtlasPredictionRepository._();
  static const _key = 'atlas_predictive_ai_scenarios_v1';

  Future<List<AtlasPredictiveScenario>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final seeds = _seeds();
      await saveAll(seeds);
      return seeds;
    }
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => AtlasPredictiveScenario.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      final seeds = _seeds();
      await saveAll(seeds);
      return seeds;
    }
  }

  Future<void> save(AtlasPredictiveScenario scenario) async {
    final items = await loadAll();
    final index = items.indexWhere((e) => e.id == scenario.id);
    if (index >= 0) { items[index] = scenario; } else { items.add(scenario); }
    await saveAll(items);
  }

  Future<void> delete(String id) async {
    final items = await loadAll()..removeWhere((e) => e.id == id);
    await saveAll(items);
  }

  Future<void> saveAll(List<AtlasPredictiveScenario> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  List<AtlasPredictiveScenario> _seeds() => <AtlasPredictiveScenario>[
    AtlasPredictiveScenario(
      id: 'pred_${DateTime.now().millisecondsSinceEpoch}_1', farmId: '',
      title: 'Reforma de 30 hectares de pastagem',
      description: 'Avalia impacto da reforma sobre lotação, produtividade e resultado financeiro.',
      area: AtlasPredictionArea.production, createdAt: DateTime.now(),
      investment: 180000, currentRevenue: 145000, currentCost: 98000,
      productivityChange: 14, costChange: 6, revenueChange: 9,
      capacityChange: 12, horizonMonths: 24,
    ),
    AtlasPredictiveScenario(
      id: 'pred_${DateTime.now().millisecondsSinceEpoch}_2', farmId: '',
      title: 'Antecipação do protocolo de IATF',
      description: 'Projeta efeito reprodutivo e financeiro da antecipação do protocolo.',
      area: AtlasPredictionArea.reproduction, createdAt: DateTime.now(),
      investment: 52000, currentRevenue: 145000, currentCost: 98000,
      productivityChange: 8, costChange: 3, revenueChange: 5,
      capacityChange: 0, horizonMonths: 18,
    ),
  ];
}
