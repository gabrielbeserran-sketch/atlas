import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventAnalyticsData {
  const AtlasEventAnalyticsData({
    required this.generatedAt,
    required this.totalEvents,
    required this.last7DaysEvents,
    required this.last30DaysEvents,
    required this.criticalEvents,
    required this.highPriorityEvents,
    required this.priorityDistribution,
    required this.moduleDistribution,
    required this.farmDistribution,
    required this.typeDistribution,
    required this.dailyTrend,
    required this.recurringCriticalEvents,
    required this.recommendations,
  });

  final DateTime generatedAt;

  final int totalEvents;
  final int last7DaysEvents;
  final int last30DaysEvents;
  final int criticalEvents;
  final int highPriorityEvents;

  final Map<AtlasEventPriority, int> priorityDistribution;

  final List<AtlasEventAnalyticsRankingItem> moduleDistribution;

  final List<AtlasEventAnalyticsRankingItem> farmDistribution;

  final List<AtlasEventAnalyticsTypeItem> typeDistribution;

  final List<AtlasEventAnalyticsDailyPoint> dailyTrend;

  final List<AtlasEventAnalyticsCriticalPattern> recurringCriticalEvents;

  final List<AtlasEventAnalyticsRecommendation> recommendations;

  bool get hasData => totalEvents > 0;
}

class AtlasEventAnalyticsRankingItem {
  const AtlasEventAnalyticsRankingItem({
    required this.position,
    required this.label,
    required this.count,
    required this.percent,
  });

  final int position;
  final String label;
  final int count;
  final double percent;
}

class AtlasEventAnalyticsTypeItem {
  const AtlasEventAnalyticsTypeItem({
    required this.position,
    required this.type,
    required this.count,
    required this.percent,
  });

  final int position;
  final AtlasEventType type;
  final int count;
  final double percent;
}

class AtlasEventAnalyticsDailyPoint {
  const AtlasEventAnalyticsDailyPoint({
    required this.date,
    required this.total,
    required this.high,
    required this.critical,
  });

  final DateTime date;
  final int total;
  final int high;
  final int critical;
}

class AtlasEventAnalyticsCriticalPattern {
  const AtlasEventAnalyticsCriticalPattern({
    required this.position,
    required this.type,
    required this.title,
    required this.sourceModule,
    required this.farmName,
    required this.count,
    required this.lastOccurrence,
  });

  final int position;
  final AtlasEventType type;
  final String title;
  final String sourceModule;
  final String farmName;
  final int count;
  final DateTime lastOccurrence;
}

class AtlasEventAnalyticsRecommendation {
  const AtlasEventAnalyticsRecommendation({
    required this.position,
    required this.title,
    required this.description,
    required this.priority,
    required this.reason,
  });

  final int position;
  final String title;
  final String description;
  final AtlasEventPriority priority;
  final String reason;
}
