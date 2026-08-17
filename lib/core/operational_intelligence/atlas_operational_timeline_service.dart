import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_timeline.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_service.dart';

class AtlasOperationalTimelineService {
  AtlasOperationalTimelineService({
    AtlasOperationalMemoryService? memoryService,
  }) : _memoryService = memoryService ?? AtlasOperationalMemoryService.instance;

  final AtlasOperationalMemoryService _memoryService;

  Future<AtlasOperationalTimeline> build({
    String? farmName,
    String? search,
    String? sourceModule,
    String? entityType,
    AtlasEventPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 300,
  }) async {
    await _memoryService.initialize();

    final entries = _memoryService.query(
      farmName: farmName,
      search: search,
      sourceModule: sourceModule,
      entityType: entityType,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    final ordered = List<AtlasOperationalMemoryEntry>.from(entries)
      ..sort((first, second) => second.occurredAt.compareTo(first.occurredAt));

    final modules = ordered
        .map((entry) => entry.sourceModule)
        .where((module) => module.trim().isNotEmpty)
        .toSet();

    DateTime? firstOccurredAt;
    DateTime? lastOccurredAt;

    if (ordered.isNotEmpty) {
      firstOccurredAt = ordered.last.occurredAt;
      lastOccurredAt = ordered.first.occurredAt;
    }

    return AtlasOperationalTimeline(
      generatedAt: DateTime.now(),
      farmName: farmName,
      entries: List<AtlasOperationalMemoryEntry>.unmodifiable(ordered),
      totalEvents: ordered.length,
      modules: Set<String>.unmodifiable(modules),
      firstOccurredAt: firstOccurredAt,
      lastOccurredAt: lastOccurredAt,
    );
  }
}
