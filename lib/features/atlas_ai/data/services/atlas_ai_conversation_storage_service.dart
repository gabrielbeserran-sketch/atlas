import 'dart:convert';

import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_response.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart'
    as farm_intelligence;
import 'package:shared_preferences/shared_preferences.dart';

class AtlasAiConversationStorageService {
  const AtlasAiConversationStorageService();

  static const String _keyPrefix = 'atlas_ai_conversation_v1';

  static const int maximumMessagesPerFarm = 80;

  Future<List<AtlasAiStoredMessage>> load({required String farmName}) async {
    final preferences = await SharedPreferences.getInstance();

    final value = preferences.getString(_storageKey(farmName));

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
            return AtlasAiStoredMessage.fromJson(
              Map<String, dynamic>.from(item),
            );
          })
          .take(maximumMessagesPerFarm)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save({
    required String farmName,
    required List<AtlasAiStoredMessage> messages,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final limited = messages.length > maximumMessagesPerFarm
        ? messages.sublist(messages.length - maximumMessagesPerFarm)
        : messages;

    await preferences.setString(
      _storageKey(farmName),
      jsonEncode(
        limited.map((item) {
          return item.toJson();
        }).toList(),
      ),
    );
  }

  Future<void> clear({required String farmName}) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey(farmName));
  }

  String _storageKey(String farmName) {
    return '${_keyPrefix}_${_normalize(farmName)}';
  }

  String _normalize(String value) {
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

    return normalized.isEmpty ? 'farm' : normalized;
  }
}

class AtlasAiStoredMessage {
  const AtlasAiStoredMessage({
    required this.isUser,
    required this.createdAt,
    this.text,
    this.response,
  });

  final bool isUser;
  final DateTime createdAt;

  final String? text;
  final AtlasAiResponse? response;

  Map<String, dynamic> toJson() {
    return {
      'isUser': isUser,
      'createdAt': createdAt.toIso8601String(),
      'text': text,
      'response': response?.toJson(),
    };
  }

  factory AtlasAiStoredMessage.fromJson(Map<String, dynamic> json) {
    final responseJson = json['response'];

    return AtlasAiStoredMessage(
      isUser: json['isUser'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      text: json['text']?.toString(),
      response: responseJson is Map
          ? _responseFromJson(Map<String, dynamic>.from(responseJson))
          : null,
    );
  }

  static AtlasAiResponse _responseFromJson(Map<String, dynamic> json) {
    final intentName = json['intent']?.toString() ?? '';

    final levelName = json['level']?.toString() ?? '';

    final evidencesJson = json['evidences'];

    final actionPlanJson = json['actionPlan'];

    final actionsJson = json['actions'];

    return AtlasAiResponse(
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
      question: json['question']?.toString() ?? '',
      intent: AtlasAiIntent.values.firstWhere(
        (item) => item.name == intentName,
        orElse: () => AtlasAiIntent.unknown,
      ),
      directAnswer: json['directAnswer']?.toString() ?? '',
      justification: json['justification']?.toString() ?? '',
      evidences: evidencesJson is List
          ? evidencesJson.whereType<Map>().map((item) {
              return _evidenceFromJson(Map<String, dynamic>.from(item));
            }).toList()
          : const [],
      actionPlan: actionPlanJson is List
          ? actionPlanJson.whereType<Map>().map((item) {
              return _actionStepFromJson(Map<String, dynamic>.from(item));
            }).toList()
          : const [],
      nextStep: json['nextStep']?.toString() ?? '',
      confidence: _readDouble(json['confidence']),
      level: AtlasDiagnosticLevel.values.firstWhere(
        (item) => item.name == levelName,
        orElse: () => AtlasDiagnosticLevel.stable,
      ),
      actions: actionsJson is List
          ? actionsJson.whereType<Map>().map((item) {
              return _navigationFromJson(Map<String, dynamic>.from(item));
            }).toList()
          : const [],
    );
  }

  static AtlasAiEvidence _evidenceFromJson(Map<String, dynamic> json) {
    final areaName = json['area']?.toString() ?? '';

    return AtlasAiEvidence(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      area: farm_intelligence.AtlasFarmAnalysisArea.values.firstWhere(
        (item) => item.name == areaName,
        orElse: () => farm_intelligence.AtlasFarmAnalysisArea.general,
      ),
      weight: _readDouble(json['weight']),
    );
  }

  static AtlasAiResponseActionStep _actionStepFromJson(
    Map<String, dynamic> json,
  ) {
    final areaName = json['area']?.toString() ?? '';

    return AtlasAiResponseActionStep(
      position: _readInt(json['position'], 1),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      expectedResult: json['expectedResult']?.toString() ?? '',
      area: farm_intelligence.AtlasFarmAnalysisArea.values.firstWhere(
        (item) => item.name == areaName,
        orElse: () => farm_intelligence.AtlasFarmAnalysisArea.general,
      ),
      deadlineDays: _readInt(json['deadlineDays'], 1),
    );
  }

  static AtlasAiNavigationAction _navigationFromJson(
    Map<String, dynamic> json,
  ) {
    final typeName = json['type']?.toString() ?? '';

    return AtlasAiNavigationAction(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: AtlasAiNavigationActionType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => AtlasAiNavigationActionType.openDiagnostic,
      ),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
