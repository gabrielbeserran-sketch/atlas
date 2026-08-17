import 'dart:math' as math;

import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_insight.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_event_correlation.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_event_correlation_service.dart';
import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';

class AtlasOperationalInsightService {
  const AtlasOperationalInsightService({
    AtlasEventCorrelationService correlationService =
        const AtlasEventCorrelationService(),
  }) : _correlationService = correlationService;

  final AtlasEventCorrelationService _correlationService;

  List<AtlasOperationalInsight> build({
    required List<AtlasOperationalMemoryEntry> entries,
    int maxItems = 20,
  }) {
    if (entries.isEmpty || maxItems <= 0) {
      return const <AtlasOperationalInsight>[];
    }

    final insights = <AtlasOperationalInsight>[
      ..._criticalEventInsights(entries),
      ..._repetitionInsights(entries),
      ..._correlationInsights(entries),
    ];

    final unique = <String, AtlasOperationalInsight>{};

    for (final insight in insights) {
      final current = unique[insight.id];

      if (current == null ||
          insight.confidencePercent > current.confidencePercent) {
        unique[insight.id] = insight;
      }
    }

    final ordered = unique.values.toList()
      ..sort((first, second) {
        final priorityComparison = _priorityWeight(
          second.priority,
        ).compareTo(_priorityWeight(first.priority));

        if (priorityComparison != 0) {
          return priorityComparison;
        }

        return second.confidencePercent.compareTo(first.confidencePercent);
      });

    return ordered.take(maxItems).toList(growable: false);
  }

  List<AtlasOperationalInsight> _criticalEventInsights(
    List<AtlasOperationalMemoryEntry> entries,
  ) {
    return entries
        .where(
          (entry) =>
              entry.priority == AtlasEventPriority.high ||
              entry.priority == AtlasEventPriority.critical,
        )
        .map((entry) {
          final critical = entry.priority == AtlasEventPriority.critical;

          return AtlasOperationalInsight(
            id: 'insight_event_${entry.eventId}',
            title: critical
                ? 'Ocorrência crítica exige decisão'
                : 'Ocorrência relevante requer acompanhamento',
            description: '${entry.title}: ${entry.description}',
            recommendation:
                'Confirme o responsável, defina um prazo e registre o resultado no Atlas.',
            priority: critical
                ? AtlasCanonicalPriority.critical
                : AtlasCanonicalPriority.high,
            confidencePercent: critical ? 98 : 90,
            farmName: entry.farmName,
            modules: <String>{entry.sourceModule},
            relatedEventIds: <String>[entry.eventId],
            generatedAt: DateTime.now(),
          );
        })
        .toList(growable: false);
  }

  List<AtlasOperationalInsight> _repetitionInsights(
    List<AtlasOperationalMemoryEntry> entries,
  ) {
    final groups = <String, List<AtlasOperationalMemoryEntry>>{};

    for (final entry in entries) {
      final key =
          '${entry.farmName ?? 'operacao'}|${entry.sourceModule}|${entry.title.toLowerCase()}';
      groups.putIfAbsent(key, () => <AtlasOperationalMemoryEntry>[]).add(entry);
    }

    final result = <AtlasOperationalInsight>[];

    for (final group in groups.values) {
      if (group.length < 3) {
        continue;
      }

      group.sort(
        (first, second) => second.occurredAt.compareTo(first.occurredAt),
      );

      final newest = group.first;
      final oldest = group.last;
      final periodDays = math.max(
        1,
        newest.occurredAt.difference(oldest.occurredAt).inDays,
      );

      result.add(
        AtlasOperationalInsight(
          id: 'insight_repetition_${newest.sourceModule}_${newest.title.hashCode}',
          title: 'Padrão repetido detectado',
          description:
              '"${newest.title}" apareceu ${group.length} vezes em $periodDays dia(s).',
          recommendation:
              'Investigue a causa recorrente e crie uma ação preventiva.',
          priority: group.length >= 5
              ? AtlasCanonicalPriority.high
              : AtlasCanonicalPriority.medium,
          confidencePercent: (65 + math.min(25, group.length * 4)).toDouble(),
          farmName: newest.farmName,
          modules: <String>{newest.sourceModule},
          relatedEventIds: group
              .map((entry) => entry.eventId)
              .toList(growable: false),
          generatedAt: DateTime.now(),
        ),
      );
    }

    return result;
  }

  List<AtlasOperationalInsight> _correlationInsights(
    List<AtlasOperationalMemoryEntry> entries,
  ) {
    final correlations = _correlationService.build(
      entries: entries,
      maxItems: 15,
    );

    return correlations.map(_insightFromCorrelation).toList(growable: false);
  }

  AtlasOperationalInsight _insightFromCorrelation(
    AtlasEventCorrelation correlation,
  ) {
    return AtlasOperationalInsight(
      id: 'insight_${correlation.id}',
      title: 'Relação operacional entre módulos',
      description: correlation.description,
      recommendation:
          'Compare os registros dos dois módulos antes de concluir causalidade e defina uma ação de verificação.',
      priority: _canonicalPriority(correlation.priority),
      confidencePercent: correlation.confidencePercent,
      farmName: correlation.farmName,
      modules: <String>{correlation.firstModule, correlation.secondModule},
      relatedEventIds: <String>[
        correlation.firstEventId,
        correlation.secondEventId,
      ],
      generatedAt: DateTime.now(),
    );
  }

  AtlasCanonicalPriority _canonicalPriority(AtlasEventPriority priority) {
    switch (priority) {
      case AtlasEventPriority.low:
        return AtlasCanonicalPriority.low;
      case AtlasEventPriority.normal:
        return AtlasCanonicalPriority.medium;
      case AtlasEventPriority.high:
        return AtlasCanonicalPriority.high;
      case AtlasEventPriority.critical:
        return AtlasCanonicalPriority.critical;
    }
  }

  int _priorityWeight(AtlasCanonicalPriority priority) {
    switch (priority) {
      case AtlasCanonicalPriority.low:
        return 1;
      case AtlasCanonicalPriority.medium:
        return 2;
      case AtlasCanonicalPriority.high:
        return 3;
      case AtlasCanonicalPriority.critical:
        return 4;
    }
  }
}
