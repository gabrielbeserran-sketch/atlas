import 'package:projeto_atlas/core/event_center/atlas_event_analytics_data.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';

class AtlasEventAnalyticsBrainBridge {
  const AtlasEventAnalyticsBrainBridge();

  AtlasExecutiveBrainData enrich({
    required AtlasExecutiveBrainData brain,
    required AtlasEventAnalyticsData analytics,
  }) {
    if (!analytics.hasData) {
      return brain;
    }

    final historicalInsights = _buildHistoricalInsights(analytics);

    final mergedInsights = _mergeInsights(
      current: brain.memoryInsights,
      historical: historicalInsights,
    );

    final score = (brain.brainScore - _riskPenalty(analytics))
        .clamp(0.0, 100.0)
        .toDouble();

    final confidence = (brain.confidencePercent + _evidenceBonus(analytics))
        .clamp(0.0, 100.0)
        .toDouble();

    return AtlasExecutiveBrainData(
      generatedAt: brain.generatedAt,
      summary: _buildSummary(
        originalSummary: brain.summary,
        analytics: analytics,
        historicalInsights: historicalInsights,
      ),
      brainScore: score,
      confidencePercent: confidence,
      status: _status(score: score, analytics: analytics),
      officialDecision: brain.officialDecision,
      strategy: brain.strategy,
      crossImpacts: brain.crossImpacts,
      conflicts: brain.conflicts,
      dailyPlan: brain.dailyPlan,
      weeklyPlan: brain.weeklyPlan,
      monthlyPlan: brain.monthlyPlan,
      memoryInsights: mergedInsights,
      scoreDimensions: brain.scoreDimensions,
      radarItems: brain.radarItems,
    );
  }

  List<AtlasExecutiveMemoryInsight> _buildHistoricalInsights(
    AtlasEventAnalyticsData analytics,
  ) {
    final result = <AtlasExecutiveMemoryInsight>[];

    for (final pattern in analytics.recurringCriticalEvents.take(8)) {
      result.add(
        AtlasExecutiveMemoryInsight(
          id:
              'event_pattern_'
              '${pattern.type.name}_'
              '${pattern.sourceModule}_'
              '${pattern.farmName}',
          title:
              'Padrão recorrente: '
              '${pattern.title}',
          description:
              '${pattern.count} ocorrências '
              'de alta relevância foram '
              'registradas em '
              '${pattern.farmName}, com origem '
              'em ${pattern.sourceModule}.',
          type: AtlasExecutiveMemoryInsightType.recurringPattern,
          farmName: pattern.farmName,
          relevanceScore: (55 + pattern.count * 8).clamp(0, 100).toDouble(),
          recommendation:
              'Investigar a causa comum, '
              'definir um responsável e '
              'acompanhar a situação até '
              'interromper a recorrência.',
        ),
      );
    }

    for (final recommendation in analytics.recommendations.take(8)) {
      result.add(
        AtlasExecutiveMemoryInsight(
          id:
              'event_recommendation_'
              '${recommendation.position}_'
              '${recommendation.priority.name}',
          title: recommendation.title,
          description: recommendation.description,
          type: _memoryInsightType(recommendation.priority),
          farmName: 'Operação',
          relevanceScore: _priorityScore(recommendation.priority),
          recommendation: recommendation.reason,
        ),
      );
    }

    final leadingFarm = analytics.farmDistribution.isEmpty
        ? null
        : analytics.farmDistribution.first;

    if (leadingFarm != null && leadingFarm.count >= 5) {
      result.add(
        AtlasExecutiveMemoryInsight(
          id:
              'event_concentration_farm_'
              '${leadingFarm.label}',
          title:
              'Concentração de eventos em '
              '${leadingFarm.label}',
          description:
              '${leadingFarm.count} eventos '
              'representam '
              '${leadingFarm.percent.toStringAsFixed(1)}% '
              'do histórico analisado.',
          type: AtlasExecutiveMemoryInsightType.decisionLesson,
          farmName: leadingFarm.label,
          relevanceScore: (45 + leadingFarm.percent * 0.5)
              .clamp(0, 100)
              .toDouble(),
          recommendation:
              'Comparar essa concentração '
              'com o tamanho e a complexidade '
              'da operação antes de priorizar '
              'intervenções.',
        ),
      );
    }

    final leadingModule = analytics.moduleDistribution.isEmpty
        ? null
        : analytics.moduleDistribution.first;

    if (leadingModule != null && leadingModule.count >= 5) {
      result.add(
        AtlasExecutiveMemoryInsight(
          id:
              'event_concentration_module_'
              '${leadingModule.label}',
          title:
              'Alta atividade no módulo '
              '${leadingModule.label}',
          description:
              '${leadingModule.count} eventos '
              'foram registrados nesse módulo, '
              'representando '
              '${leadingModule.percent.toStringAsFixed(1)}% '
              'do histórico.',
          type: AtlasExecutiveMemoryInsightType.decisionLesson,
          farmName: 'Operação',
          relevanceScore: (42 + leadingModule.percent * 0.45)
              .clamp(0, 100)
              .toDouble(),
          recommendation:
              'Verificar se o volume representa '
              'atividade normal ou concentração '
              'de problemas operacionais.',
        ),
      );
    }

    result.sort((first, second) {
      return second.relevanceScore.compareTo(first.relevanceScore);
    });

    return result.take(15).toList();
  }

