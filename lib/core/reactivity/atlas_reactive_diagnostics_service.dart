import 'package:projeto_atlas/core/reactivity/atlas_reactive_diagnostics.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_target.dart';

class AtlasReactiveDiagnosticsService {
  AtlasReactiveDiagnosticsService._();

  static final AtlasReactiveDiagnosticsService instance =
      AtlasReactiveDiagnosticsService._();

  int _receivedEvents = 0;
  int _processedEvents = 0;
  int _discardedDuplicateEvents = 0;
  int _generatedUpdates = 0;
  int _criticalFlushes = 0;
  DateTime? _lastUpdateAt;
  Duration _lastUpdateDuration = Duration.zero;

  final Map<AtlasReactiveTarget, _MutableTargetDiagnostics> _targets =
      <AtlasReactiveTarget, _MutableTargetDiagnostics>{};

  void registerHandler(AtlasReactiveTarget target) {
    final diagnostics = _target(target);
    diagnostics.registeredHandlers += 1;
  }

  void unregisterHandler(AtlasReactiveTarget target) {
    final diagnostics = _target(target);
    if (diagnostics.registeredHandlers > 0) {
      diagnostics.registeredHandlers -= 1;
    }
  }

  void recordReceivedEvent() {
    _receivedEvents += 1;
  }

  void recordProcessedEvents(int count) {
    _processedEvents += count;
  }

  void recordDuplicateEvent() {
    _discardedDuplicateEvents += 1;
  }

  void recordCriticalFlush() {
    _criticalFlushes += 1;
  }

  void recordUpdate({
    required DateTime completedAt,
    required Duration duration,
  }) {
    _generatedUpdates += 1;
    _lastUpdateAt = completedAt;
    _lastUpdateDuration = duration;
  }

  void recordTargetExecution({
    required AtlasReactiveTarget target,
    required Duration duration,
    String? error,
  }) {
    final diagnostics = _target(target);
    diagnostics.executions += 1;
    diagnostics.lastDuration = duration;
    diagnostics.totalDuration += duration;
    diagnostics.lastExecutedAt = DateTime.now();
    diagnostics.lastError = error;

    if (error != null) {
      diagnostics.failures += 1;
    }
  }

  AtlasReactiveDiagnostics snapshot({
    required bool isRunning,
    required int pendingEvents,
  }) {
    final targetDiagnostics = AtlasReactiveTarget.values
        .map((target) {
          final mutable = _target(target);

          return AtlasReactiveTargetDiagnostics(
            target: target,
            registeredHandlers: mutable.registeredHandlers,
            executions: mutable.executions,
            failures: mutable.failures,
            lastDuration: mutable.lastDuration,
            totalDuration: mutable.totalDuration,
            lastExecutedAt: mutable.lastExecutedAt,
            lastError: mutable.lastError,
          );
        })
        .where(
          (item) =>
              item.registeredHandlers > 0 ||
              item.executions > 0 ||
              item.failures > 0,
        )
        .toList(growable: false);

    final registeredHandlers = targetDiagnostics.fold<int>(
      0,
      (total, item) => total + item.registeredHandlers,
    );

    return AtlasReactiveDiagnostics(
      generatedAt: DateTime.now(),
      isRunning: isRunning,
      receivedEvents: _receivedEvents,
      processedEvents: _processedEvents,
      discardedDuplicateEvents: _discardedDuplicateEvents,
      generatedUpdates: _generatedUpdates,
      criticalFlushes: _criticalFlushes,
      pendingEvents: pendingEvents,
      registeredHandlers: registeredHandlers,
      lastUpdateAt: _lastUpdateAt,
      lastUpdateDuration: _lastUpdateDuration,
      targetDiagnostics: targetDiagnostics,
    );
  }

  void reset() {
    _receivedEvents = 0;
    _processedEvents = 0;
    _discardedDuplicateEvents = 0;
    _generatedUpdates = 0;
    _criticalFlushes = 0;
    _lastUpdateAt = null;
    _lastUpdateDuration = Duration.zero;

    for (final diagnostics in _targets.values) {
      diagnostics.executions = 0;
      diagnostics.failures = 0;
      diagnostics.lastDuration = Duration.zero;
      diagnostics.totalDuration = Duration.zero;
      diagnostics.lastExecutedAt = null;
      diagnostics.lastError = null;
    }
  }

  _MutableTargetDiagnostics _target(AtlasReactiveTarget target) {
    return _targets.putIfAbsent(
      target,
      _MutableTargetDiagnostics.new,
    );
  }
}

class _MutableTargetDiagnostics {
  int registeredHandlers = 0;
  int executions = 0;
  int failures = 0;
  Duration lastDuration = Duration.zero;
  Duration totalDuration = Duration.zero;
  DateTime? lastExecutedAt;
  String? lastError;
}
