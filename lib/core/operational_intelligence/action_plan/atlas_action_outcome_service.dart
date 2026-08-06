import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_outcome.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasActionOutcomeService {
  AtlasActionOutcomeService._();

  static final AtlasActionOutcomeService instance =
      AtlasActionOutcomeService._();

  static const String _storageKey =
      'atlas_action_outcomes_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasActionOutcome>> load({
    String? farmName,
  }) async {
    final all = await _loadAll();
    final normalizedFarm =
        farmName?.trim().toLowerCase();

    final filtered = all.where((outcome) {
      if (normalizedFarm == null ||
          normalizedFarm.isEmpty) {
        return true;
      }

      return outcome.farmName?.trim().toLowerCase() ==
          normalizedFarm;
    }).toList()
      ..sort(
        (first, second) =>
            second.updatedAt.compareTo(first.updatedAt),
      );

    return filtered;
  }

  Future<AtlasActionOutcome?> findByAction(
    String actionId,
  ) async {
    final all = await _loadAll();

    for (final outcome in all) {
      if (outcome.actionId == actionId) {
        return outcome;
      }
    }

    return null;
  }

  Future<AtlasActionOutcome> save({
    required AtlasCommandCenterAction action,
    required String technicalResult,
    required String lessonsLearned,
    required String evidence,
    required double realizedFinancialImpact,
    required double executionCost,
    required double revenueGenerated,
    required double savingsGenerated,
  }) async {
    final now = DateTime.now();
    final all = await _loadAll();
    final index = all.indexWhere(
      (item) => item.actionId == action.id,
    );

    final previous = index == -1 ? null : all[index];

    final outcome = AtlasActionOutcome(
      id: previous?.id ??
          'action_outcome_${now.microsecondsSinceEpoch}',
      actionId: action.id,
      farmName: action.farmName,
      technicalResult: technicalResult.trim(),
      lessonsLearned: lessonsLearned.trim(),
      evidence: evidence.trim(),
      expectedFinancialImpact:
          action.expectedFinancialImpact,
      realizedFinancialImpact:
          realizedFinancialImpact,
      executionCost: executionCost,
      revenueGenerated: revenueGenerated,
      savingsGenerated: savingsGenerated,
      recordedAt: previous?.recordedAt ?? now,
      updatedAt: now,
    );

    if (index == -1) {
      all.add(outcome);
    } else {
      all[index] = outcome;
    }

    await _saveAll(all);
    await _publish(action, outcome);
    return outcome;
  }

  Future<void> deleteByAction(String actionId) async {
    final all = await _loadAll()
      ..removeWhere(
        (outcome) => outcome.actionId == actionId,
      );

    await _saveAll(all);
  }

  Future<List<AtlasActionOutcome>> _loadAll() async {
    final encoded =
        await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasActionOutcome>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasActionOutcome.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasActionOutcome>[];
    }
  }

  Future<void> _saveAll(
    List<AtlasActionOutcome> outcomes,
  ) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(
        outcomes.map((item) => item.toMap()).toList(),
      ),
    );
  }

  Future<void> _publish(
    AtlasCommandCenterAction action,
    AtlasActionOutcome outcome,
  ) async {
    await AtlasEventBus.instance.publish(
      AtlasEvent(
        id: 'action_outcome_${outcome.id}_'
            '${DateTime.now().microsecondsSinceEpoch}',
        type: AtlasEventType.systemUpdated,
        sourceModule: 'action_results_intelligence',
        title: 'Resultado da ação registrado',
        description:
            'A ação "${action.title}" recebeu resultado '
            'técnico e financeiro.',
        occurredAt: DateTime.now(),
        priority: AtlasEventPriority.normal,
        farmName: action.farmName,
        entityId: action.id,
        entityType: 'command_center_action',
        payload: <String, dynamic>{
          'outcomeId': outcome.id,
          'expectedFinancialImpact':
              outcome.expectedFinancialImpact,
          'realizedFinancialImpact':
              outcome.realizedFinancialImpact,
          'executionCost': outcome.executionCost,
          'netFinancialResult':
              outcome.netFinancialResult,
          'roiPercent': outcome.roiPercent,
        },
        tags: const <String>[
          'command_center',
          'action_result',
          'financial_intelligence',
        ],
      ),
    );
  }
}