  List<AtlasExecutiveMemoryInsight> _mergeInsights({
    required List<AtlasExecutiveMemoryInsight> current,
    required List<AtlasExecutiveMemoryInsight> historical,
  }) {
    final byId = <String, AtlasExecutiveMemoryInsight>{};

    for (final item in [...historical, ...current]) {
      final existing = byId[item.id];

      if (existing == null || item.relevanceScore > existing.relevanceScore) {
        byId[item.id] = item;
      }
    }

    final merged = byId.values.toList()
      ..sort((first, second) {
        return second.relevanceScore.compareTo(first.relevanceScore);
      });

    return merged.take(30).toList();
  }

  double _riskPenalty(AtlasEventAnalyticsData analytics) {
    final criticalPenalty = analytics.criticalEvents * 1.8;

    final highPenalty = analytics.highPriorityEvents * 0.45;

    final recurringPenalty = analytics.recurringCriticalEvents.length * 1.4;

    return (criticalPenalty + highPenalty + recurringPenalty)
        .clamp(0.0, 22.0)
        .toDouble();
  }

  double _evidenceBonus(AtlasEventAnalyticsData analytics) {
    if (analytics.totalEvents < 5) {
      return 0;
    }

    final volumeBonus = analytics.totalEvents >= 100
        ? 7.0
        : analytics.totalEvents >= 30
        ? 5.0
        : 3.0;

    final recencyBonus = analytics.last30DaysEvents > 0 ? 2.0 : 0.0;

    return (volumeBonus + recencyBonus).clamp(0.0, 9.0).toDouble();
  }

  AtlasExecutiveBrainStatus _status({
    required double score,
    required AtlasEventAnalyticsData analytics,
  }) {
    if (analytics.criticalEvents >= 5 || score < 35) {
      return AtlasExecutiveBrainStatus.critical;
    }

    if (analytics.criticalEvents > 0 || score < 60) {
      return AtlasExecutiveBrainStatus.attention;
    }

    if (score < 80) {
      return AtlasExecutiveBrainStatus.adequate;
    }

    return AtlasExecutiveBrainStatus.excellent;
  }

  AtlasExecutiveMemoryInsightType _memoryInsightType(
    AtlasEventPriority priority,
  ) {
    switch (priority) {
      case AtlasEventPriority.low:
      case AtlasEventPriority.normal:
        return AtlasExecutiveMemoryInsightType.decisionLesson;

      case AtlasEventPriority.high:
      case AtlasEventPriority.critical:
        return AtlasExecutiveMemoryInsightType.historicalRisk;
    }
  }

  double _priorityScore(AtlasEventPriority priority) {
    switch (priority) {
      case AtlasEventPriority.low:
        return 35;

      case AtlasEventPriority.normal:
        return 50;

      case AtlasEventPriority.high:
        return 78;

      case AtlasEventPriority.critical:
        return 94;
    }
  }

  String _buildSummary({
    required String originalSummary,
    required AtlasEventAnalyticsData analytics,
    required List<AtlasExecutiveMemoryInsight> historicalInsights,
  }) {
    return '$originalSummary '
        'O histórico acrescentou '
        '${historicalInsights.length} '
        'memórias executivas, com '
        '${analytics.totalEvents} eventos '
        'analisados, '
        '${analytics.criticalEvents} críticos '
        'e '
        '${analytics.recurringCriticalEvents.length} '
        'padrões recorrentes.';
  }
}
