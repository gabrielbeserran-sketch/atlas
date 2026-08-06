import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_audit_entry.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_audit_service.dart';

class AtlasExecutionAuditScreen extends StatefulWidget {
  const AtlasExecutionAuditScreen({
    this.entityId,
    this.farmName,
    super.key,
  });

  final String? entityId;
  final String? farmName;

  @override
  State<AtlasExecutionAuditScreen> createState() =>
      _AtlasExecutionAuditScreenState();
}

class _AtlasExecutionAuditScreenState
    extends State<AtlasExecutionAuditScreen> {
  final AtlasExecutionAuditService service =
      AtlasExecutionAuditService.instance;

  List<AtlasExecutionAuditEntry> entries =
      <AtlasExecutionAuditEntry>[];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);

    entries = await service.load(
      entityId: widget.entityId,
      farmName: widget.farmName,
    );

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria da execução'),
        actions: [
          IconButton(
            tooltip: 'Atualizar auditoria',
            onPressed: isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading && entries.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma alteração auditada foi registrada.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = entries[index];

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.history),
                        ),
                        title: Text(
                          '${entry.entityTitle} — '
                          '${entry.fieldName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'De: ${entry.oldValue}\n'
                            'Para: ${entry.newValue}\n'
                            '${entry.changedBy} • ${entry.source} • '
                            '${DateFormat('dd/MM/yyyy HH:mm').format(entry.changedAt)}',
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
