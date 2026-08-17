import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/services/atlas_enterprise_sync_repository.dart';
import '../../data/services/atlas_enterprise_version_repository.dart';
import '../../domain/models/atlas_enterprise_sync_data.dart';
import '../../domain/models/atlas_enterprise_version_data.dart';
import '../../domain/services/atlas_enterprise_authorization_service.dart';
import '../../domain/services/atlas_enterprise_conflict_resolution_service.dart';
import '../../domain/services/atlas_enterprise_session_service.dart';
import '../../domain/services/atlas_enterprise_sync_engine_24c.dart';
import '../../domain/services/atlas_enterprise_version_service.dart';
import 'atlas_enterprise_24d_screen.dart';

class AtlasEnterprise24CScreen extends StatefulWidget {
  const AtlasEnterprise24CScreen({super.key});

  @override
  State<AtlasEnterprise24CScreen> createState() =>
      _AtlasEnterprise24CScreenState();
}

class _AtlasEnterprise24CScreenState extends State<AtlasEnterprise24CScreen> {
  final syncRepository = AtlasEnterpriseSyncRepository.instance;
  final versionRepository = AtlasEnterpriseVersionRepository.instance;
  final versionService = AtlasEnterpriseVersionService.instance;
  final authorization = AtlasEnterpriseAuthorizationService.instance;
  final session = AtlasEnterpriseSessionService.instance;
  final syncEngine = AtlasEnterpriseSyncEngine24C();
  final conflictResolver = AtlasEnterpriseConflictResolutionService.instance;

  List<AtlasVersionedEntitySnapshot> versions = [];
  List<AtlasEnterpriseSyncOperation> queue = [];
  List<AtlasEnterpriseSyncConflict> conflicts = [];
  AtlasEnterpriseSyncCheckpoint? checkpoint;
  AtlasEnterpriseSyncSummary summary = const AtlasEnterpriseSyncSummary(
    total: 0,
    pending: 0,
    syncing: 0,
    synchronized: 0,
    conflicts: 0,
    errors: 0,
  );
  bool loading = true;
  bool online = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await session.ensureInitialized();
    final companyId = session.currentCompanyId;

    final allVersions = await versionRepository.loadAll();
    final allQueue = await syncRepository.loadQueue();
    final allConflicts = await syncRepository.loadConflicts();
    final loadedCheckpoint = companyId == null
        ? null
        : await syncRepository.checkpoint(companyId);

    final scopedQueue = companyId == null
        ? <AtlasEnterpriseSyncOperation>[]
        : allQueue.where((item) => item.companyId == companyId).toList();

