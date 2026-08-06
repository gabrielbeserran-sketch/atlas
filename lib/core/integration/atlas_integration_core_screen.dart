import 'package:flutter/material.dart';

import 'atlas_integration_core.dart';
import 'atlas_integration_event.dart';
import 'atlas_integration_module.dart';

class AtlasIntegrationCoreScreen extends StatefulWidget {
  const AtlasIntegrationCoreScreen({super.key});

  @override
  State<AtlasIntegrationCoreScreen> createState() => _AtlasIntegrationCoreScreenState();
}

class _AtlasIntegrationCoreScreenState extends State<AtlasIntegrationCoreScreen> {
  final AtlasIntegrationCore _core = AtlasIntegrationCore.instance;
  late AtlasIntegrationSnapshot _snapshot;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _snapshot = _core.snapshot();
  }

  void _refresh() {
    setState(() {
      _snapshot = _core.snapshot();
    });
  }

  Future<void> _runHealthCheck() async {
    setState(() {
      _checking = true;
    });
    await _core.runHealthCheck();
    if (!mounted) {
      return;
    }
    setState(() {
      _checking = false;
      _snapshot = _core.snapshot();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Integration Core'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _runHealthCheck,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildSummaryGrid(),
            const SizedBox(height: 24),
            const Text(
              'Módulos conectados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._snapshot.modules.map(_buildModuleCard),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Eventos recentes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: _snapshot.events.isEmpty
                      ? null
                      : () {
                          _core.clearEvents();
                          _refresh();
                        },
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_snapshot.events.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Nenhum evento registrado. Execute a verificação para testar a comunicação central.',
                  ),
                ),
              )
            else
              ..._snapshot.events.take(8).map(_buildEventTile),
            const SizedBox(height: 28),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _checking ? null : _runHealthCheck,
        icon: _checking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.health_and_safety_outlined),
        label: Text(_checking ? 'Verificando...' : 'Verificar integração'),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.hub_outlined, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Arquitetura unificada do Atlas',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Centralize comunicação, saúde dos módulos, eventos e dependências compartilhadas em uma única camada.',
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _snapshot.healthScore / 100),
            const SizedBox(height: 8),
            Text(
              'Saúde da integração: ${_snapshot.healthScore.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: <Widget>[
        _metric('Módulos ativos', '${_snapshot.activeModules}', Icons.widgets_outlined),
        _metric('Módulos saudáveis', '${_snapshot.healthyModules}', Icons.verified_outlined),
        _metric('Eventos pendentes', '${_snapshot.pendingEvents}', Icons.bolt_outlined),
        _metric('Eventos registrados', '${_snapshot.events.length}', Icons.receipt_long_outlined),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(AtlasIntegrationModule module) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        value: module.isEnabled,
        onChanged: (_) {
          _core.toggleModule(module.id);
          _refresh();
        },
        secondary: CircleAvatar(
          child: Icon(module.isHealthy ? Icons.check_rounded : Icons.warning_amber_rounded),
        ),
        title: Text(module.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${module.category} • ${module.description}\n${module.pendingEvents} evento(s) pendente(s)',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEventTile(AtlasIntegrationEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.swap_horiz_rounded),
        title: Text(event.message),
        subtitle: Text('${event.sourceModule} • ${event.type}'),
        trailing: Text(
          '${event.createdAt.hour.toString().padLeft(2, '0')}:${event.createdAt.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
