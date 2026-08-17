import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/integration_ecosystem/data/atlas_integrations_repository.dart';

class AtlasIntegrationEcosystemScreen extends StatefulWidget {
  const AtlasIntegrationEcosystemScreen({super.key});

  @override
  State<AtlasIntegrationEcosystemScreen> createState() =>
      _AtlasIntegrationEcosystemScreenState();
}

class _AtlasIntegrationEcosystemScreenState
    extends State<AtlasIntegrationEcosystemScreen> {
  final repository = AtlasIntegrationsRepository();

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> connections = [];
  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> deliveries = [];
  List<Map<String, dynamic>> partners = [];

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
      final values = await Future.wait([
        repository.dashboard(),
        repository.connections(),
        repository.syncJobs(),
        repository.webhookDeliveries(),
        repository.partnerApplications(),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        connections = values[1] as List<Map<String, dynamic>>;
        jobs = values[2] as List<Map<String, dynamic>>;
        deliveries = values[3] as List<Map<String, dynamic>>;
        partners = values[4] as List<Map<String, dynamic>>;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ecossistema de Integrações'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      title: 'Conexões',
                      value: '${dashboard['connections'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Conexões ativas',
                      value: '${dashboard['active_connections'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Conexões degradadas',
                      value: '${dashboard['degraded_connections'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Jobs pendentes',
                      value: '${dashboard['queued_jobs'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Webhooks pendentes',
                      value: '${dashboard['pending_webhooks'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Aplicações parceiras',
                      value: '${dashboard['active_partner_applications'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Conexões', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (connections.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('Nenhuma conexão configurada.'),
                    ),
                  )
                else
                  ...connections
                      .take(8)
                      .map(
                        (item) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.cable_outlined),
                            title: Text(item['name']?.toString() ?? ''),
                            subtitle: Text('Status: ${item['status'] ?? ''}'),
                            trailing: Text(
                              item['last_sync_at']?.toString() ?? 'Nunca',
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                Text(
                  'Sincronizações recentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...jobs
                    .take(6)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.sync),
                          title: Text(item['job_type']?.toString() ?? ''),
                          subtitle: Text(
                            '${item['direction'] ?? ''} • '
                            '${item['status'] ?? ''}',
                          ),
                          trailing: Text('${item['records_processed'] ?? 0}'),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Entregas de webhook',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...deliveries
                    .take(6)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.webhook_outlined),
                          title: Text(item['event_type']?.toString() ?? ''),
                          subtitle: Text(
                            '${item['status'] ?? ''} • '
                            'Tentativas: ${item['attempt_count'] ?? 0}',
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Parceiros',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...partners
                    .take(6)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.handshake_outlined),
                          title: Text(item['partner_name']?.toString() ?? ''),
                          subtitle: Text(item['name']?.toString() ?? ''),
                          trailing: Text(
                            '${item['rate_limit_per_minute'] ?? 0}/min',
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
