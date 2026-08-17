import 'package:projeto_atlas/core/event_center/atlas_event_analytics_data.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_entry.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventAnalyticsService {
  const AtlasEventAnalyticsService();

  AtlasEventAnalyticsData build({
    required List<AtlasEventLogEntry> entries,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final last7DaysStart = currentTime.subtract(const Duration(days: 7));

    final last30DaysStart = currentTime.subtract(const Duration(days: 30));

    final last7DaysEvents = entries.where((item) {
      return !item.occurredAt.isBefore(last7DaysStart);
    }).length;

    final last30DaysEvents = entries.where((item) {
      return !item.occurredAt.isBefore(last30DaysStart);
    }).length;

    final priorityDistribution = <AtlasEventPriority, int>{
      for (final priority in AtlasEventPriority.values)
        priority: entries.where((item) {
          return item.priority == priority;
        }).length,
    };

    return AtlasEventAnalyticsData(
      generatedAt: currentTime,
      totalEvents: entries.length,
      last7DaysEvents: last7DaysEvents,
      last30DaysEvents: last30DaysEvents,
      criticalEvents: priorityDistribution[AtlasEventPriority.critical] ?? 0,
      highPriorityEvents: priorityDistribution[AtlasEventPriority.high] ?? 0,
      priorityDistribution: priorityDistribution,
      moduleDistribution: _ranking(
        values: entries.map((item) => item.sourceModule),
        total: entries.length,
      ),
      farmDistribution: _ranking(
        values: entries.map((item) => item.farmName ?? 'Operação'),
        total: entries.length,
      ),
      typeDistribution: _typeRanking(entries),
      dailyTrend: _dailyTrend(entries: entries, now: currentTime),
      recurringCriticalEvents: _criticalPatterns(entries),
      recommendations: _recommendations(
        entries: entries,
        priorityDistribution: priorityDistribution,
      ),
    );
  }

  List<AtlasEventAnalyticsRankingItem> _ranking({
    required Iterable<String> values,
    required int total,
  }) {
    final counts = <String, int>{};

    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    return List.generate(sorted.length, (index) {
      final item = sorted[index];

      return AtlasEventAnalyticsRankingItem(
        position: index + 1,
        label: item.key,
        count: item.value,
        percent: total == 0 ? 0 : item.value / total * 100,
      );
    });
  }

  List<AtlasEventAnalyticsTypeItem> _typeRanking(
    List<AtlasEventLogEntry> entries,
  ) {
    final counts = <AtlasEventType, int>{};

    for (final item in entries) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    return List.generate(sorted.length, (index) {
      final item = sorted[index];

      return AtlasEventAnalyticsTypeItem(
        position: index + 1,
        type: item.key,
        count: item.value,
        percent: entries.isEmpty ? 0 : item.value / entries.length * 100,
      );
    });
  }

  List<AtlasEventAnalyticsDailyPoint> _dailyTrend({
    required List<AtlasEventLogEntry> entries,
    required DateTime now,
  }) {
    final result = <AtlasEventAnalyticsDailyPoint>[];

    for (var day = 29; day >= 0; day--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: day));

      final nextDate = date.add(const Duration(days: 1));

      final dayEntries = entries.where((item) {
        return !item.occurredAt.isBefore(date) &&
            item.occurredAt.isBefore(nextDate);
      }).toList();

      result.add(
        AtlasEventAnalyticsDailyPoint(
          date: date,
          total: dayEntries.length,
          high: dayEntries.where((item) {
            return item.priority == AtlasEventPriority.high;
          }).length,
          critical: dayEntries.where((item) {
            return item.priority == AtlasEventPriority.critical;
          }).length,
        ),
      );
    }

    return result;
  }

  List<AtlasEventAnalyticsCriticalPattern> _criticalPatterns(
    List<AtlasEventLogEntry> entries,
  ) {
    final critical = entries.where((item) {
      return item.priority == AtlasEventPriority.critical ||
          item.priority == AtlasEventPriority.high;
    }).toList();

    final grouped = <String, List<AtlasEventLogEntry>>{};

    for (final item in critical) {
      final key =
          '${item.type.name}|'
          '${item.sourceModule}|'
          '${item.farmName ?? 'Operação'}';

      grouped.putIfAbsent(key, () => <AtlasEventLogEntry>[]).add(item);
    }

    final candidates =
        grouped.values.where((items) => items.length >= 2).toList()
          ..sort((first, second) => second.length.compareTo(first.length));

    return List.generate(candidates.length, (index) {
      final items = candidates[index]
        ..sort(
          (first, second) => second.occurredAt.compareTo(first.occurredAt),
        );

      final latest = items.first;

      return AtlasEventAnalyticsCriticalPattern(
        position: index + 1,
        type: latest.type,
        title: latest.title,
        sourceModule: latest.sourceModule,
        farmName: latest.farmName ?? 'Operação',
        count: items.length,
        lastOccurrence: latest.occurredAt,
      );
    });
  }

  List<AtlasEventAnalyticsRecommendation> _recommendations({
    required List<AtlasEventLogEntry> entries,
    required Map<AtlasEventPriority, int> priorityDistribution,
  }) {
    final result = <AtlasEventAnalyticsRecommendation>[];

    final criticalCount =
        priorityDistribution[AtlasEventPriority.critical] ?? 0;

    final highCount = priorityDistribution[AtlasEventPriority.high] ?? 0;

    if (criticalCount > 0) {
      result.add(
        AtlasEventAnalyticsRecommendation(
          position: 0,
          title: 'Revisar eventos críticos',
          description: 'Existem $criticalCount eventos críticos registrados.',
          priority: AtlasEventPriority.critical,
          reason: 'Eventos críticos exigem resposta imediata e acompanhamento.',
        ),
      );
    }

    if (highCount >= 5) {
      result.add(
        AtlasEventAnalyticsRecommendation(
          position: 0,
          title: 'Reduzir concentração de riscos altos',
          description:
              'Foram identificados $highCount eventos de prioridade alta.',
          priority: AtlasEventPriority.high,
          reason: 'O volume elevado pode indicar gargalos recorrentes.',
        ),
      );
    }

    final inventoryAlerts = entries.where((item) {
      return item.type == AtlasEventType.inventoryLowStock ||
          item.type == AtlasEventType.inventoryOutOfStock;
    }).length;

    if (inventoryAlerts >= 2) {
      result.add(
        AtlasEventAnalyticsRecommendation(
          position: 0,
          title: 'Revisar política de reposição',
          description: '$inventoryAlerts alertas de estoque foram registrados.',
          priority: AtlasEventPriority.high,
          reason: 'Alertas recorrentes indicam falha de reposição ou previsão.',
        ),
      );
    }

    final workflowDelays = entries.where((item) {
      return item.type == AtlasEventType.taskDelayed ||
          item.type == AtlasEventType.workflowDelayed;
    }).length;

    if (workflowDelays >= 2) {
      result.add(
        AtlasEventAnalyticsRecommendation(
          position: 0,
          title: 'Reavaliar capacidade de execução',
          description:
              '$workflowDelays atrasos foram registrados em tarefas ou workflows.',
          priority: AtlasEventPriority.high,
          reason:
              'Atrasos repetidos podem indicar excesso de demanda ou dependências.',
        ),
      );
    }

    final diseaseAlerts = entries.where((item) {
      return item.type == AtlasEventType.diseaseAlertCreated;
    }).length;

    if (diseaseAlerts > 0) {
      result.add(
        AtlasEventAnalyticsRecommendation(
          position: 0,
          title: 'Priorizar revisão sanitária',
          description: '$diseaseAlerts alertas sanitários foram registrados.',
          priority: AtlasEventPriority.critical,
          reason: 'Ocorrências sanitárias podem impactar produção e custos.',
        ),
      );
    }

    if (result.isEmpty && entries.isNotEmpty) {
      result.add(
        const AtlasEventAnalyticsRecommendation(
          position: 1,
          title: 'Manter acompanhamento',
          description: 'Não foram identificados padrões críticos recorrentes.',
          priority: AtlasEventPriority.normal,
          reason:
              'O histórico atual não mostra concentração relevante de risco.',
        ),
      );
    }

    return List.generate(result.length, (index) {
      final item = result[index];

      return AtlasEventAnalyticsRecommendation(
        position: index + 1,
        title: item.title,
        description: item.description,
        priority: item.priority,
        reason: item.reason,
      );
    });
  }
}
