import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../session/atlas_session_controller.dart';
import '../models/offline_sync_models.dart';
import '../services/offline_repository.dart';
import '../services/offline_sync_coordinator.dart';

class AtlasOfflineController extends ChangeNotifier {
  AtlasOfflineController({
    required this.sessionController,
    OfflineRepository? repository,
    OfflineSyncCoordinator? coordinator,
  }) : _repository = repository ?? OfflineRepository(),
       _coordinator = coordinator ?? OfflineSyncCoordinator();

  final AtlasSessionController sessionController;
  final OfflineRepository _repository;
  final OfflineSyncCoordinator _coordinator;

  OfflineQueueStats _stats = const OfflineQueueStats(
    pending: 0,
    retry: 0,
    conflicts: 0,
    failed: 0,
    accepted: 0,
  );
  OfflineServerStatus? _serverStatus;
  List<OfflineConflict> _conflicts = const <OfflineConflict>[];
  OfflineSyncReport? _lastReport;
  String _phase = '';
  String? _error;
  bool _loading = false;
  int _completed = 0;
  int _total = 0;
  String? _deviceId;

  OfflineQueueStats get stats => _stats;
  OfflineServerStatus? get serverStatus => _serverStatus;
  List<OfflineConflict> get conflicts => List.unmodifiable(_conflicts);
  OfflineSyncReport? get lastReport => _lastReport;
  String get phase => _phase;
  String? get error => _error;
  bool get loading => _loading;
  int get completed => _completed;
  int get total => _total;
  double? get progress => _total <= 0 ? null : _completed / _total;
  bool get canManage => sessionController.allows('sync.manage');

  Future<void> load() async {
    final session = sessionController.session;
    if (session == null || session.companyId.isEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _repository.queueStats(
        companyId: session.companyId,
        farmId: sessionController.activeFarm?.id,
      );
      _conflicts = await _repository.conflicts(
        companyId: session.companyId,
        farmId: sessionController.activeFarm?.id,
      );
      try {
        _serverStatus = await _coordinator.serverStatus();
      } catch (_) {
        _serverStatus = null;
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> synchronize() async {
    final session = sessionController.session;
    if (session == null) return;
    _loading = true;
    _error = null;
    _phase = 'Preparando sincronização';
    _completed = 0;
    _total = 1;
    notifyListeners();
    try {
      _deviceId ??= await _coordinator.registerDevice(
        deviceKey: _deviceKey(session.userId),
      );
      _lastReport = await _coordinator.synchronize(
        companyId: session.companyId,
        tenantId: session.tenantId,
        farmId: sessionController.activeFarm?.id,
        deviceId: _deviceId!,
        onProgress: (phase, completed, total) {
          _phase = phase;
          _completed = completed;
          _total = total;
          notifyListeners();
        },
      );
      await load();
      await _coordinator.sendDiagnostics(deviceId: _deviceId!, stats: _stats);
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      _phase = '';
      notifyListeners();
    }
  }

  Future<void> resolve(OfflineConflict conflict, String resolution) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _coordinator.resolveConflict(
        conflict: conflict,
        resolution: resolution,
        note: 'Resolvido pelo aplicativo Atlas.',
      );
      await load();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _deviceKey(String userId) {
    final seed =
        '${Platform.localHostname}:${Platform.operatingSystem}:$userId';
    return '${Platform.operatingSystem}-${seed.hashCode.abs()}-$userId';
  }
}
