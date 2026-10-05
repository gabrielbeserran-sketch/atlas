import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../network/atlas_http_client.dart';
import '../../session/atlas_session_controller.dart';
import '../models/offline_operation.dart';
import '../models/offline_sync_models.dart';
import '../services/offline_repository.dart';
import '../services/offline_sync_coordinator.dart';
import '../services/offline_device_identity.dart';

class AtlasOfflineController extends ChangeNotifier {
  AtlasOfflineController({
    required this.sessionController,
    OfflineRepository? repository,
    OfflineSyncCoordinator? coordinator,
  }) : _repository = repository ?? OfflineRepository(),
       _coordinator = coordinator ?? OfflineSyncCoordinator() {
    _observedCompanyId = sessionController.session?.companyId;
    _observedTenantId = sessionController.session?.tenantId;
    _observedFarmId = sessionController.activeFarm?.id;
    _observedUserId = sessionController.session?.userId;
    sessionController.addListener(_onScopeChanged);
  }

  final AtlasSessionController sessionController;
  final OfflineRepository _repository;
  final OfflineSyncCoordinator _coordinator;
  String? _observedCompanyId;
  String? _observedTenantId;
  String? _observedFarmId;
  String? _observedUserId;
  int _loadGeneration = 0;
  int _scopeGeneration = 0;
  bool _disposed = false;

  OfflineQueueStats _stats = const OfflineQueueStats(
    pending: 0,
    retry: 0,
    conflicts: 0,
    failed: 0,
    accepted: 0,
  );
  OfflineServerStatus? _serverStatus;
  List<OfflineConflict> _conflicts = const <OfflineConflict>[];
  List<OfflineOperation> _failedOperations = const <OfflineOperation>[];
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
  List<OfflineOperation> get failedOperations =>
      List.unmodifiable(_failedOperations);
  OfflineSyncReport? get lastReport => _lastReport;
  String get phase => _phase;
  String? get error => _error;
  bool get loading => _loading;
  int get completed => _completed;
  int get total => _total;
  double? get progress => _total <= 0 ? null : _completed / _total;
  bool get canManage => sessionController.allows('sync.manage');

  void _onScopeChanged() {
    final companyId = sessionController.session?.companyId;
    final tenantId = sessionController.session?.tenantId;
    final farmId = sessionController.activeFarm?.id;
    final userId = sessionController.session?.userId;
    if (companyId == _observedCompanyId &&
        tenantId == _observedTenantId &&
        farmId == _observedFarmId &&
        userId == _observedUserId) {
      return;
    }
    _observedCompanyId = companyId;
    _observedTenantId = tenantId;
    _observedFarmId = farmId;
    _observedUserId = userId;
    _scopeGeneration++;
    _deviceId = null;
    _lastReport = null;
    unawaited(load());
  }

  bool _isCurrent(
    int generation,
    String companyId,
    String? farmId,
    String userId,
  ) => generation == _loadGeneration && _sameScope(companyId, farmId, userId);

  bool _sameScope(String companyId, String? farmId, String userId) =>
      !_disposed &&
      sessionController.session?.companyId == companyId &&
      sessionController.activeFarm?.id == farmId &&
      sessionController.session?.userId == userId;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    final session = sessionController.session;
    final farmId = sessionController.activeFarm?.id;
    _stats = const OfflineQueueStats(
      pending: 0,
      retry: 0,
      conflicts: 0,
      failed: 0,
      accepted: 0,
    );
    _conflicts = const <OfflineConflict>[];
    _failedOperations = const <OfflineOperation>[];
    _serverStatus = null;
    if (session == null || session.companyId.isEmpty) {
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final stats = await _repository.queueStats(
        companyId: session.companyId,
        farmId: farmId,
      );
      final conflicts = await _repository.conflicts(
        companyId: session.companyId,
        farmId: farmId,
      );
      final failedOperations = await _repository.failedOperations(
        companyId: session.companyId,
        farmId: farmId,
      );
      OfflineServerStatus? serverStatus;
      try {
        serverStatus = await _coordinator.serverStatus();
      } catch (_) {
        serverStatus = null;
      }
      if (!_isCurrent(generation, session.companyId, farmId, session.userId)) {
        return;
      }
      _stats = stats;
      _conflicts = conflicts;
      _failedOperations = failedOperations;
      _serverStatus = serverStatus;
    } catch (error) {
      if (_isCurrent(generation, session.companyId, farmId, session.userId)) {
        _error = error.toString();
      }
    } finally {
      if (_isCurrent(generation, session.companyId, farmId, session.userId)) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    sessionController.removeListener(_onScopeChanged);
    super.dispose();
  }

