import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_response.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasAiMemory {
  const AtlasAiMemory({
    required this.generatedAt,
    required this.farmName,
    required this.messageCount,
    required this.userQuestionCount,
    required this.assistantResponseCount,
    required this.summary,
    required this.lastQuestion,
    required this.lastAnswer,
    required this.mostFrequentIntents,
    required this.frequentAreas,
    required this.pendingActions,
    required this.recentTopics,
    required this.suggestedQuestions,
  });

  final DateTime generatedAt;
  final String farmName;

  final int messageCount;
  final int userQuestionCount;
  final int assistantResponseCount;

  final String summary;

  final String? lastQuestion;
  final String? lastAnswer;

  final List<AtlasAiMemoryIntent> mostFrequentIntents;
  final List<AtlasAiMemoryArea> frequentAreas;
  final List<AtlasAiMemoryPendingAction> pendingActions;
  final List<String> recentTopics;
  final List<String> suggestedQuestions;

  bool get hasHistory {
    return messageCount > 0;
  }

  bool get hasPendingActions {
    return pendingActions.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'farmName': farmName,
      'messageCount': messageCount,
      'userQuestionCount': userQuestionCount,
      'assistantResponseCount':
          assistantResponseCount,
      'summary': summary,
      'lastQuestion': lastQuestion,
      'lastAnswer': lastAnswer,
      'mostFrequentIntents':
          mostFrequentIntents.map((item) {
        return item.toJson();
      }).toList(),
      'frequentAreas': frequentAreas.map((item) {
        return item.toJson();
      }).toList(),
      'pendingActions': pendingActions.map((item) {
        return item.toJson();
      }).toList(),
      'recentTopics': recentTopics,
      'suggestedQuestions': suggestedQuestions,
    };
  }
}

class AtlasAiMemoryIntent {
  const AtlasAiMemoryIntent({
    required this.intent,
    required this.count,
    required this.label,
  });

  final AtlasAiIntent intent;
  final int count;
  final String label;

  Map<String, dynamic> toJson() {
    return {
      'intent': intent.name,
      'count': count,
      'label': label,
    };
  }
}

class AtlasAiMemoryArea {
  const AtlasAiMemoryArea({
    required this.area,
    required this.count,
    required this.label,
  });

  final AtlasFarmAnalysisArea area;
  final int count;
  final String label;

  Map<String, dynamic> toJson() {
    return {
      'area': area.name,
      'count': count,
      'label': label,
    };
  }
}

class AtlasAiMemoryPendingAction {
  const AtlasAiMemoryPendingAction({
    required this.title,
    required this.description,
    required this.expectedResult,
    required this.area,
    required this.deadlineDays,
    required this.sourceQuestion,
  });

  final String title;
  final String description;
  final String expectedResult;

  final AtlasFarmAnalysisArea area;

  final int deadlineDays;

  final String sourceQuestion;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'expectedResult': expectedResult,
      'area': area.name,
      'deadlineDays': deadlineDays,
      'sourceQuestion': sourceQuestion,
    };
  }
}
