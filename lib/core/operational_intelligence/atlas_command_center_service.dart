import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_insight_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_metrics_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_timeline_service.dart';

class AtlasCommandCenterService {
  AtlasCommandCenterService({
    AtlasOperationalTimelineService? timelineService,
    AtlasOperationalPriorityService? priorityService,
    AtlasOperationalInsightService? insightService,
    AtlasOperationalMetricsService? metricsService,
  })  : _timelineService =
            timelineService ?? AtlasOperationalTimelineService(),
        _priorityService =
            priorityService ?? const AtlasOperationalPriorityService(),
        _insightService =
            insightService ?? const AtlasOperationalInsightService(),
        _metricsService =
            metricsService ?? const AtlasOperationalMetricsService();

  final AtlasOperationalTimelineService _timelineService;
  final AtlasOperationalPriorityService _priorityService;
  final AtlasOperationalInsightService _insightService;
  final AtlasOperationalMetricsService _metricsService;

  Future<AtlasCommandCenterSnapshot> build({
    String? farmName,
    DateTime? startDate,
    DateTime? endDate,
    int timelineLimit = 500,
    int priorityLimit = 30,
    int insightLimit = 20,
  }) async {
    final timeline = await _timelineService.build(
      farmName: farmName,
      startDate: startDate,
      endDate: endDate,
      limit: timelineLimit,
    );

    final metrics = _metricsService.build(
      entries: timeline.entries,
      farmName: farmName,
    );

    final priorities = _priorityService.build(
      entries: timeline.entries,
      maxItems: priorityLimit,
    );

    final insights = _insightService.build(
      entries: timeline.entries,
      maxItems: insightLimit,
    );

    return AtlasCommandCenterSnapshot(
      generatedAt: DateTime.now(),
      farmName: farmName,
      timeline: timeline,
      metrics: metrics,
      priorities: List.unmodifiable(priorities),
      insights: List.unmodifiable(insights),
    );
  }
}
