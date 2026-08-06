import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_detail_screen.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_entry.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_service.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_event_correlation.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_event_correlation_service.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_service.dart';

class AtlasOperationalMemoryScreen extends StatefulWidget {
  const AtlasOperationalMemoryScreen({super.key});

  @override
  State<AtlasOperationalMemoryScreen> createState() {
    return _AtlasOperationalMemoryScreenState();
  }
}

class _AtlasOperationalMemoryScreenState
    extends State<AtlasOperationalMemoryScreen> {
  final TextEditingController searchController = TextEditingController();
  final AtlasEventCorrelationService correlationService =
      const AtlasEventCorrelationService();

  String? selectedFarm;
  String? selectedModule;
  String? selectedEntityType;
  AtlasEventPriority? selectedPriority;
  bool isLoading = true;
  bool showCorrelations = true;
  StreamSubscription<AtlasEvent>? eventSubscription;
  Timer? refreshDebounce;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    refreshDebounce?.cancel();
    eventSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await AtlasOperationalMemoryService.instance.initialize();

    eventSubscription = AtlasEventBus.instance.stream.listen((event) {
      refreshDebounce?.cancel();
      refreshDebounce = Timer(
        const Duration(milliseconds: 250),
        () {
          if (mounted) {
            setState(() {});
          }
        },
      );
    });

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });
  }

  List<AtlasOperationalMemoryEntry> get entries {
    return AtlasOperationalMemoryService.instance.query(
      search: searchController.text,
      farmName: selectedFarm,
      sourceModule: selectedModule,
      entityType: selectedEntityType,
      priority: selectedPriority,
      limit: 300,
    );
  }

  List<AtlasEventCorrelation> get correlations {
    return correlationService.build(
      entries: entries,
      maxItems: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEntries = entries;
    final currentCorrelations = correlations;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Memória Operacional',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: showCorrelations
                ? 'Ocultar correlações'
                : 'Exibir correlações',
            onPressed: () {
              setState(() {
                showCorrelations = !showCorrelations;
              });
            },
            icon: Icon(
              showCorrelations
                  ? Icons.hub_outlined
                  : Icons.hub,
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _HeaderCard(
                        totalEvents: currentEntries.length,
                        totalCorrelations: currentCorrelations.length,
                        criticalEvents: currentEntries.where((item) {
                          return item.priority ==
                              AtlasEventPriority.critical;
                        }).length,
                      ),
                      const SizedBox(height: 16),
                      _buildFilters(),
                      if (showCorrelations) ...[
                        const SizedBox(height: 20),
                        _SectionTitle(
                          title: 'Correlações entre módulos',
                          subtitle:
                              'Relações detectadas por proximidade temporal, entidade, prioridade e sinais em comum.',
                          count: currentCorrelations.length,
                        ),
                        const SizedBox(height: 12),
                        if (currentCorrelations.isEmpty)
                          const _EmptyCard(
                            message:
                                'Ainda não existem eventos suficientes para identificar correlações.',
                          )
                        else
                          ...currentCorrelations.map(
                            (item) => _CorrelationCard(item: item),
                          ),
                      ],
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: 'Linha do tempo global',
                        subtitle:
                            'Histórico consolidado de alterações operacionais registradas pelo Atlas.',
                        count: currentEntries.length,
                      ),
                      const SizedBox(height: 12),
                      if (currentEntries.isEmpty)
                        const _EmptyCard(
                          message:
                              'Nenhum evento encontrado para os filtros selecionados.',
                        )
                      else
                        ...currentEntries.map(
                          (item) => _TimelineCard(
                            item: item,
                            onOpen: () => _openDetails(item),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFilters() {
    final farms = AtlasOperationalMemoryService.instance.availableFarms();
    final modules = AtlasOperationalMemoryService.instance.availableModules();
    final entityTypes =
        AtlasOperationalMemoryService.instance.availableEntityTypes();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Buscar na memória',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            _FilterDropdown<String>(
              width: 210,
              label: 'Fazenda',
              value: selectedFarm,
              items: farms,
              itemLabel: (value) => value,
              onChanged: (value) {
                setState(() {
                  selectedFarm = value;
                });
              },
            ),
            _FilterDropdown<String>(
              width: 210,
              label: 'Módulo',
              value: selectedModule,
              items: modules,
              itemLabel: (value) => value,
              onChanged: (value) {
                setState(() {
                  selectedModule = value;
                });
              },
            ),
            _FilterDropdown<String>(
              width: 210,
              label: 'Entidade',
              value: selectedEntityType,
              items: entityTypes,
              itemLabel: (value) => value,
              onChanged: (value) {
                setState(() {
                  selectedEntityType = value;
                });
              },
            ),
            _FilterDropdown<AtlasEventPriority>(
              width: 190,
              label: 'Prioridade',
              value: selectedPriority,
              items: AtlasEventPriority.values,
              itemLabel: _priorityLabel,
              onChanged: (value) {
                setState(() {
                  selectedPriority = value;
                });
              },
            ),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    searchController.clear();

    setState(() {
      selectedFarm = null;
      selectedModule = null;
      selectedEntityType = null;
      selectedPriority = null;
    });
  }

  Future<void> _openDetails(AtlasOperationalMemoryEntry item) async {
    AtlasEventLogEntry? original;

    for (final entry in AtlasEventLogService.instance.entries) {
      if (entry.eventId == item.eventId) {
        original = entry;
        break;
      }
    }

    if (original == null || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AtlasEventDetailScreen(item: original!),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.totalEvents,
    required this.totalCorrelations,
    required this.criticalEvents,
  });

  final int totalEvents;
  final int totalCorrelations;
  final int criticalEvents;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Memória viva da operação',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'O Atlas consolida eventos de todos os módulos e procura relações que apoiem decisões mais rápidas.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  icon: Icons.history,
                  label: 'Eventos',
                  value: '$totalEvents',
                ),
                _MetricChip(
                  icon: Icons.hub_outlined,
                  label: 'Correlações',
                  value: '$totalCorrelations',
                ),
                _MetricChip(
                  icon: Icons.warning_amber_rounded,
                  label: 'Críticos',
                  value: '$criticalEvents',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle),
            ],
          ),
        ),
        Chip(label: Text('$count')),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.item,
    required this.onOpen,
  });

  final AtlasOperationalMemoryEntry item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          child: Icon(_priorityIcon(item.priority)),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.description),
              const SizedBox(height: 6),
              Text(
                '${item.sourceModule} • ${item.farmName ?? 'Operação'} • ${_formatDate(item.occurredAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _CorrelationCard extends StatelessWidget {
  const _CorrelationCard({required this.item});

  final AtlasEventCorrelation item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(child: Icon(Icons.hub_outlined)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(item.description),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(item.farmName)),
                      Chip(label: Text('${item.confidencePercent.toStringAsFixed(0)}% de confiança')),
                      Chip(label: Text('${item.hoursBetweenEvents} h entre eventos')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final double width;
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<T?>(
            value: null,
            child: Text('Todos'),
          ),
          ...items.map(
            (item) => DropdownMenuItem<T?>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(child: Text(message)),
      ),
    );
  }
}

String _priorityLabel(AtlasEventPriority priority) {
  switch (priority) {
    case AtlasEventPriority.low:
      return 'Baixa';
    case AtlasEventPriority.normal:
      return 'Normal';
    case AtlasEventPriority.high:
      return 'Alta';
    case AtlasEventPriority.critical:
      return 'Crítica';
  }
}

IconData _priorityIcon(AtlasEventPriority priority) {
  switch (priority) {
    case AtlasEventPriority.low:
      return Icons.info_outline;
    case AtlasEventPriority.normal:
      return Icons.notifications_none;
    case AtlasEventPriority.high:
      return Icons.priority_high;
    case AtlasEventPriority.critical:
      return Icons.warning_amber_rounded;
  }
}

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');

  return '${two(value.day)}/${two(value.month)}/${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}
