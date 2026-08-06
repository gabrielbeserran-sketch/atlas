import 'package:projeto_atlas/features/copilot/data/services/atlas_copilot_history_storage_service.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_feedback_analytics.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_message.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';

class AtlasCopilotFeedbackAnalyticsService {
  const AtlasCopilotFeedbackAnalyticsService({
    this.historyStorage =
        const AtlasCopilotHistoryStorageService(),
  });

  final AtlasCopilotHistoryStorageService
      historyStorage;

  Future<AtlasCopilotFeedbackAnalytics>
      buildAnalytics() async {
    final summaries =
        await historyStorage.loadConversationSummaries();

    final intentAccumulator =
        <AtlasCopilotIntent, _FeedbackAccumulator>{};

    final contextMetrics =
        <AtlasCopilotContextFeedbackMetric>[];

    final recentFeedback =
        <AtlasCopilotRecentFeedbackItem>[];

    var totalMessages = 0;
    var evaluatedResponses = 0;
    var usefulResponses = 0;
    var notUsefulResponses = 0;

    for (final summary in summaries) {
      final messages = await historyStorage.load(
        contextKey: summary.contextKey,
      );

      final copilotMessages =
          messages.where((message) {
        return message.isCopilot;
      }).toList();

      totalMessages += copilotMessages.length;

      var contextUseful = 0;
      var contextNotUseful = 0;

      for (final message in copilotMessages) {
        final feedback = message.feedback;

        if (feedback == null) {
          continue;
        }

        evaluatedResponses++;

        if (feedback ==
            AtlasCopilotMessageFeedback.useful) {
          usefulResponses++;
          contextUseful++;
        } else {
          notUsefulResponses++;
          contextNotUseful++;
        }

        final intent =
            message.intent ?? AtlasCopilotIntent.unknown;

        final accumulator =
            intentAccumulator.putIfAbsent(
          intent,
          _FeedbackAccumulator.new,
        );

        accumulator.total++;

        if (feedback ==
            AtlasCopilotMessageFeedback.useful) {
          accumulator.useful++;
        } else {
          accumulator.notUseful++;
        }

        recentFeedback.add(
          AtlasCopilotRecentFeedbackItem(
            contextLabel: summary.contextLabel,
            messageText: message.text,
            intent: message.intent,
            feedback: feedback,
            createdAt: message.createdAt,
          ),
        );
      }

      final contextTotal =
          contextUseful + contextNotUseful;

      if (contextTotal > 0) {
        contextMetrics.add(
          AtlasCopilotContextFeedbackMetric(
            contextKey: summary.contextKey,
            contextLabel: summary.contextLabel,
            total: contextTotal,
            useful: contextUseful,
            notUseful: contextNotUseful,
            approvalRate:
                contextUseful / contextTotal * 100,
          ),
        );
      }
    }

    final intentMetrics =
        intentAccumulator.entries.map((entry) {
      final total = entry.value.total;

      return AtlasCopilotIntentFeedbackMetric(
        intent: entry.key,
        total: total,
        useful: entry.value.useful,
        notUseful: entry.value.notUseful,
        approvalRate: total == 0
            ? 0
            : entry.value.useful / total * 100,
      );
    }).toList()
      ..sort(
        (first, second) {
          final rateComparison =
              first.approvalRate.compareTo(
            second.approvalRate,
          );

          if (rateComparison != 0) {
            return rateComparison;
          }

          return second.total.compareTo(
            first.total,
          );
        },
      );

    contextMetrics.sort(
      (first, second) {
        final rateComparison =
            first.approvalRate.compareTo(
          second.approvalRate,
        );

        if (rateComparison != 0) {
          return rateComparison;
        }

        return second.total.compareTo(
          first.total,
        );
      },
    );

    recentFeedback.sort(
      (first, second) =>
          second.createdAt.compareTo(
        first.createdAt,
      ),
    );

    return AtlasCopilotFeedbackAnalytics(
      totalConversations: summaries.length,
      totalMessages: totalMessages,
      evaluatedResponses: evaluatedResponses,
      usefulResponses: usefulResponses,
      notUsefulResponses: notUsefulResponses,
      approvalRate: evaluatedResponses == 0
          ? 0
          : usefulResponses /
              evaluatedResponses *
              100,
      intentMetrics: intentMetrics,
      contextMetrics: contextMetrics,
      recentFeedback:
          recentFeedback.take(30).toList(),
    );
  }
}

class _FeedbackAccumulator {
  int total = 0;
  int useful = 0;
  int notUseful = 0;
}
