import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/widgets/atlas_command_center_module_card.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_intelligence.dart';
import 'package:projeto_atlas/core/services/atlas_canonical_operations_service.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_message.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_context_snapshot.dart';
import 'package:projeto_atlas/features/copilot/domain/services/atlas_copilot_context_service.dart';
import 'package:projeto_atlas/features/copilot/presentation/controllers/atlas_copilot_controller.dart';
import 'package:projeto_atlas/features/copilot/presentation/screens/atlas_copilot_feedback_analytics_screen.dart';
import 'package:projeto_atlas/features/copilot/presentation/screens/atlas_copilot_history_screen.dart';
import 'package:projeto_atlas/features/copilot/presentation/widgets/copilot_chat_bubble.dart';
import 'package:projeto_atlas/features/copilot/presentation/widgets/copilot_input_bar.dart';
import 'package:projeto_atlas/features/copilot/presentation/widgets/copilot_suggestions.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_operations_intelligence_service.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';

class AtlasCopilotScreen extends StatefulWidget {
  const AtlasCopilotScreen({
    this.operationBrief,
    this.farmIntelligence,
    this.executiveBrainData,
    this.canonicalOperations,
    this.onReactiveRefresh,
    this.onOpenExecutiveBrain,
    this.consultantName = 'Gabriel',
    this.onOpenIntelligence,
    this.onOpenFarmIntelligence,
    this.onOpenActions,
    this.onOpenFarms,
    this.onOpenFarm,
    this.onOpenFinance,
    this.onOpenHerd,
    this.onOpenPaddocks,
    this.onOpenInventory,
    this.onOpenAgenda,
    super.key,
  });

  final AtlasIntelligenceBrief? operationBrief;
  final AtlasFarmIntelligenceData? farmIntelligence;
  final AtlasExecutiveBrainData? executiveBrainData;
  final AtlasCanonicalOperationsData? canonicalOperations;

  final Future<void> Function(AtlasReactiveUpdate update)? onReactiveRefresh;

  final VoidCallback? onOpenExecutiveBrain;
  final String consultantName;

  final VoidCallback? onOpenIntelligence;
  final VoidCallback? onOpenFarmIntelligence;
  final VoidCallback? onOpenActions;
  final VoidCallback? onOpenFarms;
  final VoidCallback? onOpenFarm;
  final VoidCallback? onOpenFinance;
  final VoidCallback? onOpenHerd;
  final VoidCallback? onOpenPaddocks;
  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenAgenda;

  @override
  State<AtlasCopilotScreen> createState() {
    return _AtlasCopilotScreenState();
  }
}

class _AtlasCopilotScreenState extends State<AtlasCopilotScreen> {
  final AtlasReactiveIntelligenceCoordinator reactiveCoordinator =
      AtlasReactiveRuntime.instance.coordinator;

  late final AtlasCopilotController controller;
  late final String reactiveRegistrationId;

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    controller = AtlasCopilotController(
      service: const AtlasCopilotService(),
      operationBrief: widget.operationBrief,
      farmIntelligence: widget.farmIntelligence,
      consultantName: widget.consultantName,
    );

    controller.addListener(_handleControllerChange);

    AtlasReactiveRuntime.instance.start();

    reactiveRegistrationId = reactiveCoordinator.registerHandler(
      target: AtlasReactiveTarget.copilot,
      owner: 'atlas_copilot_screen',
      handler: _handleReactiveUpdate,
    );

