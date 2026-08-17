import 'package:flutter/material.dart';

import '../../session/atlas_session_scope.dart';
import '../controllers/atlas_offline_controller.dart';
import '../models/offline_sync_models.dart';

class AtlasOfflineCenterScreen extends StatefulWidget {
  const AtlasOfflineCenterScreen({super.key});

  @override
  State<AtlasOfflineCenterScreen> createState() =>
      _AtlasOfflineCenterScreenState();
}

class _AtlasOfflineCenterScreenState extends State<AtlasOfflineCenterScreen> {
  AtlasOfflineController? controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller ??= AtlasOfflineController(
      sessionController: AtlasSessionScope.read(context),
    )..load();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = controller!;
    return AnimatedBuilder(
      animation: current,
      builder: (context, _) => RefreshIndicator(
        onRefresh: current.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header(controller: current),
            const SizedBox(height: 16),
            if (current.error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Não foi possível concluir a operação'),
                  subtitle: Text(current.error!),
                  trailing: IconButton(
                    tooltip: 'Tentar novamente',
                    onPressed: current.load,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ),
            _StatsGrid(stats: current.stats),
            const SizedBox(height: 16),
            _ServerCard(status: current.serverStatus),
            const SizedBox(height: 16),
            _LastReportCard(report: current.lastReport),
            const SizedBox(height: 16),
            Text(
              'Conflitos pendentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (current.conflicts.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Nenhum conflito pendente'),
                  subtitle: Text(
                    'As alterações locais e remotas estão consistentes.',
                  ),
                ),
              )
            else
              ...current.conflicts.map(
                (conflict) => _ConflictCard(
                  conflict: conflict,
                  busy: current.loading || !current.canManage,
                  onResolve: (resolution) =>
                      current.resolve(conflict, resolution),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final AtlasOfflineController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Central offline',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text(
                        'Fila local, sincronização incremental e conflitos.',
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: controller.loading || !controller.canManage
                      ? null
                      : controller.synchronize,
                  icon: const Icon(Icons.cloud_sync_outlined),
                  label: const Text('Sincronizar agora'),
                ),
              ],
            ),
            if (controller.loading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: controller.progress),
              const SizedBox(height: 8),
              Text(
                controller.phase.isEmpty
                    ? 'Atualizando informações...'
                    : controller.phase,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final OfflineQueueStats stats;

  @override
  Widget build(BuildContext context) {
    final items = <(String, int, IconData)>[
      ('Aguardando envio', stats.waiting, Icons.schedule_send_outlined),
      ('Conflitos', stats.conflicts, Icons.compare_arrows_outlined),
      ('Falhas', stats.failed, Icons.error_outline),
      ('Concluídas', stats.accepted, Icons.task_alt_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 540
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Card(
                    child: ListTile(
                      leading: Icon(item.$3),
                      title: Text('${item.$2}'),
                      subtitle: Text(item.$1),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.status});
  final OfflineServerStatus? status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          status?.ready == true ? Icons.cloud_done_outlined : Icons.cloud_off,
        ),
        title: Text(
          status?.ready == true
              ? 'Servidor de sincronização disponível'
              : 'Servidor indisponível ou não consultado',
        ),
        subtitle: status == null
            ? const Text('Os dados locais continuam disponíveis.')
            : Text(
                '${status!.activeDevices} dispositivo(s) ativo(s) • '
                '${status!.openConflicts} conflito(s) remoto(s) • '
                'cursor ${status!.latestCursor}',
              ),
      ),
    );
  }
}

class _LastReportCard extends StatelessWidget {
  const _LastReportCard({required this.report});
  final OfflineSyncReport? report;

  @override
  Widget build(BuildContext context) {
    if (report == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: const Text('Última sincronização'),
        subtitle: Text(
          '${report!.pushed} enviada(s), ${report!.pulled} recebida(s), '
          '${report!.conflicts} conflito(s), ${report!.rejected} rejeitada(s).',
        ),
        trailing: Text('${report!.duration.inSeconds}s'),
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.conflict,
    required this.busy,
    required this.onResolve,
  });

  final OfflineConflict conflict;
  final bool busy;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber_outlined),
        title: Text('${conflict.entityType} • ${conflict.entityId}'),
        subtitle: Text(
          'Versão local ${conflict.localVersion} • '
          'versão remota ${conflict.remoteVersion}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Local: ${conflict.localPayload}'),
                const SizedBox(height: 8),
                Text('Servidor: ${conflict.remotePayload}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: busy ? null : () => onResolve('keep_remote'),
                      child: const Text('Manter servidor'),
                    ),
                    FilledButton(
                      onPressed: busy ? null : () => onResolve('keep_local'),
                      child: const Text('Manter local'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