  Future<void> synchronize() async {
    final session = sessionController.session;
    if (session == null) return;
    final farmId = sessionController.activeFarm?.id;
    final scopeGeneration = _scopeGeneration;
    bool isScopeCurrent() =>
        scopeGeneration == _scopeGeneration &&
        sessionController.session?.tenantId == session.tenantId &&
        _sameScope(session.companyId, farmId, session.userId);
    _loading = true;
    _error = null;
    _phase = 'Preparando sincronização';
    _completed = 0;
    _total = 1;
    notifyListeners();
    try {
      var deviceId = _deviceId;
      if (deviceId == null) {
        final registered = await _coordinator.registerDevice(
          deviceKey: OfflineDeviceIdentity.key(session.userId),
        );
        if (!isScopeCurrent()) return;
        _deviceId = registered;
        deviceId = registered;
      }
      final report = await _coordinator.synchronize(
        companyId: session.companyId,
        tenantId: session.tenantId,
        farmId: farmId,
        deviceId: deviceId,
        isScopeCurrent: isScopeCurrent,
        onProgress: (phase, completed, total) {
          if (!isScopeCurrent()) return;
          _phase = phase;
          _completed = completed;
          _total = total;
          notifyListeners();
        },
      );
      if (!isScopeCurrent()) return;
      _lastReport = report;
      await load();
      if (!isScopeCurrent()) return;
      await _coordinator.sendDiagnostics(deviceId: deviceId, stats: _stats);
    } catch (error) {
      if (isScopeCurrent()) {
        _error = error.toString();
      }
    } finally {
      if (isScopeCurrent()) {
        _loading = false;
        _phase = '';
        notifyListeners();
      }
    }
  }

  Future<void> resolve(OfflineConflict conflict, String resolution) async {
    final session = sessionController.session;
    final companyId = session?.companyId;
    final farmId = sessionController.activeFarm?.id;
    final userId = session?.userId;
    if (session == null || companyId == null || userId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _coordinator.resolveConflict(
        conflict: conflict,
        resolution: resolution,
        note: 'Resolvido pelo aplicativo Atlas.',
      );
      if (!_sameScope(companyId, farmId, userId)) return;
      await load();
    } on AtlasHttpException catch (error) {
      if (error.statusCode == 409 &&
          await _refreshChangedConflict(
            conflict,
            companyId: companyId,
            tenantId: session.tenantId,
            farmId: farmId,
            userId: userId,
          )) {
        if (_sameScope(companyId, farmId, userId)) {
          _error =
              'O registro mudou no servidor. Compare os dados atualizados '
              'antes de escolher novamente.';
        }
      } else if (_sameScope(companyId, farmId, userId)) {
        _error = error.toString();
      }
    } catch (error) {
      if (_sameScope(companyId, farmId, userId)) _error = error.toString();
    } finally {
      if (_sameScope(companyId, farmId, userId)) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _refreshChangedConflict(
    OfflineConflict conflict, {
    required String companyId,
    required String tenantId,
    required String? farmId,
    required String userId,
  }) async {
    final serverId = conflict.serverConflictId;
    if (serverId == null || serverId.isEmpty) return false;
    try {
      final remote = await _coordinator.fetchRemoteConflicts();
      if (!_sameScope(companyId, farmId, userId)) return false;
      final updated = remote.where(
        (item) => item['id']?.toString() == serverId,
      );
      if (updated.isEmpty) return false;
      final item = updated.first;
      final version = (item['remote_version'] as num?)?.toInt();
      if (version == null || version == conflict.remoteVersion) return false;
      await _repository.importRemoteConflicts(
        companyId: companyId,
        tenantId: tenantId,
        conflicts: <Map<String, dynamic>>[item],
      );
      if (!_sameScope(companyId, farmId, userId)) return false;
      await load();
      return _sameScope(companyId, farmId, userId);
    } catch (_) {
      return false;
    }
  }
}
