import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventLogEntry {
  const AtlasEventLogEntry({
    required this.id,
    required this.eventId,
    required this.type,
    required this.sourceModule,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.recordedAt,
    required this.priority,
    required this.farmId,
    required this.farmName,
    required this.entityId,
    required this.entityType,
    required this.payload,
    required this.tags,
  });

  final String id;
  final String eventId;
  final AtlasEventType type;
  final String sourceModule;
  final String title;
  final String description;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final AtlasEventPriority priority;
  final String? farmId;
  final String? farmName;
  final String? entityId;
  final String? entityType;
  final Map<String, dynamic> payload;
  final List<String> tags;

  factory AtlasEventLogEntry.fromEvent(AtlasEvent event) {
    final now = DateTime.now();

    return AtlasEventLogEntry(
      id: 'event_log_${now.microsecondsSinceEpoch}',
      eventId: event.id,
      type: event.type,
      sourceModule: event.sourceModule,
      title: event.title,
      description: event.description,
      occurredAt: event.occurredAt,
      recordedAt: now,
      priority: event.priority,
      farmId: event.farmId,
      farmName: event.farmName,
      entityId: event.entityId,
      entityType: event.entityType,
      payload: Map<String, dynamic>.from(event.payload),
      tags: List<String>.from(event.tags),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'eventId': eventId,
      'type': type.name,
      'sourceModule': sourceModule,
      'title': title,
      'description': description,
      'occurredAt': occurredAt.toIso8601String(),
      'recordedAt': recordedAt.toIso8601String(),
      'priority': priority.name,
      'farmId': farmId,
      'farmName': farmName,
      'entityId': entityId,
      'entityType': entityType,
      'payload': payload,
      'tags': tags,
    };
  }

  factory AtlasEventLogEntry.fromJson(Map<String, dynamic> json) {
    return AtlasEventLogEntry(
      id: json['id'] as String? ?? 'event_log_unknown',
      eventId: json['eventId'] as String? ?? 'event_unknown',
      type: AtlasEventType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => AtlasEventType.systemUpdated,
      ),
      sourceModule: json['sourceModule'] as String? ?? 'unknown',
      title: json['title'] as String? ?? 'Evento',
      description: json['description'] as String? ?? '',
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.now(),
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
      priority: AtlasEventPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => AtlasEventPriority.normal,
      ),
      farmId: json['farmId'] as String?,
      farmName: json['farmName'] as String?,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ?? const <String, dynamic>{},
      ),
      tags: List<String>.from(json['tags'] as List? ?? const <String>[]),
    );
  }
}
