import 'dart:math' as math;

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_metrics.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';

class AtlasOperationalMetricsService {
  const AtlasOperationalMetricsService();

  AtlasOperationalMetrics build({
    required List<AtlasOperationalMemoryEntry> entries,
    String? farmName,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    final eventsByModule = <String, int>{};
    final eventsByEntityType = <String, int>{};
    final numericBuckets = <String, List<double>>{};

    var eventsLast24Hours = 0;
    var eventsLast7Days = 0;
    var criticalEvents = 0;
    var highPriorityEvents = 0;

    for (final entry in entries) {
      eventsByModule.update(
        entry.sourceModule,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final entityType = entry.entityType?.trim();

      if (entityType != null && entityType.isNotEmpty) {
        eventsByEntityType.update(
          entityType,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      if (!entry.occurredAt.isBefore(last24Hours)) {
        eventsLast24Hours += 1;
      }

      if (!entry.occurredAt.isBefore(last7Days)) {
        eventsLast7Days += 1;
      }

      if (entry.priority == AtlasEventPriority.critical) {
        criticalEvents += 1;
      }

      if (entry.priority == AtlasEventPriority.high) {
        highPriorityEvents += 1;
      }

      _collectNumericPayload(entry.payload, numericBuckets);
    }

    final numericIndicators = <String, double>{};

    for (final bucket in numericBuckets.entries) {
      if (bucket.value.isEmpty) {
        continue;
      }

      final sum = bucket.value.fold<double>(
        0,
        (total, value) => total + value,
      );

      numericIndicators[bucket.key] =
          sum / math.max(1, bucket.value.length);
    }

    return AtlasOperationalMetrics(
      generatedAt: now,
      farmName: farmName,
      totalEvents: entries.length,
      eventsLast24Hours: eventsLast24Hours,
      eventsLast7Days: eventsLast7Days,
      criticalEvents: criticalEvents,
      highPriorityEvents: highPriorityEvents,
      activeModules: eventsByModule.length,
      eventsByModule: Map<String, int>.unmodifiable(eventsByModule),
      eventsByEntityType:
          Map<String, int>.unmodifiable(eventsByEntityType),
      numericIndicators:
          Map<String, double>.unmodifiable(numericIndicators),
    );
  }

  void _collectNumericPayload(
    Map<String, dynamic> payload,
    Map<String, List<double>> buckets,
  ) {
    for (final entry in payload.entries) {
      final value = entry.value;

      if (value is num) {
        buckets
            .putIfAbsent(entry.key, () => <double>[])
            .add(value.toDouble());
      }
    }
  }
}
