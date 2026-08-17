import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_analytics_screen.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_detail_screen.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_entry.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_filter.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_service.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_screen.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AtlasEventCenterScreen extends StatefulWidget {
  const AtlasEventCenterScreen({super.key});

  @override
  State<AtlasEventCenterScreen> createState() {
    return _AtlasEventCenterScreenState();
  }
}

class _AtlasEventCenterScreenState extends State<AtlasEventCenterScreen> {
  final TextEditingController searchController = TextEditingController();

  StreamSubscription<AtlasEvent>? eventSubscription;

  bool isLoading = true;
  bool liveUpdatesEnabled = true;

  AtlasEventPriority? priority;
  String? sourceModule;
  String? farmName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    eventSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await AtlasEventLogService.instance.load();

    eventSubscription = AtlasEventBus.instance.stream.listen((event) {
      if (!liveUpdatesEnabled || !mounted) {
        return;
      }

      setState(() {});
    });

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });
  }

  List<AtlasEventLogEntry> get allEntries {
    return AtlasEventLogService.instance.entries;
  }

  List<String> get availableModules {
    final modules =
        allEntries
            .map((item) => item.sourceModule)
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return modules;
  }

  List<String> get availableFarms {
    final farms =
        allEntries
            .map((item) => item.farmName)
            .whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return farms;
  }

  List<AtlasEventLogEntry> get filtered {
    return AtlasEventLogService.instance.query(
      filter: AtlasEventLogFilter(
        search: searchController.text,
        priorities: priority == null ? null : <AtlasEventPriority>{priority!},
        sourceModule: sourceModule,
        farmName: farmName,
      ),
    );
  }

  int countByPriority(AtlasEventPriority value) {
    return allEntries.where((item) => item.priority == value).length;
  }

  @override
  Widget build(BuildContext context) {
    final entries = filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Atlas Event Center',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Memória operacional',
            onPressed: _openOperationalMemory,
            icon: const Icon(Icons.history_toggle_off),
          ),
          IconButton(
            tooltip: 'Análises dos eventos',
            onPressed: _openAnalytics,
            icon: const Icon(Icons.analytics_outlined),
          ),
          IconButton(
            tooltip: liveUpdatesEnabled
                ? 'Pausar atualização ao vivo'
                : 'Retomar atualização ao vivo',
            onPressed: () {
              setState(() {
                liveUpdatesEnabled = !liveUpdatesEnabled;
              });
            },
            icon: Icon(
              liveUpdatesEnabled
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
            ),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: allEntries.isEmpty ? null : _confirmClear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      _SummaryBar(
                        total: allEntries.length,
                        low: countByPriority(AtlasEventPriority.low),
                        normal: countByPriority(AtlasEventPriority.normal),
                        high: countByPriority(AtlasEventPriority.high),
                        critical: countByPriority(AtlasEventPriority.critical),
                        liveUpdatesEnabled: liveUpdatesEnabled,
                      ),
                      _FilterPanel(
                        searchController: searchController,
                        priority: priority,
                        sourceModule: sourceModule,
                        farmName: farmName,
                        modules: availableModules,
                        farms: availableFarms,
                        onChanged: () {
                          setState(() {});
                        },
                        onPriorityChanged: (value) {
                          setState(() {
                            priority = value;
                          });
                        },
                        onModuleChanged: (value) {
                          setState(() {
                            sourceModule = value;
                          });
                        },
                        onFarmChanged: (value) {
                          setState(() {
                            farmName = value;
                          });
                        },
                        onClearFilters: () {
                          setState(() {
                            searchController.clear();
                            priority = null;
                            sourceModule = null;
                            farmName = null;
                          });
                        },
                      ),
                      Expanded(
                        child: entries.isEmpty
                            ? const _EmptyView()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  8,
                                  22,
                                  28,
                                ),
                                itemCount: entries.length,
                                separatorBuilder: (context, index) {
                                  return const SizedBox(height: 10);
                                },
                                itemBuilder: (context, index) {
                                  final item = entries[index];

                                  return _EventCard(
                                    item: item,
                                    onOpen: () {
                                      _openDetails(item);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _openOperationalMemory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasOperationalMemoryScreen();
        },
      ),
    );
  }

  Future<void> _openAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const AtlasEventAnalyticsScreen();
        },
      ),
    );
  }

  Future<void> _openDetails(AtlasEventLogEntry item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AtlasEventDetailScreen(item: item);
        },
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limpar histórico?'),
          content: const Text(
            'Todos os eventos registrados serão removidos permanentemente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AtlasEventLogService.instance.clear();

    if (!mounted) {
      return;
    }

    setState(() {});
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.total,
    required this.low,
    required this.normal,
    required this.high,
    required this.critical,
    required this.liveUpdatesEnabled,
  });

  final int total;
  final int low;
  final int normal;
  final int high;
  final int critical;
  final bool liveUpdatesEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SummaryChip(
                label: 'Total',
                value: total,
                color: const Color(0xFF455A64),
              ),
              _SummaryChip(
                label: 'Baixa',
                value: low,
                color: const Color(0xFF2E7D32),
              ),
              _SummaryChip(
                label: 'Normal',
                value: normal,
                color: const Color(0xFF1565C0),
              ),
              _SummaryChip(
                label: 'Alta',
                value: high,
                color: const Color(0xFFEF6C00),
              ),
              _SummaryChip(
                label: 'Crítica',
                value: critical,
                color: const Color(0xFFC62828),
              ),
              Chip(
                avatar: Icon(
                  liveUpdatesEnabled
                      ? Icons.circle
                      : Icons.pause_circle_outline,
                  size: 15,
                  color: liveUpdatesEnabled
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF616161),
                ),
                label: Text(
                  liveUpdatesEnabled
                      ? 'Atualização ao vivo'
                      : 'Atualização pausada',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.searchController,
    required this.priority,
    required this.sourceModule,
    required this.farmName,
    required this.modules,
    required this.farms,
    required this.onChanged,
    required this.onPriorityChanged,
    required this.onModuleChanged,
    required this.onFarmChanged,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final AtlasEventPriority? priority;
  final String? sourceModule;
  final String? farmName;
  final List<String> modules;
  final List<String> farms;
  final VoidCallback onChanged;
  final ValueChanged<AtlasEventPriority?> onPriorityChanged;
  final ValueChanged<String?> onModuleChanged;
  final ValueChanged<String?> onFarmChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar eventos',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<AtlasEventPriority?>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridade',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<AtlasEventPriority?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...AtlasEventPriority.values.map((item) {
                      return DropdownMenuItem<AtlasEventPriority?>(
                        value: item,
                        child: Text(atlasEventPriorityLabel(item)),
                      );
                    }),
                  ],
                  onChanged: onPriorityChanged,
                ),
              ),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String?>(
                  initialValue: sourceModule,
                  decoration: const InputDecoration(
                    labelText: 'Módulo',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...modules.map((item) {
                      return DropdownMenuItem<String?>(
                        value: item,
                        child: Text(item),
                      );
                    }),
                  ],
                  onChanged: onModuleChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  initialValue: farmName,
                  decoration: const InputDecoration(
                    labelText: 'Fazenda',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...farms.map((item) {
                      return DropdownMenuItem<String?>(
                        value: item,
                        child: Text(item),
                      );
                    }),
                  ],
                  onChanged: onFarmChanged,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.item, required this.onOpen});

  final AtlasEventLogEntry item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(item.priority);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_eventIcon(item.type), color: color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item.sourceModule} · '
          '${item.farmName ?? 'Operação'} · '
          '${_formatDateTime(item.occurredAt)}\n'
          '${item.description}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              atlasEventPriorityLabel(item.priority),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, size: 56, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Nenhum evento encontrado.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'Altere os filtros ou utilize os módulos do Atlas para gerar novos eventos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

