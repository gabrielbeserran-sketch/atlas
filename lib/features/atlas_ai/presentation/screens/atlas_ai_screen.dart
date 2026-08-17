import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_farm_context.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_memory.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/services/atlas_ai_memory_service.dart';
import 'package:projeto_atlas/features/atlas_ai/data/services/atlas_ai_tracked_action_storage_service.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/services/atlas_ai_action_tracking_service.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_response.dart';
import 'package:projeto_atlas/features/atlas_ai/data/services/atlas_ai_conversation_storage_service.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/services/atlas_ai_response_service.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasAiScreen extends StatefulWidget {
  const AtlasAiScreen({
    required this.contextData,
    this.onOpenDiagnostic,
    this.onOpenPredictive,
    this.onOpenFinance,
    this.onOpenHerd,
    this.onOpenPaddocks,
    this.onOpenInventory,
    this.onOpenAgenda,
    super.key,
  });

  final AtlasAiFarmContext contextData;

  final VoidCallback? onOpenDiagnostic;
  final VoidCallback? onOpenPredictive;
  final VoidCallback? onOpenFinance;
  final VoidCallback? onOpenHerd;
  final VoidCallback? onOpenPaddocks;
  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenAgenda;

  @override
  State<AtlasAiScreen> createState() {
    return _AtlasAiScreenState();
  }
}

class _AtlasAiScreenState extends State<AtlasAiScreen> {
  final AtlasAiResponseService responseService = const AtlasAiResponseService();

  final AtlasAiConversationStorageService conversationStorage =
      const AtlasAiConversationStorageService();

  final AtlasAiMemoryService memoryService = const AtlasAiMemoryService();

  final AtlasAiTrackedActionStorageService trackedActionStorage =
      const AtlasAiTrackedActionStorageService();

  final AtlasAiActionTrackingService actionTrackingService =
      const AtlasAiActionTrackingService();

  final TextEditingController inputController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  final List<_AtlasAiChatItem> messages = [];

  bool isProcessing = false;
  bool isLoadingHistory = true;

  AtlasAiMemory? memoryData;

  List<AtlasAiTrackedAction> trackedActions = [];

  AtlasAiTrackedActionStatus? selectedActionStatus;

  AtlasAiFarmContext get contextData {
    return widget.contextData;
  }

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    final stored = await conversationStorage.load(
      farmName: contextData.farmName,
    );

    final savedTrackedActions = await trackedActionStorage.load(
      farmName: contextData.farmName,
    );

    if (!mounted) {
      return;
    }

    trackedActions = savedTrackedActions;

    messages
      ..clear()
      ..addAll(stored.map(_AtlasAiChatItem.fromStored));

    if (messages.isEmpty) {
      messages.add(_buildWelcomeMessage());
    }

    _rebuildMemory();

    final memory = memoryData;

    if (memory != null) {
      trackedActions = actionTrackingService.importFromMemory(
        farmName: contextData.farmName,
        memory: memory,
        existingActions: trackedActions,
      );

      await _saveTrackedActions();
    }

    setState(() {
      isLoadingHistory = false;
    });

