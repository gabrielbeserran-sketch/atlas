import 'package:flutter/foundation.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_monitoring_item.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_monitoring_service.dart';

class AtlasMeetingDecisionMonitoringController
    extends ChangeNotifier {
  AtlasMeetingDecisionMonitoringController({
    AtlasExecutionMeetingService? meetingService,
    AtlasMeetingDecisionMonitoringService monitoringService =
        const AtlasMeetingDecisionMonitoringService(),
    this.farmName,
  })  : _meetingService = meetingService ??
            AtlasExecutionMeetingService.instance,
        _monitoringService = monitoringService;

  final AtlasExecutionMeetingService _meetingService;
  final AtlasMeetingDecisionMonitoringService
      _monitoringService;
  final String? farmName;

  List<AtlasMeetingDecisionMonitoringItem> _items =
      <AtlasMeetingDecisionMonitoringItem>[];
  bool _isLoading = false;
  String? _errorMessage;

  List<AtlasMeetingDecisionMonitoringItem> get items =>
      List<AtlasMeetingDecisionMonitoringItem>.unmodifiable(
        _items,
      );

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount =>
      _items.where((item) => !item.isCompleted).length;

  int get overdueCount =>
      _items.where((item) => item.isOverdue).length;

  int get dueSoonCount =>
      _items.where((item) => item.isDueSoon).length;

  int get withoutResponsibleCount => _items
      .where((item) => !item.hasResponsible)
      .length;

  int get withoutLinkedActionCount => _items
      .where((item) => !item.hasLinkedAction)
      .length;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final meetings = await _meetingService.load(
        farmName: farmName,
      );

      _items = _monitoringService.build(
        meetings: meetings,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