Color _priorityColor(AtlasEventPriority priority) {
  switch (priority) {
    case AtlasEventPriority.low:
      return const Color(0xFF2E7D32);
    case AtlasEventPriority.normal:
      return const Color(0xFF1565C0);
    case AtlasEventPriority.high:
      return const Color(0xFFEF6C00);
    case AtlasEventPriority.critical:
      return const Color(0xFFC62828);
  }
}

IconData _eventIcon(AtlasEventType type) {
  switch (type) {
    case AtlasEventType.animalWeightRecorded:
      return Icons.monitor_weight_outlined;
    case AtlasEventType.vaccinationRecorded:
    case AtlasEventType.treatmentRecorded:
    case AtlasEventType.healthEventCreated:
    case AtlasEventType.diseaseAlertCreated:
      return Icons.medical_services_outlined;
    case AtlasEventType.reproductionEventCreated:
    case AtlasEventType.pregnancyConfirmed:
    case AtlasEventType.calvingRecorded:
    case AtlasEventType.inseminationRecorded:
      return AtlasLivestockIcons.cow;
    case AtlasEventType.financialEntryCreated:
    case AtlasEventType.financialEntryUpdated:
    case AtlasEventType.cashFlowUpdated:
    case AtlasEventType.expenseLimitReached:
      return Icons.account_balance_wallet_outlined;
    case AtlasEventType.inventoryItemCreated:
    case AtlasEventType.inventoryItemUpdated:
    case AtlasEventType.inventoryLowStock:
    case AtlasEventType.inventoryOutOfStock:
      return Icons.inventory_2_outlined;
    case AtlasEventType.taskCreated:
    case AtlasEventType.taskUpdated:
    case AtlasEventType.taskCompleted:
    case AtlasEventType.taskDelayed:
    case AtlasEventType.workflowCreated:
    case AtlasEventType.workflowUpdated:
    case AtlasEventType.workflowCompleted:
    case AtlasEventType.workflowDelayed:
      return Icons.schema_outlined;
    case AtlasEventType.executiveBrainUpdated:
      return Icons.hub_outlined;
    case AtlasEventType.systemError:
      return Icons.error_outline;
    default:
      return Icons.notifications_none;
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month/${value.year} $hour:$minute';
}
