class AtlasCopilotConversationSummary {
  const AtlasCopilotConversationSummary({
    required this.contextKey,
    required this.contextLabel,
    required this.messageCount,
    required this.lastMessage,
    required this.updatedAt,
  });

  final String contextKey;
  final String contextLabel;
  final int messageCount;
  final String lastMessage;
  final DateTime updatedAt;

  bool get isFarmContext {
    return contextKey.startsWith('farm_');
  }

  bool get isOperationContext {
    return contextKey == 'operation_consolidated';
  }

  factory AtlasCopilotConversationSummary.fromJson(Map<String, dynamic> json) {
    return AtlasCopilotConversationSummary(
      contextKey: json['contextKey']?.toString() ?? '',
      contextLabel: json['contextLabel']?.toString() ?? '',
      messageCount: _readInt(json['messageCount']),
      lastMessage: json['lastMessage']?.toString() ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contextKey': contextKey,
      'contextLabel': contextLabel,
      'messageCount': messageCount,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
