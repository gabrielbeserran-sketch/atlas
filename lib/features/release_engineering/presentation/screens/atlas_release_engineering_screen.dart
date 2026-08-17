import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/release_engineering/data/atlas_release_engineering_repository.dart';

class AtlasReleaseEngineeringScreen extends StatefulWidget {
  const AtlasReleaseEngineeringScreen({super.key});

  @override
  State<AtlasReleaseEngineeringScreen> createState() =>
      _AtlasReleaseEngineeringScreenState();
}

class _AtlasReleaseEngineeringScreenState
    extends State<AtlasReleaseEngineeringScreen> {
  final repository = AtlasReleaseEngineeringRepository();

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> builds = [];
  List<Map<String, dynamic>> deployments = [];
  List<Map<String, dynamic>> environments = [];
  List<Map<String, dynamic>> approvals = [];

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
        repository.builds(),
        repository.deployments(),
        repository.environments(),
        repository.approvals(),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        builds = values[1] as List<Map<String, dynamic>>;
        deployments = values[2] as List<Map<String, dynamic>>;
        environments = values[3] as List<Map<String, dynamic>>;
        approvals = values[4] as List<Map<String, dynamic>>;
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
    final readiness = dashboard['readiness'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Release Engineering'),
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
                      title: 'Builds',
                      value: '${dashboard['builds'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Builds aprovados',
                      value: '${dashboard['successful_builds'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Deployments',
                      value: '${dashboard['deployments'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Deployments concluídos',
                      value: '${dashboard['successful_deployments'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Aprovações pendentes',
                      value: '${dashboard['pending_approvals'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Pronto para produção',
                      value: readiness['ready'] == true ? 'Sim' : 'Não',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: const Text('Prontidão para produção'),
                    subtitle: Text(
                      'Checks obrigatórios: '
                      '${readiness['required_checks'] ?? 0} • '
                      'Aprovados: '
                      '${readiness['required_passed'] ?? 0} • '
                      'Bloqueios: ${readiness['blockers'] ?? 0}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Builds recentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (builds.isEmpty)
                  const Card(
                    child: ListTile(title: Text('Nenhum build registrado.')),
                  )
                else
                  ...builds
                      .take(8)
                      .map(
                        (item) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.build_circle_outlined),
                            title: Text('Versão ${item['version'] ?? ''}'),
                            subtitle: Text(
                              '${item['branch'] ?? ''} • '
                              '${item['status'] ?? ''}',
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                Text(
                  'Deployments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...deployments
                    .take(8)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.rocket_launch_outlined),
                          title: Text(item['strategy']?.toString() ?? ''),
                          subtitle: Text(
                            '${item['status'] ?? ''} • '
                            'Aprovação: '
                            '${item['approval_status'] ?? ''}',
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Ambientes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...environments
                    .take(6)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.cloud_outlined),
                          title: Text(item['name']?.toString() ?? ''),
                          subtitle: Text(
                            '${item['environment_type'] ?? ''} • '
                            '${item['base_url'] ?? ''}',
                          ),
                          trailing: item['protected'] == true
                              ? const Icon(Icons.lock_outline)
                              : null,
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Aprovações',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...approvals
                    .take(6)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.approval_outlined),
                          title: Text(item['title']?.toString() ?? ''),
                          subtitle: Text(
                            '${item['risk_level'] ?? ''} • '
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
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
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
