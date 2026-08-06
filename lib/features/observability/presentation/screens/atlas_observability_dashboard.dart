import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/observability/data/services/atlas_observability_repository.dart';
import 'package:projeto_atlas/features/observability/domain/models/atlas_observability_data.dart';
import 'package:projeto_atlas/features/observability/domain/services/atlas_observability_engine.dart';

class AtlasObservabilityDashboard extends StatefulWidget {
  const AtlasObservabilityDashboard({super.key});

  @override
  State<AtlasObservabilityDashboard> createState() =>
      _AtlasObservabilityDashboardState();
}

class _AtlasObservabilityDashboardState
    extends State<AtlasObservabilityDashboard> {
  final AtlasObservabilityRepository _repository =
      AtlasObservabilityRepository();
  final AtlasObservabilityEngine _engine = const AtlasObservabilityEngine();

  AtlasObservabilityData? _data;
  bool _loading = true;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AtlasObservabilityData data = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _runDiagnostic() async {
    final AtlasObservabilityData? current = _data;
    if (current == null || _running) {
      return;
    }
    setState(() => _running = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final AtlasObservabilityData updated = _engine.runDiagnostic(current);
    await _repository.save(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _data = updated;
      _running = false;
    });
  }

  Future<void> _toggleResolved(AtlasSystemLog log) async {
    final AtlasObservabilityData? current = _data;
    if (current == null) {
      return;
    }
    final List<AtlasSystemLog> logs = current.logs
        .map((AtlasSystemLog item) =>
            item.id == log.id ? item.copyWith(resolved: !item.resolved) : item)
        .toList();
    final AtlasObservabilityData updated = AtlasObservabilityData(
      healthChecks: current.healthChecks,
      logs: logs,
      lastDiagnosticAt: current.lastDiagnosticAt,
    );
    await _repository.save(updated);
    if (mounted) {
      setState(() => _data = updated);
    }
  }

  Future<void> _clearResolvedLogs() async {
    final AtlasObservabilityData? current = _data;
    if (current == null) {
      return;
    }
    final AtlasObservabilityData updated = AtlasObservabilityData(
      healthChecks: current.healthChecks,
      logs: current.logs.where((AtlasSystemLog item) => !item.resolved).toList(),
      lastDiagnosticAt: current.lastDiagnosticAt,
    );
    await _repository.save(updated);
    if (mounted) {
      setState(() => _data = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Observability & Diagnostics'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Limpar registros resolvidos',
            onPressed: _clearResolvedLogs,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, _data!),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _running ? null : _runDiagnostic,
        icon: _running
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.monitor_heart_outlined),
        label: Text(_running ? 'Diagnosticando...' : 'Executar diagnóstico'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AtlasObservabilityData data) {
    final int score = _engine.healthScore(data.healthChecks);
    final int average = _engine.averageResponseTime(data.healthChecks);
    final int warnings = data.healthChecks
        .where((AtlasHealthCheck item) =>
            item.status == AtlasHealthStatus.warning)
        .length;
    final int critical = data.healthChecks
        .where((AtlasHealthCheck item) =>
            item.status == AtlasHealthStatus.critical)
        .length;
    final int openLogs = data.logs.where((AtlasSystemLog item) => !item.resolved).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Saúde geral da plataforma',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 9,
                            ),
                            Text(
                              '$score%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Tempo médio de resposta: $average ms'),
                            const SizedBox(height: 6),
                            Text('Módulos em atenção: $warnings'),
                            const SizedBox(height: 6),
                            Text('Módulos críticos: $critical'),
                            const SizedBox(height: 6),
                            Text('Registros abertos: $openLogs'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.lastDiagnosticAt == null
                        ? 'Nenhum diagnóstico completo executado nesta instalação.'
                        : 'Último diagnóstico: ${_formatDateTime(data.lastDiagnosticAt!)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Saúde dos módulos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...data.healthChecks.map(_buildHealthCard),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Registros técnicos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Text('${data.logs.length} registro(s)'),
            ],
          ),
          const SizedBox(height: 10),
          if (data.logs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Nenhum registro técnico disponível.'),
              ),
            )
          else
            ...data.logs.map(_buildLogCard),
        ],
      ),
    );
  }

  Widget _buildHealthCard(AtlasHealthCheck check) {
    final Color color = _statusColor(check.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_statusIcon(check.status), color: color),
        ),
        title: Text(check.module),
        subtitle: Text(
          '${check.description}\nResposta: ${check.responseTimeMs} ms • ${_formatDateTime(check.checkedAt)}',
        ),
        isThreeLine: true,
        trailing: Text(
          _statusLabel(check.status),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLogCard(AtlasSystemLog log) {
    final Color color = _logColor(log.level);
    return Card(
      child: ListTile(
        leading: Icon(_logIcon(log.level), color: color),
        title: Text(log.module),
        subtitle: Text('${log.message}\n${_formatDateTime(log.createdAt)}'),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: log.resolved ? 'Reabrir' : 'Marcar como resolvido',
          onPressed: () => _toggleResolved(log),
          icon: Icon(
            log.resolved ? Icons.check_circle : Icons.radio_button_unchecked,
            color: log.resolved ? Colors.green : Colors.black45,
          ),
        ),
      ),
    );
  }

  Color _statusColor(AtlasHealthStatus status) {
    switch (status) {
      case AtlasHealthStatus.healthy:
        return Colors.green;
      case AtlasHealthStatus.warning:
        return Colors.orange;
      case AtlasHealthStatus.critical:
        return Colors.red;
    }
  }

  IconData _statusIcon(AtlasHealthStatus status) {
    switch (status) {
      case AtlasHealthStatus.healthy:
        return Icons.check_circle_outline;
      case AtlasHealthStatus.warning:
        return Icons.warning_amber_rounded;
      case AtlasHealthStatus.critical:
        return Icons.error_outline;
    }
  }

  String _statusLabel(AtlasHealthStatus status) {
    switch (status) {
      case AtlasHealthStatus.healthy:
        return 'Saudável';
      case AtlasHealthStatus.warning:
        return 'Atenção';
      case AtlasHealthStatus.critical:
        return 'Crítico';
    }
  }

  Color _logColor(AtlasLogLevel level) {
    switch (level) {
      case AtlasLogLevel.info:
        return Colors.blue;
      case AtlasLogLevel.warning:
        return Colors.orange;
      case AtlasLogLevel.error:
        return Colors.red;
    }
  }

  IconData _logIcon(AtlasLogLevel level) {
    switch (level) {
      case AtlasLogLevel.info:
        return Icons.info_outline;
      case AtlasLogLevel.warning:
        return Icons.warning_amber_rounded;
      case AtlasLogLevel.error:
        return Icons.error_outline;
    }
  }

  String _formatDateTime(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} às $hour:$minute';
  }
}
