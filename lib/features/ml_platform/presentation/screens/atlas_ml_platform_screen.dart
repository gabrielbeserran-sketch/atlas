import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/ml_platform/data/atlas_ml_repository.dart';

class AtlasMlPlatformScreen extends StatefulWidget {
  const AtlasMlPlatformScreen({super.key});

  @override
  State<AtlasMlPlatformScreen> createState() => _AtlasMlPlatformScreenState();
}

class _AtlasMlPlatformScreenState extends State<AtlasMlPlatformScreen> {
  final repository = AtlasMlRepository();

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> models = [];
  List<Map<String, dynamic>> deployments = [];
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
        repository.models(),
        repository.deployments(),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        models = values[1] as List<Map<String, dynamic>>;
        deployments = values[2] as List<Map<String, dynamic>>;
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
        title: const Text('Atlas Machine Learning'),
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
                      title: 'Datasets',
                      value: '${dashboard['datasets'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Modelos',
                      value: '${dashboard['models'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Deploys ativos',
                      value: '${dashboard['active_deployments'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Predições',
                      value: '${dashboard['predictions'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Alertas de deriva',
                      value: '${dashboard['drift_alerts'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Card(
                  color: Color(0xFFFFF8E1),
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Runtime explicável de baseline'),
                    subtitle: Text(
                      'A plataforma, o registro e o monitoramento estão prontos. '
                      'O runtime de artefatos treinados reais ainda deve ser conectado.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Modelos registrados',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                if (models.isEmpty)
                  const Card(
                    child: ListTile(title: Text('Nenhum modelo registrado.')),
                  )
                else
                  ...models.map(
                    (item) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.model_training),
                        title: Text(
                          '${item['name'] ?? ''} '
                          'v${item['version'] ?? ''}',
                        ),
                        subtitle: Text(
                          '${item['task_type'] ?? ''} • '
                          '${item['algorithm'] ?? ''}',
                        ),
                        trailing: Chip(
                          label: Text(item['status']?.toString() ?? ''),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Deployments',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                if (deployments.isEmpty)
                  const Card(
                    child: ListTile(title: Text('Nenhum modelo publicado.')),
                  )
                else
                  ...deployments.map(
                    (item) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.rocket_launch_outlined),
                        title: Text('Ambiente: ${item['environment'] ?? ''}'),
                        subtitle: Text(
                          'Tráfego: ${item['traffic_percent'] ?? 0}% • '
                          'Modelo: ${item['model_id'] ?? ''}',
                        ),
                        trailing: Chip(
                          label: Text(item['status']?.toString() ?? ''),
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
