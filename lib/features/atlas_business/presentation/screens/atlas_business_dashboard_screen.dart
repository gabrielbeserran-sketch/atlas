import 'package:flutter/material.dart';

import '../../data/services/atlas_business_service.dart';
import '../../domain/models/atlas_business_dashboard_data.dart';

class AtlasBusinessDashboardScreen extends StatefulWidget {
  const AtlasBusinessDashboardScreen({super.key, this.farmId, this.farmName});

  final String? farmId;
  final String? farmName;

  @override
  State<AtlasBusinessDashboardScreen> createState() =>
      _AtlasBusinessDashboardScreenState();
}

class _AtlasBusinessDashboardScreenState
    extends State<AtlasBusinessDashboardScreen> {
  final AtlasBusinessService _service = AtlasBusinessService();

  late Future<AtlasBusinessDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _service.dashboard(farmId: widget.farmId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final farmName = widget.farmName?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          farmName.isEmpty
              ? 'Atlas Negócios 360'
              : 'Atlas Negócios — $farmName',
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<AtlasBusinessDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Não foi possível carregar o painel.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('Nenhum dado comercial disponível.'),
            );
          }

          final biKpis = _mapValue(data.bi['kpis']);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _section(
                  context,
                  title: 'Comercialização',
                  icon: Icons.handshake_outlined,
                  data: data.commercial,
                  keys: const ['documents', 'open_contracts', 'crm_parties'],
                ),
                _section(
                  context,
                  title: 'Consultoria',
                  icon: Icons.assignment_ind_outlined,
                  data: data.consulting,
                  keys: const [
                    'visits',
                    'scheduled_visits',
                    'open_actions',
                    'overdue_actions',
                    'completion_percent',
                  ],
                ),
                _section(
                  context,
                  title: 'Plataforma Enterprise',
                  icon: Icons.account_tree_outlined,
                  data: data.enterprise,
                  keys: const [
                    'approval_workflows',
                    'public_api_keys',
                    'webhooks',
                    'score',
                  ],
                ),
                _section(
                  context,
                  title: 'Business Intelligence',
                  icon: Icons.query_stats_outlined,
                  data: biKpis,
                  keys: const [
                    'animals',
                    'average_weight',
                    'pregnancy_rate_percent',
                    'income',
                    'expense',
                    'margin',
                    'roi_percent',
                  ],
                ),
                _section(
                  context,
                  title: 'Produto comercial',
                  icon: Icons.rocket_launch_outlined,
                  data: data.product,
                  keys: const ['score'],
                ),
                const SizedBox(height: 8),
                Text(
                  'Atualizado em ${data.generatedAt.toLocal()}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Map<String, dynamic> data,
    required List<String> keys,
  }) {
    final visibleKeys = keys.where(data.containsKey).toList(growable: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visibleKeys.isEmpty)
              Text(
                'Nenhum indicador disponível.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: visibleKeys
                    .map(
                      (key) => _MetricCard(
                        label: _label(key),
                        value: _formatValue(data[key]),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const <String, dynamic>{};
  }

  String _formatValue(Object? value) {
    if (value == null) {
      return '—';
    }

    if (value is double) {
      return value.toStringAsFixed(2);
    }

    return value.toString();
  }

  String _label(String key) {
    return const <String, String>{
          'documents': 'Documentos',
          'open_contracts': 'Contratos abertos',
          'crm_parties': 'Clientes/fornecedores',
          'visits': 'Visitas',
          'scheduled_visits': 'Agendadas',
          'open_actions': 'Ações abertas',
          'overdue_actions': 'Atrasadas',
          'completion_percent': 'Conclusão (%)',
          'approval_workflows': 'Workflows',
          'public_api_keys': 'Chaves API',
          'webhooks': 'Webhooks',
          'score': 'Pontuação',
          'animals': 'Animais',
          'average_weight': 'Peso médio',
          'pregnancy_rate_percent': 'Prenhez (%)',
          'income': 'Receitas',
          'expense': 'Despesas',
          'margin': 'Margem',
          'roi_percent': 'ROI (%)',
        }[key] ??
        key;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
