import 'package:flutter/foundation.dart';
import 'package:projeto_atlas/features/copilot/data/services/atlas_copilot_history_storage_service.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_message.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_operations_intelligence_service.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasCopilotController extends ChangeNotifier {
  AtlasCopilotController({
    required this.service,
    this.historyStorage =
        const AtlasCopilotHistoryStorageService(),
    this.operationBrief,
    this.farmIntelligence,
    this.consultantName = 'Gabriel',
  });

  final AtlasCopilotService service;
  final AtlasCopilotHistoryStorageService historyStorage;

  final AtlasIntelligenceBrief? operationBrief;
  final AtlasFarmIntelligenceData? farmIntelligence;
  final String consultantName;

  final List<AtlasCopilotMessage> _messages = [];

  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;

  List<AtlasCopilotMessage> get messages =>
      List.unmodifiable(_messages);

  bool get isInitializing => _isInitializing;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  bool get hasFarmContext =>
      farmIntelligence != null;

  int get usefulFeedbackCount =>
      _messages.where((message) {
        return message.feedback ==
            AtlasCopilotMessageFeedback.useful;
      }).length;

  int get notUsefulFeedbackCount =>
      _messages.where((message) {
        return message.feedback ==
            AtlasCopilotMessageFeedback.notUseful;
      }).length;

  String get contextLabel {
    if (farmIntelligence != null) {
      return farmIntelligence!.farmName;
    }

    if (operationBrief != null) {
      return 'Operação consolidada';
    }

    return 'Sem contexto';
  }

  String get contextKey {
    if (farmIntelligence != null) {
      return 'farm_${farmIntelligence!.farmName}';
    }

    if (operationBrief != null) {
      return 'operation_consolidated';
    }

    return 'without_context';
  }

  List<String> get suggestedQuestions {
    return service.buildSuggestedQuestions(
      operationBrief: operationBrief,
      farmIntelligence: farmIntelligence,
    );
  }

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final savedMessages =
          await historyStorage.load(
        contextKey: contextKey,
      );

      _messages
        ..clear()
        ..addAll(savedMessages);

      if (_messages.isEmpty) {
        _addInitialMessage();
        await _saveHistory();
      }
    } catch (_) {
      _messages.clear();
      _addInitialMessage();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _addInitialMessage() {
    final contextDescription =
        farmIntelligence != null
            ? 'Estou analisando os dados da ${farmIntelligence!.farmName}.'
            : operationBrief != null
                ? 'Estou analisando a operação consolidada.'
                : 'Ainda não recebi dados suficientes da operação.';

    _messages.add(
      AtlasCopilotMessage(
        id: _newId(),
        text:
            'Olá, $consultantName. Sou o Copiloto Atlas.\n\n'
            '$contextDescription\n\n'
            'Pergunte sobre prioridades, riscos, financeiro, rebanho, '
            'piquetes, estoque, agenda ou oportunidades.',
        author: AtlasCopilotMessageAuthor.copilot,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> sendQuestion(
    String question,
  ) async {
    final normalized = question.trim();

    if (normalized.isEmpty ||
        _isProcessing ||
        _isInitializing) {
      return;
    }

    _errorMessage = null;

    _messages.add(
      AtlasCopilotMessage(
        id: _newId(),
        text: normalized,
        author: AtlasCopilotMessageAuthor.user,
        createdAt: DateTime.now(),
      ),
    );

    _isProcessing = true;
    notifyListeners();

    await _saveHistory();

    try {
      await Future<void>.delayed(
        const Duration(milliseconds: 350),
      );

      final response = service.answer(
        question: normalized,
        operationBrief: operationBrief,
        farmIntelligence: farmIntelligence,
        consultantName: consultantName,
      );

      _messages.add(
        AtlasCopilotMessage(
          id: _newId(),
          text: response.answer,
          author: AtlasCopilotMessageAuthor.copilot,
          createdAt: response.generatedAt,
          intent: response.intent,
          confidence: response.confidence,
          actions: response.actions,
        ),
      );

      await _saveHistory();
    } catch (_) {
      _errorMessage =
          'Não foi possível processar a pergunta. Tente novamente.';

      _messages.add(
        AtlasCopilotMessage(
          id: _newId(),
          text: _errorMessage!,
          author: AtlasCopilotMessageAuthor.copilot,
          createdAt: DateTime.now(),
        ),
      );

      await _saveHistory();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> registerFeedback({
    required String messageId,
    required AtlasCopilotMessageFeedback feedback,
  }) async {
    final index = _messages.indexWhere(
      (message) => message.id == messageId,
    );

    if (index < 0 || !_messages[index].isCopilot) {
      return;
    }

    final current = _messages[index];

    if (current.feedback == feedback) {
      _messages[index] = current.copyWith(
        clearFeedback: true,
      );
    } else {
      _messages[index] = current.copyWith(
        feedback: feedback,
      );
    }

    notifyListeners();
    await _saveHistory();
  }

  Future<void> selectSuggestion(
    String suggestion,
  ) {
    return sendQuestion(suggestion);
  }

  Future<void> clearConversation() async {
    if (_isProcessing || _isInitializing) {
      return;
    }

    _messages.clear();
    _errorMessage = null;

    await historyStorage.clear(
      contextKey: contextKey,
    );

    _addInitialMessage();
    await _saveHistory();

    notifyListeners();
  }

  Future<void> reloadHistory() async {
    final savedMessages =
        await historyStorage.load(
      contextKey: contextKey,
    );

    _messages
      ..clear()
      ..addAll(savedMessages);

    if (_messages.isEmpty) {
      _addInitialMessage();
      await _saveHistory();
    }

    notifyListeners();
  }

  Future<void> _saveHistory() {
    return historyStorage.save(
      contextKey: contextKey,
      contextLabel: contextLabel,
      messages: _messages,
    );
  }

  String _newId() {
    return DateTime.now()
        .microsecondsSinceEpoch
        .toString();
  }
}
