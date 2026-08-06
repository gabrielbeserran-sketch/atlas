import 'package:flutter/material.dart';

import '../../data/services/atlas_sprints_16_20_service.dart';
import '../../domain/models/atlas_sprints_16_20_data.dart';

class AtlasSprints1620DashboardScreen extends StatefulWidget {
  const AtlasSprints1620DashboardScreen({super.key});

  @override
  State<AtlasSprints1620DashboardScreen> createState() =>
      _AtlasSprints1620DashboardScreenState();
}

class _AtlasSprints1620DashboardScreenState
    extends State<AtlasSprints1620DashboardScreen> {
  final AtlasSprints1620Service _service = AtlasSprints1620Service();

  AtlasSprints1620DashboardData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.loadDashboard();
      if (!mounted) return;

      setState(() {
        _data = data;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Enterprise 1.0'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return const Center(
        child: Text('Nenhum dado disponível.'),
      );
    }

    final cards = <_DashboardCardData>[
      _DashboardCardData(
        title: 'Sprint 16 — Comercial',
        icon: Icons.payments_outlined,
        data: data.billing,
      ),
      _DashboardCardData(
        title: 'Sprint 17 — API Pública',
        icon: Icons.api_outlined,
        data: data.publicApi,
      ),
      _DashboardCardData(
        title: 'Sprint 18 — Analytics',
        icon: Icons.analytics_outlined,
        data: data.analytics,
      ),
      _DashboardCardData(
        title: 'Sprint 19 — Machine Learning',
        icon: Icons.model_training_outlined,
        data: data.machineLearning,
      ),
      _DashboardCardData(
        title: 'Sprint 20 — Enterprise 1.0',
        icon: Icons.verified_outlined,
        data: data.enterprise,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: cards
            .map<Widget>(
              (card) => _buildDashboardCard(
                context: context,
                card: card,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required _DashboardCardData card,
  }) {
    final entries = card.data.entries.toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(card.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    card.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('Nenhum indicador disponível.')
            else
              ...entries.map<Widget>(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${_formatLabel(entry.key)}: ${_formatValue(entry.value)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String value) {
    final normalized = value.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return value;

    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _formatValue(Object? value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Sim' : 'Não';
    if (value is num) {
      return value is int ? value.toString() : value.toStringAsFixed(2);
    }
    if (value is List) {
      return value.isEmpty ? '—' : value.join(', ');
    }
    if (value is Map) {
      return value.isEmpty ? '—' : value.toString();
    }
    return value.toString();
  }
}

class _DashboardCardData {
  const _DashboardCardData({
    required this.title,
    required this.icon,
    required this.data,
  });

  final String title;
  final IconData icon;
  final Map<String, dynamic> data;
}
