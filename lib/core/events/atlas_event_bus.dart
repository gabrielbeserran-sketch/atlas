import 'dart:async';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_filter.dart';
import 'package:projeto_atlas/core/events/atlas_event_subscription.dart';

class AtlasEventBus {
  AtlasEventBus._();

  static final AtlasEventBus instance = AtlasEventBus._();

  final Map<String, AtlasEventSubscription> _subscriptions =
      <String, AtlasEventSubscription>{};

  final List<AtlasEvent> _history = <AtlasEvent>[];

  final StreamController<AtlasEvent> _streamController =
      StreamController<AtlasEvent>.broadcast();

  int maxHistoryItems = 300;

  Stream<AtlasEvent> get stream {
    return _streamController.stream;
  }

  List<AtlasEvent> get history {
    return List<AtlasEvent>.unmodifiable(_history);
  }

  List<AtlasEventSubscription> get subscriptions {
    return List<AtlasEventSubscription>.unmodifiable(_subscriptions.values);
  }

  String subscribe({
    required AtlasEventListener listener,
    required String owner,
    AtlasEventFilter filter = const AtlasEventFilter(),
  }) {
    final id = _createId(prefix: 'subscription');

    _subscriptions[id] = AtlasEventSubscription(
      id: id,
      listener: listener,
      filter: filter,
      createdAt: DateTime.now(),
      owner: owner,
    );

    return id;
  }

  bool unsubscribe(String subscriptionId) {
    return _subscriptions.remove(subscriptionId) != null;
  }

  int unsubscribeOwner(String owner) {
    final ids = _subscriptions.values
        .where((item) => item.owner == owner)
        .map((item) => item.id)
        .toList();

    for (final id in ids) {
      _subscriptions.remove(id);
    }

    return ids.length;
  }

  Future<AtlasEventDispatchResult> publish(AtlasEvent event) async {
    _addToHistory(event);

    if (!_streamController.isClosed) {
      _streamController.add(event);
    }

    final matchingSubscriptions = _subscriptions.values.where((subscription) {
      return subscription.filter.matches(event);
    }).toList();

    final errors = <AtlasEventListenerError>[];

    var successCount = 0;

    for (final subscription in matchingSubscriptions) {
      try {
        await subscription.listener(event);

        successCount++;
      } catch (error, stackTrace) {
        errors.add(
          AtlasEventListenerError(
            subscriptionId: subscription.id,
            owner: subscription.owner,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    return AtlasEventDispatchResult(
      event: event,
      matchedListeners: matchingSubscriptions.length,
      successfulListeners: successCount,
      failedListeners: errors.length,
      errors: errors,
    );
  }

  Future<List<AtlasEventDispatchResult>> publishAll(
    Iterable<AtlasEvent> events,
  ) async {
    final results = <AtlasEventDispatchResult>[];

    for (final event in events) {
      results.add(await publish(event));
    }

    return results;
  }

  void publishDetached(AtlasEvent event) {
    unawaited(publish(event));
  }

  List<AtlasEvent> queryHistory({
    AtlasEventFilter filter = const AtlasEventFilter(),
    int? limit,
    bool newestFirst = true,
  }) {
    Iterable<AtlasEvent> result = _history.where(filter.matches);

    if (newestFirst) {
      result = result.toList().reversed;
    }

    if (limit != null && limit >= 0) {
      result = result.take(limit);
    }

    return result.toList();
  }

  void clearHistory() {
    _history.clear();
  }

  Future<void> dispose() async {
    _subscriptions.clear();
    _history.clear();

    await _streamController.close();
  }

  void _addToHistory(AtlasEvent event) {
    _history.add(event);

    if (_history.length > maxHistoryItems) {
      final overflow = _history.length - maxHistoryItems;

      _history.removeRange(0, overflow);
    }
  }

  String _createId({required String prefix}) {
    final now = DateTime.now().microsecondsSinceEpoch;

    return '${prefix}_$now';
  }
}

class AtlasEventDispatchResult {
  const AtlasEventDispatchResult({
    required this.event,
    required this.matchedListeners,
    required this.successfulListeners,
    required this.failedListeners,
    required this.errors,
  });

  final AtlasEvent event;

  final int matchedListeners;
  final int successfulListeners;
  final int failedListeners;

  final List<AtlasEventListenerError> errors;

  bool get hasErrors {
    return errors.isNotEmpty;
  }

  bool get wasHandled {
    return matchedListeners > 0;
  }
}

class AtlasEventListenerError {
  const AtlasEventListenerError({
    required this.subscriptionId,
    required this.owner,
    required this.error,
    required this.stackTrace,
  });

  final String subscriptionId;
  final String owner;

  final Object error;
  final StackTrace stackTrace;
}
