import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_goal_action_link.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_operational_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasGoalActionLinkService {
  AtlasGoalActionLinkService._();

  static final AtlasGoalActionLinkService instance =
      AtlasGoalActionLinkService._();

  static const String _storageKey =
      'atlas_goal_action_links_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasGoalActionLink>> loadAll() async {
    final encoded =
        await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasGoalActionLink>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasGoalActionLink.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasGoalActionLink>[];
    }
  }

  Future<List<AtlasGoalActionLink>> loadByGoal(
    String goalId,
  ) async {
    final all = await loadAll();

    return all
        .where((link) => link.goalId == goalId)
        .toList(growable: false);
  }

  Future<void> replaceGoalLinks({
    required AtlasOperationalGoal goal,
    required Iterable<String> actionIds,
  }) async {
    final all = await loadAll()
      ..removeWhere((link) => link.goalId == goal.id);

    final now = DateTime.now();

    for (final actionId in actionIds.toSet()) {
      all.add(
        AtlasGoalActionLink(
          id: 'goal_action_${goal.id}_$actionId',
          goalId: goal.id,
          actionId: actionId,
          area: goal.area,
          createdAt: now,
        ),
      );
    }

    await _saveAll(all);
  }

  Future<void> removeGoal(String goalId) async {
    final all = await loadAll()
      ..removeWhere((link) => link.goalId == goalId);

    await _saveAll(all);
  }

  Future<void> _saveAll(
    List<AtlasGoalActionLink> links,
  ) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(
        links.map((link) => link.toMap()).toList(),
      ),
    );
  }
}
