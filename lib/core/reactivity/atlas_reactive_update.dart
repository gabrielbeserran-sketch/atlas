import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_target.dart';

class AtlasReactiveUpdate {
  const AtlasReactiveUpdate({
    required this.id,
    required this.createdAt,
    required this.events,
    required this.targets,
    required this.priority,
    required this.reason,
  });

  final String id;
  final DateTime createdAt;
  final List<AtlasEvent> events;
  final Set<AtlasReactiveTarget> targets;
  final AtlasEventPriority priority;
  final String reason;

  bool get isCritical =>
      priority == AtlasEventPriority.critical;
}
