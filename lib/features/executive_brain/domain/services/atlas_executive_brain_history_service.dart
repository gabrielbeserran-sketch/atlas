import 'dart:async';
import 'dart:convert';

import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutiveBrainHistoryService {
  AtlasExecutiveBrainHistoryService._();

  static final AtlasExecutiveBrainHistoryService instance =
      AtlasExecutiveBrainHistoryService._();

  static const String _storageKey =
      'atlas_executive_brain_history_v1';

  final List<AtlasExecutiveBrainHistoryEntry> _entries =
      <AtlasExecutiveBrainHistoryEntry>[];

  int maxItems = 200;

  bool _loaded = false;
  Future<void>? _loadingFuture;

  bool get isLoaded => _loaded;

  List<AtlasExecutiveBrainHistoryEntry> get entries {
    return List<AtlasExecutiveBrainHistoryEntry>.unmodifiable(
      _entries.reversed,
    );
  }

  AtlasExecutiveBrainHistoryEntry? get latest {
    return _entries.isEmpty ? null : _entries.last;
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
          final loaded = decoded
              .whereType<Map>()
              .map(
                (item) => AtlasExecutiveBrainHistoryEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
            ..sort(
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

  void add(AtlasExecutiveBrainHistoryEntry entry) {
    _entries.add(entry);

    if (_entries.length > maxItems) {
      _entries.removeRange(0, _entries.length - maxItems);
    }

    unawaited(_save());
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
        _entries.map((item) => item.toJson()).toList(),
      ),
    );
  }
}
