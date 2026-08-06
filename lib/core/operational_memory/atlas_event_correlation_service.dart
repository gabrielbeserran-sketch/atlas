import 'dart:math' as math;

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_event_correlation.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';

class AtlasEventCorrelationService {
  const AtlasEventCorrelationService();

  List<AtlasEventCorrelation> build({
    required List<AtlasOperationalMemoryEntry> entries,
    Duration maximumDistance = const Duration(hours: 72),
    int maxItems = 30,
  }) {
    if (entries.length < 2 || maxItems <= 0) {
      return const <AtlasEventCorrelation>[];
    }

    final ordered = List<AtlasOperationalMemoryEntry>.from(entries)
      ..sort((first, second) {
        return first.occurredAt.compareTo(second.occurredAt);
      });

    final correlations = <AtlasEventCorrelation>[];
    final usedKeys = <String>{};

    for (var firstIndex = 0;
        firstIndex < ordered.length - 1;
        firstIndex++) {
      final first = ordered[firstIndex];

      for (var secondIndex = firstIndex + 1;
          secondIndex < ordered.length;
          secondIndex++) {
        final second = ordered[secondIndex];
        final distance = second.occurredAt.difference(first.occurredAt);

        if (distance > maximumDistance) {
          break;
        }

        if (!_canCorrelate(first, second)) {
          continue;
        }

        final key = _correlationKey(first, second);

        if (!usedKeys.add(key)) {
          continue;
        }

        correlations.add(
          _createCorrelation(
            first: first,
            second: second,
            distance: distance,
            maximumDistance: maximumDistance,
          ),
        );
      }
    }

    correlations.sort((first, second) {
      final confidenceComparison = second.confidencePercent.compareTo(
        first.confidencePercent,
      );

      if (confidenceComparison != 0) {
        return confidenceComparison;
      }

      return second.secondOccurredAt.compareTo(first.secondOccurredAt);
    });

    return correlations.take(maxItems).toList(growable: false);
  }

  bool _canCorrelate(
    AtlasOperationalMemoryEntry first,
    AtlasOperationalMemoryEntry second,
  ) {
    if (first.eventId == second.eventId) {
      return false;
    }

    if (first.sourceModule == second.sourceModule) {
      return false;
    }

    final firstFarm = first.farmName?.trim();
    final secondFarm = second.farmName?.trim();

    if (firstFarm != null &&
        firstFarm.isNotEmpty &&
        secondFarm != null &&
        secondFarm.isNotEmpty &&
        firstFarm != secondFarm) {
      return false;
    }

    final sameEntity = first.entityId != null &&
        second.entityId != null &&
        first.entityId == second.entityId;

    final sharedTag = first.tags.any(second.tags.contains);
    final relevantPriority =
        first.priority == AtlasEventPriority.high ||
            first.priority == AtlasEventPriority.critical ||
            second.priority == AtlasEventPriority.high ||
            second.priority == AtlasEventPriority.critical;

    return sameEntity || sharedTag || relevantPriority;
  }

  String _correlationKey(
    AtlasOperationalMemoryEntry first,
    AtlasOperationalMemoryEntry second,
  ) {
    final modules = <String>[first.sourceModule, second.sourceModule]..sort();
    final entity = first.entityId ?? second.entityId ?? 'sem_entidade';
    final farm = first.farmName ?? second.farmName ?? 'operacao';

    return '${modules.join('|')}|$farm|$entity|${first.eventId}|${second.eventId}';
  }

  AtlasEventCorrelation _createCorrelation({
    required AtlasOperationalMemoryEntry first,
    required AtlasOperationalMemoryEntry second,
    required Duration distance,
    required Duration maximumDistance,
  }) {
    final sameEntity = first.entityId != null &&
        second.entityId != null &&
        first.entityId == second.entityId;
    final sharedTags = first.tags.where(second.tags.contains).length;
    final criticalWeight = _priorityWeight(first.priority) +
        _priorityWeight(second.priority);
    final proximity = 1 -
        (distance.inMinutes /
                math.max(1, maximumDistance.inMinutes))
            .clamp(0.0, 1.0);

    final confidence = (
      35 +
      proximity * 30 +
      (sameEntity ? 20 : 0) +
      math.min(10, sharedTags * 5) +
      criticalWeight * 2.5
    ).clamp(0.0, 99.0).toDouble();

    final priority = _highestPriority(first.priority, second.priority);
    final farmName = first.farmName ?? second.farmName ?? 'Operação';

    return AtlasEventCorrelation(
      id: 'correlation_${first.eventId}_${second.eventId}',
      title: '${first.sourceModule} relacionado a ${second.sourceModule}',
      description:
          '${first.title} ocorreu antes de ${second.title}, com intervalo de '
          '${distance.inHours} hora(s). O Atlas identificou proximidade temporal '
          'e sinais operacionais em comum.',
      farmName: farmName,
      firstModule: first.sourceModule,
      secondModule: second.sourceModule,
      firstEventId: first.eventId,
      secondEventId: second.eventId,
      firstOccurredAt: first.occurredAt,
      secondOccurredAt: second.occurredAt,
      priority: priority,
      confidencePercent: confidence,
      hoursBetweenEvents: distance.inHours,
    );
  }

  int _priorityWeight(AtlasEventPriority priority) {
    switch (priority) {
      case AtlasEventPriority.low:
        return 0;
      case AtlasEventPriority.normal:
        return 1;
      case AtlasEventPriority.high:
        return 2;
      case AtlasEventPriority.critical:
        return 3;
    }
  }

  AtlasEventPriority _highestPriority(
    AtlasEventPriority first,
    AtlasEventPriority second,
  ) {
    return _priorityWeight(first) >= _priorityWeight(second)
        ? first
        : second;
  }
}
