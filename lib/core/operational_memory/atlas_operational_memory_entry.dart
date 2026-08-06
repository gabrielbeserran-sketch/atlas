import 'package:projeto_atlas/core/event_center/atlas_event_log_entry.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasOperationalMemoryEntry {
  const AtlasOperationalMemoryEntry({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.sourceModule,
    required this.priority,
    required this.farmName,
    required this.entityId,
    required this.entityType,
    required this.tags,
    required this.payload,
  });

  final String id;
  final String eventId;
  final String title;
  final String description;
  final DateTime occurredAt;
  final String sourceModule;
  final AtlasEventPriority priority;
  final String? farmName;
  final String? entityId;
  final String? entityType;
  final List<String> tags;
  final Map<String, dynamic> payload;

  factory AtlasOperationalMemoryEntry.fromLogEntry(
    AtlasEventLogEntry entry,
  ) {
    return AtlasOperationalMemoryEntry(
      id: 'memory_${entry.id}',
      eventId: entry.eventId,
      title: entry.title,
      description: entry.description,
      occurredAt: entry.occurredAt,
      sourceModule: entry.sourceModule,
      priority: entry.priority,
      farmName: entry.farmName,
      entityId: entry.entityId,
      entityType: entry.entityType,
      tags: List<String>.unmodifiable(entry.tags),
      payload: Map<String, dynamic>.unmodifiable(entry.payload),
    );
  }

  bool containsText(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return true;
    }

    final content = <String>[
      title,
      description,
      sourceModule,
      farmName ?? '',
      entityId ?? '',
      entityType ?? '',
      ...tags,
    ].join(' ').toLowerCase();

    return content.contains(normalized);
  }
}
