import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_cache_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_cached_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_controller.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_reactive_runtime.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_store.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_version_service.dart';

class AtlasCommandCenterRuntime {
  AtlasCommandCenterRuntime._()
    : cacheService = AtlasCommandCenterCacheService(),
      versionService = AtlasCommandCenterVersionService(),
      store = AtlasCommandCenterStore() {
    reactiveRuntime = AtlasCommandCenterReactiveRuntime(
      eventBus: AtlasEventBus.instance,
      cacheService: cacheService,
      versionService: versionService,
    );

    cachedService = AtlasCommandCenterCachedService(
      commandCenterService: AtlasCommandCenterService(),
      cacheService: cacheService,
    );

    controller = AtlasCommandCenterController(
      service: cachedService,
      versionService: versionService,
      store: store,
    );
  }

  static final AtlasCommandCenterRuntime instance =
      AtlasCommandCenterRuntime._();

  final AtlasCommandCenterCacheService cacheService;
  final AtlasCommandCenterVersionService versionService;
  final AtlasCommandCenterStore store;

  late final AtlasCommandCenterReactiveRuntime reactiveRuntime;
  late final AtlasCommandCenterCachedService cachedService;
  late final AtlasCommandCenterController controller;

  bool get isStarted => reactiveRuntime.isStarted;

  void start() {
    reactiveRuntime.start();
  }

  void stop() {
    reactiveRuntime.stop();
  }

  void reset() {
    cacheService.clear();
    versionService.reset();
    store.clearAll();
  }
}
