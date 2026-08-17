import 'dart:async';
import 'dart:convert';

import 'package:projeto_atlas/core/event_center/atlas_event_log_entry.dart';
import 'package:projeto_atlas/core/event_center/atlas_event_log_filter.dart';
import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasEventLogService {
  AtlasEventLogService._();

  static final AtlasEventLogService instance = AtlasEventLogService._();

  static const String _storageKey = 'atlas_event_center_log_v1';

  final List<AtlasEventLogEntry> _entries = <AtlasEventLogEntry>[];

  String? _subscriptionId;
  bool _loaded = false;
  Future<void>? _loadingFuture;

  int maxItems = 1000;

  bool get isStarted => _subscriptionId != null;

  bool get isLoaded => _loaded;

  List<AtlasEventLogEntry> get entries {
    return List<AtlasEventLogEntry>.unmodifiable(_entries.reversed);
  }

  Future<void> start() async {
    await load();

    if (_subscriptionId != null) {
      return;
    }

    _subscriptionId = AtlasEventBus.instance.subscribe(
      owner: 'atlas_event_center',
      filter: const AtlasEventFilter(),
      listener: _recordEvent,
    );
  }

  void stop() {
    final id = _subscriptionId;

    if (id != null) {
      AtlasEventBus.instance.unsubscribe(id);
    }

    _subscriptionId = null;
  }

  Future<void> load() {
    if (_loaded) {
      return Future<void>.value();
    }

    final current = _loadingFuture;

    if (current != null) {
      return current;
    }

    final future = _loadInternal();
    _loadingFuture = future;

    return future;
  }

  Future<void> _loadInternal() async {
    final preferences = await SharedPreferences.getInstance();

    final stored = preferences.getString(_storageKey);

    _entries.clear();

    if (stored != null && stored.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);

        if (decoded is List) {
          final loaded =
              decoded.whereType<Map>().map((item) {
                return AtlasEventLogEntry.fromJson(
                  Map<String, dynamic>.from(item),
                );
              }).toList()..sort(
                (first, second) =>
                    first.recordedAt.compareTo(second.recordedAt),
              );

          _entries.addAll(
            loaded.length > maxItems
                ? loaded.sublist(loaded.length - maxItems)
                : loaded,
          );
        }
      } catch (_) {
        _entries.clear();
      }
    }

    _loaded = true;
    _loadingFuture = null;
  }

  Future<void> _recordEvent(AtlasEvent event) async {
    final duplicate = _entries.any((item) => item.eventId == event.id);

    if (duplicate) {
      return;
    }

    _entries.add(AtlasEventLogEntry.fromEvent(event));

    if (_entries.length > maxItems) {
      _entries.removeRange(0, _entries.length - maxItems);
    }

    await _save();
  }

  List<AtlasEventLogEntry> query({
    AtlasEventLogFilter filter = const AtlasEventLogFilter(),
    int? limit,
  }) {
    Iterable<AtlasEventLogEntry> result = entries.where(filter.matches);

    if (limit != null && limit >= 0) {
      result = result.take(limit);
    }

    return result.toList();
  }

  Future<void> clear() async {
    _entries.clear();

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        _entries.map((item) {
          return item.toJson();
        }).toList(),
      ),
    );
  }
}
