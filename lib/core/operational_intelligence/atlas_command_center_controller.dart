import 'dart:async';

import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_cached_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_store.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_version_service.dart';

class AtlasCommandCenterController {
  AtlasCommandCenterController({
    required AtlasCommandCenterCachedService service,
    required AtlasCommandCenterVersionService versionService,
    required this.store,
  })  : _service = service,
        _versionService = versionService;

  final AtlasCommandCenterCachedService _service;
  final AtlasCommandCenterVersionService _versionService;
  final AtlasCommandCenterStore store;

  final Map<String, Future<AtlasCommandCenterSnapshot>> _runningRequests =
      <String, Future<AtlasCommandCenterSnapshot>>{};

  Future<AtlasCommandCenterSnapshot> load({
    String? farmName,
    bool forceRefresh = false,
  }) {
    final key = _key(farmName);

    if (!forceRefresh) {
      final running = _runningRequests[key];

      if (running != null) {
        return running;
      }
    }

    final request = _executeLoad(
      farmName: farmName,
      forceRefresh: forceRefresh,
    );

    _runningRequests[key] = request;

    return request.whenComplete(() {
      if (identical(_runningRequests[key], request)) {
        _runningRequests.remove(key);
      }
    });
  }

  Future<AtlasCommandCenterSnapshot> refresh({
    String? farmName,
  }) {
    return load(
      farmName: farmName,
      forceRefresh: true,
    );
  }

  Future<AtlasCommandCenterSnapshot> _executeLoad({
    required String? farmName,
    required bool forceRefresh,
  }) async {
    store.markLoading(farmName);

    try {
      final snapshot = await _service.build(
        farmName: farmName,
        forceRefresh: forceRefresh,
      );

      final version = _versionService.current(farmName);

      store.publish(
        farmName: farmName,
        snapshot: snapshot,
        version: version,
      );

      return snapshot;
    } catch (error) {
      store.publishError(
        farmName: farmName,
        error: error,
      );
      rethrow;
    }
  }

  String _key(String? farmName) {
    final normalized = farmName?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return 'global';
    }

    return normalized;
  }
}
