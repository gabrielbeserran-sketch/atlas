import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/session/atlas_session_scope.dart';
import 'package:projeto_atlas/features/data_intelligence/data/services/atlas_data_intelligence_service.dart';
import 'package:projeto_atlas/features/data_intelligence/domain/models/atlas_data_intelligence_snapshot.dart';

class AtlasDataIntelligenceScreen extends StatefulWidget {
  const AtlasDataIntelligenceScreen({super.key});
  @override
  State<AtlasDataIntelligenceScreen> createState() =>
      _AtlasDataIntelligenceScreenState();
}

class _AtlasDataIntelligenceScreenState
    extends State<AtlasDataIntelligenceScreen> {
  final _service = AtlasDataIntelligenceService();
  AtlasDataIntelligenceSnapshot? _snapshot;
  Object? _error;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_snapshot == null && !_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await _service.load();
      if (mounted) setState(() => _snapshot = value);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AtlasSessionScope.of(context);
    final canManage = session.allows('analytics.manage');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dados e Analytics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Text(
                      'Eventos, KPIs, relatórios, benchmark anonimizado e métricas em tempo real.',
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(_error.toString()),
                trailing: TextButton(
                  onPressed: _load,
                  child: const Text('Tentar novamente'),
                ),
              ),
            ),
          if (_snapshot != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: _cards(_snapshot!)),
            const SizedBox(height: 20),
            Text(
              'Métricas em tempo real',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_snapshot!.realtime.isEmpty)
              const ListTile(title: Text('Nenhuma métrica publicada.')),
            ..._snapshot!.realtime
                .take(20)
                .map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.monitor_heart_outlined),
                      title: Text(
                        item['metric_key']?.toString() ??
                            item['code']?.toString() ??
                            'Métrica',
                      ),
                      subtitle: Text(
                        item['scope']?.toString() ??
                            item['farm_id']?.toString() ??
                            'Escopo atual',
                      ),
                      trailing: Text(item['value']?.toString() ?? '—'),
                    ),
                  ),
                ),
          ],
          if (canManage) ...[
            const SizedBox(height: 20),
            Text(
              'Administração analítica',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _createKpi,
                  icon: const Icon(Icons.add_chart),
                  label: const Text('Novo KPI'),
                ),
                OutlinedButton.icon(
                  onPressed: _requestReport,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Gerar relatório'),
                ),
                OutlinedButton.icon(
                  onPressed: session.activeFarm == null
                      ? null
                      : () => _benchmark(session.activeFarm!.id),
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Benchmark'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _cards(AtlasDataIntelligenceSnapshot snapshot) {
    const keys = [
      'events',
      'facts',
      'kpis',
      'goals',
      'benchmarks',
      'reports',
      'jobs',
    ];
    return keys
        .map(
          (key) => SizedBox(
            width: 180,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(key.toUpperCase()),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.intMetric(key)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Future<String?> _ask(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createKpi() async {
    final value = await _ask('Código do KPI');
    if (value == null || value.isEmpty) return;
    await _service.createKpi(key: value, name: value, unit: 'unit');
    await _load();
  }

  Future<void> _requestReport() async {
    final value = await _ask('Nome do relatório');
    if (value == null || value.isEmpty) return;
    await _service.requestReport(value);
    await _load();
  }

  Future<void> _benchmark(String farmId) async {
    await _service.generateBenchmark(farmId);
    await _load();
  }
}
