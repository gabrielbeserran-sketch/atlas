import 'dart:convert';

import 'package:projeto_atlas/features/reports/domain/models/report_action_history_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportActionHistoryStorageService {
  static const String _storageKey = 'atlas_report_action_history';

  Future<List<ReportActionHistoryData>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();

    final encodedHistory = preferences.getString(_storageKey);

    if (encodedHistory == null || encodedHistory.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encodedHistory);

      if (decoded is! List) {
        return [];
      }

      final history = decoded
          .whereType<Map>()
          .map((item) {
            return ReportActionHistoryData.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .where((item) {
            return item.id.trim().isNotEmpty && item.actionId.trim().isNotEmpty;
          })
          .toList();

      history.sort(compareReportActionHistory);

      return history;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<ReportActionHistoryData> history) async {
    final preferences = await SharedPreferences.getInstance();

    final normalizedHistory = List<ReportActionHistoryData>.from(history)
      ..sort(compareReportActionHistory);

    final encodedHistory = jsonEncode(
      normalizedHistory.map((item) {
        return item.toJson();
      }).toList(),
    );

    await preferences.setString(_storageKey, encodedHistory);
  }

  Future<ReportActionHistoryData> addHistoryItem(
    ReportActionHistoryData item,
  ) async {
    final history = await loadHistory();

    final itemToSave = item.id.trim().isEmpty
        ? item.copyWith(id: createReportActionHistoryId())
        : item;

    history.add(itemToSave);

    await saveHistory(history);

    return itemToSave;
  }

  Future<void> addHistoryItems(List<ReportActionHistoryData> items) async {
    if (items.isEmpty) {
      return;
    }

    final history = await loadHistory();

    final existingIds = history.map((item) {
      return item.id;
    }).toSet();

    for (final item in items) {
      final itemToSave = item.id.trim().isEmpty || existingIds.contains(item.id)
          ? item.copyWith(id: createReportActionHistoryId())
          : item;

      history.add(itemToSave);

      existingIds.add(itemToSave.id);
    }

    await saveHistory(history);
  }

  Future<void> updateHistoryItem(ReportActionHistoryData updatedItem) async {
    final history = await loadHistory();

    final index = history.indexWhere((item) {
      return item.id == updatedItem.id;
    });

    if (index == -1) {
      history.add(updatedItem);
    } else {
      history[index] = updatedItem;
    }

    await saveHistory(history);
  }

  Future<void> deleteHistoryItem(String historyId) async {
    final history = await loadHistory();

    history.removeWhere((item) {
      return item.id == historyId;
    });

    await saveHistory(history);
  }

  Future<void> deleteActionHistory(String actionId) async {
    final history = await loadHistory();

    history.removeWhere((item) {
      return item.actionId == actionId;
    });

    await saveHistory(history);
  }

  Future<void> deleteHistoryItems(List<String> historyIds) async {
    if (historyIds.isEmpty) {
      return;
    }

    final ids = historyIds.toSet();

    final history = await loadHistory();

    history.removeWhere((item) {
      return ids.contains(item.id);
    });

    await saveHistory(history);
  }

  Future<void> clearHistory() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }

  Future<List<ReportActionHistoryData>> loadActionHistory(
    String actionId,
  ) async {
    final history = await loadHistory();

    final actionHistory = history.where((item) {
      return item.actionId == actionId;
    }).toList();

    actionHistory.sort(compareReportActionHistory);

    return actionHistory;
  }

  Future<List<ReportActionHistoryData>> loadHistoryByType(
    String eventType,
  ) async {
    final history = await loadHistory();

    final filtered = history.where((item) {
      return item.eventType == eventType;
    }).toList();

    filtered.sort(compareReportActionHistory);

    return filtered;
  }

  Future<List<ReportActionHistoryData>> loadHistoryBySource(
    String source,
  ) async {
    final history = await loadHistory();

    final normalizedSource = source.trim().toLowerCase();

    final filtered = history.where((item) {
      return item.source.trim().toLowerCase() == normalizedSource;
    }).toList();

    filtered.sort(compareReportActionHistory);

    return filtered;
  }

  Future<ReportActionHistoryData?> findHistoryById(String historyId) async {
    final history = await loadHistory();

    for (final item in history) {
      if (item.id == historyId) {
        return item;
      }
    }

    return null;
  }

  Future<ReportActionHistorySummary> loadSummary() async {
    final history = await loadHistory();

    final creationCount = history.where((item) {
      return item.isCreation;
    }).length;

    final statusChangeCount = history.where((item) {
      return item.isStatusChange;
    }).length;

    final deadlineChangeCount = history.where((item) {
      return item.isDeadlineChange;
    }).length;

    final responsibleChangeCount = history.where((item) {
      return item.isResponsibleChange;
    }).length;

    final priorityChangeCount = history.where((item) {
      return item.isPriorityChange;
    }).length;

    final notesChangeCount = history.where((item) {
      return item.isNotesChange;
    }).length;

    final completionCount = history.where((item) {
      return item.isCompletion;
    }).length;

    final cancellationCount = history.where((item) {
      return item.isCancellation;
    }).length;

    return ReportActionHistorySummary(
      totalCount: history.length,
      creationCount: creationCount,
      statusChangeCount: statusChangeCount,
      deadlineChangeCount: deadlineChangeCount,
      responsibleChangeCount: responsibleChangeCount,
      priorityChangeCount: priorityChangeCount,
      notesChangeCount: notesChangeCount,
      completionCount: completionCount,
      cancellationCount: cancellationCount,
    );
  }

  Future<ReportActionHistorySummary> loadActionSummary(String actionId) async {
    final history = await loadActionHistory(actionId);

    final creationCount = history.where((item) {
      return item.isCreation;
    }).length;

    final statusChangeCount = history.where((item) {
      return item.isStatusChange;
    }).length;

    final deadlineChangeCount = history.where((item) {
      return item.isDeadlineChange;
    }).length;

    final responsibleChangeCount = history.where((item) {
      return item.isResponsibleChange;
    }).length;

    final priorityChangeCount = history.where((item) {
      return item.isPriorityChange;
    }).length;

    final notesChangeCount = history.where((item) {
      return item.isNotesChange;
    }).length;

    final completionCount = history.where((item) {
      return item.isCompletion;
    }).length;

    final cancellationCount = history.where((item) {
      return item.isCancellation;
    }).length;

    return ReportActionHistorySummary(
      totalCount: history.length,
      creationCount: creationCount,
      statusChangeCount: statusChangeCount,
      deadlineChangeCount: deadlineChangeCount,
      responsibleChangeCount: responsibleChangeCount,
      priorityChangeCount: priorityChangeCount,
      notesChangeCount: notesChangeCount,
      completionCount: completionCount,
      cancellationCount: cancellationCount,
    );
  }

  Future<void> registerCreation({
    required String actionId,
    required String actionTitle,
    required String source,
    String createdBy = 'Usuário',
  }) async {
    await addHistoryItem(
      createActionCreatedHistory(
        actionId: actionId,
        actionTitle: actionTitle,
        source: source,
        createdBy: createdBy,
      ),
    );
  }

  Future<void> registerStatusChange({
    required String actionId,
    required String actionTitle,
    required String previousStatus,
    required String newStatus,
    required String source,
    String createdBy = 'Usuário',
  }) async {
    if (previousStatus == newStatus) {
      return;
    }

    await addHistoryItem(
      createActionStatusHistory(
        actionId: actionId,
        actionTitle: actionTitle,
        previousStatus: previousStatus,
        newStatus: newStatus,
        source: source,
        createdBy: createdBy,
      ),
    );
  }

  Future<void> registerDeadlineChange({
    required String actionId,
    required String actionTitle,
    required String previousDeadline,
    required String newDeadline,
    required String source,
    String createdBy = 'Usuário',
  }) async {
    if (previousDeadline == newDeadline) {
      return;
    }

    await addHistoryItem(
      createActionDeadlineHistory(
        actionId: actionId,
        actionTitle: actionTitle,
        previousDeadline: previousDeadline,
        newDeadline: newDeadline,
        source: source,
        createdBy: createdBy,
      ),
    );
  }

  Future<void> registerResponsibleChange({
    required String actionId,
    required String actionTitle,
    required String previousResponsible,
    required String newResponsible,
    required String source,
    String createdBy = 'Usuário',
  }) async {
    if (previousResponsible == newResponsible) {
      return;
    }

    await addHistoryItem(
      createActionResponsibleHistory(
        actionId: actionId,
        actionTitle: actionTitle,
        previousResponsible: previousResponsible,
        newResponsible: newResponsible,
        source: source,
        createdBy: createdBy,
      ),
    );
  }

  Future<void> registerPriorityChange({
    required String actionId,
    required String actionTitle,
    required String previousPriority,
    required String newPriority,
    required String source,
    String createdBy = 'Usuário',
  }) async {
    if (previousPriority == newPriority) {
      return;
    }

    await addHistoryItem(
      createActionPriorityHistory(
        actionId: actionId,
        actionTitle: actionTitle,
        previousPriority: previousPriority,
        newPriority: newPriority,
        source: source,
        createdBy: createdBy,
      ),
    );
  }

  Future<void> registerNotesChange({
    required String actionId,
    required String actionTitle,
    required String previousNotes,
    required String newNotes,
    required String source,
    String createdBy = 'Usuário',
  }) async {
    if (previousNotes == newNotes) {
      return;
    }

    await addHistoryItem(
      createActionNotesHistory(
        actionId: actionId,
        actionTitle: actionTitle,
        previousNotes: previousNotes,
        newNotes: newNotes,
        source: source,
        createdBy: createdBy,
      ),
    );
  }
}

class ReportActionHistorySummary {
  const ReportActionHistorySummary({
    required this.totalCount,
    required this.creationCount,
    required this.statusChangeCount,
    required this.deadlineChangeCount,
    required this.responsibleChangeCount,
    required this.priorityChangeCount,
    required this.notesChangeCount,
    required this.completionCount,
    required this.cancellationCount,
  });

  final int totalCount;
  final int creationCount;
  final int statusChangeCount;
  final int deadlineChangeCount;
  final int responsibleChangeCount;
  final int priorityChangeCount;
  final int notesChangeCount;
  final int completionCount;
  final int cancellationCount;

  int get editCount {
    return deadlineChangeCount +
        responsibleChangeCount +
        priorityChangeCount +
        notesChangeCount;
  }

  bool get hasHistory {
    return totalCount > 0;
  }

  bool get hasStatusChanges {
    return statusChangeCount > 0 ||
        completionCount > 0 ||
        cancellationCount > 0;
  }
}
