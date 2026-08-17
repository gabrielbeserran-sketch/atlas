import 'dart:async';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';

class AtlasEventObserver {
  AtlasEventObserver({AtlasEventBus? eventBus})
    : _eventBus = eventBus ?? AtlasEventBus.instance;

  final AtlasEventBus _eventBus;

  StreamSubscription<AtlasEvent>? _subscription;

  final List<AtlasEvent> _events = <AtlasEvent>[];

  List<AtlasEvent> get events {
    return List<AtlasEvent>.unmodifiable(_events);
  }

  bool get isListening {
    return _subscription != null;
  }

  void start({int maxItems = 100, void Function(AtlasEvent event)? onEvent}) {
    if (_subscription != null) {
      return;
    }

    _subscription = _eventBus.stream.listen((event) {
      _events.add(event);

      if (_events.length > maxItems) {
        _events.removeAt(0);
      }

      onEvent?.call(event);
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void clear() {
    _events.clear();
  }
}
