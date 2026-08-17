import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_cache_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_version_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_invalidation_service.dart';

class AtlasCommandCenterReactiveRuntime {
  AtlasCommandCenterReactiveRuntime({
    AtlasEventBus? eventBus,
    AtlasCommandCenterCacheService? cacheService,
    AtlasCommandCenterVersionService? versionService,
    AtlasOperationalInvalidationService invalidationService =
        const AtlasOperationalInvalidationService(),
  }) : _eventBus = eventBus ?? AtlasEventBus.instance,
       cacheService = cacheService ?? AtlasCommandCenterCacheService(),
       versionService = versionService ?? AtlasCommandCenterVersionService(),
       _invalidationService = invalidationService;

  final AtlasEventBus _eventBus;
  final AtlasOperationalInvalidationService _invalidationService;

  final AtlasCommandCenterCacheService cacheService;
  final AtlasCommandCenterVersionService versionService;

  String? _subscriptionId;

  bool get isStarted => _subscriptionId != null;

  void start() {
    if (_subscriptionId != null) {
      return;
    }

    _subscriptionId = _eventBus.subscribe(
      owner: 'atlas_command_center_reactive_runtime',
      listener: _handleEvent,
    );
  }

  void stop() {
    final subscriptionId = _subscriptionId;

    if (subscriptionId == null) {
      return;
    }

    _eventBus.unsubscribe(subscriptionId);
    _subscriptionId = null;
  }

  Future<void> _handleEvent(AtlasEvent event) async {
    final invalidation = _invalidationService.fromEvent(event);

    cacheService.invalidate(invalidation);
    versionService.advance(invalidation);
  }
}
