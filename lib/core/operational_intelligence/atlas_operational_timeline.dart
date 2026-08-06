import 'package:projeto_atlas/core/operational_memory/atlas_operational_memory_entry.dart';

class AtlasOperationalTimeline {
  const AtlasOperationalTimeline({
    required this.generatedAt,
    required this.farmName,
    required this.entries,
    required this.totalEvents,
    required this.modules,
    required this.firstOccurredAt,
    required this.lastOccurredAt,
  });

  final DateTime generatedAt;
  final String? farmName;
  final List<AtlasOperationalMemoryEntry> entries;
  final int totalEvents;
  final Set<String> modules;
  final DateTime? firstOccurredAt;
  final DateTime? lastOccurredAt;

  bool get isEmpty => entries.isEmpty;
  bool get hasData => entries.isNotEmpty;

  Duration? get coveredPeriod {
    final first = firstOccurredAt;
    final last = lastOccurredAt;

    if (first == null || last == null) {
      return null;
    }

    return last.difference(first);
  }
}
