import 'dart:math' as math;

import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';

class AtlasOperationalPriorityService {
  const AtlasOperationalPriorityService();

  List<AtlasOperationalPriority> build({
    required List<AtlasOperationalMemoryEntry> entries,
    DateTime? referenceDate,
    int maxItems = 30,
  }) {
    if (entries.isEmpty || maxItems <= 0) {
      return const <AtlasOperationalPriority>[];
    }

    final now = referenceDate ?? DateTime.now();

    final priorities =
        entries.map((entry) {
          final score = _score(entry, now);
          final canonicalPriority = _priorityFromScore(score);

          return AtlasOperationalPriority(
            id: 'priority_${entry.eventId}',
            title: entry.title,
            description: entry.description,
            priority: canonicalPriority,
            score: score,
            recommendedAction: _recommendedAction(entry, canonicalPriority),
            sourceModule: entry.sourceModule,
            farmName: entry.farmName,
            entityId: entry.entityId,
            occurredAt: entry.occurredAt,
            event: entry,
          );
        }).toList()..sort((first, second) {
          final scoreComparison = second.score.compareTo(first.score);

          if (scoreComparison != 0) {
            return scoreComparison;
          }

          return second.occurredAt.compareTo(first.occurredAt);
        });

    return priorities.take(maxItems).toList(growable: false);
  }

  double _score(AtlasOperationalMemoryEntry entry, DateTime now) {
    var score = _priorityBase(entry.priority);

    final age = now.difference(entry.occurredAt);
    final ageHours = math.max(0, age.inHours);

    if (ageHours <= 24) {
      score += 15;
    } else if (ageHours <= 72) {
      score += 8;
    } else if (ageHours <= 168) {
      score += 3;
    }

    final content = <String>[
      entry.title,
      entry.description,
      entry.sourceModule,
      entry.entityType ?? '',
      ...entry.tags,
    ].join(' ').toLowerCase();

    if (_containsAny(content, <String>[
      'crítico',
      'critico',
      'urgente',
      'doença',
      'doenca',
      'morte',
      'mortalidade',
      'esgotado',
      'atrasado',
      'vencido',
    ])) {
      score += 18;
    }

    if (_containsAny(content, <String>[
      'baixo',
      'queda',
      'risco',
      'alerta',
      'limite',
      'tratamento',
      'vacina',
    ])) {
      score += 9;
    }

    if (entry.entityId != null && entry.entityId!.trim().isNotEmpty) {
      score += 3;
    }

    return score.clamp(0, 100).toDouble();
  }

  double _priorityBase(AtlasEventPriority priority) {
    switch (priority) {
      case AtlasEventPriority.low:
        return 20;
      case AtlasEventPriority.normal:
        return 40;
      case AtlasEventPriority.high:
        return 70;
      case AtlasEventPriority.critical:
        return 90;
    }
  }

  AtlasCanonicalPriority _priorityFromScore(double score) {
    if (score >= 85) {
      return AtlasCanonicalPriority.critical;
    }

    if (score >= 65) {
      return AtlasCanonicalPriority.high;
    }

    if (score >= 40) {
      return AtlasCanonicalPriority.medium;
    }

    return AtlasCanonicalPriority.low;
  }

  String _recommendedAction(
    AtlasOperationalMemoryEntry entry,
    AtlasCanonicalPriority priority,
  ) {
    final prefix = switch (priority) {
      AtlasCanonicalPriority.critical => 'Atue imediatamente',
      AtlasCanonicalPriority.high => 'Priorize ainda hoje',
      AtlasCanonicalPriority.medium => 'Inclua no plano da semana',
      AtlasCanonicalPriority.low => 'Acompanhe na rotina',
    };

    return '$prefix: revise "${entry.title}" e registre a decisão tomada.';
  }

  bool _containsAny(String content, List<String> values) {
    return values.any(content.contains);
  }
}