    controller.initialize();
  }

  @override
  void dispose() {
    reactiveCoordinator.unregisterHandlerById(
      target: AtlasReactiveTarget.copilot,
      registrationId: reactiveRegistrationId,
    );

    controller.removeListener(_handleControllerChange);
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleReactiveUpdate(AtlasReactiveUpdate update) async {
    if (!mounted || !update.targets.contains(AtlasReactiveTarget.copilot)) {
      return;
    }

    final callback = widget.onReactiveRefresh;

    if (callback != null) {
      await callback(update);
    }

    await controller.reloadHistory();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }

  void scrollToBottom() {
    if (!scrollController.hasClients) {
      return;
    }

    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AtlasCopilotHistoryScreen(
            currentContextKey: controller.contextKey,
          );
        },
      ),
    );

    await controller.reloadHistory();
  }

  Future<void> openQualityPanel() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasCopilotFeedbackAnalyticsScreen();
        },
      ),
    );

    await controller.reloadHistory();
  }

  Future<void> handleFeedback(
    String messageId,
    AtlasCopilotMessageFeedback feedback,
  ) async {
    await controller.registerFeedback(messageId: messageId, feedback: feedback);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          content: Text(
            feedback == AtlasCopilotMessageFeedback.useful
                ? 'Obrigado! Resposta marcada como útil.'
                : 'Obrigado! Resposta marcada como não útil.',
          ),
        ),
      );
  }

  void handleAction(AtlasCopilotAction action) {
    final callback = switch (action.type) {
      AtlasCopilotActionType.openIntelligence => widget.onOpenIntelligence,
      AtlasCopilotActionType.openFarmIntelligence =>
        widget.onOpenFarmIntelligence,
      AtlasCopilotActionType.openActions => widget.onOpenActions,
      AtlasCopilotActionType.openFarms => widget.onOpenFarms,
      AtlasCopilotActionType.openFarm => widget.onOpenFarm,
      AtlasCopilotActionType.openFinance => widget.onOpenFinance,
      AtlasCopilotActionType.openHerd => widget.onOpenHerd,
      AtlasCopilotActionType.openPaddocks => widget.onOpenPaddocks,
      AtlasCopilotActionType.openInventory => widget.onOpenInventory,
      AtlasCopilotActionType.openAgenda => widget.onOpenAgenda,
    };

    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A ação "${action.label}" ainda não está disponível neste contexto.',
          ),
        ),
      );
      return;
    }

    callback();
  }

  Future<void> confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limpar conversa?'),
          content: Text(
            'O histórico de "${controller.contextLabel}" será removido.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.clearConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contextSnapshot = const AtlasCopilotContextService().build(
      contextLabel: controller.contextLabel,
      hasFarmContext: controller.hasFarmContext,
      hasOperationBrief: controller.operationBrief != null,
      suggestedQuestions: controller.suggestedQuestions,
      executiveBrainData: widget.executiveBrainData,
      canonicalOperations: widget.canonicalOperations,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atlas AI Copilot 2.0',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              controller.contextLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Qualidade das respostas',
            onPressed: controller.isInitializing ? null : openQualityPanel,
            icon: const Icon(Icons.analytics_outlined),
          ),
          IconButton(
            tooltip: 'Históricos',
            onPressed: controller.isInitializing ? null : openHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Limpar conversa',
            onPressed: controller.isProcessing || controller.isInitializing
                ? null
                : confirmClear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: controller.isInitializing
          ? const _CopilotLoadingView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AtlasCommandCenterModuleCard(
                    module: AtlasCommandCenterModule.copilot,
                    farmName: widget.farmIntelligence?.farmName,
                  ),
                ),
                _CopilotContextBanner(controller: controller),
                if (widget.executiveBrainData != null &&
                    widget.executiveBrainData!.officialDecision != null)
                  _CopilotExecutiveDecisionBanner(
                    data: widget.executiveBrainData!,
                    onOpen: widget.onOpenExecutiveBrain,
                  ),
                _CopilotIntelligenceContextPanel(
                  snapshot: contextSnapshot,
                  enabled: !controller.isProcessing,
                  onPromptSelected: controller.selectSuggestion,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    itemCount:
                        controller.messages.length +
                        (controller.isProcessing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.messages.length) {
                        return const _CopilotTypingIndicator();
                      }

                      final message = controller.messages[index];

                      return CopilotChatBubble(
                        message: message,
                        onActionPressed: handleAction,
                        onFeedback: handleFeedback,
                      );
                    },
                  ),
                ),
                CopilotSuggestions(
                  suggestions: controller.suggestedQuestions,
                  enabled: !controller.isProcessing,
                  onSelected: controller.selectSuggestion,
                ),
                CopilotInputBar(
                  enabled: !controller.isProcessing,
                  onSend: controller.sendQuestion,
                ),
              ],
            ),
    );
  }
}

class _CopilotExecutiveDecisionBanner extends StatelessWidget {
  const _CopilotExecutiveDecisionBanner({
    required this.data,
    required this.onOpen,
  });

