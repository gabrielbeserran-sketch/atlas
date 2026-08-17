import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/commercial_platform/data/atlas_commercial_repository.dart';

class AtlasCommercialDashboardScreen extends StatefulWidget {
  const AtlasCommercialDashboardScreen({super.key});

  @override
  State<AtlasCommercialDashboardScreen> createState() =>
      _AtlasCommercialDashboardScreenState();
}

class _AtlasCommercialDashboardScreenState
    extends State<AtlasCommercialDashboardScreen> {
  final repository = AtlasCommercialRepository();

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> opportunities = [];
  List<Map<String, dynamic>> invoices = [];
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
        repository.opportunities(),
        repository.invoices(status: 'open'),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = values[0] as Map<String, dynamic>;
        opportunities = values[1] as List<Map<String, dynamic>>;
        invoices = values[2] as List<Map<String, dynamic>>;
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
        title: const Text('Plataforma Comercial Atlas'),
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
                      title: 'Leads',
                      value: '${dashboard['leads'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Oportunidades',
                      value: '${dashboard['open_opportunities'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Pipeline',
                      value: 'R\$ ${dashboard['pipeline_value'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'A receber',
                      value: 'R\$ ${dashboard['accounts_receivable'] ?? 0}',
                    ),
                    _MetricCard(
                      title: 'Assinaturas',
                      value: '${dashboard['active_subscriptions'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Oportunidades abertas',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                if (opportunities.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('Nenhuma oportunidade aberta.'),
                    ),
                  )
                else
                  ...opportunities.map(
                    (item) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.trending_up),
                        title: Text(item['title']?.toString() ?? ''),
                        subtitle: Text(
                          'Etapa: ${item['stage'] ?? ''} • '
                          'Probabilidade: ${item['probability_percent'] ?? 0}%\n'
                          'Valor: R\$ ${item['estimated_value'] ?? 0}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Faturas abertas',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                if (invoices.isEmpty)
                  const Card(
                    child: ListTile(title: Text('Nenhuma fatura em aberto.')),
                  )
                else
                  ...invoices.map(
                    (item) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(item['reference']?.toString() ?? ''),
                        subtitle: Text(
                          'R\$ ${item['amount'] ?? 0} • '
                          'Vencimento: ${item['due_at'] ?? ''}',
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
