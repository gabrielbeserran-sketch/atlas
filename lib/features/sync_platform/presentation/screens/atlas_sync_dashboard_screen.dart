import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/sync_platform/data/services/atlas_sync_repository.dart';
import 'package:projeto_atlas/features/sync_platform/domain/models/atlas_sync_data.dart';
import 'package:projeto_atlas/features/sync_platform/domain/services/atlas_sync_engine.dart';

class AtlasSyncDashboardScreen extends StatefulWidget {
  const AtlasSyncDashboardScreen({super.key});

  @override
  State<AtlasSyncDashboardScreen> createState() => _AtlasSyncDashboardScreenState();
}

class _AtlasSyncDashboardScreenState extends State<AtlasSyncDashboardScreen> {
  final AtlasSyncRepository _repository = AtlasSyncRepository();
  final AtlasSyncEngine _engine = const AtlasSyncEngine();

  bool _loading = true;
  bool _syncing = false;
  List<AtlasSyncItem> _items = <AtlasSyncItem>[];
  AtlasSyncSettings _settings = const AtlasSyncSettings(
    online: true,
    automaticSync: true,
    wifiOnly: false,
    lastSyncAt: null,
  );

  AtlasSyncSummary get _summary => _engine.summarize(_items);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AtlasSyncState state = await _repository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = state.items;
      _settings = state.settings;
      _loading = false;
    });
  }

  Future<void> _saveSettings(AtlasSyncSettings settings) async {
    setState(() => _settings = settings);
    await _repository.saveSettings(settings);
  }

  Future<void> _synchronize({AtlasSyncItem? only}) async {
    if (!_settings.online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ative o modo online para sincronizar.')),
      );
      return;
    }
    setState(() => _syncing = true);
    final Set<String> targets = only == null
        ? _items
            .where((AtlasSyncItem item) => item.status != AtlasSyncStatus.synced)
            .map((AtlasSyncItem item) => item.id)
            .toSet()
        : <String>{only.id};

    setState(() {
      _items = _items.map((AtlasSyncItem item) {
        return targets.contains(item.id)
            ? item.copyWith(status: AtlasSyncStatus.syncing, updatedAt: DateTime.now())
            : item;
      }).toList();
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final DateTime completedAt = DateTime.now();
    setState(() {
      _items = _items.map((AtlasSyncItem item) {
        return targets.contains(item.id)
            ? item.copyWith(
                status: AtlasSyncStatus.synced,
                attempts: item.attempts + 1,
                updatedAt: completedAt,
                clearError: true,
              )
            : item;
      }).toList();
      _settings = _settings.copyWith(lastSyncAt: completedAt);
      _syncing = false;
    });
    await _repository.saveItems(_items);
    await _repository.saveSettings(_settings);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${targets.length} item(ns) sincronizado(s).')),
    );
  }

  Future<void> _addTestItem() async {
    final DateTime now = DateTime.now();
    final AtlasSyncItem item = AtlasSyncItem(
      id: 'sync_${now.microsecondsSinceEpoch}',
      module: 'Command Center',
      entityType: 'prioridade',
      entityId: 'priority_${now.millisecondsSinceEpoch}',
      operation: 'create',
      createdAt: now,
      updatedAt: now,
      status: AtlasSyncStatus.pending,
      priority: AtlasSyncPriority.high,
      attempts: 0,
      payload: const <String, dynamic>{'origem': 'teste manual'},
    );
    setState(() => _items = <AtlasSyncItem>[item, ..._items]);
    await _repository.saveItems(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Sync & Cloud Platform'),
        actions: <Widget>[
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _syncing ? null : _synchronize,
        icon: _syncing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.cloud_sync_outlined),
        label: const Text('Sincronizar agora'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: <Widget>[
                  _buildConnectionCard(),
                  const SizedBox(height: 14),
                  _buildSummaryCard(),
                  const SizedBox(height: 14),
                  _buildSettingsCard(),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('Fila centralizada', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      TextButton.icon(onPressed: _addTestItem, icon: const Icon(Icons.add), label: const Text('Adicionar teste')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('A fila está vazia.'))))
                  else
                    ..._engine.ordered(_items).map(_buildItemCard),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 26,
              child: Icon(_settings.online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_settings.online ? 'Conexão disponível' : 'Modo offline', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_settings.lastSyncAt == null ? 'Nenhuma sincronização concluída.' : 'Última sincronização: ${_formatDate(_settings.lastSyncAt!)}'),
                ],
              ),
            ),
            Switch(value: _settings.online, onChanged: (bool value) => _saveSettings(_settings.copyWith(online: value))),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final AtlasSyncSummary summary = _summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Visão geral da sincronização', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _metric('Pendentes', '${summary.pending}', Icons.schedule),
                _metric('Sincronizados', '${summary.synced}', Icons.cloud_done_outlined),
                _metric('Falhas', '${summary.failed}', Icons.error_outline),
                _metric('Conflitos', '${summary.conflicts}', Icons.compare_arrows),
                _metric('Taxa de sucesso', '${summary.successRate.toStringAsFixed(0)}%', Icons.insights_outlined),
                _metric('Módulos pendentes', '${summary.modulesWithPendingItems}', Icons.widgets_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 22),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 12))])),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Column(
        children: <Widget>[
          SwitchListTile(
            title: const Text('Sincronização automática'),
            subtitle: const Text('Processar a fila quando houver conexão disponível.'),
            value: _settings.automaticSync,
            onChanged: (bool value) => _saveSettings(_settings.copyWith(automaticSync: value)),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Somente por Wi-Fi'),
            subtitle: const Text('Evitar consumo de dados móveis em sincronizações futuras.'),
            value: _settings.wifiOnly,
            onChanged: (bool value) => _saveSettings(_settings.copyWith(wifiOnly: value)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(AtlasSyncItem item) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_statusIcon(item.status))),
        title: Text('${item.module} • ${item.entityType}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_operationLabel(item.operation)} • ${_statusLabel(item.status)} • ${_formatDate(item.updatedAt)}'),
        trailing: item.status == AtlasSyncStatus.synced
            ? const Icon(Icons.check_circle_outline)
            : IconButton(onPressed: _syncing ? null : () => _synchronize(only: item), icon: const Icon(Icons.sync), tooltip: 'Sincronizar item'),
      ),
    );
  }

  IconData _statusIcon(AtlasSyncStatus status) {
    switch (status) {
      case AtlasSyncStatus.pending:
        return Icons.schedule;
      case AtlasSyncStatus.syncing:
        return Icons.sync;
      case AtlasSyncStatus.synced:
        return Icons.cloud_done_outlined;
      case AtlasSyncStatus.failed:
        return Icons.error_outline;
      case AtlasSyncStatus.conflict:
        return Icons.compare_arrows;
    }
  }

  String _statusLabel(AtlasSyncStatus status) {
    switch (status) {
      case AtlasSyncStatus.pending:
        return 'Pendente';
      case AtlasSyncStatus.syncing:
        return 'Sincronizando';
      case AtlasSyncStatus.synced:
        return 'Sincronizado';
      case AtlasSyncStatus.failed:
        return 'Falha';
      case AtlasSyncStatus.conflict:
        return 'Conflito';
    }
  }

  String _operationLabel(String operation) {
    switch (operation) {
      case 'create':
        return 'Criação';
      case 'delete':
        return 'Exclusão';
      default:
        return 'Atualização';
    }
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
