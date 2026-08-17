import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_cache_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';

class AtlasCommandCenterCachedService {
  AtlasCommandCenterCachedService({
    AtlasCommandCenterService? commandCenterService,
    AtlasCommandCenterCacheService? cacheService,
  }) : _commandCenterService =
           commandCenterService ?? AtlasCommandCenterService(),
       _cacheService = cacheService ?? AtlasCommandCenterCacheService();

  final AtlasCommandCenterService _commandCenterService;
  final AtlasCommandCenterCacheService _cacheService;

  AtlasCommandCenterCacheService get cache => _cacheService;

  Future<AtlasCommandCenterSnapshot> build({
    String? farmName,
    DateTime? startDate,
    DateTime? endDate,
    int timelineLimit = 500,
    int priorityLimit = 30,
    int insightLimit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && startDate == null && endDate == null) {
      final cached = _cacheService.get(farmName: farmName);

      if (cached != null) {
        return cached;
      }
    }

    final snapshot = await _commandCenterService.build(
      farmName: farmName,
      startDate: startDate,
      endDate: endDate,
      timelineLimit: timelineLimit,
      priorityLimit: priorityLimit,
      insightLimit: insightLimit,
    );

    if (startDate == null && endDate == null) {
      _cacheService.put(farmName: farmName, snapshot: snapshot);
    }

    return snapshot;
  }
}
