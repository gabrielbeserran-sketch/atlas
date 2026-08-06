import 'package:flutter/material.dart';

import '../../data/services/atlas_offline_repository.dart';
import '../../domain/models/atlas_offline_record.dart';
import '../../domain/models/atlas_offline_sync_summary.dart';
import '../../domain/services/atlas_offline_sync_engine.dart';

class AtlasOfflineFieldScreen extends StatefulWidget {
  const AtlasOfflineFieldScreen({
    super.key,
    this.farmId,
  });

  final String? farmId;

  @override
  State<AtlasOfflineFieldScreen> createState() {
    return _AtlasOfflineFieldScreenState();
  }
}

class _AtlasOfflineFieldScreenState extends State<AtlasOfflineFieldScreen> {
  final AtlasOfflineRepository _repository = AtlasOfflineRepository();
  final AtlasOfflineSyncEngine _engine = const AtlasOfflineSyncEngine();

  List<AtlasOfflineRecord> _records = <AtlasOfflineRecord>[];
  bool _loading = true;
  bool _syncing = false;
  bool _online = false;
  bool _autoSync = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<dynamic> data = await Future.wait<dynamic>(<Future<dynamic>>[
      _repository.loadRecords(farmId: widget.farmId),
      _repository.loadOnlineState(),
      _repository.loadAutoSync(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _records = data[0] as List<AtlasOfflineRecord>;
      _online = data[1] as bool;
      _autoSync = data[2] as bool;
      _loading = false;
    });

    if (_online && _autoSync) {
      await _synchronize();
    }
  }

  Future<void> _setOnline(bool value) async {
    setState(() {
      _online = value;
    });
    await _repository.saveOnlineState(value);

    if (value && _autoSync) {
      await _synchronize();
    }
  }

  Future<void> _setAutoSync(bool value) async {
    setState(() {
      _autoSync = value;
    });
    await _repository.saveAutoSync(value);

    if (value && _online) {
      await _synchronize();
    }
  }

  Future<void> _synchronize() async {
    if (!_online || _syncing) {
      return;
    }

    setState(() {
      _syncing = true;
    });

    final List<AtlasOfflineRecord> synchronized =
        await _engine.synchronize(records: _records, online: _online);
    await _repository.saveRecords(synchronized);

    if (!mounted) {
      return;
    }

    setState(() {
      _records = synchronized;
      _syncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados locais sincronizados com sucesso.'),
      ),
    );
  }

  Future<void> _createRecord() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController valueController = TextEditingController();
    AtlasOfflineRecordType selectedType = AtlasOfflineRecordType.note;