  final AtlasExecutiveBrainData data;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final decision = data.officialDecision;

    if (decision == null) {
      return const SizedBox.shrink();
    }

    final color = switch (decision.priority) {
      AtlasExecutiveBrainPriority.low => const Color(0xFF2E7D32),
      AtlasExecutiveBrainPriority.medium => const Color(0xFF1565C0),
      AtlasExecutiveBrainPriority.high => const Color(0xFFEF6C00),
      AtlasExecutiveBrainPriority.critical => const Color(0xFFC62828),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel_outlined, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Decisão oficial ativa',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  decision.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${decision.confidencePercent.toStringAsFixed(0)}% de confiança · '
                  '${decision.deadlineHours} horas',
                  style: const TextStyle(color: Colors.black54, fontSize: 9),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              tooltip: 'Abrir Executive Brain',
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_outlined),
            ),
        ],
      ),
    );
  }
}

class _CopilotIntelligenceContextPanel extends StatefulWidget {
  const _CopilotIntelligenceContextPanel({
    required this.snapshot,
    required this.enabled,
    required this.onPromptSelected,
  });

  final AtlasCopilotContextSnapshot snapshot;
  final bool enabled;
  final ValueChanged<String> onPromptSelected;

  @override
  State<_CopilotIntelligenceContextPanel> createState() {
    return _CopilotIntelligenceContextPanelState();
  }
}

class _CopilotIntelligenceContextPanelState
    extends State<_CopilotIntelligenceContextPanel> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final scoreColor = snapshot.contextScore >= 70
        ? const Color(0xFF2E7D32)
        : snapshot.contextScore >= 50
        ? const Color(0xFFEF6C00)
        : const Color(0xFFC62828);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E6EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF123B5D).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.hub_outlined,
                      color: Color(0xFF123B5D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contexto inteligente conectado',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${snapshot.modeLabel} · ${snapshot.connectedSources.length} fonte(s)',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${snapshot.contextScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        snapshot.qualityLabel,
                        style: TextStyle(color: scoreColor, fontSize: 9),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
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
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CopilotContextMetric(
                          label: 'Confiança',
                          value:
                              '${snapshot.confidencePercent.toStringAsFixed(0)}%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CopilotContextMetric(
                          label: 'Sinais ativos',
                          value: snapshot.activeSignals.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CopilotContextMetric(
                          label: 'Fontes',
                          value: snapshot.connectedSources.length.toString(),
                        ),
                      ),
                    ],
                  ),
                  if (snapshot.activeSignals.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Sinais utilizados na análise',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ...snapshot.activeSignals
                        .take(4)
                        .map(
                          (signal) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 15,
                                  color: Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    signal,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                  if (snapshot.recommendedPrompts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Análises rápidas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: snapshot.recommendedPrompts.map((prompt) {
                        return ActionChip(
                          avatar: const Icon(Icons.auto_awesome, size: 15),
                          label: Text(prompt, overflow: TextOverflow.ellipsis),
                          onPressed: widget.enabled
                              ? () => widget.onPromptSelected(prompt)
                              : null,
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

class _CopilotContextMetric extends StatelessWidget {
  const _CopilotContextMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _CopilotLoadingView extends StatelessWidget {
  const _CopilotLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Carregando histórico...',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _CopilotContextBanner extends StatelessWidget {
  const _CopilotContextBanner({required this.controller});

  final AtlasCopilotController controller;

  @override
  Widget build(BuildContext context) {
    final hasContext =
        controller.operationBrief != null ||
        controller.farmIntelligence != null;

    final color = hasContext
        ? const Color(0xFF1B5E20)
        : const Color(0xFFEF6C00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: color.withValues(alpha: 0.09),
      child: Row(
        children: [
          Icon(
            hasContext ? Icons.verified_outlined : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasContext
                  ? 'Contexto ativo: ${controller.contextLabel}'
                  : 'O Copiloto está sem contexto de dados.',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.history, color: Colors.black38, size: 15),
          const SizedBox(width: 4),
          const Text(
            'Histórico salvo',
            style: TextStyle(color: Colors.black45, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _CopilotTypingIndicator extends StatelessWidget {
  const _CopilotTypingIndicator();

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
              'Analisando os dados...',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
