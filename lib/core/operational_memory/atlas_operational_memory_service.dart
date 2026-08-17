import 'package:projeto_atlas/core/event_center/atlas_event_log_filter.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_service.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';

class AtlasOperationalMemoryService {
  AtlasOperationalMemoryService._();

  static final AtlasOperationalMemoryService instance =
      AtlasOperationalMemoryService._();

  Future<void> initialize() async {
    await AtlasEventLogService.instance.start();
  }

  List<AtlasOperationalMemoryEntry> query({
    String? search,
    String? farmName,
    String? sourceModule,
    String? entityType,
    AtlasEventPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    final entries = AtlasEventLogService.instance.query(
      filter: AtlasEventLogFilter(
        search: search,
        farmName: farmName,
        sourceModule: sourceModule,
        priorities: priority == null ? null : <AtlasEventPriority>{priority},
        startDate: startDate,
        endDate: endDate,
      ),
    );

    Iterable<AtlasOperationalMemoryEntry> result = entries.map(
      AtlasOperationalMemoryEntry.fromLogEntry,
    );

    if (entityType != null && entityType.trim().isNotEmpty) {
      result = result.where((item) => item.entityType == entityType);
    }

    if (limit != null && limit >= 0) {
      result = result.take(limit);
    }

    return result.toList(growable: false);
  }

  List<String> availableFarms() {
    final values =
        AtlasEventLogService.instance.entries
            .map((item) => item.farmName)
            .whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return values;
  }

  List<String> availableModules() {
    final values =
        AtlasEventLogService.instance.entries
            .map((item) => item.sourceModule)
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return values;
  }

  List<String> availableEntityTypes() {
    final values =
        AtlasEventLogService.instance.entries
            .map((item) => item.entityType)
            .whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return values;
  }
}