    final AtlasOfflineRecord? result = await showDialog<AtlasOfflineRecord>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return AlertDialog(
              title: const Text('Novo registro de campo'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição do registro',
                          prefixIcon: Icon(Icons.edit_note_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasOfflineRecordType>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: AtlasOfflineRecordType.values.map(
                          (AtlasOfflineRecordType type) {
                            return DropdownMenuItem<AtlasOfflineRecordType>(
                              value: type,
                              child: Text(_typeLabel(type)),
                            );
                          },
                        ).toList(),
                        onChanged: (AtlasOfflineRecordType? value) {
                          if (value == null) {
                            return;
                          }

                          setLocalState(() {
                            selectedType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: valueController,
                        decoration: const InputDecoration(
                          labelText: 'Valor ou observação',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final String title = titleController.text.trim();

                    if (title.isEmpty) {
                      return;
                    }

                    final DateTime now = DateTime.now();
                    Navigator.of(dialogContext).pop(
                      AtlasOfflineRecord(
                        id: now.microsecondsSinceEpoch.toString(),
                        title: title,
                        type: selectedType,
                        status: AtlasOfflineRecordStatus.pending,
                        createdAt: now,
                        updatedAt: now,
                        payload: <String, dynamic>{
                          'value': valueController.text.trim(),
                        },
                        farmId: widget.farmId,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar offline'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    valueController.dispose();

    if (result == null || !mounted) {
      return;
    }

    final List<AtlasOfflineRecord> updated = _engine.queueRecord(
      records: _records,
      record: result,
    );
    await _repository.saveRecords(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _records = updated;
    });

    if (_online && _autoSync) {
      await _synchronize();
    }
  }

  Future<void> _deleteRecord(AtlasOfflineRecord record) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Excluir registro'),
          content: Text('Deseja excluir “${record.title}”?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final List<AtlasOfflineRecord> updated = _records.where(
      (AtlasOfflineRecord item) => item.id != record.id,
    ).toList();
    await _repository.saveRecords(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _records = updated;
    });
  }

  String _typeLabel(AtlasOfflineRecordType type) {
    switch (type) {
      case AtlasOfflineRecordType.animal:
        return 'Animal';
      case AtlasOfflineRecordType.weighing:
        return 'Pesagem';
      case AtlasOfflineRecordType.health:
        return 'Sanidade';
      case AtlasOfflineRecordType.reproduction:
        return 'Reprodução';
      case AtlasOfflineRecordType.operation:
        return 'Operação';
      case AtlasOfflineRecordType.finance:
        return 'Financeiro';
      case AtlasOfflineRecordType.inventory:
        return 'Estoque';
      case AtlasOfflineRecordType.note:
        return 'Observação';
    }
  }

  String _statusLabel(AtlasOfflineRecordStatus status) {
    switch (status) {
      case AtlasOfflineRecordStatus.pending:
        return 'Pendente';
      case AtlasOfflineRecordStatus.syncing:
        return 'Sincronizando';
      case AtlasOfflineRecordStatus.synchronized:
        return 'Sincronizado';
      case AtlasOfflineRecordStatus.failed:
        return 'Falhou';
    }
  }

  Color _statusColor(AtlasOfflineRecordStatus status) {
    switch (status) {
      case AtlasOfflineRecordStatus.pending:
        return Colors.orange;
      case AtlasOfflineRecordStatus.syncing:
        return Colors.blue;
      case AtlasOfflineRecordStatus.synchronized:
        return Colors.green;
      case AtlasOfflineRecordStatus.failed:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} às $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final AtlasOfflineSyncSummary summary =
        AtlasOfflineSyncSummary.fromRecords(_records);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Aplicativo de Campo Offline'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRecord,
        icon: const Icon(Icons.add),
        label: const Text('Registrar no campo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: (_online ? Colors.green : Colors.orange)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  _online ? Icons.cloud_done : Icons.cloud_off,
                                  color: _online ? Colors.green : Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _online
                                          ? 'Conectado e pronto para sincronizar'
                                          : 'Modo offline ativo',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Os registros são salvos no aparelho e enviados quando a conexão estiver disponível.',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _online,
                                onChanged: _setOnline,
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _autoSync,
                            onChanged: _setAutoSync,
                            title: const Text('Sincronização automática'),
                            subtitle: const Text(
                              'Enviar a fila automaticamente ao entrar online.',
                            ),
                            secondary: const Icon(Icons.sync),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _online && !_syncing && summary.pending > 0
                                  ? _synchronize
                                  : null,
                              icon: _syncing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined),
                              label: Text(
                                _syncing
                                    ? 'Sincronizando...'
                                    : 'Sincronizar agora',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      _OfflineMetric(
                        label: 'Registros',
                        value: '${summary.total}',
                        icon: Icons.storage_outlined,
                      ),
                      _OfflineMetric(
                        label: 'Pendentes',
                        value: '${summary.pending}',
                        icon: Icons.schedule_outlined,
                      ),
                      _OfflineMetric(
                        label: 'Sincronizados',
                        value: '${summary.synchronized}',
                        icon: Icons.cloud_done_outlined,
                      ),
                      _OfflineMetric(
                        label: 'Taxa de envio',
                        value: '${summary.completionRate.toStringAsFixed(0)}%',
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Fila de registros de campo',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_records.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                          child: Text('Nenhum registro local disponível.'),
                        ),
                      ),
                    )
                  else
                    ..._records.map((AtlasOfflineRecord record) {
                      final Color color = _statusColor(record.status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(Icons.description_outlined, color: color),
                          ),
                          title: Text(
                            record.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${_typeLabel(record.type)} • ${_formatDate(record.updatedAt)}\n${_statusLabel(record.status)}',
                            ),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (String value) {
                              if (value == 'delete') {
                                _deleteRecord(record);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return const <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: <Widget>[
                                      Icon(Icons.delete_outline, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text(
                                        'Excluir',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _OfflineMetric extends StatelessWidget {
  const _OfflineMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
