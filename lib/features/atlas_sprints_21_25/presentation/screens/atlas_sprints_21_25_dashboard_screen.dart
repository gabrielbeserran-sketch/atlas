import 'package:flutter/material.dart';

import '../../data/services/atlas_sprints_21_25_service.dart';
import '../../domain/models/atlas_sprints_21_25_data.dart';

class AtlasSprints2125DashboardScreen extends StatefulWidget {
  const AtlasSprints2125DashboardScreen({super.key, required this.farmId});

  final String farmId;

  @override
  State<AtlasSprints2125DashboardScreen> createState() =>
      _AtlasSprints2125DashboardScreenState();
}

class _AtlasSprints2125DashboardScreenState
    extends State<AtlasSprints2125DashboardScreen> {
  final AtlasSprints2125Service _service = AtlasSprints2125Service();

  Future<AtlasSprints2125DashboardData>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.loadDashboard(widget.farmId);
    });
  }

  Future<void> _refresh() async {
    _reload();
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas — Sprints 21 a 25'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<AtlasSprints2125DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Não foi possível carregar: ${snapshot.error}',
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return _ErrorState(
              message: 'Nenhum dado foi retornado pelo servidor.',
              onRetry: _reload,
            );
          }

          final cards = <_DashboardSection>[
            _DashboardSection(
              title: 'Pecuária de Precisão',
              icon: Icons.analytics_outlined,
              data: data.precision,
            ),
            _DashboardSection(
              title: 'Reprodução Avançada',
              icon: Icons.favorite_outline,
              data: data.reproduction,
            ),
            _DashboardSection(
              title: 'Sanidade Inteligente',
              icon: Icons.health_and_safety_outlined,
              data: data.health,
            ),
            _DashboardSection(
              title: 'Nutrição Inteligente',
              icon: Icons.grass_outlined,
              data: data.nutrition,
            ),
            _DashboardSection(
              title: 'Gestão Operacional',
              icon: Icons.build_circle_outlined,
              data: data.operations,
            ),
          ];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: cards
                  .map<Widget>(
                    (section) => _DashboardSectionCard(section: section),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardSection {
  const _DashboardSection({
    required this.title,
    required this.icon,
    required this.data,
  });

  final String title;
  final IconData icon;
  final Map<String, dynamic> data;
}

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({required this.section});

  final _DashboardSection section;

  @override
  Widget build(BuildContext context) {
    final entries = section.data.entries.take(12).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(section.icon),
        title: Text(section.title),
        subtitle: Text(
          entries.isEmpty
              ? 'Sem indicadores disponíveis'
              : '${entries.length} indicador(es)',
        ),
        children: entries.isEmpty
            ? const <Widget>[
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Nenhum dado disponível para esta área.'),
                ),
              ]
            : entries
                  .map<Widget>(
                    (entry) => ListTile(
                      dense: true,
                      title: Text(_formatLabel(entry.key)),
                      subtitle: Text(_formatValue(entry.value)),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  static String _formatLabel(String value) {
    final normalized = value.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) {
      return 'Indicador';
    }

    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  static String _formatValue(dynamic value) {
    if (value == null) {
      return 'Não informado';
    }

    if (value is bool) {
      return value ? 'Sim' : 'Não';
    }

    if (value is num) {
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }

    if (value is List) {
      return value.isEmpty ? 'Nenhum item' : value.join(', ');
    }

    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' • ');
    }

    final text = value.toString().trim();
    return text.isEmpty ? 'Não informado' : text;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
