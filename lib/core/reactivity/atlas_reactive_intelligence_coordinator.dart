import 'dart:async';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_filter.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_diagnostics.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_diagnostics_service.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_policy.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_target.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_update.dart';

typedef AtlasReactiveHandler = Future<void> Function(
  AtlasReactiveUpdate update,
);

class AtlasReactiveIntelligenceCoordinator {
  AtlasReactiveIntelligenceCoordinator({
    AtlasEventBus? eventBus,
    AtlasReactivePolicy policy = const AtlasReactivePolicy(),
    AtlasReactiveDiagnosticsService? diagnosticsService,
    this.debounceDuration = const Duration(milliseconds: 500),
  })  : _eventBus = eventBus ?? AtlasEventBus.instance,
        _policy = policy,
        _diagnostics =
            diagnosticsService ?? AtlasReactiveDiagnosticsService.instance;

  final AtlasEventBus _eventBus;
  final AtlasReactivePolicy _policy;
  final AtlasReactiveDiagnosticsService _diagnostics;
  final Duration debounceDuration;

  final Map<AtlasReactiveTarget, Map<String, AtlasReactiveHandler>> _handlers =
      <AtlasReactiveTarget, Map<String, AtlasReactiveHandler>>{};

  final List<AtlasEvent> _pending = <AtlasEvent>[];
  final Set<String> _pendingEventIds = <String>{};

  String? _subscriptionId;
  Timer? _timer;
  bool _executing = false;
  bool _queued = false;
  int _handlerSequence = 0;

  bool get isRunning => _subscriptionId != null;

  int get pendingEventCount => _pending.length;

  AtlasReactiveDiagnostics get diagnostics => _diagnostics.snapshot(
        isRunning: isRunning,
        pendingEvents: pendingEventCount,
      );

  String registerHandler({
    required AtlasReactiveTarget target,
    required AtlasReactiveHandler handler,
    String? owner,
  }) {
    _handlerSequence += 1;

    final registrationId =
        '${target.name}_${owner ?? 'handler'}_$_handlerSequence';

    final targetHandlers = _handlers.putIfAbsent(
      target,
      () => <String, AtlasReactiveHandler>{},
    );

    targetHandlers[registrationId] = handler;
    _diagnostics.registerHandler(target);

    return registrationId;
  }

  void unregisterHandler(
    AtlasReactiveTarget target,
  ) {
    final removedHandlers = _handlers.remove(target);

    if (removedHandlers == null) {
      return;
    }

    for (var index = 0; index < removedHandlers.length; index += 1) {
      _diagnostics.unregisterHandler(target);
    }
  }

  bool unregisterHandlerById({
    required AtlasReactiveTarget target,
    required String registrationId,
  }) {
    final targetHandlers = _handlers[target];

    if (targetHandlers == null) {
      return false;
    }

    final removed = targetHandlers.remove(registrationId) != null;

    if (!removed) {
      return false;
    }

    _diagnostics.unregisterHandler(target);

    if (targetHandlers.isEmpty) {
      _handlers.remove(target);
    }

    return true;
  }

  void start() {
    if (_subscriptionId != null) {
      return;
    }

    _subscriptionId = _eventBus.subscribe(
      owner: 'reactive_intelligence',
      filter: const AtlasEventFilter(),
      listener: _receive,
    );
  }

  void stop() {
    final id = _subscriptionId;

    if (id != null) {
      _eventBus.unsubscribe(id);
    }

    _subscriptionId = null;
    _timer?.cancel();
    _timer = null;
    _pending.clear();
    _pendingEventIds.clear();
    _queued = false;
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    await _executePending();
  }

  Future<void> _receive(
    AtlasEvent event,
  ) async {
    _diagnostics.recordReceivedEvent();

    if (!_pendingEventIds.add(event.id)) {
      _diagnostics.recordDuplicateEvent();
      return;
    }

    _pending.add(event);

    if (event.isCritical) {
      _diagnostics.recordCriticalFlush();
      await flush();
      return;
    }

    _timer?.cancel();
    _timer = Timer(
      debounceDuration,
      () => unawaited(_executePending()),
    );
  }

  Future<void> _executePending() async {
    if (_pending.isEmpty) {
      return;
    }

    if (_executing) {
      _queued = true;
      return;
    }

    _executing = true;

    final events = List<AtlasEvent>.from(_pending);
    _pending.clear();

    for (final event in events) {
      _pendingEventIds.remove(event.id);
    }

    final updateStopwatch = Stopwatch()..start();

    try {
      final update = _buildUpdate(events);
      _diagnostics.recordProcessedEvents(events.length);

      for (final target in update.targets) {
        final targetHandlers = _handlers[target];

        if (targetHandlers == null || targetHandlers.isEmpty) {
          continue;
        }

        final handlers = Map<String, AtlasReactiveHandler>.from(
          targetHandlers,
        );

        for (final handler in handlers.values) {
          final targetStopwatch = Stopwatch()..start();
          String? errorMessage;

          try {
            await handler(update);
          } catch (error) {
            errorMessage = error.toString();
          } finally {
            targetStopwatch.stop();
            _diagnostics.recordTargetExecution(
              target: target,
              duration: targetStopwatch.elapsed,
              error: errorMessage,
            );
          }
        }
      }
    } finally {
      updateStopwatch.stop();
      _diagnostics.recordUpdate(
        completedAt: DateTime.now(),
        duration: updateStopwatch.elapsed,
      );

      _executing = false;

      if (_queued || _pending.isNotEmpty) {
        _queued = false;
        await _executePending();
      }
    }
  }

  AtlasReactiveUpdate _buildUpdate(
    List<AtlasEvent> events,
  ) {
    final targets = <AtlasReactiveTarget>{};
    var priority = AtlasEventPriority.low;

    for (final event in events) {
      targets.addAll(_policy.targetsFor(event));

      if (_weight(event.priority) > _weight(priority)) {
        priority = event.priority;
      }
    }

    final now = DateTime.now();

    return AtlasReactiveUpdate(
      id: 'reactive_${now.microsecondsSinceEpoch}',
      createdAt: now,
      events: List<AtlasEvent>.unmodifiable(events),
      targets: Set<AtlasReactiveTarget>.unmodifiable(targets),
      priority: priority,
      reason: events.length == 1
          ? events.first.title
          : '${events.length} eventos agrupados.',
    );
  }

  int _weight(
    AtlasEventPriority priority,
  ) {
    switch (priority) {
      case AtlasEventPriority.low:
        return 1;
      case AtlasEventPriority.normal:
        return 2;
      case AtlasEventPriority.high:
        return 3;
      case AtlasEventPriority.critical:
        return 4;
    }
  }
}
