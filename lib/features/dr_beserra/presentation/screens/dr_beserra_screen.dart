import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/dr_beserra/data/services/dr_beserra_command_gateway.dart';
import 'package:projeto_atlas/features/dr_beserra/data/services/dr_beserra_voice_service.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_command.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_operation_draft.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';

class DrBeserraScreen extends StatefulWidget {
  const DrBeserraScreen({
    required this.farm,
    required this.onNavigateModule,
    this.embedded = false,
    super.key,
  });

  final FarmData farm;
  final ValueChanged<String> onNavigateModule;
  final bool embedded;

  @override
  State<DrBeserraScreen> createState() => _DrBeserraScreenState();
}

class _DrBeserraScreenState extends State<DrBeserraScreen> {
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final DrBeserraCommandGateway gateway = DrBeserraCommandGateway();
  final DrBeserraVoiceService voice = DrBeserraVoiceService.instance;

  final List<_ChatMessage> messages = const [
    _ChatMessage(
      fromUser: false,
      text:
          'Pode falar do jeito que você fala no dia a dia. Eu consulto os dados oficiais do Atlas e nunca altero um registro sem uma ação permitida.',
    ),
  ].toList();

  bool busy = false;
  bool voiceReady = false;
  String lastVoiceFinal = '';
  String? confirmationTaskId;
  String? confirmationTaskTitle;
  DrBeserraOperationDraft? confirmationOperation;
  String? confirmationOperationTitle;
  String? relatedTaskId;
  String? relatedTaskTitle;

  @override
  void initState() {
    super.initState();
    voice.state.addListener(_onVoiceStateChanged);
    _initializeVoice();
  }

