import 'dart:async';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_sync_result.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_meeting_decision_action_sync_service.dart';

class AtlasDecisionActionAutoSyncService {
  AtlasDecisionActionAutoSyncService._();

  static final AtlasDecisionActionAutoSyncService instance =
      AtlasDecisionActionAutoSyncService._();

  final AtlasMeetingDecisionActionSyncService _syncService =
      AtlasMeetingDecisionActionSyncService.instance;

  Timer? _timer;
  bool _isRunning = false;
  String? _farmName;
  Future<void> Function()? _onSynchronized;

  bool get isRunning => _isRunning;

  void start({
    String? farmName,
    Duration interval = const Duration(seconds: 30),
    Future<void> Function()? onSynchronized,
  }) {
    _farmName = farmName;
    _onSynchronized = onSynchronized;

    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      synchronizeNow();
    });

    synchronizeNow();
  }

  Future<AtlasMeetingDecisionActionSyncResult?>
      synchronizeNow() async {
    if (_isRunning) {
      return null;
    }

    _isRunning = true;

    try {
      final result = await _syncService.synchronize(
        farmName: _farmName,
        repairBrokenLinks: true,
      );

      if (_onSynchronized != null) {
        await _onSynchronized!();
      }

      return result;
    } finally {
      _isRunning = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _onSynchronized = null;
  }
}
