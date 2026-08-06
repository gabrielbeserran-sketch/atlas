
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/analytics/data/atlas_analytics_repository.dart';

class AtlasBiDashboardScreen extends StatefulWidget {
  const AtlasBiDashboardScreen({
    this.farmId,
    super.key,
  });

  final String? farmId;

  @override
  State<AtlasBiDashboardScreen> createState() =>
      _AtlasBiDashboardScreenState();
}

class _AtlasBiDashboardScreenState
    extends State<AtlasBiDashboardScreen> {
  final repository = AtlasAnalyticsRepository();

  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await repository.dashboard(
        farmId: widget.farmId,
      );

      if (!mounted) return;

      setState(() => data = result);
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> refreshWarehouse() async {
    setState(() => loading = true);

    try {
      await repository.refreshWarehouse(
        farmId: widget.farmId,
      );
      await load();
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = exception.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final facts =
        ((data?['facts'] as List?) ?? const <dynamic>[])
            .map(
              (item) => Map<String, dynamic>.from(
                item as Map,
              ),
            )
            .toList();
    final goals =
        ((data?['goals'] as List?) ?? const <dynamic>[])
            .map(
              (item) => Map<String, dynamic>.from(
                item as Map,
              ),
            )
            .toList();
    final scores =
        ((data?['scores'] as List?) ?? const <dynamic>[])
            .map(
              (item) => Map<String, dynamic>.from(
                item as Map,
              ),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas BI Enterprise'),
        actions: [
          IconButton(
            onPressed: loading ? null : refreshWarehouse,
            tooltip: 'Atualizar Data Warehouse',
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Recarregar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: facts.take(12).map((fact) {
                        return SizedBox(
                          width: 250,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fact['metric_name']
                                            ?.toString() ??
                                        '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${fact['value'] ?? 0} ${fact['unit'] ?? ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    fact['formula']
                                            ?.toString() ??
                                        '',
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Metas',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    if (goals.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text(
                            'Nenhuma meta cadastrada.',
                          ),
                        ),
                      )
                    else
                      ...goals.map(
                        (goal) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.flag_outlined,
                            ),
                            title: Text(
                              goal['title']?.toString() ??
                                  '',
                            ),
                            subtitle: Text(
                              'Atual: ${goal['current_value']} • '
                              'Meta: ${goal['target_value']} • '
                              '${goal['status']}',
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Histórico do score',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    if (scores.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text(
                            'Gere o primeiro score da fazenda.',
                          ),
                        ),
                      )
                    else
                      ...scores.map(
                        (score) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                score['grade']?.toString() ??
                                    '-',
                              ),
                            ),
                            title: Text(
                              'Score ${score['score']}',
                            ),
                            subtitle: Text(
                              score['period_end']
                                      ?.toString() ??
                                  '',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
