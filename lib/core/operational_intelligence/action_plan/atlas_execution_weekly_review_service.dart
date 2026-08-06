import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_weekly_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutionWeeklyReviewService {
  AtlasExecutionWeeklyReviewService._();

  static final AtlasExecutionWeeklyReviewService instance =
      AtlasExecutionWeeklyReviewService._();

  static const String _storageKey =
      'atlas_execution_weekly_reviews_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasExecutionWeeklyReview>> load({
    String? farmName,
  }) async {
    final all = await _loadAll();
    final normalizedFarm =
        farmName?.trim().toLowerCase();

    final filtered = all.where((review) {
      if (normalizedFarm == null ||
          normalizedFarm.isEmpty) {
        return true;
      }

      return review.farmName?.trim().toLowerCase() ==
          normalizedFarm;
    }).toList()
      ..sort(
        (first, second) =>
            second.generatedAt.compareTo(first.generatedAt),
      );

    return filtered;
  }

  Future<void> save(
    AtlasExecutionWeeklyReview review,
  ) async {
    final all = await _loadAll();
    all.removeWhere((item) => item.id == review.id);
    all.add(review);

    await _preferences.setString(
      _storageKey,
      jsonEncode(
        all.map((item) => item.toMap()).toList(),
      ),
    );

    await AtlasEventBus.instance.publish(
      AtlasEvent(
        id: 'weekly_review_${review.id}',
        type: AtlasEventType.systemUpdated,
        sourceModule: 'command_center_action_plan',
        title: 'Revisão semanal gerada',
        description:
            'A revisão semanal do plano de ação foi gerada com '
            '${review.completedInPeriod} conclusão(ões) e '
            '${review.overdueActions} atraso(s).',
        occurredAt: review.generatedAt,
        priority: review.overdueActions > 0 ||
                review.blockedActions > 0
            ? AtlasEventPriority.high
            : AtlasEventPriority.normal,
        farmName: review.farmName,
        entityId: review.id,
        entityType: 'execution_weekly_review',
        payload: <String, dynamic>{
          'totalActions': review.totalActions,
          'openActions': review.openActions,
          'completedInPeriod':
              review.completedInPeriod,
          'overdueActions': review.overdueActions,
          'blockedActions': review.blockedActions,
          'executionHealthPercent':
              review.executionHealthPercent,
        },
        tags: const <String>[
          'command_center',
          'action_plan',
          'weekly_review',
        ],
      ),
    );
  }

  Future<void> delete(String id) async {
    final all = await _loadAll()
      ..removeWhere((item) => item.id == id);

    await _preferences.setString(
      _storageKey,
      jsonEncode(
        all.map((item) => item.toMap()).toList(),
      ),
    );
  }

  Future<List<AtlasExecutionWeeklyReview>>
      _loadAll() async {
    final encoded =
        await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasExecutionWeeklyReview>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) =>
                AtlasExecutionWeeklyReview.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasExecutionWeeklyReview>[];
    }
  }
}
