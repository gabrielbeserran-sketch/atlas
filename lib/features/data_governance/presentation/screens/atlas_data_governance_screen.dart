import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projeto_atlas/features/data_governance/data/services/atlas_data_governance_repository.dart';
import 'package:projeto_atlas/features/data_governance/domain/models/atlas_data_governance.dart';
import 'package:projeto_atlas/features/data_governance/domain/services/atlas_data_governance_engine.dart';

class AtlasDataGovernanceScreen extends StatefulWidget {
  const AtlasDataGovernanceScreen({super.key});

  @override
  State<AtlasDataGovernanceScreen> createState() =>
      _AtlasDataGovernanceScreenState();
}

class _AtlasDataGovernanceScreenState extends State<AtlasDataGovernanceScreen> {
  final AtlasDataGovernanceRepository _repository =
      AtlasDataGovernanceRepository();
  final AtlasDataGovernanceEngine _engine = const AtlasDataGovernanceEngine();

  bool _loading = true;
  bool _working = false;
  List<AtlasBackupSnapshot> _backups = <AtlasBackupSnapshot>[];

  AtlasDataGovernanceSummary get _summary => _engine.buildSummary(_backups);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<AtlasBackupSnapshot> backups = await _repository.loadBackups();
    if (!mounted) {
      return;
    }
    setState(() {
      _backups = backups;
      _loading = false;
    });
  }

  Future<void> _createBackup() async {
    setState(() => _working = true);
    await _repository.createBackup();
    await _load();
    if (!mounted) {
      return;
    }
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup local criado com sucesso.')),
    );
  }

  Future<void> _restore(AtlasBackupSnapshot snapshot) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: Text(
          'Os dados armazenados no Atlas serão atualizados com a versão "${snapshot.label}".',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _working = true);
    await _repository.restoreBackup(snapshot);
    if (!mounted) {
      return;
    }
    setState(() => _working = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Backup restaurado. Reabra as telas para atualizar os dados.',
        ),
      ),
    );
  }

  Future<void> _delete(AtlasBackupSnapshot snapshot) async {
    await _repository.deleteBackup(snapshot.id);
    await _load();
  }

  Future<void> _copy(AtlasBackupSnapshot snapshot) async {
    await Clipboard.setData(ClipboardData(text: snapshot.exportJson()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conteúdo do backup copiado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas Data Governance & Backup'),
        actions: <Widget>[
          IconButton(
            onPressed: _working ? null : _load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _working ? null : _createBackup,
        icon: _working
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.backup_outlined),
        label: const Text('Criar backup'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: <Widget>[
                  _buildOverview(),
                  const SizedBox(height: 16),
                  _buildIntegrity(),
                  const SizedBox(height: 16),
                  Text(
                    'Histórico de backups',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_backups.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Column(
                          children: <Widget>[
                            Icon(Icons.cloud_off_outlined, size: 42),
                            SizedBox(height: 10),
                            Text('Nenhum backup criado ainda.'),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._backups.map(_buildBackupCard),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview() {
    final AtlasDataGovernanceSummary summary = _summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.shield_outlined, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Proteção e governança dos dados',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _metric('Integridade', '${summary.integrityScore}%'),
                _metric('Backups', '${summary.backups.length}'),
                _metric('Itens protegidos', '${summary.totalItems}'),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Os backups são mantidos localmente no aparelho. Para proteção contra perda física do dispositivo, copie o JSON e guarde-o também em local seguro.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildIntegrity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Verificações de integridade',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._summary.checks.map(
              (check) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  check.passed
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: check.passed ? Colors.green : Colors.orange,
                ),
                title: Text(check.title),
                subtitle: Text(check.description),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(AtlasBackupSnapshot snapshot) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(snapshot.label),
        subtitle: Text(
          '${_formatDate(snapshot.createdAt)} • ${snapshot.itemCount} itens • ${snapshot.formattedSize}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'copy') {
              _copy(snapshot);
            }
            if (value == 'restore') {
              _restore(snapshot);
            }
            if (value == 'delete') {
              _delete(snapshot);
            }
          },
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem(value: 'copy', child: Text('Copiar JSON')),
            PopupMenuItem(value: 'restore', child: Text('Restaurar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}
