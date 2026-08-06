
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/atlas_ai_2/data/atlas_ai_repository.dart';

class AtlasExecutiveAiScreen extends StatefulWidget {
  const AtlasExecutiveAiScreen({
    this.farmId,
    super.key,
  });

  final String? farmId;

  @override
  State<AtlasExecutiveAiScreen> createState() =>
      _AtlasExecutiveAiScreenState();
}

class _AtlasExecutiveAiScreenState
    extends State<AtlasExecutiveAiScreen> {
  final repository = AtlasAiRepository();

  Map<String, dynamic>? result;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    analyze();
  }

  Future<void> analyze() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await repository.executive(
        farmId: widget.farmId,
      );

      if (!mounted) return;

      setState(() => result = data);
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendations =
        ((result?['recommendations'] as List?) ??
                const <dynamic>[])
            .map(
              (item) => Map<String, dynamic>.from(
                item as Map,
              ),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Executive AI'),
        actions: [
          IconButton(
            onPressed: loading ? null : analyze,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricCard(
                          title: 'Score executivo',
                          value:
                              '${result?['executive_score'] ?? 0}',
                        ),
                        _MetricCard(
                          title: 'Situação',
                          value:
                              result?['status']?.toString() ??
                                  '',
                        ),
                        _MetricCard(
                          title: 'Recomendações',
                          value:
                              '${recommendations.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.gavel_outlined,
                        ),
                        title: const Text('Decisão oficial'),
                        subtitle: Text(
                          result?['official_decision']
                                  ?.toString() ??
                              '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Prioridades',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    ...recommendations.map(
                      (item) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              item['priority']
                                      ?.toString()
                                      .substring(0, 1)
                                      .toUpperCase() ??
                                  '-',
                            ),
                          ),
                          title: Text(
                            item['title']?.toString() ??
                                '',
                          ),
                          subtitle: Text(
                            '${item['summary'] ?? ''}\n'
                            'Confiança: ${item['confidence'] ?? 0}%',
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Card(
                      color: Color(0xFFFFF8E1),
                      child: ListTile(
                        leading: Icon(Icons.warning_amber),
                        title: Text('Limitações'),
                        subtitle: Text(
                          'O motor atual usa regras explicáveis e dados internos. '
                          'Toda decisão clínica, nutricional, comercial ou financeira '
                          'deve ser revisada por profissional responsável.',
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
