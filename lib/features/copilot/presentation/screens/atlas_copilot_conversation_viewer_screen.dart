import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/copilot/data/services/atlas_copilot_history_storage_service.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_conversation_summary.dart';
import 'package:projeto_atlas/features/copilot/domain/models/atlas_copilot_message.dart';
import 'package:projeto_atlas/features/dashboard/domain/services/atlas_copilot_service.dart';

class AtlasCopilotConversationViewerScreen extends StatefulWidget {
  const AtlasCopilotConversationViewerScreen({
    required this.summary,
    required this.currentContextKey,
    super.key,
  });

  final AtlasCopilotConversationSummary summary;
  final String currentContextKey;

  @override
  State<AtlasCopilotConversationViewerScreen> createState() {
    return _AtlasCopilotConversationViewerScreenState();
  }
}

class _AtlasCopilotConversationViewerScreenState
    extends State<AtlasCopilotConversationViewerScreen> {
  final AtlasCopilotHistoryStorageService storage =
      const AtlasCopilotHistoryStorageService();

  bool isLoading = true;
  String? errorMessage;

  List<AtlasCopilotMessage> messages = [];

  bool get isCurrentContext {
    return widget.summary.contextKey == widget.currentContextKey;
  }

  @override
  void initState() {
    super.initState();
    loadConversation();
  }

  Future<void> loadConversation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loaded = await storage.load(contextKey: widget.summary.contextKey);

      if (!mounted) {
        return;
      }

      setState(() {
        messages = loaded;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Não foi possível carregar esta conversa.';
        isLoading = false;
      });
    }
  }

  Future<void> confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir conversa?'),
          content: Text(
            'O histórico de "${widget.summary.contextLabel}" será apagado.',
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
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await storage.clear(contextKey: widget.summary.contextKey);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      const AtlasCopilotConversationViewerResult(
        deleted: true,
        continueCurrentConversation: false,
      ),
    );
  }

  void continueConversation() {
    Navigator.of(context).pop(
      const AtlasCopilotConversationViewerResult(
        deleted: false,
        continueCurrentConversation: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.summary.contextLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '${widget.summary.messageCount} mensagens',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Excluir conversa',
            onPressed: isLoading ? null : confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _ConversationErrorView(
              message: errorMessage!,
              onRetry: loadConversation,
            )
          : messages.isEmpty
          ? const _ConversationEmptyView()
          : Column(
              children: [
                _ConversationContextBanner(
                  summary: widget.summary,
                  isCurrentContext: isCurrentContext,
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _ReadOnlyMessageBubble(message: messages[index]);
                    },
                  ),
                ),
                if (isCurrentContext)
                  SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: FilledButton.icon(
                        onPressed: continueConversation,
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Continuar conversa'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class AtlasCopilotConversationViewerResult {
  const AtlasCopilotConversationViewerResult({
    required this.deleted,
    required this.continueCurrentConversation,
  });

  final bool deleted;
  final bool continueCurrentConversation;
}

class _ConversationContextBanner extends StatelessWidget {
  const _ConversationContextBanner({
    required this.summary,
    required this.isCurrentContext,
  });

  final AtlasCopilotConversationSummary summary;
  final bool isCurrentContext;

  @override
  Widget build(BuildContext context) {
    final color = summary.isFarmContext
        ? const Color(0xFF1B5E20)
        : const Color(0xFF1565C0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      color: color.withValues(alpha: 0.09),
      child: Row(
        children: [
          Icon(
            summary.isFarmContext
                ? Icons.agriculture_outlined
                : Icons.business_outlined,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary.isFarmContext
                  ? 'Histórico da fazenda ${summary.contextLabel}'
                  : 'Histórico da operação consolidada',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isCurrentContext)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Contexto atual',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Text(
              'Somente leitura',
              style: TextStyle(color: Colors.black45, fontSize: 9),
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyMessageBubble extends StatelessWidget {
  const _ReadOnlyMessageBubble({required this.message});

  final AtlasCopilotMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: isUser
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUser ? Icons.person_outline : Icons.auto_awesome_outlined,
                  size: 17,
                  color: isUser ? Colors.white70 : const Color(0xFF1B5E20),
                ),
                const SizedBox(width: 7),
                Text(
                  isUser ? 'Você' : 'Copiloto Atlas',
                  style: TextStyle(
                    color: isUser ? Colors.white70 : const Color(0xFF1B5E20),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message.intent != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      atlasCopilotIntentLabel(message.intent!),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUser ? Colors.white54 : Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 9),
            SelectableText(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF263238),
                height: 1.48,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _formatDateTime(message.createdAt),
              style: TextStyle(
                color: isUser ? Colors.white54 : Colors.black38,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} · '
        '$hour:$minute';
  }
}

class _ConversationErrorView extends StatelessWidget {
  const _ConversationErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Color(0xFFC62828)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationEmptyView extends StatelessWidget {
  const _ConversationEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 52, color: Colors.black38),
            SizedBox(height: 14),
            Text(
              'Esta conversa está vazia.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
