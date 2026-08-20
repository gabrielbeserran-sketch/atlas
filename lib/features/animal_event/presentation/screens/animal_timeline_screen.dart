import 'package:flutter/material.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_document/data/services/animal_document_storage_service.dart';
import 'package:projeto_atlas/features/animal_document/domain/models/animal_document_data.dart';
import 'package:projeto_atlas/features/animal_event/data/services/animal_enterprise_timeline_service.dart';
import 'package:projeto_atlas/features/animal_event/data/services/animal_event_storage_service.dart';
import 'package:projeto_atlas/features/animal_event/domain/models/animal_enterprise_timeline_data.dart';
import 'package:projeto_atlas/features/animal_event/domain/models/animal_event_data.dart';
import 'package:projeto_atlas/features/animal_event/presentation/screens/animal_event_form_screen.dart';
import 'package:projeto_atlas/features/animal_health/data/services/animal_health_storage_service.dart';
import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_movement/data/services/animal_movement_storage_service.dart';
import 'package:projeto_atlas/features/animal_movement/domain/models/animal_movement_data.dart';
import 'package:projeto_atlas/features/animal_photo/data/services/animal_photo_storage_service.dart';
import 'package:projeto_atlas/features/animal_photo/domain/models/animal_photo_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:projeto_atlas/core/branding/atlas_livestock_icons.dart';

