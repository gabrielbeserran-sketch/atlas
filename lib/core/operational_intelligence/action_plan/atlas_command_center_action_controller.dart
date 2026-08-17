import 'package:flutter/foundation.dart';
import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_analytics.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_analytics_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_update.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action_update_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_decision_action_auto_sync_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_priority.dart';

class AtlasCommandCenterActionController extends ChangeNotifier {
  AtlasCommandCenterActionController({
    AtlasCommandCenterActionService? service,
    AtlasCommandCenterActionAnalyticsService analyticsService =
        const AtlasCommandCenterActionAnalyticsService(),
    this.farmName,
  }) : _service = service ?? AtlasCommandCenterActionService.instance,
       _analyticsService = analyticsService;

  final AtlasCommandCenterActionService _service;
  final AtlasCommandCenterActionAnalyticsService _analyticsService;
  final AtlasCommandCenterActionUpdateService _updateService =
      AtlasCommandCenterActionUpdateService.instance;
  final AtlasDecisionActionAutoSyncService _autoSyncService =
      AtlasDecisionActionAutoSyncService.instance;
  bool _hasStartedAutoSync = false;

  Map<String, DateTime> _latestUpdateDates = <String, DateTime>{};
  final String? farmName;

  List<AtlasCommandCenterAction> _actions = <AtlasCommandCenterAction>[];

  bool _isLoading = false;
  String? _errorMessage;

  List<AtlasCommandCenterAction> get actions =>
      List<AtlasCommandCenterAction>.unmodifiable(_actions);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AtlasCommandCenterActionAnalytics get analytics =>
      _analyticsService.build(_actions);

  DateTime? latestUpdateFor(String actionId) => _latestUpdateDates[actionId];

  Map<String, DateTime> get latestUpdateDates =>
      Map<String, DateTime>.unmodifiable(_latestUpdateDates);

  bool isWithoutRecentFollowUp(AtlasCommandCenterAction action) {
    if (!action.isOpen) {
      return false;
    }

    final reference = latestUpdateFor(action.id) ?? action.updatedAt;

    return DateTime.now().difference(reference).inDays >= 7;
  }

  int get pendingCount => _actions
      .where(
        (action) =>
            action.status == AtlasCanonicalStatus.pending ||
            action.status == AtlasCanonicalStatus.inProgress ||
            action.status == AtlasCanonicalStatus.blocked,
      )
      .length;

  int get overdueCount => _actions.where((action) => action.isOverdue).length;

  Future<void> load() async {
    if (!_hasStartedAutoSync) {
      _hasStartedAutoSync = true;
      _autoSyncService.start(farmName: farmName);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _actions = await _service.loadActions(farmName: farmName);
      _latestUpdateDates = await _updateService.loadLatestDates();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AtlasCommandCenterAction> createFromPriority(
    AtlasOperationalPriority priority,
  ) async {
    final action = await _service.createFromPriority(priority: priority);

    await load();
    return action;
  }

  Future<List<AtlasCommandCenterActionUpdate>> loadUpdates(
    AtlasCommandCenterAction action,
  ) {
    return _updateService.loadForAction(action.id);
  }

  Future<void> addFollowUp({
    required AtlasCommandCenterAction action,
    required String note,
  }) async {
    await _updateService.add(
      action: action,
      note: note,
      progressPercent: action.progressPercent,
      responsibleName: action.responsibleName,
    );

    _latestUpdateDates = await _updateService.loadLatestDates();
    notifyListeners();
  }

  Future<void> updateStatus(
    AtlasCommandCenterAction action,
    AtlasCanonicalStatus status,
  ) async {
    await _service.saveAction(
      action.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        completedAt: status == AtlasCanonicalStatus.completed
            ? DateTime.now()
            : null,
        clearCompletedAt: status != AtlasCanonicalStatus.completed,
      ),
    );

    await load();
  }

  Future<void> updateExecution({
    required AtlasCommandCenterAction action,
    required String responsibleName,
    String? responsibleId,
    required DateTime? dueAt,
    required int progressPercent,
    required double expectedFinancialImpact,
    required String notes,
  }) async {
    final progress = progressPercent.clamp(0, 100);
    var status = action.status;

    if (progress == 100) {
      status = AtlasCanonicalStatus.completed;
    } else if (progress > 0 && status == AtlasCanonicalStatus.pending) {
      status = AtlasCanonicalStatus.inProgress;
    }

    await _service.saveAction(
      action.copyWith(
        responsibleName: responsibleName.trim(),
        responsibleId: responsibleId,
        clearResponsibleId: responsibleId == null,
        dueAt: dueAt,
        clearDueAt: dueAt == null,
        progressPercent: progress,
        expectedFinancialImpact: expectedFinancialImpact,
        notes: notes.trim(),
        status: status,
        completedAt: status == AtlasCanonicalStatus.completed
            ? DateTime.now()
            : null,
        clearCompletedAt: status != AtlasCanonicalStatus.completed,
        updatedAt: DateTime.now(),
      ),
    );
    await load();
  }

  Future<void> updateNotes(
    AtlasCommandCenterAction action,
    String notes,
  ) async {
    await _service.saveAction(
      action.copyWith(notes: notes, updatedAt: DateTime.now()),
    );

    await load();
  }

  Future<void> delete(AtlasCommandCenterAction action) async {
    await _service.deleteAction(action.id);
    await _updateService.deleteForAction(action.id);
    await load();
  }
}