    if (!mounted) return;
    setState(() {
      versions =
          companyId == null
                ? <AtlasVersionedEntitySnapshot>[]
                : allVersions
                      .where((item) => item.companyId == companyId)
                      .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      queue = scopedQueue..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      conflicts =
          companyId == null
                ? <AtlasEnterpriseSyncConflict>[]
                : allConflicts
                      .where((item) => item.companyId == companyId)
                      .toList()
            ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      checkpoint = loadedCheckpoint;
      summary = syncEngine.summarize(scopedQueue);
      loading = false;
    });
  }

  Future<void> _synchronize() async {
    await authorization.require('enterprise.sync.manage');
    setState(() => loading = true);
    await syncEngine.synchronize(online: online);
    await _load();
  }

  Future<void> _createVersionTest() async {
    await authorization.require('enterprise.versions.restore');

    final companyId = session.currentCompanyId;
    if (companyId == null) return;

    final history = await versionService.history(
      companyId: companyId,
      entityType: '24c_test',
      entityId: 'diagnostic_record',
    );
    final base = history.isEmpty ? 0 : history.first.version;

    final snapshot = await versionService.commit(
      tenantId: companyId,
      companyId: companyId,
      farmId: session.currentFarmId,
      entityType: '24c_test',
      entityId: 'diagnostic_record',
      payload: <String, dynamic>{
        'generatedAt': DateTime.now().toIso8601String(),
        'message': 'Registro diagnóstico 24C',
      },
      baseVersion: base,
      mutationType: base == 0
          ? AtlasVersionMutationType.create
          : AtlasVersionMutationType.update,
      reason: 'Teste manual do versionamento Enterprise.',
    );

    await syncEngine.enqueue(
      tenantId: companyId,
      companyId: companyId,
      farmId: session.currentFarmId,
      entityType: snapshot.entityType,
      entityId: snapshot.entityId,
      operationType: base == 0
          ? AtlasEnterpriseSyncOperationType.create
          : AtlasEnterpriseSyncOperationType.update,
      payload: snapshot.payload,
      baseVersion: base,
    );

    await _load();
  }

  Future<void> _runConcurrencyTest() async {
    final companyId = session.currentCompanyId;
    if (companyId == null) return;

    final history = await versionService.history(
      companyId: companyId,
      entityType: '24c_test',
      entityId: 'diagnostic_record',
    );
    final current = history.isEmpty ? 0 : history.first.version;
    final valid = await versionService.checkConcurrency(
      companyId: companyId,
      entityType: '24c_test',
      entityId: 'diagnostic_record',
      baseVersion: current,
    );
    final stale = await versionService.checkConcurrency(
      companyId: companyId,
      entityType: '24c_test',
      entityId: 'diagnostic_record',
      baseVersion: current > 0 ? current - 1 : 1,
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Teste de concorrência'),
        content: Text(
          'Versão atual: $current\n'
          'Base atual aceita: ${valid.allowed ? 'SIM' : 'NÃO'}\n'
          'Base desatualizada bloqueada: '
          '${!stale.allowed ? 'SIM' : 'NÃO'}\n\n'
          '${stale.message}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreVersion(AtlasVersionedEntitySnapshot source) async {
    await authorization.require('enterprise.versions.restore');

    await versionService.restore(
      source: source,
      reason: 'Restauração manual pelo console Enterprise 24C.',
    );
    await _load();
  }

  Future<void> _resolveConflict(AtlasEnterpriseSyncConflict conflict) async {
    await authorization.require('enterprise.sync.conflicts.resolve');

    if (!mounted) return;

    final resolution = await showDialog<AtlasEnterpriseConflictResolution>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolver conflito'),
        content: Text(
          '${conflict.entityType}/${conflict.entityId}\n'
          'Versão local: ${conflict.localVersion}\n'
          'Versão remota: ${conflict.remoteVersion}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(AtlasEnterpriseConflictResolution.keepRemote),
            child: const Text('Usar remoto'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(AtlasEnterpriseConflictResolution.merge),
            child: const Text('Mesclar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(AtlasEnterpriseConflictResolution.keepLocal),
            child: const Text('Usar local'),
          ),
        ],
      ),
    );

    if (resolution == null) return;

    await conflictResolver.resolve(conflict: conflict, resolution: resolution);
    await _load();
  }

  Future<void> _open24D() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AtlasEnterprise24DScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enterprise 24C'),
          actions: [
            IconButton(
              tooltip: 'Backend e API 24D',
              onPressed: _open24D,
              icon: const Icon(Icons.cloud_outlined),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Online'),
                Switch(
                  value: online,
                  onChanged: (value) {
                    setState(() => online = value);
                  },
                ),
              ],
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Versionamento'),
              Tab(text: 'Fila offline'),
              Tab(text: 'Conflitos'),
              Tab(text: 'Sincronização'),
              Tab(text: 'Testes'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: loading ? null : _synchronize,
          icon: const Icon(Icons.sync),
          label: const Text('Sincronizar'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _VersionsTab(versions: versions, onRestore: _restoreVersion),
                  _QueueTab(queue: queue),
                  _ConflictsTab(
                    conflicts: conflicts,
                    onResolve: _resolveConflict,
                  ),
                  _SyncTab(
                    summary: summary,
                    checkpoint: checkpoint,
                    online: online,
                  ),
                  _TestsTab(
                    onCreateVersion: _createVersionTest,
                    onConcurrency: _runConcurrencyTest,
                    onSync: _synchronize,
                  ),
                ],
              ),
      ),
    );
  }
}

class _VersionsTab extends StatelessWidget {
  const _VersionsTab({required this.versions, required this.onRestore});

  final List<AtlasVersionedEntitySnapshot> versions;
  final ValueChanged<AtlasVersionedEntitySnapshot> onRestore;

