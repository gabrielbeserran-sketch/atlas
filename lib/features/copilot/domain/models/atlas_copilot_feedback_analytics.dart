import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_message.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';

class AtlasCopilotFeedbackAnalytics {
  const AtlasCopilotFeedbackAnalytics({
    required this.totalConversations,
    required this.totalMessages,
    required this.evaluatedResponses,
    required this.usefulResponses,
    required this.notUsefulResponses,
    required this.approvalRate,
    required this.intentMetrics,
    required this.contextMetrics,
    required this.recentFeedback,
  });

  final int totalConversations;
  final int totalMessages;
  final int evaluatedResponses;
  final int usefulResponses;
  final int notUsefulResponses;

  final double approvalRate;

  final List<AtlasCopilotIntentFeedbackMetric>
      intentMetrics;

  final List<AtlasCopilotContextFeedbackMetric>
      contextMetrics;

  final List<AtlasCopilotRecentFeedbackItem>
      recentFeedback;

  bool get hasFeedback {
    return evaluatedResponses > 0;
  }

  int get pendingResponses {
    return totalMessages - evaluatedResponses;
  }
}

class AtlasCopilotIntentFeedbackMetric {
  const AtlasCopilotIntentFeedbackMetric({
    required this.intent,
    required this.total,
    required this.useful,
    required this.notUseful,
    required this.approvalRate,
  });

  final AtlasCopilotIntent intent;

  final int total;
  final int useful;
  final int notUseful;

  final double approvalRate;
}

class AtlasCopilotContextFeedbackMetric {
  const AtlasCopilotContextFeedbackMetric({
    required this.contextKey,
    required this.contextLabel,
    required this.total,
    required this.useful,
    required this.notUseful,
    required this.approvalRate,
  });

  final String contextKey;
  final String contextLabel;

  final int total;
  final int useful;
  final int notUseful;

  final double approvalRate;

  bool get isFarmContext {
    return contextKey.startsWith('farm_');
  }
}

class AtlasCopilotRecentFeedbackItem {
  const AtlasCopilotRecentFeedbackItem({
    required this.contextLabel,
    required this.messageText,
    required this.intent,
    required this.feedback,
    required this.createdAt,
  });

  final String contextLabel;
  final String messageText;

  final AtlasCopilotIntent? intent;
  final AtlasCopilotMessageFeedback feedback;

  final DateTime createdAt;
}