  @override
  void dispose() {
    voice.state.removeListener(_onVoiceStateChanged);
    voice.stopListening();
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoice() async {
    final available = await voice.initialize();
    if (!mounted) return;
    setState(() => voiceReady = available);
  }

  Future<void> toggleVoice() async {
    if (busy) return;

    if (voice.state.value.listening) {
      await voice.stopListening();
      return;
    }

    final available = await voice.startListening();
    if (!mounted) return;

    setState(() => voiceReady = available);
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            voice.state.value.errorMessage.isEmpty
                ? 'O reconhecimento de voz não está disponível neste dispositivo.'
                : voice.state.value.errorMessage,
          ),
        ),
      );
    }
  }

  void _onVoiceStateChanged() {
    if (!mounted) return;
    final state = voice.state.value;

    if (state.transcript.isNotEmpty && state.transcript != inputController.text) {
      inputController.value = TextEditingValue(
        text: state.transcript,
        selection: TextSelection.collapsed(
          offset: state.transcript.length,
        ),
      );
    }

    if (state.errorMessage.isNotEmpty) {
      setState(() => voiceReady = state.available);
    } else {
      setState(() => voiceReady = state.available);
    }

    if (state.finalResult &&
        state.transcript.trim().isNotEmpty &&
        state.transcript.trim() != lastVoiceFinal) {
      lastVoiceFinal = state.transcript.trim();
      voice.clearFinalResult();
      sendText(lastVoiceFinal);
    }
  }

  Future<void> sendText([String? suggested]) async {
    final text = (suggested ?? inputController.text).trim();
    if (text.isEmpty || busy) return;

    inputController.clear();
    setState(() {
      busy = true;
      confirmationTaskId = null;
      confirmationTaskTitle = null;
      confirmationOperation = null;
      confirmationOperationTitle = null;
      relatedTaskId = null;
      relatedTaskTitle = null;
      messages.add(_ChatMessage(fromUser: true, text: text));
    });
    _scrollToEnd();

    try {
      final reply = await gateway.interpret(
        farm: widget.farm,
        text: text,
      );
      if (!mounted) return;
      _applyReply(reply);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        messages.add(
          const _ChatMessage(
            fromUser: false,
            text:
                'Não consegui confirmar essa informação no sistema agora. Nenhum registro foi alterado.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => busy = false);
        _scrollToEnd();
      }
    }
  }

  Future<void> confirmOperation() async {
    final operation = confirmationOperation;
    if (operation == null || busy) return;

    setState(() => busy = true);
    try {
      final reply = await gateway.confirmOperation(
        farm: widget.farm,
        operation: operation,
        relatedTaskId: relatedTaskId ?? '',
        relatedTaskTitle: relatedTaskTitle ?? '',
      );
      if (!mounted) return;
      setState(() {
        confirmationOperation = null;
        confirmationOperationTitle = null;
        relatedTaskId = null;
        relatedTaskTitle = null;
        messages.add(_ChatMessage(fromUser: false, text: reply.message));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        confirmationOperation = null;
        confirmationOperationTitle = null;
        relatedTaskId = null;
        relatedTaskTitle = null;
        messages.add(
          const _ChatMessage(
            fromUser: false,
            text:
                'Não consegui confirmar a operação no servidor. Nenhum sucesso foi informado e você deve conferir o módulo oficial antes de tentar novamente.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => busy = false);
        _scrollToEnd();
      }
    }
  }

  Future<void> confirmCompletion() async {
    final id = confirmationTaskId;
    if (id == null || busy) return;

    setState(() => busy = true);
    try {
      final reply = await gateway.confirmTaskCompletion(
        farm: widget.farm,
        taskId: id,
      );
      if (!mounted) return;
      setState(() {
        confirmationTaskId = null;
        confirmationTaskTitle = null;
        messages.add(_ChatMessage(fromUser: false, text: reply.message));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        confirmationTaskId = null;
        confirmationTaskTitle = null;
        messages.add(
          const _ChatMessage(
            fromUser: false,
            text:
                'Não consegui confirmar a conclusão no servidor. A tarefa foi mantida como estava.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => busy = false);
        _scrollToEnd();
      }
    }
  }

  void cancelConfirmation() {
    setState(() {
      confirmationTaskId = null;
      confirmationTaskTitle = null;
      confirmationOperation = null;
      confirmationOperationTitle = null;
      relatedTaskId = null;
      relatedTaskTitle = null;
      messages.add(
        const _ChatMessage(
          fromUser: false,
          text: 'Certo. Não alterei nada.',
        ),
      );
    });
  }

  void _applyReply(DrBeserraReply reply) {
    setState(() {
      messages.add(_ChatMessage(fromUser: false, text: reply.message));
      confirmationTaskId = reply.confirmationTaskId;
      confirmationTaskTitle = reply.confirmationTaskTitle;
      confirmationOperation = reply.confirmationOperation;
      confirmationOperationTitle = reply.confirmationOperationTitle;
      relatedTaskId = reply.relatedTaskId;
      relatedTaskTitle = reply.relatedTaskTitle;
    });

    final route = reply.routeLabel;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onNavigateModule(route);
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _DrBeserraHeader(farmName: widget.farm.name),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            itemCount: messages.length,
            itemBuilder: (context, index) =>
                _MessageBubble(message: messages[index]),
          ),
        ),
        if (confirmationOperation != null)
          _ConfirmationBar(
            title: confirmationOperationTitle ?? 'operação',
            busy: busy,
            onConfirm: confirmOperation,
            onCancel: cancelConfirmation,
          ),
        if (confirmationTaskId != null)
          _ConfirmationBar(
            title: confirmationTaskTitle ?? 'atividade',
            busy: busy,
            onConfirm: confirmCompletion,
            onCancel: cancelConfirmation,
          ),
        _QuickActions(
          enabled: !busy,
          onSelected: sendText,
        ),
        _Composer(
          controller: inputController,
          busy: busy,
          voiceReady: voiceReady,
          listening: voice.state.value.listening,
          onSend: sendText,
          onVoice: toggleVoice,
        ),
      ],
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Dr. Beserra')),
      body: content,
    );
  }
}

class _DrBeserraHeader extends StatelessWidget {
  const _DrBeserraHeader({required this.farmName});

  final String farmName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            child: Icon(Icons.record_voice_over_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Beserra',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text('$farmName • conversa segura com o Atlas'),
                const SizedBox(height: 4),
                const Text(
                  'Você pode escrever ou tocar no microfone e falar. O áudio vira texto e segue as mesmas regras de segurança da conversa.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.enabled,
    required this.onSelected,
  });

  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const suggestions = <String>[
      'O que tenho hoje?',
      'O que tenho amanhã?',
      'O que ficou atrasado?',
      'Qual a prioridade hoje?',
      'O que merece atenção hoje?',
      'Como estão as matrizes?',
      'Qual lote está pior?',
      'O que está pesando no financeiro?',
      'Realizar manejo',
      'Abrir sanidade',
      'Abrir reprodução',
      'Abrir nutrição',
      'Ver indicadores',
      'Vacinar brinco 101',
      'Fazer IATF no brinco 101',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: suggestions
            .map(
              (text) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(text),
                  onPressed: enabled ? () => onSelected(text) : null,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.voiceReady,
    required this.listening,
    required this.onSend,
    required this.onVoice,
  });

  final TextEditingController controller;
  final bool busy;
  final bool voiceReady;
  final bool listening;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !busy,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Ex.: terminei vacinação',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: listening
                  ? 'Parar de ouvir'
                  : voiceReady
                      ? 'Falar com Dr. Beserra'
                      : 'Verificar microfone',
              onPressed: busy ? null : onVoice,
              icon: Icon(
                listening ? Icons.stop_circle_outlined : Icons.mic_outlined,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Enviar mensagem',
              onPressed: busy ? null : onSend,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationBar extends StatelessWidget {
  const _ConfirmationBar({
    required this.title,
    required this.busy,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Confirmar conclusão de “$title”?',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: busy ? null : onCancel,
              child: const Text('Não'),
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: busy ? null : onConfirm,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.fromUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(message.text),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.fromUser,
    required this.text,
  });

  final bool fromUser;
  final String text;
}
