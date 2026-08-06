import 'package:projeto_atlas/features/atlas_ai/data/services/atlas_ai_conversation_storage_service.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_memory.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_response.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasAiMemoryService {
  const AtlasAiMemoryService();

  AtlasAiMemory buildMemory({
    required String farmName,
    required List<AtlasAiStoredMessage> messages,
    DateTime? now,
  }) {
    final validMessages = messages.where((item) {
      if (item.isUser) {
        return item.text?.trim().isNotEmpty == true;
      }

      return item.response != null;
    }).toList();

    final userMessages = validMessages.where((item) {
      return item.isUser;
    }).toList();

    final assistantMessages =
        validMessages.where((item) {
      return !item.isUser && item.response != null;
    }).toList();

    final responses = assistantMessages
        .map((item) => item.response!)
        .toList();

    final intentCounts = <AtlasAiIntent, int>{};

    final areaCounts =
        <AtlasFarmAnalysisArea, int>{};

    final pendingActions =
        <AtlasAiMemoryPendingAction>[];

    for (final response in responses) {
      intentCounts.update(
        response.intent,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      for (final evidence in response.evidences) {
        areaCounts.update(
          evidence.area,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      for (final action in response.actionPlan) {
        areaCounts.update(
          action.area,
          (value) => value + 1,
          ifAbsent: () => 1,
        );

        final exists = pendingActions.any((item) {
          return item.title == action.title &&
              item.area == action.area;
        });

        if (exists) {
          continue;
        }

        pendingActions.add(
          AtlasAiMemoryPendingAction(
            title: action.title,
            description: action.description,
            expectedResult:
                action.expectedResult,
            area: action.area,
            deadlineDays:
                action.deadlineDays,
            sourceQuestion:
                response.question,
          ),
        );
      }
    }

    final orderedIntents = intentCounts.entries
        .map((entry) {
          return AtlasAiMemoryIntent(
            intent: entry.key,
            count: entry.value,
            label:
                atlasAiIntentLabel(entry.key),
          );
        })
        .toList()
      ..sort(
        (first, second) =>
            second.count.compareTo(
          first.count,
        ),
      );

    final orderedAreas = areaCounts.entries
        .map((entry) {
          return AtlasAiMemoryArea(
            area: entry.key,
            count: entry.value,
            label:
                atlasFarmAreaLabel(entry.key),
          );
        })
        .toList()
      ..sort(
        (first, second) =>
            second.count.compareTo(
          first.count,
        ),
      );

    final lastQuestion =
        _lastUserQuestion(validMessages);

    final lastAnswer =
        _lastAssistantAnswer(validMessages);

    final recentTopics = _recentTopics(
      userMessages: userMessages,
      responses: responses,
    );

    final suggestedQuestions =
        _suggestedQuestions(
      intents: orderedIntents,
      areas: orderedAreas,
      pendingActions: pendingActions,
      lastQuestion: lastQuestion,
    );

    return AtlasAiMemory(
      generatedAt: now ?? DateTime.now(),
      farmName: farmName,
      messageCount: validMessages.length,
      userQuestionCount: userMessages.length,
      assistantResponseCount:
          assistantMessages.length,
      summary: _buildSummary(
        farmName: farmName,
        userQuestionCount:
            userMessages.length,
        orderedIntents: orderedIntents,
        orderedAreas: orderedAreas,
        pendingActions: pendingActions,
        lastQuestion: lastQuestion,
      ),
      lastQuestion: lastQuestion,
      lastAnswer: lastAnswer,
      mostFrequentIntents:
          orderedIntents.take(5).toList(),
      frequentAreas:
          orderedAreas.take(5).toList(),
      pendingActions:
          pendingActions.take(10).toList(),
      recentTopics: recentTopics,
      suggestedQuestions:
          suggestedQuestions,
    );
  }

  String? _lastUserQuestion(
    List<AtlasAiStoredMessage> messages,
  ) {
    for (
      var index = messages.length - 1;
      index >= 0;
      index--
    ) {
      final item = messages[index];

      if (item.isUser &&
          item.text?.trim().isNotEmpty == true) {
        return item.text!.trim();
      }
    }

    return null;
  }

  String? _lastAssistantAnswer(
    List<AtlasAiStoredMessage> messages,
  ) {
    for (
      var index = messages.length - 1;
      index >= 0;
      index--
    ) {
      final response =
          messages[index].response;

      if (response != null &&
          response.directAnswer
              .trim()
              .isNotEmpty) {
        return response.directAnswer.trim();
      }
    }

    return null;
  }

  List<String> _recentTopics({
    required List<AtlasAiStoredMessage>
        userMessages,
    required List<AtlasAiResponse> responses,
  }) {
    final topics = <String>[];

    for (
      var index = userMessages.length - 1;
      index >= 0;
      index--
    ) {
      final text =
          userMessages[index].text?.trim();

      if (text == null || text.isEmpty) {
        continue;
      }

      if (!topics.contains(text)) {
        topics.add(text);
      }

      if (topics.length >= 5) {
        break;
      }
    }

    if (topics.length < 5) {
      for (
        var index = responses.length - 1;
        index >= 0;
        index--
      ) {
        final label =
            atlasAiIntentLabel(
          responses[index].intent,
        );

        if (!topics.contains(label)) {
          topics.add(label);
        }

        if (topics.length >= 5) {
          break;
        }
      }
    }

    return topics;
  }

  List<String> _suggestedQuestions({
    required List<AtlasAiMemoryIntent>
        intents,
    required List<AtlasAiMemoryArea> areas,
    required List<AtlasAiMemoryPendingAction>
        pendingActions,
    required String? lastQuestion,
  }) {
    final questions = <String>[];

    if (pendingActions.isNotEmpty) {
      questions.add(
        'Quais ações discutidas ainda precisam ser executadas?',
      );

      questions.add(
        'Qual ação pendente devo priorizar agora?',
      );
    }

    if (areas.isNotEmpty) {
      questions.add(
        'O que mudou em ${areas.first.label.toLowerCase()} desde a última análise?',
      );
    }

    if (intents.isNotEmpty) {
      final first = intents.first.intent;

      switch (first) {
        case AtlasAiIntent.finance:
          questions.add(
            'O resultado financeiro melhorou?',
          );

        case AtlasAiIntent.risks:
          questions.add(
            'Os principais riscos continuam os mesmos?',
          );

        case AtlasAiIntent.predictiveDecision:
          questions.add(
            'Qual cenário preditivo deve ser revisto?',
          );

        case AtlasAiIntent.shortTermPlan:
        case AtlasAiIntent.mediumTermPlan:
        case AtlasAiIntent.longTermPlan:
          questions.add(
            'Quais ações do plano já deveriam estar concluídas?',
          );

        default:
          questions.add(
            'Qual é a prioridade atual da fazenda?',
          );
      }
    }

    if (lastQuestion != null) {
      questions.add(
        'Retome o último assunto e explique o próximo passo.',
      );
    }

    questions.addAll(
      const [
        'Resuma as últimas conversas.',
        'Quais assuntos estão sendo repetidos?',
        'O que ainda não foi resolvido?',
      ],
    );

    return questions.toSet().take(8).toList();
  }

  String _buildSummary({
    required String farmName,
    required int userQuestionCount,
    required List<AtlasAiMemoryIntent>
        orderedIntents,
    required List<AtlasAiMemoryArea>
        orderedAreas,
    required List<AtlasAiMemoryPendingAction>
        pendingActions,
    required String? lastQuestion,
  }) {
    if (userQuestionCount == 0) {
      return 'Ainda não existem conversas suficientes para formar uma memória inteligente da $farmName.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A memória da $farmName reúne '
      '$userQuestionCount '
      '${userQuestionCount == 1 ? 'pergunta' : 'perguntas'} do usuário. ',
    );

    if (orderedIntents.isNotEmpty) {
      buffer.write(
        'O assunto mais frequente é '
        '${orderedIntents.first.label.toLowerCase()}. ',
      );
    }

    if (orderedAreas.isNotEmpty) {
      buffer.write(
        'A área mais consultada é '
        '${orderedAreas.first.label}. ',
      );
    }

    if (pendingActions.isNotEmpty) {
      buffer.write(
        'Foram identificadas '
        '${pendingActions.length} '
        '${pendingActions.length == 1 ? 'ação pendente' : 'ações pendentes'} '
        'nas respostas anteriores. ',
      );
    }

    if (lastQuestion != null) {
      buffer.write(
        'O último assunto tratado foi: '
        '"$lastQuestion".',
      );
    }

    return buffer.toString().trim();
  }
}
