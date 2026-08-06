import 'package:flutter/material.dart';

import '../../data/services/atlas_operations_repository.dart';
import '../../domain/models/atlas_farm_operation.dart';
import '../../domain/services/atlas_operations_engine.dart';

class AtlasOperationsCenterScreen extends StatefulWidget {
  const AtlasOperationsCenterScreen({super.key, this.farmId});

  final String? farmId;

  @override
  State<AtlasOperationsCenterScreen> createState() =>
      _AtlasOperationsCenterScreenState();
}

class _AtlasOperationsCenterScreenState
    extends State<AtlasOperationsCenterScreen> {
  final AtlasOperationsRepository _repository = AtlasOperationsRepository();

  final AtlasOperationsEngine _engine = const AtlasOperationsEngine();

  List<AtlasFarmOperation> _items = <AtlasFarmOperation>[];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final List<AtlasFarmOperation> items = await _repository.load(
      farmId: widget.farmId,
    );

    items.sort((AtlasFarmOperation a, AtlasFarmOperation b) {
      return a.scheduledAt.compareTo(b.scheduledAt);
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _repository.save(_items);
  }

  String _money(double value) {
    final String formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    return 'R\$ $formatted';
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _type(AtlasOperationType value) {
    switch (value) {
      case AtlasOperationType.reproduction:
        return 'Reprodução';

      case AtlasOperationType.health:
        return 'Sanidade';

      case AtlasOperationType.weighing:
        return 'Pesagem';

      case AtlasOperationType.nutrition:
        return 'Nutrição';

      case AtlasOperationType.pasture:
        return 'Pastagem';

      case AtlasOperationType.infrastructure:
        return 'Infraestrutura';

      case AtlasOperationType.herd:
        return 'Rebanho';

      case AtlasOperationType.other:
        return 'Outro';
    }
  }

  String _status(AtlasOperationStatus value) {
    switch (value) {
      case AtlasOperationStatus.planned:
        return 'Planejada';

      case AtlasOperationStatus.inProgress:
        return 'Em andamento';

      case AtlasOperationStatus.paused:
        return 'Pausada';

      case AtlasOperationStatus.completed:
        return 'Concluída';

      case AtlasOperationStatus.cancelled:
        return 'Cancelada';
    }
  }

  String _priority(AtlasOperationPriority value) {
    switch (value) {
      case AtlasOperationPriority.low:
        return 'Baixa';

      case AtlasOperationPriority.medium:
        return 'Média';

      case AtlasOperationPriority.high:
        return 'Alta';

      case AtlasOperationPriority.critical:
        return 'Crítica';
    }
  }

  Color _statusColor(AtlasFarmOperation operation) {
    if (operation.isOverdue) {
      return Colors.red;
    }

    switch (operation.status) {
      case AtlasOperationStatus.completed:
        return Colors.green;

      case AtlasOperationStatus.inProgress:
        return Colors.blue;

      case AtlasOperationStatus.paused:
        return Colors.orange;

      case AtlasOperationStatus.cancelled:
        return Colors.grey;

      case AtlasOperationStatus.planned:
        return Colors.indigo;
    }
  }

  Color _priorityColor(AtlasOperationPriority priority) {
    switch (priority) {
      case AtlasOperationPriority.low:
        return Colors.green;

      case AtlasOperationPriority.medium:
        return Colors.blue;

      case AtlasOperationPriority.high:
        return Colors.orange;

      case AtlasOperationPriority.critical:
        return Colors.red;
    }
  }

  Future<void> _edit([AtlasFarmOperation? current]) async {
    final TextEditingController titleController = TextEditingController(
      text: current?.title ?? '',
    );

    final TextEditingController responsibleController = TextEditingController(
      text: current?.responsible ?? '',
    );

    final TextEditingController costController = TextEditingController(
      text: (current?.plannedCost ?? 0).toStringAsFixed(2),
    );

    AtlasOperationType selectedType =
        current?.type ?? AtlasOperationType.health;

    AtlasOperationPriority selectedPriority =
        current?.priority ?? AtlasOperationPriority.medium;

    DateTime selectedDate =
        current?.scheduledAt ?? DateTime.now().add(const Duration(days: 1));

    final AtlasFarmOperation? result = await showDialog<AtlasFarmOperation>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocalState) {
            return AlertDialog(
              title: Text(
                current == null ? 'Nova operação' : 'Editar operação',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          prefixIcon: Icon(Icons.assignment_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: responsibleController,
                        decoration: const InputDecoration(
                          labelText: 'Responsável',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasOperationType>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: AtlasOperationType.values.map((
                          AtlasOperationType item,
                        ) {
                          return DropdownMenuItem<AtlasOperationType>(
                            value: item,
                            child: Text(_type(item)),
                          );
                        }).toList(),
                        onChanged: (AtlasOperationType? value) {
                          if (value == null) {
                            return;
                          }

                          setLocalState(() {
                            selectedType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AtlasOperationPriority>(
                        initialValue: selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Prioridade',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: AtlasOperationPriority.values.map((
                          AtlasOperationPriority item,
                        ) {
                          return DropdownMenuItem<AtlasOperationPriority>(
                            value: item,
                            child: Text(_priority(item)),
                          );
                        }).toList(),
                        onChanged: (AtlasOperationPriority? value) {
                          if (value == null) {
                            return;
                          }

                          setLocalState(() {
                            selectedPriority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Custo planejado',
                          prefixText: 'R\$ ',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Data programada'),
                        subtitle: Text(_formatDate(selectedDate)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final DateTime? date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1825),
                            ),
                          );

                          if (date == null) {
                            return;
                          }

                          setLocalState(() {
                            selectedDate = date;
                          });
                        },
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe o título da operação.'),
                        ),
                      );

                      return;
                    }

                    final double plannedCost =
                        double.tryParse(
                          costController.text
                              .trim()
                              .replaceAll('.', '')
                              .replaceAll(',', '.'),
                        ) ??
                        0;

                    final AtlasFarmOperation operation = AtlasFarmOperation(
                      id:
                          current?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      farmId: widget.farmId,
                      title: title,
                      description: current?.description ?? '',
                      type: selectedType,
                      status: current?.status ?? AtlasOperationStatus.planned,
                      priority: selectedPriority,
                      responsible: responsibleController.text.trim(),
                      team: current?.team ?? const [],
                      equipment: current?.equipment ?? const [],
                      scheduledAt: selectedDate,
                      estimatedHours: current?.estimatedHours ?? 4,
                      actualHours: current?.actualHours ?? 0,
                      plannedCost: plannedCost,
                      actualCost: current?.actualCost ?? 0,
                      progress: current?.progress ?? 0,
                      notes: current?.notes ?? '',
                    );

                    Navigator.of(dialogContext).pop(operation);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    responsibleController.dispose();
    costController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final int index = _items.indexWhere((AtlasFarmOperation item) {
        return item.id == result.id;
      });

      if (index < 0) {
        _items = <AtlasFarmOperation>[..._items, result];
      } else {
        final List<AtlasFarmOperation> copy = <AtlasFarmOperation>[..._items];

        copy[index] = result;
        _items = copy;
      }

      _items.sort((AtlasFarmOperation a, AtlasFarmOperation b) {
        return a.scheduledAt.compareTo(b.scheduledAt);
      });
    });

    await _save();
  }

  Future<void> _advance(AtlasFarmOperation item) async {
    AtlasOperationStatus nextStatus;

    switch (item.status) {
      case AtlasOperationStatus.planned:
        nextStatus = AtlasOperationStatus.inProgress;
        break;

      case AtlasOperationStatus.inProgress:
        nextStatus = AtlasOperationStatus.completed;
        break;

      case AtlasOperationStatus.paused:
      case AtlasOperationStatus.completed:
      case AtlasOperationStatus.cancelled:
        nextStatus = item.status;
        break;
    }

    final double nextProgress;

    if (nextStatus == AtlasOperationStatus.completed) {
      nextProgress = 100;
    } else if (item.progress < 10) {
      nextProgress = 10;
    } else {
      nextProgress = item.progress.toDouble();
    }

    final AtlasFarmOperation updated = item.copyWith(
      status: nextStatus,
      progress: nextProgress,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _items = _items.map((AtlasFarmOperation operation) {
        if (operation.id == item.id) {
          return updated;
        }

        return operation;
      }).toList();
    });

    await _save();
  }

  Future<void> _delete(AtlasFarmOperation operation) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Excluir operação'),
          content: Text(
            'Deseja excluir a operação '
            '"${operation.title}"?',
          ),
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

    setState(() {
      _items = _items.where((AtlasFarmOperation item) {
        return item.id != operation.id;
      }).toList();
    });

    await _save();
  }

  Widget _buildOperationCard(AtlasFarmOperation operation) {
    final Color statusColor = _statusColor(operation);

    final Color priorityColor = _priorityColor(operation.priority);

    final double progressValue =
        operation.progress.clamp(0, 100).toDouble() / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    operation.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    operation.isOverdue
                        ? 'Atrasada'
                        : _status(operation.status),
                  ),
                  side: BorderSide.none,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opções',
                  onSelected: (String value) {
                    if (value == 'edit') {
                      _edit(operation);
                    }

                    if (value == 'delete') {
                      _delete(operation);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 10),
                            Text('Editar'),
                          ],
                        ),
                      ),
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
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_type(operation.type)} • '
              '${operation.responsible.isEmpty ? 'Sem responsável' : operation.responsible}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _InformationChip(
                  icon: Icons.flag_outlined,
                  label: _priority(operation.priority),
                  color: priorityColor,
                ),
                _InformationChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(operation.scheduledAt),
                  color: Colors.indigo,
                ),
                _InformationChip(
                  icon: Icons.payments_outlined,
                  label:
                      '${_money(operation.actualCost)} de ${_money(operation.plannedCost)}',
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${operation.progress.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (operation.status == AtlasOperationStatus.planned ||
                operation.status ==
                    AtlasOperationStatus.inProgress) ...<Widget>[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () {
                    _advance(operation);
                  },
                  icon: Icon(
                    operation.status == AtlasOperationStatus.planned
                        ? Icons.play_arrow
                        : Icons.check,
                  ),
                  label: Text(
                    operation.status == AtlasOperationStatus.planned
                        ? 'Iniciar'
                        : 'Concluir',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _engine.summarize(_items);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Centro de Operações da Fazenda'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _edit();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova operação'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      _Metric(
                        'Operações',
                        '${summary.total}',
                        Icons.assignment_outlined,
                      ),
                      _Metric('Hoje', '${summary.today}', Icons.today_outlined),
                      _Metric(
                        'Em andamento',
                        '${summary.inProgress}',
                        Icons.play_circle_outline,
                      ),
                      _Metric(
                        'Atrasadas',
                        '${summary.overdue}',
                        Icons.warning_amber_outlined,
                      ),
                      _Metric(
                        'Avanço médio',
                        '${summary.averageProgress.toStringAsFixed(0)}%',
                        Icons.trending_up,
                      ),
                      _Metric(
                        'Custo realizado',
                        _money(summary.actualCost),
                        Icons.payments_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Agenda operacional',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Icon(
                                Icons.assignment_outlined,
                                size: 46,
                                color: Colors.black38,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Nenhuma operação cadastrada.',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Toque em “Nova operação” para começar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._items.map((AtlasFarmOperation operation) {
                      return _buildOperationCard(operation);
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);

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
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationChip extends StatelessWidget {
  const _InformationChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
