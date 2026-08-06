import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventFilter {
  const AtlasEventFilter({
    this.types,
    this.sourceModules,
    this.priorities,
    this.farmId,
    this.farmName,
    this.entityId,
    this.entityType,
    this.tags,
  });

  final Set<AtlasEventType>? types;
  final Set<String>? sourceModules;
  final Set<AtlasEventPriority>? priorities;

  final String? farmId;
  final String? farmName;

  final String? entityId;
  final String? entityType;

  final Set<String>? tags;

  bool matches(
    AtlasEvent event,
  ) {
    if (types != null &&
        types!.isNotEmpty &&
        !types!.contains(event.type)) {
      return false;
    }

    if (sourceModules != null &&
        sourceModules!.isNotEmpty &&
        !sourceModules!.contains(
          event.sourceModule,
        )) {
      return false;
    }

    if (priorities != null &&
        priorities!.isNotEmpty &&
        !priorities!.contains(
          event.priority,
        )) {
      return false;
    }

    if (farmId != null &&
        event.farmId != farmId) {
      return false;
    }

    if (farmName != null &&
        event.farmName != farmName) {
      return false;
    }

    if (entityId != null &&
        event.entityId != entityId) {
      return false;
    }

    if (entityType != null &&
        event.entityType != entityType) {
      return false;
    }

    if (tags != null &&
        tags!.isNotEmpty &&
        !tags!.every(
          event.tags.contains,
        )) {
      return false;
    }

    return true;
  }
}
