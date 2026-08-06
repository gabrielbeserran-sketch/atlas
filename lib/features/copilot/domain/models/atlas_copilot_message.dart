import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';

enum AtlasCopilotMessageAuthor {
  user,
  copilot,
}

enum AtlasCopilotMessageFeedback {
  useful,
  notUseful,
}

class AtlasCopilotMessage {
  const AtlasCopilotMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
    this.intent,
    this.confidence,
    this.actions = const [],
    this.feedback,
  });

  final String id;
  final String text;
  final AtlasCopilotMessageAuthor author;
  final DateTime createdAt;

  final AtlasCopilotIntent? intent;
  final double? confidence;

  final List<AtlasCopilotAction> actions;

  final AtlasCopilotMessageFeedback? feedback;

  bool get isUser {
    return author == AtlasCopilotMessageAuthor.user;
  }

  bool get isCopilot {
    return author == AtlasCopilotMessageAuthor.copilot;
  }

  bool get hasFeedback {
    return feedback != null;
  }

  AtlasCopilotMessage copyWith({
    String? id,
    String? text,
    AtlasCopilotMessageAuthor? author,
    DateTime? createdAt,
    AtlasCopilotIntent? intent,
    double? confidence,
    List<AtlasCopilotAction>? actions,
    AtlasCopilotMessageFeedback? feedback,
    bool clearFeedback = false,
  }) {
    return AtlasCopilotMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      intent: intent ?? this.intent,
      confidence: confidence ?? this.confidence,
      actions: actions ?? this.actions,
      feedback: clearFeedback
          ? null
          : feedback ?? this.feedback,
    );
  }

  factory AtlasCopilotMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    final authorName =
        json['author']?.toString() ?? '';

    final intentName =
        json['intent']?.toString();

    final feedbackName =
        json['feedback']?.toString();

    final rawActions = json['actions'];

    return AtlasCopilotMessage(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      author:
          AtlasCopilotMessageAuthor.values.firstWhere(
        (item) => item.name == authorName,
        orElse: () =>
            AtlasCopilotMessageAuthor.copilot,
      ),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      intent: intentName == null
          ? null
          : AtlasCopilotIntent.values.firstWhere(
              (item) => item.name == intentName,
              orElse: () =>
                  AtlasCopilotIntent.unknown,
            ),
      confidence: _readDouble(
        json['confidence'],
      ),
      actions: rawActions is List
          ? rawActions
              .whereType<Map>()
              .map((item) {
                return _actionFromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                );
              })
              .toList()
          : const [],
      feedback: feedbackName == null
          ? null
          : AtlasCopilotMessageFeedback.values.firstWhere(
              (item) => item.name == feedbackName,
              orElse: () =>
                  AtlasCopilotMessageFeedback.useful,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author.name,
      'createdAt': createdAt.toIso8601String(),
      'intent': intent?.name,
      'confidence': confidence,
      'actions': actions.map((action) {
        return action.toJson();
      }).toList(),
      'feedback': feedback?.name,
    };
  }

  static AtlasCopilotAction _actionFromJson(
    Map<String, dynamic> json,
  ) {
    final typeName =
        json['type']?.toString() ?? '';

    return AtlasCopilotAction(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type:
          AtlasCopilotActionType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () =>
            AtlasCopilotActionType.openIntelligence,
      ),
    );
  }

  static double? _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }
}
