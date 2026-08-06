import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_filter.dart';

typedef AtlasEventListener = Future<void> Function(
  AtlasEvent event,
);

class AtlasEventSubscription {
  const AtlasEventSubscription({
    required this.id,
    required this.listener,
    required this.filter,
    required this.createdAt,
    required this.owner,
  });

  final String id;
  final AtlasEventListener listener;
  final AtlasEventFilter filter;
  final DateTime createdAt;
  final String owner;
}
