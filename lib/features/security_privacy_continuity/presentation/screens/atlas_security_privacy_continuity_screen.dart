import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/security_privacy_continuity/data/atlas_security_enterprise_repository.dart';

class AtlasSecurityPrivacyContinuityScreen extends StatefulWidget {
  const AtlasSecurityPrivacyContinuityScreen({super.key});

  @override
  State<AtlasSecurityPrivacyContinuityScreen> createState() =>
      _AtlasSecurityPrivacyContinuityScreenState();
}

class _AtlasSecurityPrivacyContinuityScreenState
    extends State<AtlasSecurityPrivacyContinuityScreen> {
  final repository = AtlasSecurityEnterpriseRepository();

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> policies = [];
  List<Map<String, dynamic>> reviews = [];
  List<Map<String, dynamic>> privacyRequests = [];
  List<Map<String, dynamic>> risks = [];
  List<Map<String, dynamic>> plans = [];

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
        repository.policies(),
        repository.accessReviews(),
        repository.privacyRequests(),
        repository.risks(),
        repository.continuityPlans(),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        policies = values[1] as List<Map<String, dynamic>>;
        reviews = values[2] as List<Map<String, dynamic>>;
        privacyRequests = values[3] as List<Map<String, dynamic>>;
        risks = values[4] as List<Map<String, dynamic>>;
        plans = values[5] as List<Map<String, dynamic>>;
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
        title: const Text('Segurança, Privacidade e Continuidade'),
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
                      title: 'Postura de segurança',
                      value: '${dashboard['posture_score'] ?? 0}%',
                    ),
                    _MetricCard(
                      title: 'Políticas ativas',
                      value: '${dashboard['active_policies'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Riscos abertos',
                      value: '${dashboard['open_risks'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Revisões atrasadas',
                      value: '${dashboard['overdue_reviews'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Solicitações de privacidade',
                      value: '${dashboard['open_privacy_requests'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Planos sem teste',
                      value: '${dashboard['untested_continuity_plans'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Riscos prioritários',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (risks.isEmpty)
                  const Card(
                    child: ListTile(title: Text('Nenhum risco cadastrado.')),
                  )
                else
                  ...risks
                      .take(8)
                      .map(
                        (item) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.security_outlined),
                            title: Text(item['title']?.toString() ?? ''),
                            subtitle: Text(
                              '${item['category'] ?? ''} • '
                              '${item['status'] ?? ''}',
                            ),
                            trailing: Text('${item['score'] ?? 0}'),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                Text(
                  'Revisões de acesso',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...reviews
                    .take(6)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.manage_accounts_outlined),
                          title: Text(item['review_type']?.toString() ?? ''),
                          subtitle: Text(
                            'Usuário: ${item['subject_user_id'] ?? ''}',
                          ),
                          trailing: Text(item['status']?.toString() ?? ''),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Privacidade',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...privacyRequests
                    .take(6)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: Text(item['request_type']?.toString() ?? ''),
                          subtitle: Text(
                            item['data_subject_id']?.toString() ?? '',
                          ),
                          trailing: Text(item['status']?.toString() ?? ''),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Continuidade',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...plans
                    .take(6)
                    .map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.restore_page_outlined),
                          title: Text(item['name']?.toString() ?? ''),
                          subtitle: Text(
                            '${item['scenario'] ?? ''} • '
                            'RTO ${item['rto_minutes'] ?? 0} min • '
                            'RPO ${item['rpo_minutes'] ?? 0} min',
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
