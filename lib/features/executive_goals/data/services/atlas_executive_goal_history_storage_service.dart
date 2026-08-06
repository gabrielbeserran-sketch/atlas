import 'dart:convert';

import 'package:projeto_atlas/features/executive_goals/domain/models/atlas_executive_goal_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutiveGoalHistoryStorageService {
  const AtlasExecutiveGoalHistoryStorageService();

  static const _key = 'atlas_executive_goal_history_v1';
  static const maximumEvents = 3000;

  Future<List<AtlasExecutiveGoalHistoryEvent>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);

    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final events = decoded
          .whereType<Map>()
          .map(
            (item) => AtlasExecutiveGoalHistoryEvent.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (item) =>
                item.id.trim().isNotEmpty &&
                item.goalId.trim().isNotEmpty,
          )
          .toList();

      events.sort(
        (a, b) => a.recordedAt.compareTo(b.recordedAt),
      );

      return events.length > maximumEvents
          ? events.sublist(events.length - maximumEvents)
          : events;
    } catch (_) {
      return [];
    }
  }

  Future<void> save(
    List<AtlasExecutiveGoalHistoryEvent> events,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final ordered = [...events]
      ..sort(
        (a, b) => a.recordedAt.compareTo(b.recordedAt),
      );

    final limited = ordered.length > maximumEvents
        ? ordered.sublist(ordered.length - maximumEvents)
        : ordered;

    await preferences.setString(
      _key,
      jsonEncode(
        limited.map((item) => item.toJson()).toList(),
      ),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
