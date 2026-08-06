import 'package:projeto_atlas/core/reactivity/atlas_reactive_target.dart';

class AtlasReactiveTargetDiagnostics {
  const AtlasReactiveTargetDiagnostics({
    required this.target,
    required this.registeredHandlers,
    required this.executions,
    required this.failures,
    required this.lastDuration,
    required this.totalDuration,
    this.lastExecutedAt,
    this.lastError,
  });

  final AtlasReactiveTarget target;
  final int registeredHandlers;
  final int executions;
  final int failures;
  final Duration lastDuration;
  final Duration totalDuration;
  final DateTime? lastExecutedAt;
  final String? lastError;

  double get averageDurationMilliseconds {
    if (executions == 0) {
      return 0;
    }

    return totalDuration.inMicroseconds / executions / 1000;
  }

  double get successRate {
    if (executions == 0) {
      return 100;
    }

    return ((executions - failures) / executions) * 100;
  }
}

class AtlasReactiveDiagnostics {
  const AtlasReactiveDiagnostics({
    required this.generatedAt,
    required this.isRunning,
    required this.receivedEvents,
    required this.processedEvents,
    required this.discardedDuplicateEvents,
    required this.generatedUpdates,
    required this.criticalFlushes,
    required this.pendingEvents,
    required this.registeredHandlers,
    required this.targetDiagnostics,
    this.lastUpdateAt,
    this.lastUpdateDuration = Duration.zero,
  });

  final DateTime generatedAt;
  final bool isRunning;
  final int receivedEvents;
  final int processedEvents;
  final int discardedDuplicateEvents;
  final int generatedUpdates;
  final int criticalFlushes;
  final int pendingEvents;
  final int registeredHandlers;
  final DateTime? lastUpdateAt;
  final Duration lastUpdateDuration;
  final List<AtlasReactiveTargetDiagnostics> targetDiagnostics;

  double get duplicateRate {
    if (receivedEvents == 0) {
      return 0;
    }

    return discardedDuplicateEvents / receivedEvents * 100;
  }
}
