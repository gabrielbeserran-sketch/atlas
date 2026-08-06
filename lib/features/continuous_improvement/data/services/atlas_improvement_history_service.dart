import 'dart:convert';

import 'package:projeto_atlas/features/continuous_improvement/domain/models/atlas_improvement_cycle.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasImprovementHistoryService {
  AtlasImprovementHistoryService._();

  static final AtlasImprovementHistoryService instance =
      AtlasImprovementHistoryService._();

  static const String _storageKey =
      'atlas_improvement_cycles_v1';

  Future<List<AtlasImprovementCycle>> loadAll() async {
    final preferences =
        await SharedPreferences.getInstance();

    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return <AtlasImprovementCycle>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <AtlasImprovementCycle>[];
      }

      final cycles = decoded
          .whereType<Map>()
          .map(
            (item) => AtlasImprovementCycle.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      cycles.sort(
        (first, second) =>
            second.generatedAt.compareTo(first.generatedAt),
      );

      return cycles;
    } catch (_) {
      return <AtlasImprovementCycle>[];
    }
  }

  Future<List<AtlasImprovementCycle>> byFarmId(
    String farmId,
  ) async {
    final all = await loadAll();

    return all
        .where((item) => item.farmId == farmId)
        .toList();
  }

  Future<void> save(
    AtlasImprovementCycle cycle,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final current = await loadAll();

    current.removeWhere((item) => item.id == cycle.id);
    current.insert(0, cycle);

    await preferences.setString(
      _storageKey,
      jsonEncode(
        current
            .take(100)
            .map((item) => item.toJson())
            .toList(),
      ),
    );
  }
}
