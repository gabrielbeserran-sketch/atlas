import 'package:projeto_atlas/core/event_center/atlas_event_log_entry.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventLogFilter {
  const AtlasEventLogFilter({
    this.search,
    this.types,
    this.priorities,
    this.sourceModule,
    this.farmName,
    this.startDate,
    this.endDate,
  });

  final String? search;
  final Set<AtlasEventType>? types;
  final Set<AtlasEventPriority>? priorities;
  final String? sourceModule;
  final String? farmName;
  final DateTime? startDate;
  final DateTime? endDate;

  bool matches(AtlasEventLogEntry item) {
    final normalizedSearch = search?.trim().toLowerCase();

    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      final haystack = <String>[
        item.title,
        item.description,
        item.sourceModule,
        item.farmName ?? '',
        item.entityType ?? '',
        ...item.tags,
      ].join(' ').toLowerCase();

      if (!haystack.contains(normalizedSearch)) {
        return false;
      }
    }

    if (types != null && types!.isNotEmpty && !types!.contains(item.type)) {
      return false;
    }

    if (priorities != null &&
        priorities!.isNotEmpty &&
        !priorities!.contains(item.priority)) {
      return false;
    }

    if (sourceModule != null &&
        sourceModule!.isNotEmpty &&
        item.sourceModule != sourceModule) {
      return false;
    }

    if (farmName != null && farmName!.isNotEmpty && item.farmName != farmName) {
      return false;
    }

    if (startDate != null && item.occurredAt.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && item.occurredAt.isAfter(endDate!)) {
      return false;
    }

    return true;
  }
}
