import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_ai_2/data/atlas_ai_repository.dart';

class AtlasAiConversationScreen extends StatefulWidget {
  const AtlasAiConversationScreen({
    this.farmId,
    this.specialistArea = 'general',
    super.key,
  });

  final String? farmId;
  final String specialistArea;

  @override
  State<AtlasAiConversationScreen> createState() =>
      _AtlasAiConversationScreenState();
}

class _AtlasAiConversationScreenState extends State<AtlasAiConversationScreen> {
  final repository = AtlasAiRepository();
  final controller = TextEditingController();
  final scrollController = ScrollController();

  String? conversationId;
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      final conversation = await repository.createConversation(
        farmId: widget.farmId,
        specialistArea: widget.specialistArea,
        title: 'Atlas IA — ${widget.specialistArea}',
      );

      if (!mounted) return;

      setState(() {
        conversationId = conversation['id']?.toString();
        loading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = exception.toString();
        loading = false;
      });
    }
  }

  Future<void> send() async {
    final text = controller.text.trim();
    final id = conversationId;

    if (text.isEmpty || id == null || sending) return;

    controller.clear();
    setState(() => sending = true);

    try {
      final result = await repository.sendMessage(
        conversationId: id,
        content: text,
      );

      if (!mounted) return;

      setState(() => messages.addAll(result));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (exception) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.toString())));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Atlas IA — ${widget.specialistArea}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : Column(
              children: [
                const Card(
                  margin: EdgeInsets.all(12),
                  color: Color(0xFFFFF8E1),
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('IA explicável e baseada nos dados do Atlas'),
                    subtitle: Text(
                      'As respostas desta fase são produzidas por regras auditáveis. '
                      'Elas não substituem diagnóstico veterinário, recomendação nutricional '
                      'ou decisão financeira profissional.',
                    ),
                  ),
                ),
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('Envie uma pergunta para iniciar.'),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final item = messages[index];
                            final user = item['role'] == 'user';

                            return Align(
                              alignment: user
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 720,
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: user
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['content']?.toString() ?? ''),
                                    if (!user) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Confiança: ${item['confidence'] ?? 0}%',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            enabled: !sending,
                            minLines: 1,
                            maxLines: 4,
                            onSubmitted: (_) => send(),
                            decoration: const InputDecoration(
                              hintText: 'Pergunte ao Atlas...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: sending ? null : send,
                          icon: sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
