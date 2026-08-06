import 'dart:convert';

import 'package:projeto_atlas/features/reports/domain/models/report_action_item_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportActionStorageService {
  static const String _storageKey = 'atlas_report_action_items';

  Future<List<ReportActionItemData>> loadActions() async {
    final preferences = await SharedPreferences.getInstance();

    final encodedActions = preferences.getString(_storageKey);

    if (encodedActions == null || encodedActions.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encodedActions);

      if (decoded is! List) {
        return [];
      }

      final actions = decoded
          .whereType<Map>()
          .map((item) {
            return ReportActionItemData.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .where((action) {
            return action.id.trim().isNotEmpty;
          })
          .toList();

      actions.sort(compareReportActions);

      return actions;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveActions(List<ReportActionItemData> actions) async {
    final preferences = await SharedPreferences.getInstance();

    final normalizedActions = List<ReportActionItemData>.from(actions)
      ..sort(compareReportActions);

    final encodedActions = jsonEncode(
      normalizedActions.map((action) {
        return action.toJson();
      }).toList(),
    );

    await preferences.setString(_storageKey, encodedActions);
  }

  Future<ReportActionItemData> addAction(ReportActionItemData action) async {
    final actions = await loadActions();

    final actionToSave = action.id.trim().isEmpty
        ? action.copyWith(id: createReportActionId())
        : action;

    actions.add(actionToSave);

    await saveActions(actions);

    return actionToSave;
  }

  Future<void> addActions(List<ReportActionItemData> newActions) async {
    if (newActions.isEmpty) {
      return;
    }

    final actions = await loadActions();

    final existingIds = actions.map((action) {
      return action.id;
    }).toSet();

    for (final action in newActions) {
      final actionToSave =
          action.id.trim().isEmpty || existingIds.contains(action.id)
          ? action.copyWith(id: createReportActionId())
          : action;

      actions.add(actionToSave);

      existingIds.add(actionToSave.id);
    }

    await saveActions(actions);
  }

  Future<void> updateAction(ReportActionItemData updatedAction) async {
    final actions = await loadActions();

    final index = actions.indexWhere((action) {
      return action.id == updatedAction.id;
    });

    if (index == -1) {
      actions.add(updatedAction);
    } else {
      actions[index] = updatedAction;
    }

    await saveActions(actions);
  }

  Future<void> deleteAction(String actionId) async {
    final actions = await loadActions();

    actions.removeWhere((action) {
      return action.id == actionId;
    });

    await saveActions(actions);
  }

  Future<void> deleteActions(List<String> actionIds) async {
    if (actionIds.isEmpty) {
      return;
    }

    final ids = actionIds.toSet();

    final actions = await loadActions();

    actions.removeWhere((action) {
      return ids.contains(action.id);
    });

    await saveActions(actions);
  }

  Future<void> deleteFarmActions(String farmName) async {
    final actions = await loadActions();

    actions.removeWhere((action) {
      return action.farmName.trim().toLowerCase() ==
          farmName.trim().toLowerCase();
    });

    await saveActions(actions);
  }

  Future<void> clearActions() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }

  Future<List<ReportActionItemData>> loadActionsByFarm(String farmName) async {
    final actions = await loadActions();

    final normalizedFarmName = farmName.trim().toLowerCase();

    final farmActions = actions.where((action) {
      return action.farmName.trim().toLowerCase() == normalizedFarmName;
    }).toList();

    farmActions.sort(compareReportActions);

    return farmActions;
  }

  Future<List<ReportActionItemData>> loadOpenActions() async {
    final actions = await loadActions();

    final openActions = actions.where((action) {
      return action.isOpen;
    }).toList();

    openActions.sort(compareReportActions);

    return openActions;
  }

  Future<List<ReportActionItemData>> loadOverdueActions() async {
    final actions = await loadActions();

    final overdueActions = actions.where((action) {
      return action.isOverdue;
    }).toList();

    overdueActions.sort(compareReportActions);

    return overdueActions;
  }

  Future<List<ReportActionItemData>> loadUrgentActions() async {
    final actions = await loadActions();

    final urgentActions = actions.where((action) {
      return action.isUrgent && action.isOpen;
    }).toList();

    urgentActions.sort(compareReportActions);

    return urgentActions;
  }

  Future<ReportActionItemData?> findActionById(String actionId) async {
    final actions = await loadActions();

    for (final action in actions) {
      if (action.id == actionId) {
        return action;
      }
    }

    return null;
  }

  Future<void> markAsPending(String actionId) async {
    final action = await findActionById(actionId);

    if (action == null) {
      return;
    }

    await updateAction(action.markAsPending());
  }

  Future<void> markAsInProgress(String actionId) async {
    final action = await findActionById(actionId);

    if (action == null) {
      return;
    }

    await updateAction(action.markAsInProgress());
  }

  Future<void> markAsCompleted(String actionId) async {
    final action = await findActionById(actionId);

    if (action == null) {
      return;
    }

    await updateAction(action.markAsCompleted());
  }

  Future<void> markAsCancelled(String actionId) async {
    final action = await findActionById(actionId);

    if (action == null) {
      return;
    }

    await updateAction(action.markAsCancelled());
  }

  Future<ReportActionStorageSummary> loadSummary() async {
    final actions = await loadActions();

    final pendingCount = actions.where((action) {
      return action.isPending;
    }).length;

    final inProgressCount = actions.where((action) {
      return action.isInProgress;
    }).length;

    final completedCount = actions.where((action) {
      return action.isCompleted;
    }).length;

    final cancelledCount = actions.where((action) {
      return action.isCancelled;
    }).length;

    final overdueCount = actions.where((action) {
      return action.isOverdue;
    }).length;

    final urgentCount = actions.where((action) {
      return action.isUrgent && action.isOpen;
    }).length;

    return ReportActionStorageSummary(
      totalCount: actions.length,
      pendingCount: pendingCount,
      inProgressCount: inProgressCount,
      completedCount: completedCount,
      cancelledCount: cancelledCount,
      overdueCount: overdueCount,
      urgentCount: urgentCount,
    );
  }
}

class ReportActionStorageSummary {
  const ReportActionStorageSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.overdueCount,
    required this.urgentCount,
  });

  final int totalCount;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final int cancelledCount;
  final int overdueCount;
  final int urgentCount;

  int get openCount {
    return pendingCount + inProgressCount;
  }

  bool get hasOverdueActions {
    return overdueCount > 0;
  }

  bool get hasUrgentActions {
    return urgentCount > 0;
  }
}
