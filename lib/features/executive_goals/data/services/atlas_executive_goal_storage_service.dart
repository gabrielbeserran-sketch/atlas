import 'dart:convert';

import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutiveGoalStorageService {
  const AtlasExecutiveGoalStorageService();

  static const String _storageKey = 'atlas_executive_goals_v1';

  static const int maximumGoals = 500;

  Future<List<AtlasExecutiveGoal>> load() async {
    final preferences = await SharedPreferences.getInstance();

    final value = preferences.getString(_storageKey);

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      final goals = decoded
          .whereType<Map>()
          .map((item) {
            return AtlasExecutiveGoal.fromJson(Map<String, dynamic>.from(item));
          })
          .where((item) {
            return item.id.trim().isNotEmpty && item.farmName.trim().isNotEmpty;
          })
          .take(maximumGoals)
          .toList();

      goals.sort(
        (first, second) => second.updatedAt.compareTo(first.updatedAt),
      );

      return goals;
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<AtlasExecutiveGoal> goals) async {
    final preferences = await SharedPreferences.getInstance();

    final ordered = [...goals]
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));

    final limited = ordered.take(maximumGoals).toList();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        limited.map((item) {
          return item.toJson();
        }).toList(),
      ),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }
}
