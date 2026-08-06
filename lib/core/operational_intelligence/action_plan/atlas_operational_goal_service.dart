import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasOperationalGoalService {
  AtlasOperationalGoalService._();

  static final AtlasOperationalGoalService instance =
      AtlasOperationalGoalService._();

  static const String _storageKey =
      'atlas_operational_goals_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasOperationalGoal>> load({
    String? farmName,
    bool includeInactive = false,
  }) async {
    final all = await _loadAll();
    final normalizedFarm =
        farmName?.trim().toLowerCase();

    final filtered = all.where((goal) {
      final matchesFarm = normalizedFarm == null ||
          normalizedFarm.isEmpty ||
          goal.farmName?.trim().toLowerCase() ==
              normalizedFarm;
      final matchesActive =
          includeInactive || goal.active;

      return matchesFarm && matchesActive;
    }).toList()
      ..sort((first, second) {
        if (first.isOverdue != second.isOverdue) {
          return first.isOverdue ? -1 : 1;
        }

        return first.endAt.compareTo(second.endAt);
      });

    return filtered;
  }

  Future<AtlasOperationalGoal> save(
    AtlasOperationalGoal goal,
  ) async {
    final all = await _loadAll();
    final index = all.indexWhere(
      (item) => item.id == goal.id,
    );

    final updated = goal.copyWith(
      updatedAt: DateTime.now(),
    );

    if (index == -1) {
      all.add(updated);
    } else {
      all[index] = updated;
    }

    await _saveAll(all);
    return updated;
  }

  Future<void> delete(String id) async {
    final all = await _loadAll()
      ..removeWhere((goal) => goal.id == id);

    await _saveAll(all);
  }

  Future<List<AtlasOperationalGoal>> _loadAll() async {
    final encoded =
        await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasOperationalGoal>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasOperationalGoal.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasOperationalGoal>[];
    }
  }

  Future<void> _saveAll(
    List<AtlasOperationalGoal> goals,
  ) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(
        goals.map((goal) => goal.toMap()).toList(),
      ),
    );
  }
}
