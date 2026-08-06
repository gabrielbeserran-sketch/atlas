import 'dart:convert';

import 'package:projeto_atlas/features/strategy_execution/domain/models/atlas_strategy_execution_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasStrategyExecutionRepository {
  AtlasStrategyExecutionRepository._();

  static final AtlasStrategyExecutionRepository instance =
      AtlasStrategyExecutionRepository._();

  static const String _storageKey =
      'atlas_strategy_execution_plans_v1';

  Future<List<AtlasStrategyExecutionPlan>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return <AtlasStrategyExecutionPlan>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <AtlasStrategyExecutionPlan>[];
      }

      final plans = decoded
          .whereType<Map>()
          .map(
            (item) => AtlasStrategyExecutionPlan.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      plans.sort(
        (first, second) =>
            second.createdAt.compareTo(first.createdAt),
      );

      return plans;
    } catch (_) {
      return <AtlasStrategyExecutionPlan>[];
    }
  }

  Future<void> save(
    AtlasStrategyExecutionPlan plan,
  ) async {
    final plans = await loadAll();
    final index =
        plans.indexWhere((item) => item.id == plan.id);

    if (index >= 0) {
      plans[index] = plan;
    } else {
      plans.insert(0, plan);
    }

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        plans.take(100).map((item) => item.toJson()).toList(),
      ),
    );
  }

  Future<AtlasStrategyExecutionPlan?> findByScenario(
    String scenarioId,
  ) async {
    final plans = await loadAll();

    for (final plan in plans) {
      if (plan.sourceScenarioId == scenarioId) {
        return plan;
      }
    }

    return null;
  }
}