    _scrollToBottom();
  }

  _AtlasAiChatItem _buildWelcomeMessage() {
    return _AtlasAiChatItem.assistant(
      response: AtlasAiResponse(
        generatedAt: DateTime.now(),
        question: '',
        intent: AtlasAiIntent.generalSituation,
        directAnswer: 'Olá! Sou o Atlas IA da ${contextData.farmName}.',
        justification:
            'Posso explicar o diagnóstico, indicar prioridades, analisar riscos, sugerir planos de ação e comparar decisões simuladas.',
        evidences: [
          AtlasAiEvidence(
            label: 'Score atual',
            value: '${contextData.score.toStringAsFixed(0)}/100',
            description: 'Pontuação consolidada do diagnóstico.',
            area: AtlasFarmAnalysisArea.general,
            weight: 1,
          ),
          AtlasAiEvidence(
            label: 'Situação',
            value: atlasDiagnosticLevelLabel(contextData.level),
            description: 'Classificação atual da propriedade.',
            area: AtlasFarmAnalysisArea.general,
            weight: 0.9,
          ),
        ],
        actionPlan: const [],
        nextStep:
            'Escolha uma pergunta sugerida ou escreva sua própria pergunta.',
        confidence: 100,
        level: contextData.level,
        actions: const [],
      ),
    );
  }

  Future<void> _saveConversation() async {
    await conversationStorage.save(
      farmName: contextData.farmName,
      messages: messages.map((item) {
        return item.toStored();
      }).toList(),
    );

    _rebuildMemory();
  }

  void _rebuildMemory() {
    memoryData = memoryService.buildMemory(
      farmName: contextData.farmName,
      messages: messages.map((item) {
        return item.toStored();
      }).toList(),
    );
  }

  Future<void> _saveTrackedActions() {
    return trackedActionStorage.save(
      farmName: contextData.farmName,
      actions: trackedActions,
    );
  }

  AtlasAiActionProgress get actionProgress {
    return actionTrackingService.calculateProgress(trackedActions);
  }

  List<AtlasAiTrackedAction> get filteredTrackedActions {
    final selected = selectedActionStatus;

    final items = selected == null
        ? [...trackedActions]
        : trackedActions.where((item) {
            return item.status == selected;
          }).toList();

    items.sort((first, second) {
      if (first.isOverdue != second.isOverdue) {
        return first.isOverdue ? -1 : 1;
      }

      return second.updatedAt.compareTo(first.updatedAt);
    });

    return items;
  }

  Future<void> _importActionsFromResponse(AtlasAiResponse response) async {
    trackedActions = actionTrackingService.importFromResponse(
      farmName: contextData.farmName,
      response: response,
      existingActions: trackedActions,
    );

    await _saveTrackedActions();
  }

  Future<void> _changeActionStatus(
    AtlasAiTrackedAction action,
    AtlasAiTrackedActionStatus status,
  ) async {
    final index = trackedActions.indexWhere((item) => item.id == action.id);

    if (index < 0) {
      return;
    }

    final updated = actionTrackingService.updateStatus(
      action: action,
      status: status,
    );

    setState(() {
      trackedActions[index] = updated;
    });

    await _saveTrackedActions();
  }

  Future<void> _editActionNotes(AtlasAiTrackedAction action) async {
    final controller = TextEditingController(text: action.notes);

    final notes = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Observações da ação'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 7,
            decoration: const InputDecoration(
              hintText: 'Registre andamento, impedimentos ou resultados.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (notes == null) {
      return;
    }

    final index = trackedActions.indexWhere((item) => item.id == action.id);

    if (index < 0) {
      return;
    }

    final updated = actionTrackingService.updateNotes(
      action: action,
      notes: notes,
    );

    setState(() {
      trackedActions[index] = updated;
    });

    await _saveTrackedActions();
  }

  void _selectActionStatus(AtlasAiTrackedActionStatus? status) {
    setState(() {
      selectedActionStatus = status;
    });
  }

  List<String> get effectiveSuggestedQuestions {
    final progress = actionProgress;

    final merged = <String>[
      if (progress.hasActions) 'Qual é o progresso das ações da consultoria?',
      if (progress.pending > 0) 'Quais ações estão pendentes?',
      if (progress.inProgress > 0) 'Quais ações estão em andamento?',
      if (progress.overdue > 0) 'Quais ações estão atrasadas?',
      if (progress.completed > 0) 'O que já foi concluído?',
      ...?memoryData?.suggestedQuestions,
      ...contextData.suggestedQuestions,
    ];

    return merged.toSet().take(12).toList();
  }

  void resumeLastTopic() {
    final lastQuestion = memoryData?.lastQuestion;

    if (lastQuestion == null || lastQuestion.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ainda não existe um assunto anterior para retomar.'),
        ),
      );
      return;
    }

    sendQuestion(
      'Retome o assunto "$lastQuestion" e explique qual deve ser o próximo passo.',
    );
  }

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendQuestion([String? suggestedQuestion]) async {
    if (isProcessing) {
      return;
    }

    final question = (suggestedQuestion ?? inputController.text).trim();

    if (question.isEmpty) {
      return;
    }

    inputController.clear();

    setState(() {
      messages.add(_AtlasAiChatItem.user(text: question));

      isProcessing = true;
    });

    await _saveConversation();

    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 280));

    final response = responseService.answer(
      question: question,
      context: contextData,
      trackedActions: trackedActions,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      messages.add(_AtlasAiChatItem.assistant(response: response));

      isProcessing = false;
    });

    await _saveConversation();
    await _importActionsFromResponse(response);

    if (mounted) {
      setState(() {});
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void handleNavigation(AtlasAiNavigationAction action) {
    final callback = switch (action.type) {
      AtlasAiNavigationActionType.openDiagnostic => widget.onOpenDiagnostic,
      AtlasAiNavigationActionType.openPredictive => widget.onOpenPredictive,
      AtlasAiNavigationActionType.openFinance => widget.onOpenFinance,
      AtlasAiNavigationActionType.openHerd => widget.onOpenHerd,
      AtlasAiNavigationActionType.openPaddocks => widget.onOpenPaddocks,
      AtlasAiNavigationActionType.openInventory => widget.onOpenInventory,
      AtlasAiNavigationActionType.openAgenda => widget.onOpenAgenda,
    };

    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A ação "${action.label}" ainda não foi conectada.'),
        ),
      );
      return;
    }

    callback();
  }

  Future<void> clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limpar conversa?'),
          content: const Text('As mensagens desta sessão serão removidas.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await conversationStorage.clear(farmName: contextData.farmName);

    if (!mounted) {
      return;
    }

    setState(() {
      messages
        ..clear()
        ..add(_buildWelcomeMessage());

      _rebuildMemory();
    });

    await _saveConversation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atlas IA',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              contextData.farmName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Retomar último assunto',
            onPressed: isLoadingHistory || memoryData?.lastQuestion == null
                ? null
                : resumeLastTopic,
            icon: const Icon(Icons.history_toggle_off_outlined),
          ),
          IconButton(
            tooltip: 'Abrir diagnóstico',
            onPressed: widget.onOpenDiagnostic,
            icon: const Icon(Icons.health_and_safety_outlined),
          ),
          IconButton(
            tooltip: 'Simular decisões',
            onPressed: widget.onOpenPredictive,
            icon: const Icon(Icons.auto_graph_outlined),
          ),
          IconButton(
            tooltip: 'Limpar conversa',
            onPressed: isLoadingHistory || messages.isEmpty
                ? null
                : clearConversation,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoadingHistory
          ? const _AtlasAiHistoryLoadingView()
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      _AtlasAiContextBanner(contextData: contextData),
                      if (memoryData != null && memoryData!.hasHistory)
                        _AtlasAiMemoryPanel(
                          memory: memoryData!,
                          onResume: resumeLastTopic,
                          onQuestionSelected: sendQuestion,
                        ),
                      if (trackedActions.isNotEmpty)
                        _AtlasAiTrackedActionsPanel(
                          actions: filteredTrackedActions,
                          progress: actionProgress,
                          selectedStatus: selectedActionStatus,
                          onSelectStatus: _selectActionStatus,
                          onChangeStatus: _changeActionStatus,
                          onEditNotes: _editActionNotes,
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                          itemCount: messages.length + (isProcessing ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return const _AtlasAiTypingBubble();
                            }

                            final item = messages[index];

                            if (item.isUser) {
                              return _AtlasAiUserBubble(text: item.text!);
                            }

                            return _AtlasAiResponseBubble(
                              response: item.response!,
                              onActionPressed: handleNavigation,
                            );
                          },
                        ),
                      ),
                      if (effectiveSuggestedQuestions.isNotEmpty)
                        _AtlasAiSuggestions(
                          questions: effectiveSuggestedQuestions,
                          enabled: !isProcessing,
                          onSelected: sendQuestion,
                        ),
                      _AtlasAiInputBar(
                        controller: inputController,
                        enabled: !isProcessing,
                        onSend: sendQuestion,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _AtlasAiHistoryLoadingView extends StatelessWidget {
  const _AtlasAiHistoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text(
              'Carregando memória da conversa...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtlasAiMemoryPanel extends StatefulWidget {
  const _AtlasAiMemoryPanel({
    required this.memory,
    required this.onResume,
    required this.onQuestionSelected,
  });

  final AtlasAiMemory memory;
  final VoidCallback onResume;
  final ValueChanged<String> onQuestionSelected;

  @override
  State<_AtlasAiMemoryPanel> createState() {
    return _AtlasAiMemoryPanelState();
  }
}

class _AtlasAiMemoryPanelState extends State<_AtlasAiMemoryPanel> {
  bool expanded = false;

  AtlasAiMemory get memory => widget.memory;

  @override
  Widget build(BuildContext context) {
    final mainIntent = memory.mostFrequentIntents.isEmpty
        ? null
        : memory.mostFrequentIntents.first;

    final mainArea = memory.frequentAreas.isEmpty
        ? null
        : memory.frequentAreas.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECF7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF6A1B9A).withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.memory_outlined,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Memória da Fazenda',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A235A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memory.summary,
                          maxLines: expanded ? 8 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.35,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MemoryMetricChip(
                        label: 'Perguntas',
                        value: memory.userQuestionCount.toString(),
                      ),
                      _MemoryMetricChip(
                        label: 'Respostas',
                        value: memory.assistantResponseCount.toString(),
                      ),
                      _MemoryMetricChip(
                        label: 'Ações pendentes',
                        value: memory.pendingActions.length.toString(),
                      ),
                      if (mainIntent != null)
                        _MemoryMetricChip(
                          label: 'Assunto principal',
                          value: mainIntent.label,
                        ),
                      if (mainArea != null)
                        _MemoryMetricChip(
                          label: 'Área principal',
                          value: mainArea.label,
                        ),
                    ],
                  ),
                  if (memory.lastQuestion != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Último assunto',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            memory.lastQuestion!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 9),
                          FilledButton.tonalIcon(
                            onPressed: widget.onResume,
                            icon: const Icon(Icons.history_outlined),
                            label: const Text('Retomar assunto'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (memory.pendingActions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Ações discutidas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...memory.pendingActions.take(3).map((action) {
                      return _MemoryPendingActionTile(action: action);
                    }),
                  ],
                  if (memory.suggestedQuestions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Perguntas para retomar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: memory.suggestedQuestions.take(4).map((
                        question,
                      ) {
                        return ActionChip(
                          avatar: const Icon(Icons.refresh_outlined, size: 16),
                          label: Text(question),
                          onPressed: () {
                            widget.onQuestionSelected(question);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemoryMetricChip extends StatelessWidget {
  const _MemoryMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF6A1B9A),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MemoryPendingActionTile extends StatelessWidget {
  const _MemoryPendingActionTile({required this.action});

  final AtlasAiMemoryPendingAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.pending_actions_outlined,
            color: Color(0xFFEF6C00),
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  action.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${atlasFarmAreaLabel(action.area)} · '
                  '${action.deadlineDays} dias',
                  style: const TextStyle(color: Colors.black38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AtlasAiTrackedActionsPanel extends StatefulWidget {
  const _AtlasAiTrackedActionsPanel({
    required this.actions,
    required this.progress,
    required this.selectedStatus,
    required this.onSelectStatus,
    required this.onChangeStatus,
    required this.onEditNotes,
  });

  final List<AtlasAiTrackedAction> actions;
  final AtlasAiActionProgress progress;

  final AtlasAiTrackedActionStatus? selectedStatus;

  final ValueChanged<AtlasAiTrackedActionStatus?> onSelectStatus;

  final void Function(
    AtlasAiTrackedAction action,
    AtlasAiTrackedActionStatus status,
  )
  onChangeStatus;

  final ValueChanged<AtlasAiTrackedAction> onEditNotes;

  @override
  State<_AtlasAiTrackedActionsPanel> createState() {
    return _AtlasAiTrackedActionsPanelState();
  }
}

class _AtlasAiTrackedActionsPanelState
    extends State<_AtlasAiTrackedActionsPanel> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4F8),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ações da Consultoria',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${progress.completed} concluídas · '
                          '${progress.inProgress} em andamento · '
                          '${progress.pending} pendentes'
                          '${progress.overdue > 0 ? ' · ${progress.overdue} atrasadas' : ''}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${progress.completionPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      minHeight: 9,
                      value: progress.completionPercent / 100,
                      backgroundColor: const Color(
                        0xFF1565C0,
                      ).withValues(alpha: 0.10),
                    ),
                  ),
                  const SizedBox(height: 13),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ActionStatusFilterChip(
                          label: 'Todas',
                          selected: widget.selectedStatus == null,
                          count: progress.total,
                          onTap: () {
                            widget.onSelectStatus(null);
                          },
                        ),
                        const SizedBox(width: 7),
                        ...AtlasAiTrackedActionStatus.values.map((status) {
                          final count = _statusCount(progress, status);

                          return Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: _ActionStatusFilterChip(
                              label: atlasAiTrackedActionStatusLabel(status),
                              selected: widget.selectedStatus == status,
                              count: count,
                              onTap: () {
                                widget.onSelectStatus(status);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  if (widget.actions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Nenhuma ação encontrada neste filtro.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    ...widget.actions.take(8).map((action) {
                      return _TrackedActionTile(
                        action: action,
                        onChangeStatus: widget.onChangeStatus,
                        onEditNotes: widget.onEditNotes,
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _statusCount(
    AtlasAiActionProgress progress,
    AtlasAiTrackedActionStatus status,
  ) {
    switch (status) {
      case AtlasAiTrackedActionStatus.pending:
        return progress.pending;

      case AtlasAiTrackedActionStatus.inProgress:
        return progress.inProgress;

      case AtlasAiTrackedActionStatus.completed:
        return progress.completed;

      case AtlasAiTrackedActionStatus.cancelled:
        return progress.cancelled;
    }
  }
}

class _ActionStatusFilterChip extends StatelessWidget {
  const _ActionStatusFilterChip({
    required this.label,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text('$label ($count)'),
      onSelected: (_) {
        onTap();
      },
    );
  }
}

class _TrackedActionTile extends StatelessWidget {
  const _TrackedActionTile({
    required this.action,
    required this.onChangeStatus,
    required this.onEditNotes,
  });

  final AtlasAiTrackedAction action;

  final void Function(
    AtlasAiTrackedAction action,
    AtlasAiTrackedActionStatus status,
  )
  onChangeStatus;

  final ValueChanged<AtlasAiTrackedAction> onEditNotes;

  @override
  Widget build(BuildContext context) {
    final color = _trackedActionColor(action);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                action.isOverdue
                    ? Icons.warning_amber_outlined
                    : Icons.task_alt_outlined,
                color: color,
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<AtlasAiTrackedActionStatus>(
                tooltip: 'Alterar status',
                onSelected: (status) {
                  onChangeStatus(action, status);
                },
                itemBuilder: (context) {
                  return AtlasAiTrackedActionStatus.values.map((status) {
                    return PopupMenuItem(
                      value: status,
                      child: Text(atlasAiTrackedActionStatusLabel(status)),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _TrackedActionChip(
                label: atlasAiTrackedActionStatusLabel(action.status),
                color: color,
              ),
              _TrackedActionChip(
                label: atlasFarmAreaLabel(action.area),
                color: const Color(0xFF6A1B9A),
              ),
              _TrackedActionChip(
                label: 'Prazo: ${_formatDate(action.dueDate)}',
                color: action.isOverdue
                    ? const Color(0xFFC62828)
                    : const Color(0xFF1565C0),
              ),
            ],
          ),
          if (action.notes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              'Observação: ${action.notes}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              onEditNotes(action);
            },
            icon: const Icon(Icons.edit_note_outlined),
            label: Text(
              action.notes.isEmpty
                  ? 'Adicionar observação'
                  : 'Editar observação',
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackedActionChip extends StatelessWidget {
  const _TrackedActionChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _trackedActionColor(AtlasAiTrackedAction action) {
  if (action.isOverdue) {
    return const Color(0xFFC62828);
  }

  switch (action.status) {
    case AtlasAiTrackedActionStatus.pending:
      return const Color(0xFFEF6C00);

    case AtlasAiTrackedActionStatus.inProgress:
      return const Color(0xFF1565C0);

    case AtlasAiTrackedActionStatus.completed:
      return const Color(0xFF1B5E20);

    case AtlasAiTrackedActionStatus.cancelled:
      return const Color(0xFF616161);
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

class _AtlasAiContextBanner extends StatelessWidget {
  const _AtlasAiContextBanner({required this.contextData});

  final AtlasAiFarmContext contextData;

  @override
  Widget build(BuildContext context) {
    final color = _diagnosticColor(contextData.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.psychology_outlined, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${contextData.farmName} · '
              '${contextData.score.toStringAsFixed(0)}/100 · '
              '${atlasDiagnosticLevelLabel(contextData.level)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(Icons.verified_outlined, color: Colors.black38, size: 16),
          const SizedBox(width: 5),
          const Text(
            'Contexto carregado',
            style: TextStyle(color: Colors.black45, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AtlasAiUserBubble extends StatelessWidget {
  const _AtlasAiUserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.only(left: 48, bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, height: 1.4),
        ),
      ),
    );
  }
}

class _AtlasAiResponseBubble extends StatefulWidget {
  const _AtlasAiResponseBubble({
    required this.response,
    required this.onActionPressed,
  });

  final AtlasAiResponse response;

  final ValueChanged<AtlasAiNavigationAction> onActionPressed;

  @override
  State<_AtlasAiResponseBubble> createState() {
    return _AtlasAiResponseBubbleState();
  }
}

class _AtlasAiResponseBubbleState extends State<_AtlasAiResponseBubble> {
  bool showDetails = false;

  AtlasAiResponse get response {
    return widget.response;
  }

  @override
  Widget build(BuildContext context) {
    final color = _diagnosticColor(response.level);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 860),
        margin: const EdgeInsets.only(right: 32, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.psychology_outlined, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      atlasAiIntentLabel(response.intent),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _ConfidenceBadge(confidence: response.confidence),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                response.directAnswer,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                response.justification,
                style: const TextStyle(color: Colors.black54, height: 1.5),
              ),
              if (response.evidences.isNotEmpty ||
                  response.actionPlan.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      showDetails = !showDetails;
                    });
                  },
                  icon: Icon(
                    showDetails ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    showDetails ? 'Ocultar detalhes' : 'Ver evidências e plano',
                  ),
                ),
              ],
              if (showDetails) ...[
                if (response.evidences.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Evidências',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 9),
                  ...response.evidences.map((evidence) {
                    return _EvidenceTile(evidence: evidence);
                  }),
                ],
                if (response.actionPlan.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Plano de ação',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 9),
                  ...response.actionPlan.map((step) {
                    return _ActionStepTile(step: step);
                  }),
                ],
              ],
              const Divider(height: 28),
              Text(
                'Próximo passo: ${response.nextStep}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (response.actions.isNotEmpty) ...[
                const SizedBox(height: 13),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: response.actions.map((action) {
                    return FilledButton.tonalIcon(
                      onPressed: () {
                        widget.onActionPressed(action);
                      },
                      icon: Icon(_navigationIcon(action.type)),
                      label: Text(action.label),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.evidence});

  final AtlasAiEvidence evidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fact_check_outlined,
            size: 19,
            color: Color(0xFF1565C0),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${evidence.label}: ${evidence.value}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  evidence.description,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionStepTile extends StatelessWidget {
  const _ActionStepTile({required this.step});

  final AtlasAiResponseActionStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            child: Text(
              '${step.position}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 5),
                Text(
                  'Resultado esperado: ${step.expectedResult}',
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prazo: ${step.deadlineDays} dias',
                  style: const TextStyle(color: Colors.black38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AtlasAiSuggestions extends StatelessWidget {
  const _AtlasAiSuggestions({
    required this.questions,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> questions;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      color: Colors.white,
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: questions.length,
          separatorBuilder: (_, __) {
            return const SizedBox(width: 8);
          },
          itemBuilder: (context, index) {
            final question = questions[index];

            return ActionChip(
              avatar: const Icon(Icons.lightbulb_outline, size: 17),
              label: Text(question),
              onPressed: enabled
                  ? () {
                      onSelected(question);
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _AtlasAiInputBar extends StatelessWidget {
  const _AtlasAiInputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Pergunte sobre a fazenda...',
                prefixIcon: Icon(Icons.chat_outlined),
              ),
              onSubmitted: (_) {
                if (enabled) {
                  onSend();
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Enviar',
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _AtlasAiTypingBubble extends StatelessWidget {
  const _AtlasAiTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Analisando o contexto...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 80
        ? const Color(0xFF1B5E20)
        : confidence >= 60
        ? const Color(0xFFEF6C00)
        : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '${confidence.toStringAsFixed(0)}% confiança',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AtlasAiChatItem {
  const _AtlasAiChatItem._({
    required this.isUser,
    required this.createdAt,
    this.text,
    this.response,
  });

  factory _AtlasAiChatItem.user({required String text}) {
    return _AtlasAiChatItem._(
      isUser: true,
      createdAt: DateTime.now(),
      text: text,
    );
  }

  factory _AtlasAiChatItem.assistant({required AtlasAiResponse response}) {
    return _AtlasAiChatItem._(
      isUser: false,
      createdAt: response.generatedAt,
      response: response,
    );
  }

  factory _AtlasAiChatItem.fromStored(AtlasAiStoredMessage stored) {
    return _AtlasAiChatItem._(
      isUser: stored.isUser,
      createdAt: stored.createdAt,
      text: stored.text,
      response: stored.response,
    );
  }

  final bool isUser;
  final DateTime createdAt;
  final String? text;
  final AtlasAiResponse? response;

  AtlasAiStoredMessage toStored() {
    return AtlasAiStoredMessage(
      isUser: isUser,
      createdAt: createdAt,
      text: text,
      response: response,
    );
  }
}

Color _diagnosticColor(AtlasDiagnosticLevel level) {
  switch (level) {
    case AtlasDiagnosticLevel.excellent:
      return const Color(0xFF1B5E20);

    case AtlasDiagnosticLevel.stable:
      return const Color(0xFF2E7D32);

    case AtlasDiagnosticLevel.attention:
      return const Color(0xFFEF6C00);

    case AtlasDiagnosticLevel.critical:
      return const Color(0xFFC62828);
  }
}

IconData _navigationIcon(AtlasAiNavigationActionType type) {
  switch (type) {
    case AtlasAiNavigationActionType.openDiagnostic:
      return Icons.health_and_safety_outlined;

    case AtlasAiNavigationActionType.openPredictive:
      return Icons.auto_graph_outlined;

    case AtlasAiNavigationActionType.openFinance:
      return Icons.account_balance_wallet_outlined;

    case AtlasAiNavigationActionType.openHerd:
      return AtlasLivestockIcons.cow;

    case AtlasAiNavigationActionType.openPaddocks:
      return Icons.grid_view_outlined;

    case AtlasAiNavigationActionType.openInventory:
      return Icons.inventory_2_outlined;

    case AtlasAiNavigationActionType.openAgenda:
      return Icons.calendar_month_outlined;
  }
}
