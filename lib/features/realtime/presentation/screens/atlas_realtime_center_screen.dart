
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/realtime/data/atlas_realtime_repository.dart';

class AtlasRealtimeCenterScreen extends StatefulWidget {
  const AtlasRealtimeCenterScreen({
    required this.companyId,
    this.farmId,
    this.baseWsUrl = 'ws://127.0.0.1:8000',
    super.key,
  });

  final String companyId;
  final String? farmId;
  final String baseWsUrl;

  @override
  State<AtlasRealtimeCenterScreen> createState() =>
      _AtlasRealtimeCenterScreenState();
}

class _AtlasRealtimeCenterScreenState
    extends State<AtlasRealtimeCenterScreen> {
  final repository = AtlasRealtimeRepository();
  StreamSubscription<Map<String, dynamic>>? subscription;

  List<Map<String, dynamic>> notifications = [];
  Map<String, dynamic> metrics = {};
  bool loading = true;
  bool connected = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
    subscription = repository
        .connect(
          baseWsUrl: widget.baseWsUrl,
          companyId: widget.companyId,
        )
        .listen(
          onRealtimeEvent,
          onError: (Object value) {
            if (!mounted) return;
            setState(() {
              connected = false;
              error = value.toString();
            });
          },
        );
  }

  @override
  void dispose() {
    subscription?.cancel();
    repository.close();
    super.dispose();
  }

  void onRealtimeEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    setState(() {
      connected = true;
      if (event['type'] == 'notification') {
        final value = event['notification'];
        if (value is Map) {
          notifications.insert(
            0,
            Map<String, dynamic>.from(value),
          );
        }
      }
    });
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final values = await Future.wait([
        repository.notifications(
          farmId: widget.farmId,
        ),
        repository.metrics(),
      ]);
      if (!mounted) return;
      setState(() {
        notifications =
            values[0] as List<Map<String, dynamic>>;
        metrics = values[1] as Map<String, dynamic>;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> markRead(
    Map<String, dynamic> notification,
  ) async {
    final id = notification['id']?.toString();
    if (id == null) return;
    await repository.markRead(id);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central em tempo real'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              connected
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
            ),
          ),
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null && notifications.isEmpty
              ? Center(child: Text(error!))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _Metric(
                          label: 'Conexões',
                          value:
                              '${metrics['connections'] ?? 0}',
                        ),
                        _Metric(
                          label: 'Salas',
                          value: '${metrics['rooms'] ?? 0}',
                        ),
                        _Metric(
                          label: 'Eventos',
                          value:
                              '${metrics['published_events'] ?? 0}',
                        ),
                        _Metric(
                          label: 'Notificações',
                          value: '${notifications.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Notificações',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    if (notifications.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text(
                            'Nenhuma notificação encontrada.',
                          ),
                        ),
                      )
                    else
                      ...notifications.map(
                        (item) => Card(
                          child: ListTile(
                            leading: Icon(
                              item['severity'] == 'critical'
                                  ? Icons.error_outline
                                  : item['severity'] == 'high'
                                      ? Icons.warning_amber
                                      : Icons
                                          .notifications_outlined,
                            ),
                            title: Text(
                              item['title']?.toString() ??
                                  '',
                            ),
                            subtitle: Text(
                              item['message']?.toString() ??
                                  '',
                            ),
                            trailing: item['read_at'] == null
                                ? IconButton(
                                    tooltip:
                                        'Marcar como lida',
                                    onPressed: () =>
                                        markRead(item),
                                    icon: const Icon(
                                      Icons.done,
                                    ),
                                  )
                                : const Icon(
                                    Icons.done_all,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(label),
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
