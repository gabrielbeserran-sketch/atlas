
import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/governance_resilience/data/atlas_governance_repository.dart';

class AtlasGovernanceResilienceScreen extends StatefulWidget {
  const AtlasGovernanceResilienceScreen({super.key});

  @override
  State<AtlasGovernanceResilienceScreen> createState() =>
      _AtlasGovernanceResilienceScreenState();
}

class _AtlasGovernanceResilienceScreenState
    extends State<AtlasGovernanceResilienceScreen> {
  final repository = AtlasGovernanceRepository();

  Map<String, dynamic> dashboard = {};
  Map<String, dynamic> compliance = {};
  Map<String, dynamic> health = {};
  List<Map<String, dynamic>> assets = [];
  List<Map<String, dynamic>> incidents = [];

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
        repository.complianceScore(),
        repository.healthSummary(),
        repository.assets(),
        repository.incidents(),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        compliance = values[1] as Map<String, dynamic>;
        health = values[2] as Map<String, dynamic>;
        assets = values[3] as List<Map<String, dynamic>>;
        incidents = values[4] as List<Map<String, dynamic>>;
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
        title: const Text('Governança e Resiliência'),
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
                          title: 'Qualidade média',
                          value:
                              '${dashboard['data_quality_average'] ?? 0}%',
                        ),
                        _MetricCard(
                          title: 'Conformidade',
                          value:
                              '${dashboard['compliance_score'] ?? 0}%',
                        ),
                        _MetricCard(
                          title: 'Serviços saudáveis',
                          value:
                              '${dashboard['healthy_services'] ?? 0}',
                        ),
                        _MetricCard(
                          title: 'Serviços indisponíveis',
                          value:
                              '${dashboard['services_down'] ?? 0}',
                        ),
                        _MetricCard(
                          title: 'Incidentes abertos',
                          value:
                              '${dashboard['open_incidents'] ?? 0}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.verified_user_outlined,
                        ),
                        title: const Text('Resumo de conformidade'),
                        subtitle: Text(
                          'Controles: ${compliance['controls'] ?? 0} • '
                          'Avaliados: ${compliance['assessed_controls'] ?? 0} • '
                          'Não avaliados: ${compliance['unassessed_controls'] ?? 0}',
                        ),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.monitor_heart_outlined,
                        ),
                        title: const Text('Saúde da plataforma'),
                        subtitle: Text(
                          'Disponibilidade média: '
                          '${health['average_availability_percent'] ?? 0}% • '
                          'Latência média: '
                          '${health['average_latency_ms'] ?? 0} ms',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ativos de dados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (assets.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('Nenhum ativo catalogado.'),
                        ),
                      )
                    else
                      ...assets.take(8).map(
                            (item) => Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.dataset_outlined,
                                ),
                                title: Text(
                                  item['name']?.toString() ?? '',
                                ),
                                subtitle: Text(
                                  '${item['asset_type'] ?? ''} • '
                                  '${item['classification'] ?? ''}',
                                ),
                                trailing: Text(
                                  '${item['quality_score'] ?? 0}%',
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 24),
                    Text(
                      'Incidentes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (incidents.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('Nenhum incidente aberto.'),
                        ),
                      )
                    else
                      ...incidents.take(8).map(
                            (item) => Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.warning_amber_outlined,
                                ),
                                title: Text(
                                  item['title']?.toString() ?? '',
                                ),
                                subtitle: Text(
                                  '${item['severity'] ?? ''} • '
                                  '${item['status'] ?? ''}',
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
  const _MetricCard({
    required this.title,
    required this.value,
  });

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
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