  @override
  Widget build(BuildContext context) {
    if (versions.isEmpty) {
      return const Center(child: Text('Nenhuma versão registrada.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: versions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = versions[index];
        return Card(
          child: ExpansionTile(
            title: Text(
              '${item.entityType}/${item.entityId} '
              '— v${item.version}',
            ),
            subtitle: Text(
              '${atlasVersionMutationTypeLabel(item.mutationType)} • '
              '${DateFormat('dd/MM/yyyy HH:mm:ss').format(item.createdAt)}',
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              SelectableText(item.payload.toString()),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onRestore(item),
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurar como nova versão'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueTab extends StatelessWidget {
  const _QueueTab({required this.queue});

  final List<AtlasEnterpriseSyncOperation> queue;

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return const Center(child: Text('Fila offline vazia.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: queue.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = queue[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.outbox_outlined),
            title: Text('${item.entityType}/${item.entityId}'),
            subtitle: Text(
              '${item.operationType.name} • '
              'base v${item.baseVersion} • '
              'tentativas ${item.retryCount}',
            ),
            trailing: Text(
              atlasEnterpriseSyncStatusLabel(item.status),
              textAlign: TextAlign.right,
            ),
          ),
        );
      },
    );
  }
}

class _ConflictsTab extends StatelessWidget {
  const _ConflictsTab({required this.conflicts, required this.onResolve});

  final List<AtlasEnterpriseSyncConflict> conflicts;
  final ValueChanged<AtlasEnterpriseSyncConflict> onResolve;

  @override
  Widget build(BuildContext context) {
    final unresolved = conflicts
        .where(
          (item) =>
              item.resolution == AtlasEnterpriseConflictResolution.unresolved,
        )
        .toList();

    if (unresolved.isEmpty) {
      return const Center(child: Text('Nenhum conflito pendente.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: unresolved.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = unresolved[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.compare_arrows_outlined),
            title: Text('${item.entityType}/${item.entityId}'),
            subtitle: Text(
              'Local v${item.localVersion} • '
              'Remoto v${item.remoteVersion}',
            ),
            trailing: FilledButton.tonal(
              onPressed: () => onResolve(item),
              child: const Text('Resolver'),
            ),
          ),
        );
      },
    );
  }
}

class _SyncTab extends StatelessWidget {
  const _SyncTab({
    required this.summary,
    required this.checkpoint,
    required this.online,
  });

  final AtlasEnterpriseSyncSummary summary;
  final AtlasEnterpriseSyncCheckpoint? checkpoint;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _metric('Total', summary.total),
        _metric('Pendentes', summary.pending),
        _metric('Sincronizando', summary.syncing),
        _metric('Sincronizados', summary.synchronized),
        _metric('Conflitos', summary.conflicts),
        _metric('Erros', summary.errors),
        Card(
          child: ListTile(
            title: const Text('Modo atual'),
            trailing: Text(online ? 'Online' : 'Offline'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Cursor incremental'),
            subtitle: Text(
              checkpoint?.cursor.isNotEmpty == true
                  ? checkpoint!.cursor
                  : 'Ainda não iniciado',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Transporte do 24C'),
            subtitle: Text(
              'O engine usa um contrato de transporte e um '
              'loopback local para validar fila, versões, '
              'idempotência e conflitos. O backend HTTP real '
              'será conectado no 24D.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(String title, int value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _TestsTab extends StatelessWidget {
  const _TestsTab({
    required this.onCreateVersion,
    required this.onConcurrency,
    required this.onSync,
  });

  final VoidCallback onCreateVersion;
  final VoidCallback onConcurrency;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: onCreateVersion,
          icon: const Icon(Icons.history),
          label: const Text('Criar versão + enfileirar operação'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: onConcurrency,
          icon: const Icon(Icons.compare),
          label: const Text('Testar concorrência otimista'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: onSync,
          icon: const Icon(Icons.sync),
          label: const Text('Executar sincronização incremental'),
        ),
        const SizedBox(height: 18),
        const Card(
          child: ListTile(
            title: Text('Critérios 24C'),
            subtitle: Text(
              '1. Histórico nunca é sobrescrito.\n'
              '2. Base desatualizada gera conflito.\n'
              '3. Fila sobrevive ao fechamento do app.\n'
              '4. Idempotência evita duplicação.\n'
              '5. Conflitos podem ser resolvidos.\n'
              '6. Restaurar cria nova versão.',
            ),
          ),
        ),
      ],
    );
  }
}
