import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/sync/atlas_sync_engine.dart';

class AtlasSyncStatusButton extends StatefulWidget {
  const AtlasSyncStatusButton({
    this.engine,
    super.key,
  });

  final AtlasSyncEngine? engine;

  @override
  State<AtlasSyncStatusButton> createState() =>
      _AtlasSyncStatusButtonState();
}

class _AtlasSyncStatusButtonState
    extends State<AtlasSyncStatusButton> {
  late final AtlasSyncEngine engine;
  bool syncing = false;
  int pending = 0;

  @override
  void initState() {
    super.initState();
    engine = widget.engine ?? AtlasSyncEngine();
    refresh();
  }

  Future<void> refresh() async {
    final count = await engine.pendingCount();

    if (!mounted) return;

    setState(() => pending = count);
  }

  Future<void> synchronize() async {
    setState(() => syncing = true);

    final result = await engine.synchronize();

    if (!mounted) return;

    setState(() {
      syncing = false;
      pending = result.pending;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sincronização: ${result.succeeded} enviados, '
          '${result.failed} falharam, '
          '${result.pending} pendentes.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: pending > 0,
      label: Text('$pending'),
      child: IconButton(
        tooltip: pending == 0
            ? 'Dados sincronizados'
            : 'Sincronizar $pending operações',
        onPressed: syncing ? null : synchronize,
        icon: syncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Icon(
                pending == 0
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_sync_outlined,
              ),
      ),
    );
  }
}
