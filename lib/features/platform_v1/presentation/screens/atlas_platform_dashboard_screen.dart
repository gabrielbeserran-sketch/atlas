import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/platform_v1/data/services/atlas_platform_service.dart';
import 'package:projeto_atlas/features/platform_v1/domain/models/atlas_platform_dashboard_data.dart';

class AtlasPlatformDashboardScreen extends StatefulWidget {
  const AtlasPlatformDashboardScreen({
    super.key,
    required this.farmId,
    required this.farmName,
  });

  final String farmId;
  final String farmName;

  @override
  State<AtlasPlatformDashboardScreen> createState() =>
      _AtlasPlatformDashboardScreenState();
}

class _AtlasPlatformDashboardScreenState
    extends State<AtlasPlatformDashboardScreen> {
  final AtlasPlatformService _service = AtlasPlatformService();

  Future<AtlasPlatformDashboardData>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.loadFarmDashboard(widget.farmId);
    });
  }

  String _value(Map<String, dynamic> values, String key) {
    return '${values[key] ?? 0}';
  }

  Widget _buildCard(String title, List<String> lines) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atlas Executivo • ${widget.farmName}'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<AtlasPlatformDashboardData>(
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
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('Nenhum dado disponível para esta fazenda.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildCard('Rebanho', [
                  'Animais: ${_value(data.herd, 'animals')}',
                  'Lotes: ${_value(data.herd, 'lots')}',
                  'Peso médio: ${_value(data.herd, 'average_weight')} kg',
                  'Sem lote: ${_value(data.herd, 'without_lot')}',
                ]),
                _buildCard('Reprodução e sanidade', [
                  'Taxa de prenhez: ${_value(data.reproduction, 'pregnancy_rate')}%',
                  'Ações reprodutivas: ${_value(data.reproduction, 'scheduled_actions')}',
                  'Sanidade em 7 dias: ${_value(data.health, 'events_due_7d')}',
                  'Quarentenas: ${_value(data.health, 'quarantines')}',
                ]),
                _buildCard('Nutrição e estoque', [
                  'Consumo: ${_value(data.nutrition, 'total_quantity')}',
                  'Custo alimentar: ${_value(data.nutrition, 'total_cost')}',
                  'Estoque crítico: ${_value(data.inventory, 'low_stock')}',
                  'Validade em 30 dias: ${_value(data.inventory, 'expiring_30d')}',
                ]),
                _buildCard('Financeiro', [
                  'Receitas: ${_value(data.financial, 'income')}',
                  'Despesas: ${_value(data.financial, 'expense')}',
                  'Saldo projetado: ${_value(data.financial, 'projected_balance')}',
                  'ROI: ${_value(data.financial, 'roi_percent')}%',
                ]),
                const SizedBox(height: 8),
                Text(
                  'Recomendações',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.recommendations.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nenhuma recomendação foi gerada para esta fazenda.',
                      ),
                    ),
                  )
                else
                  ...data.recommendations.map(
                    (recommendation) => Card(
                      child: ListTile(
                        title: Text(recommendation.title),
                        subtitle: Text(
                          '${recommendation.description}\n'
                          'Evidência: ${recommendation.evidence.join('; ')}\n'
                          'Ação: ${recommendation.recommendedAction}',
                        ),
                        isThreeLine: true,
                        trailing: Chip(label: Text(recommendation.priority)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