class AnimalTimelineScreen extends StatefulWidget {
  const AnimalTimelineScreen({
    required this.animal,
    required this.farm,
    required this.group,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;

  @override
  State<AnimalTimelineScreen> createState() => _AnimalTimelineScreenState();
}

class _AnimalTimelineScreenState extends State<AnimalTimelineScreen> {
  final AnimalEventStorageService eventStorage = AnimalEventStorageService();
  final AnimalEnterpriseTimelineService enterpriseTimeline =
      AnimalEnterpriseTimelineService();
  final AnimalWeightStorageService weightStorage = AnimalWeightStorageService();
  final AnimalHealthStorageService healthStorage = AnimalHealthStorageService();
  final AnimalReproductionStorageService reproductionStorage =
      AnimalReproductionStorageService();
  final AnimalMovementStorageService movementStorage =
      AnimalMovementStorageService();
  final AnimalDocumentStorageService documentStorage =
      AnimalDocumentStorageService();
  final AnimalPhotoStorageService photoStorage = AnimalPhotoStorageService();

  final TextEditingController searchController = TextEditingController();

  List<AnimalEventData> manualEvents = <AnimalEventData>[];
  List<TimelineItem> timelineItems = <TimelineItem>[];

  bool isLoading = true;
  String? selectedCategory;
  TimelinePeriod selectedPeriod = TimelinePeriod.all;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_refreshFilters);
    loadTimeline();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_refreshFilters)
      ..dispose();
    super.dispose();
  }

  void _refreshFilters() {
    if (mounted) setState(() {});
  }

  List<TimelineItem> get filteredItems {
    final query = searchController.text.trim().toLowerCase();
    final threshold = selectedPeriod.threshold;

    return timelineItems
        .where((item) {
          final matchesCategory =
              selectedCategory == null || item.category == selectedCategory;

          final matchesPeriod =
              threshold == null || !item.dateTime.isBefore(threshold);

          final searchable = [
            item.category,
            item.title,
            item.subtitle,
            item.description,
            item.date,
          ].join(' ').toLowerCase();

          final matchesSearch = query.isEmpty || searchable.contains(query);

          return matchesCategory && matchesPeriod && matchesSearch;
        })
        .toList(growable: false);
  }

  int countCategory(String category) {
    return timelineItems.where((item) => item.category == category).length;
  }

  int get alertCount {
    return timelineItems.where((item) => item.isAlert).length;
  }

  Future<List<AnimalEnterpriseTimelineData>>
  loadEnterpriseTimelineSafely() async {
    try {
      return await enterpriseTimeline.loadTimeline(widget.animal.id);
    } catch (_) {
      return <AnimalEnterpriseTimelineData>[];
    }
  }

  Future<void> loadTimeline() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final results = await Future.wait<dynamic>([
        eventStorage.loadEvents(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
        ),
        weightStorage.loadWeights(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
        ),
        healthStorage.loadRecords(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
        ),
        reproductionStorage.loadRecords(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
        ),
        movementStorage.loadRecords(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
        ),
        documentStorage.loadDocuments(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
        ),
        photoStorage.loadPhotos(
          farmName: widget.farm.name,
          groupName: widget.group.name,
          animalId: widget.animal.id,
        ),
        loadEnterpriseTimelineSafely(),
      ]);

      final events = results[0] as List<AnimalEventData>;
      final weights = results[1] as List<AnimalWeightData>;
      final healthRecords = results[2] as List<AnimalHealthData>;
      final reproductionRecords = results[3] as List<AnimalReproductionData>;
      final movementRecords = results[4] as List<AnimalMovementData>;
      final documents = results[5] as List<AnimalDocumentData>;
      final photos = results[6] as List<AnimalPhotoData>;
      final enterpriseRecords =
          results[7] as List<AnimalEnterpriseTimelineData>;

      // A Timeline Enterprise consolida os mesmos eventos oficiais que
      // também são carregados pelos módulos especializados. Mantemos a versão
      // especializada (mais rica para o usuário) e usamos Enterprise apenas
      // para eventos que ainda não estejam representados localmente.
      final canonicalSourceIds = <String>{
        ...weights.map((item) => item.id),
        ...healthRecords.map((item) => item.id),
        ...reproductionRecords.map((item) => item.id),
        ...movementRecords.map((item) => item.id),
      };
      final uniqueEnterpriseRecords = enterpriseRecords
          .where((record) => !canonicalSourceIds.contains(record.id))
          .toList(growable: false);

      final items = <TimelineItem>[
        ...events.map(TimelineItem.fromManualEvent),
        ...weights.map(TimelineItem.fromWeight),
        ...healthRecords.map(TimelineItem.fromHealth),
        ...reproductionRecords.map(TimelineItem.fromReproduction),
        ...movementRecords.map(TimelineItem.fromMovement),
        ...documents.map(TimelineItem.fromDocument),
        ...documents
            .where((document) => document.hasExpiration)
            .map(TimelineItem.fromDocumentExpiration),
        ...photos.map(TimelineItem.fromPhoto),
        ...uniqueEnterpriseRecords.map(TimelineItem.fromEnterprise),
      ];

      items.sort((first, second) {
        final dateComparison = second.dateTime.compareTo(first.dateTime);
        if (dateComparison != 0) return dateComparison;
        return second.id.compareTo(first.id);
      });

      if (!mounted) return;

      setState(() {
        manualEvents = events;
        timelineItems = items;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível carregar toda a timeline: $error'),
        ),
      );
    }
  }

  Future<void> saveManualEvents() async {
    await eventStorage.saveEvents(
      farmName: widget.farm.name,
      groupName: widget.group.name,
      animalId: widget.animal.id,
      events: manualEvents,
    );
  }

  Future<void> openEventForm() async {
    final newEvent = await Navigator.push<AnimalEventData>(
      context,
      MaterialPageRoute<AnimalEventData>(
        builder: (context) => const AnimalEventFormScreen(),
      ),
    );

    if (newEvent == null || !mounted) return;

    manualEvents.add(newEvent);
    await saveManualEvents();
    await loadTimeline();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento registrado na linha do tempo.')),
    );
  }

  Future<void> editManualEvent(AnimalEventData event) async {
    final editedEvent = await Navigator.push<AnimalEventData>(
      context,
      MaterialPageRoute<AnimalEventData>(
        builder: (context) => AnimalEventFormScreen(event: event),
      ),
    );

    if (editedEvent == null || !mounted) return;

    final index = manualEvents.indexWhere((item) => item.id == event.id);
    if (index == -1) return;

    manualEvents[index] = editedEvent;
    await saveManualEvents();
    await loadTimeline();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evento atualizado.')));
  }

  Future<void> deleteManualEvent(AnimalEventData event) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir evento'),
        content: Text('Tem certeza de que deseja excluir ${event.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    manualEvents.removeWhere((item) => item.id == event.id);

    await saveManualEvents();
    await loadTimeline();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evento excluído.')));
  }

  void handleItemTap(TimelineItem item) {
    if (item.manualEvent != null) {
      editManualEvent(item.manualEvent!);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registro originado em ${item.category}. '
          'Abra o respectivo módulo na Central do Animal para editá-lo.',
        ),
      ),
    );
  }

  void resetFilters() {
    searchController.clear();
    setState(() {
      selectedCategory = null;
      selectedPeriod = TimelinePeriod.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline inteligente'),
        actions: [
          IconButton(
            tooltip: 'Limpar filtros',
            onPressed: resetFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: isLoading ? null : loadTimeline,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : openEventForm,
        icon: const Icon(Icons.add),
        label: const Text('Novo evento'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadTimeline,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        TimelineHeader(
                          animal: widget.animal,
                          farm: widget.farm,
                          group: widget.group,
                          totalRecords: timelineItems.length,
                          alertCount: alertCount,
                        ),
                        const SizedBox(height: 18),
                        TimelineSummary(timelineItems: timelineItems),
                        const SizedBox(height: 18),
                        TimelineSearchAndPeriod(
                          searchController: searchController,
                          selectedPeriod: selectedPeriod,
                          onPeriodChanged: (period) {
                            setState(() {
                              selectedPeriod = period;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TimelineFilters(
                          selectedCategory: selectedCategory,
                          countCategory: countCategory,
                          onSelected: (category) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Histórico unificado',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${visibleItems.length} de '
                              '${timelineItems.length} registros',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Pesagens, sanidade, reprodução, movimentações, '
                          'fotos, documentos, vencimentos e auditoria.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 18),
                        if (visibleItems.isEmpty)
                          EmptyTimelineMessage(
                            hasFilter:
                                selectedCategory != null ||
                                selectedPeriod != TimelinePeriod.all ||
                                searchController.text.isNotEmpty,
                          )
                        else
                          ...List.generate(visibleItems.length, (index) {
                            final item = visibleItems[index];
                            return TimelineRecord(
                              item: item,
                              isLast: index == visibleItems.length - 1,
                              onTap: () => handleItemTap(item),
                              onEdit: item.manualEvent == null
                                  ? null
                                  : () => editManualEvent(item.manualEvent!),
                              onDelete: item.manualEvent == null
                                  ? null
                                  : () => deleteManualEvent(item.manualEvent!),
                            );
                          }),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

enum TimelinePeriod {
  all('Todo o período'),
  thirtyDays('Últimos 30 dias'),
  ninetyDays('Últimos 90 dias'),
  sixMonths('Últimos 6 meses'),
  oneYear('Último ano');

  const TimelinePeriod(this.label);

  final String label;

  DateTime? get threshold {
    final now = DateTime.now();

    return switch (this) {
      TimelinePeriod.all => null,
      TimelinePeriod.thirtyDays => now.subtract(const Duration(days: 30)),
      TimelinePeriod.ninetyDays => now.subtract(const Duration(days: 90)),
      TimelinePeriod.sixMonths => now.subtract(const Duration(days: 183)),
      TimelinePeriod.oneYear => now.subtract(const Duration(days: 365)),
    };
  }
}

class TimelineHeader extends StatelessWidget {
  const TimelineHeader({
    required this.animal,
    required this.farm,
    required this.group,
    required this.totalRecords,
    required this.alertCount,
    super.key,
  });

  final AnimalData animal;
  final FarmData farm;
  final HerdGroupData group;
  final int totalRecords;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
        child: Wrap(
          spacing: 20,
          runSpacing: 18,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.history_outlined,
                color: Colors.white,
                size: 36,
              ),
            ),
            SizedBox(
              width: 590,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Brinco ${animal.tag} • ${farm.name} • ${group.name}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Histórico técnico e operacional consolidado',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            TimelineHeaderCounter(
              value: totalRecords,
              label: 'registros',
              icon: Icons.format_list_bulleted_outlined,
            ),
            TimelineHeaderCounter(
              value: alertCount,
              label: 'alertas',
              icon: Icons.notification_important_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineHeaderCounter extends StatelessWidget {
  const TimelineHeaderCounter({
    required this.value,
    required this.label,
    required this.icon,
    super.key,
  });

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class TimelineSummary extends StatelessWidget {
  const TimelineSummary({required this.timelineItems, super.key});

  final List<TimelineItem> timelineItems;

  int count(String category) {
    return timelineItems.where((item) => item.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    final summaries = [
      (
        label: 'Pesagens',
        value: count('Pesagens'),
        icon: Icons.monitor_weight_outlined,
      ),
      (
        label: 'Sanidade',
        value: count('Sanidade'),
        icon: Icons.medical_services_outlined,
      ),
      (
        label: 'Reprodução',
        value: count('Reprodução'),
        icon: Icons.favorite_outline,
      ),
      (
        label: 'Fotos',
        value: count('Fotos'),
        icon: Icons.photo_library_outlined,
      ),
      (
        label: 'Documentos',
        value: count('Documentos') + count('Vencimentos'),
        icon: Icons.folder_outlined,
      ),
      (
        label: 'Enterprise',
        value: count('Enterprise'),
        icon: Icons.verified_user_outlined,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: summaries
          .map((summary) {
            return SizedBox(
              width: 175,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(
                          0xFF1B5E20,
                        ).withValues(alpha: 0.10),
                        child: Icon(
                          summary.icon,
                          color: const Color(0xFF1B5E20),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.value.toString(),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              summary.label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class TimelineSearchAndPeriod extends StatelessWidget {
  const TimelineSearchAndPeriod({
    required this.searchController,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    super.key,
  });

  final TextEditingController searchController;
  final TimelinePeriod selectedPeriod;
  final ValueChanged<TimelinePeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;

            final search = TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar na timeline',
                hintText: 'Evento, produto, documento ou descrição',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            );

            final period = DropdownButtonFormField<TimelinePeriod>(
              initialValue: selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Período',
                prefixIcon: Icon(Icons.date_range_outlined),
                border: OutlineInputBorder(),
              ),
              items: TimelinePeriod.values
                  .map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item.label),
                    );
                  })
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) onPeriodChanged(value);
              },
            );

            if (compact) {
              return Column(
                children: [search, const SizedBox(height: 12), period],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: search),
                const SizedBox(width: 12),
                Expanded(child: period),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TimelineFilters extends StatelessWidget {
  const TimelineFilters({
    required this.selectedCategory,
    required this.countCategory,
    required this.onSelected,
    super.key,
  });

  final String? selectedCategory;
  final int Function(String category) countCategory;
  final ValueChanged<String?> onSelected;

  static const categories = [
    'Eventos',
    'Pesagens',
    'Sanidade',
    'Reprodução',
    'Movimentações',
    'Fotos',
    'Documentos',
    'Vencimentos',
    'Enterprise',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todos'),
              selected: selectedCategory == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$category (${countCategory(category)})'),
                selected: selectedCategory == category,
                onSelected: (_) => onSelected(category),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class TimelineRecord extends StatelessWidget {
  const TimelineRecord({
    required this.item,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final TimelineItem item;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 21),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFD7E7D9)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (item.isAlert)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Chip(
                                        avatar: const Icon(
                                          Icons.warning_amber,
                                          size: 16,
                                        ),
                                        label: Text(item.alertLabel),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  TimelineTag(
                                    label: item.category,
                                    icon: item.icon,
                                    color: item.color,
                                  ),
                                  TimelineTag(
                                    label: item.subtitle,
                                    icon: Icons.label_outline,
                                    color: Colors.blueGrey,
                                  ),
                                  TimelineTag(
                                    label: item.date,
                                    icon: Icons.calendar_month_outlined,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              if (item.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (onEdit != null || onDelete != null)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') onEdit?.call();
                              if (value == 'delete') {
                                onDelete?.call();
                              }
                            },
                            itemBuilder: (context) => [
                              if (onEdit != null)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                              if (onDelete != null)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Excluir'),
                                ),
                            ],
                          )
                        else
                          const Icon(
                            Icons.open_in_new_outlined,
                            color: Color(0xFF1B5E20),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineTag extends StatelessWidget {
  const TimelineTag({
    required this.label,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyTimelineMessage extends StatelessWidget {
  const EmptyTimelineMessage({required this.hasFilter, super.key});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.history_toggle_off_outlined,
              size: 52,
              color: Color(0xFF1B5E20),
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter
                  ? 'Nenhum registro corresponde aos filtros'
                  : 'Nenhum registro na timeline',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              hasFilter
                  ? 'Altere categoria, período ou pesquisa.'
                  : 'Cadastre eventos, pesagens ou outros manejos.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineItem {
  const TimelineItem({
    required this.id,
    required this.category,
    required this.date,
    required this.dateTime,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.manualEvent,
    this.isAlert = false,
    this.alertLabel = '',
  });

  final String id;
  final String category;
  final String date;
  final DateTime dateTime;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final AnimalEventData? manualEvent;
  final bool isAlert;
  final String alertLabel;

  factory TimelineItem.fromManualEvent(AnimalEventData event) {
    return TimelineItem(
      id: 'event_${event.id}',
      category: 'Eventos',
      date: event.date,
      dateTime: parseTimelineDate(event.date),
      title: event.title,
      subtitle: event.type,
      description: event.description,
      icon: manualEventIcon(event.type),
      color: const Color(0xFF455A64),
      manualEvent: event,
    );
  }

  factory TimelineItem.fromWeight(AnimalWeightData weight) {
    return TimelineItem(
      id: 'weight_${weight.id}',
      category: 'Pesagens',
      date: weight.date,
      dateTime: parseTimelineDate(weight.date),
      title: '${formatTimelineWeight(weight.weight)} kg',
      subtitle: 'Pesagem',
      description: weight.notes.trim(),
      icon: Icons.monitor_weight_outlined,
      color: const Color(0xFF1565C0),
    );
  }

  factory TimelineItem.fromHealth(AnimalHealthData record) {
    final details = <String>[
      if (record.product.trim().isNotEmpty) 'Produto: ${record.product.trim()}',
      if (record.dose.trim().isNotEmpty) 'Dose: ${record.dose.trim()}',
      if (record.diagnosis.trim().isNotEmpty)
        'Diagnóstico: ${record.diagnosis.trim()}',
      if (record.responsible.trim().isNotEmpty)
        'Responsável: ${record.responsible.trim()}',
      if (record.nextDate.trim().isNotEmpty)
        'Próximo manejo: ${record.nextDate.trim()}',
      if (record.notes.trim().isNotEmpty) record.notes.trim(),
    ];

    return TimelineItem(
      id: 'health_${record.id}',
      category: 'Sanidade',
      date: record.date,
      dateTime: parseTimelineDate(record.date),
      title: record.product.trim().isEmpty ? record.type : record.product,
      subtitle: record.type,
      description: details.join('\n'),
      icon: healthTimelineIcon(record.type),
      color: const Color(0xFFC62828),
      isAlert: record.isQuarantine || record.isMortality,
      alertLabel: record.isMortality
          ? 'Mortalidade'
          : record.isQuarantine
          ? 'Quarentena'
          : '',
    );
  }

  factory TimelineItem.fromReproduction(AnimalReproductionData record) {
    final details = <String>[
      if (record.result.trim().isNotEmpty) 'Resultado: ${record.result.trim()}',
      if (record.bullOrSemen.trim().isNotEmpty)
        'Touro ou sêmen: ${record.bullOrSemen.trim()}',
      if (record.protocolName.trim().isNotEmpty)
        'Protocolo: ${record.protocolName.trim()}',
      if (record.expectedDate.trim().isNotEmpty)
        'Data prevista: ${record.expectedDate.trim()}',
      if (record.responsible.trim().isNotEmpty)
        'Responsável: ${record.responsible.trim()}',
      if (record.notes.trim().isNotEmpty) record.notes.trim(),
    ];

    return TimelineItem(
      id: 'reproduction_${record.id}',
      category: 'Reprodução',
      date: record.date,
      dateTime: parseTimelineDate(record.date),
      title: record.type,
      subtitle: record.result.trim().isEmpty
          ? record.reproductiveStatus
          : record.result,
      description: details.join('\n'),
      icon: reproductionTimelineIcon(record.type),
      color: const Color(0xFFAD1457),
    );
  }

  factory TimelineItem.fromMovement(AnimalMovementData record) {
    final route = '${record.origin} → ${record.destination}';

    final details = <String>[
      route,
      if (record.reason.trim().isNotEmpty) 'Motivo: ${record.reason.trim()}',
      if (record.responsible.trim().isNotEmpty)
        'Responsável: ${record.responsible.trim()}',
      if (record.notes.trim().isNotEmpty) record.notes.trim(),
    ];

    return TimelineItem(
      id: 'movement_${record.id}',
      category: 'Movimentações',
      date: record.date,
      dateTime: parseTimelineDate(record.date),
      title: record.type,
      subtitle: route,
      description: details.join('\n'),
      icon: Icons.swap_horiz_outlined,
      color: const Color(0xFFEF6C00),
    );
  }

  factory TimelineItem.fromPhoto(AnimalPhotoData photo) {
    final details = <String>[
      if (photo.reference.trim().isNotEmpty)
        'Arquivo: ${photo.reference.trim()}',
      if (photo.notes.trim().isNotEmpty) photo.notes.trim(),
    ];

    return TimelineItem(
      id: 'photo_${photo.id}',
      category: 'Fotos',
      date: photo.date,
      dateTime: parseTimelineDate(photo.date),
      title: photo.title.trim().isEmpty ? 'Registro fotográfico' : photo.title,
      subtitle: photo.isPrimary ? 'Foto principal' : 'Registro fotográfico',
      description: details.join('\n'),
      icon: photo.isPrimary ? Icons.star_outline : Icons.photo_outlined,
      color: const Color(0xFF00838F),
    );
  }

  factory TimelineItem.fromDocument(AnimalDocumentData document) {
    final details = <String>[
      'Categoria: ${document.category}',
      if (document.issuer.trim().isNotEmpty)
        'Emissor: ${document.issuer.trim()}',
      if (document.reference.trim().isNotEmpty)
        'Anexo: ${document.reference.trim()}',
      if (document.notes.trim().isNotEmpty) document.notes.trim(),
    ];

    return TimelineItem(
      id: 'document_${document.id}',
      category: 'Documentos',
      date: document.date,
      dateTime: parseTimelineDate(document.date),
      title: document.title,
      subtitle: document.type,
      description: details.join('\n'),
      icon: Icons.folder_outlined,
      color: const Color(0xFF6A1B9A),
      isAlert: document.isExpired,
      alertLabel: document.isExpired ? 'Vencido' : '',
    );
  }

  factory TimelineItem.fromDocumentExpiration(AnimalDocumentData document) {
    return TimelineItem(
      id: 'expiration_${document.id}',
      category: 'Vencimentos',
      date: document.expirationDate,
      dateTime: parseTimelineDate(document.expirationDate),
      title: 'Vencimento: ${document.title}',
      subtitle: document.expirationStatus,
      description: '${document.type} • ${document.category}',
      icon: document.isExpired
          ? Icons.event_busy_outlined
          : Icons.event_available_outlined,
      color: document.isExpired
          ? const Color(0xFFC62828)
          : document.expiresSoon
          ? const Color(0xFFEF6C00)
          : const Color(0xFF2E7D32),
      isAlert: document.isExpired || document.expiresSoon,
      alertLabel: document.isExpired
          ? 'Vencido'
          : document.expiresSoon
          ? 'Vence em breve'
          : '',
    );
  }

  factory TimelineItem.fromEnterprise(AnimalEnterpriseTimelineData record) {
    final occurredAt = record.occurredAt.toLocal();

    final icon = switch (record.action) {
      'create' => Icons.add_circle_outline,
      'update' => Icons.edit_note_outlined,
      'delete' => Icons.delete_outline,
      _ => Icons.verified_user_outlined,
    };

    final color = switch (record.action) {
      'create' => const Color(0xFF2E7D32),
      'update' => const Color(0xFF1565C0),
      'delete' => const Color(0xFFC62828),
      _ => const Color(0xFF455A64),
    };

    return TimelineItem(
      id: 'enterprise_${record.id}',
      category: 'Enterprise',
      date: formatTimelineDate(occurredAt),
      dateTime: occurredAt,
      title: record.title,
      subtitle: record.category,
      description: record.changesDescription,
      icon: icon,
      color: color,
    );
  }
}

DateTime parseTimelineDate(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return DateTime(1900);

  final iso = DateTime.tryParse(normalized);
  if (iso != null) return iso;

  final parts = normalized.split('/');
  if (parts.length != 3) return DateTime(1900);

  final day = int.tryParse(parts[0]) ?? 1;
  final month = int.tryParse(parts[1]) ?? 1;
  final year = int.tryParse(parts[2]) ?? 1900;

  return DateTime(year, month, day);
}

String formatTimelineDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String formatTimelineWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toInt().toString();
  }

  return weight.toStringAsFixed(1).replaceAll('.', ',');
}

IconData manualEventIcon(String type) {
  switch (type) {
    case 'Nascimento':
      return Icons.child_friendly_outlined;
    case 'Pesagem':
      return Icons.monitor_weight_outlined;
    case 'Vacinação':
      return Icons.vaccines_outlined;
    case 'Tratamento':
      return Icons.medical_services_outlined;
    case 'Vermifugação':
      return Icons.medication_outlined;
    case 'Mudança de lote':
      return Icons.swap_horiz_outlined;
    case 'IATF':
      return Icons.favorite_outline;
    case 'Diagnóstico':
      return Icons.monitor_heart_outlined;
    case 'Parto':
      return AtlasLivestockIcons.cow;
    default:
      return Icons.event_note_outlined;
  }
}

IconData healthTimelineIcon(String type) {
  switch (type) {
    case 'Vacinação':
      return Icons.vaccines_outlined;
    case 'Vermifugação':
      return Icons.medication_outlined;
    case 'Tratamento':
      return Icons.medical_services_outlined;
    case 'Exame':
      return Icons.biotech_outlined;
    case 'Cirurgia':
      return Icons.healing_outlined;
    case 'Ocorrência clínica':
      return Icons.monitor_heart_outlined;
    default:
      return Icons.health_and_safety_outlined;
  }
}

IconData reproductionTimelineIcon(String type) {
  switch (type) {
    case 'Cio':
      return Icons.favorite_border;
    case 'Inseminação artificial':
      return Icons.science_outlined;
    case 'IATF':
      return Icons.favorite_outline;
    case 'Diagnóstico de gestação':
      return Icons.monitor_heart_outlined;
    case 'Parto':
      return AtlasLivestockIcons.cow;
    default:
      return Icons.replay_outlined;
  }
}
