
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_ai_enterprise/data/atlas_ai_enterprise_repository.dart';

class AtlasAiEnterpriseScreen extends StatefulWidget {
  const AtlasAiEnterpriseScreen({
    this.farmId,
    super.key,
  });

  final String? farmId;

  @override
  State<AtlasAiEnterpriseScreen> createState() =>
      _AtlasAiEnterpriseScreenState();
}

class _AtlasAiEnterpriseScreenState
    extends State<AtlasAiEnterpriseScreen> {
  final repository = AtlasAiEnterpriseRepository();
  final messageController = TextEditingController();

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> recommendations = [];
  List<Map<String, dynamic>> plans = [];
  final List<Map<String, String>> messages = [];

  String? sessionId;
  bool loading = true;
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final values = await Future.wait([
        repository.dashboard(),
        repository.recommendations(
          farmId: widget.farmId,
        ),
        repository.plans(
          farmId: widget.farmId,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        recommendations =
            values[1] as List<Map<String, dynamic>>;
        plans = values[2] as List<Map<String, dynamic>>;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    final text = messageController.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      sending = true;
      messages.add({'role': 'user', 'content': text});
      messageController.clear();
    });

    try {
      final response = await repository.chat(
        sessionId: sessionId,
        farmId: widget.farmId,
        message: text,
      );

      if (!mounted) return;

      setState(() {
        sessionId = response['session_id']?.toString();
        messages.add({
          'role': 'assistant',
          'content': response['answer']?.toString() ?? '',
        });
      });

      await load();
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> createDailyPlan() async {
    await repository.createPlan(
      farmId: widget.farmId,
      horizon: 'daily',
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas IA Empresarial'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null && messages.isEmpty
              ? Center(child: Text(error!))
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                const Card(
                                  color: Color(0xFFE8F5E9),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.psychology_outlined,
                                    ),
                                    title: Text(
                                      'Copiloto empresarial explicável',
                                    ),
                                    subtitle: Text(
                                      'O motor atual usa regras e dados do Atlas. '
                                      'Ainda não existe conexão automática com LLM externo.',
                                    ),
                                  ),
                                ),
                                ...messages.map(
                                  (item) => Align(
                                    alignment:
                                        item['role'] == 'user'
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: Card(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(14),
                                        child: Text(
                                          item['content'] ?? '',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: messageController,
                                    minLines: 1,
                                    maxLines: 4,
                                    decoration:
                                        const InputDecoration(
                                      labelText:
                                          'Pergunte ao Atlas',
                                      border:
                                          OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) => send(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton.filled(
                                  onPressed: sending ? null : send,
                                  icon: sending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 380,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _Metric(
                            title: 'Recomendações pendentes',
                            value:
                                '${dashboard['pending_recommendations'] ?? 0}',
                          ),
                          _Metric(
                            title: 'Prioridade alta',
                            value:
                                '${dashboard['high_priority_recommendations'] ?? 0}',
                          ),
                          _Metric(
                            title: 'Planos ativos',
                            value:
                                '${dashboard['active_plans'] ?? 0}',
                          ),
                          _Metric(
                            title: 'Confiança média',
                            value:
                                '${dashboard['average_confidence'] ?? 0}%',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: createDailyPlan,
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            label: const Text(
                              'Gerar plano diário',
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Recomendações',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 8),
                          if (recommendations.isEmpty)
                            const Card(
                              child: ListTile(
                                title: Text(
                                  'Nenhuma recomendação pendente.',
                                ),
                              ),
                            )
                          else
                            ...recommendations.take(6).map(
                                  (item) => Card(
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.lightbulb_outline,
                                      ),
                                      title: Text(
                                        item['title']
                                                ?.toString() ??
                                            '',
                                      ),
                                      subtitle: Text(
                                        '${item['priority'] ?? ''} • '
                                        '${item['confidence_percent'] ?? 0}%',
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 18),
                          Text(
                            'Planos',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 8),
                          ...plans.take(4).map(
                                (item) => Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.checklist_outlined,
                                    ),
                                    title: Text(
                                      item['title']
                                              ?.toString() ??
                                          '',
                                    ),
                                    subtitle: Text(
                                      item['summary']
                                              ?.toString() ??
                                          '',
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
