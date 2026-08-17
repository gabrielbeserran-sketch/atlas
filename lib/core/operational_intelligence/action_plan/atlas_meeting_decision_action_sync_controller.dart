import 'package:flutter/foundation.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_sync_result.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_sync_service.dart';

class AtlasMeetingDecisionActionSyncController extends ChangeNotifier {
  AtlasMeetingDecisionActionSyncController({
    AtlasMeetingDecisionActionSyncService? service,
    this.farmName,
  }) : _service = service ?? AtlasMeetingDecisionActionSyncService.instance;

  final AtlasMeetingDecisionActionSyncService _service;
  final String? farmName;

  bool _isSyncing = false;
  String? _errorMessage;
  AtlasMeetingDecisionActionSyncResult? _lastResult;

  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  AtlasMeetingDecisionActionSyncResult? get lastResult => _lastResult;

  Future<AtlasMeetingDecisionActionSyncResult?> synchronize() async {
    if (_isSyncing) {
      return _lastResult;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastResult = await _service.synchronize(farmName: farmName);
      return _lastResult;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
