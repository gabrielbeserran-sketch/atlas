import 'dart:convert';

import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_conversation_summary.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasCopilotHistoryStorageService {
  const AtlasCopilotHistoryStorageService();

  static const String _keyPrefix = 'atlas_copilot_history_v1';

  static const String _summaryKey = 'atlas_copilot_history_summaries_v1';

  static const int maximumStoredMessages = 80;

  Future<List<AtlasCopilotMessage>> load({required String contextKey}) async {
    final preferences = await SharedPreferences.getInstance();

    final value = preferences.getString(_storageKey(contextKey));

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      final messages = decoded
          .whereType<Map>()
          .map((item) {
            return AtlasCopilotMessage.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .where((message) {
            return message.id.isNotEmpty && message.text.trim().isNotEmpty;
          })
          .toList();

      messages.sort(
        (first, second) => first.createdAt.compareTo(second.createdAt),
      );

      return messages;
    } catch (_) {
      return [];
    }
  }

  Future<void> save({
    required String contextKey,
    required String contextLabel,
    required List<AtlasCopilotMessage> messages,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final limited = messages.length > maximumStoredMessages
        ? messages.sublist(messages.length - maximumStoredMessages)
        : messages;

    final value = jsonEncode(
      limited.map((message) {
        return message.toJson();
      }).toList(),
    );

    await preferences.setString(_storageKey(contextKey), value);

    await _updateSummary(
      preferences: preferences,
      contextKey: contextKey,
      contextLabel: contextLabel,
      messages: limited,
    );
  }

  Future<void> clear({required String contextKey}) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey(contextKey));

    final summaries = await _loadSummariesFromPreferences(preferences);

    summaries.removeWhere((item) => item.contextKey == contextKey);

    await _saveSummaries(preferences, summaries);
  }

  Future<List<AtlasCopilotConversationSummary>>
  loadConversationSummaries() async {
    final preferences = await SharedPreferences.getInstance();

    final summaries = await _loadSummariesFromPreferences(preferences);

    summaries.sort(
      (first, second) => second.updatedAt.compareTo(first.updatedAt),
    );

    return summaries;
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();

    final summaries = await _loadSummariesFromPreferences(preferences);

    for (final summary in summaries) {
      await preferences.remove(_storageKey(summary.contextKey));
    }

    await preferences.remove(_summaryKey);
  }

  Future<void> _updateSummary({
    required SharedPreferences preferences,
    required String contextKey,
    required String contextLabel,
    required List<AtlasCopilotMessage> messages,
  }) async {
    final summaries = await _loadSummariesFromPreferences(preferences);

    summaries.removeWhere((item) => item.contextKey == contextKey);

    if (messages.isNotEmpty) {
      final lastMessage = messages.last;

      summaries.add(
        AtlasCopilotConversationSummary(
          contextKey: contextKey,
          contextLabel: contextLabel,
          messageCount: messages.length,
          lastMessage: lastMessage.text,
          updatedAt: lastMessage.createdAt,
        ),
      );
    }

    await _saveSummaries(preferences, summaries);
  }

  Future<List<AtlasCopilotConversationSummary>> _loadSummariesFromPreferences(
    SharedPreferences preferences,
  ) async {
    final value = preferences.getString(_summaryKey);

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((item) {
            return AtlasCopilotConversationSummary.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .where((item) {
            return item.contextKey.isNotEmpty;
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSummaries(
    SharedPreferences preferences,
    List<AtlasCopilotConversationSummary> summaries,
  ) async {
    final value = jsonEncode(
      summaries.map((item) {
        return item.toJson();
      }).toList(),
    );

    await preferences.setString(_summaryKey, value);
  }

  String _storageKey(String contextKey) {
    return '${_keyPrefix}_${_normalizeKey(contextKey)}';
  }

  String _normalizeKey(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return normalized.isEmpty ? 'default' : normalized;
  }
}
