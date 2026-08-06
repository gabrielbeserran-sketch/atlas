import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasEventCorrelation {
  const AtlasEventCorrelation({
    required this.id,
    required this.title,
    required this.description,
    required this.farmName,
    required this.firstModule,
    required this.secondModule,
    required this.firstEventId,
    required this.secondEventId,
    required this.firstOccurredAt,
    required this.secondOccurredAt,
    required this.priority,
    required this.confidencePercent,
    required this.hoursBetweenEvents,
  });

  final String id;
  final String title;
  final String description;
  final String farmName;
  final String firstModule;
  final String secondModule;
  final String firstEventId;
  final String secondEventId;
  final DateTime firstOccurredAt;
  final DateTime secondOccurredAt;
  final AtlasEventPriority priority;
  final double confidencePercent;
  final int hoursBetweenEvents;
}
