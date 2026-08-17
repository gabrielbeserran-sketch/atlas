import 'dart:async';
import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_filter.dart';
import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';
import 'package:projeto_atlas/features/digital_twin/domain/services/atlas_digital_twin_event_reducer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasDigitalTwinService {
  AtlasDigitalTwinService._();

  static final AtlasDigitalTwinService instance = AtlasDigitalTwinService._();

  static const String _storageKey = 'atlas_digital_twin_v1';

  final AtlasDigitalTwinEventReducer reducer =
      const AtlasDigitalTwinEventReducer();

  final Map<String, AtlasDigitalTwin> _twins = <String, AtlasDigitalTwin>{};

  final StreamController<AtlasDigitalTwin> _changesController =
      StreamController<AtlasDigitalTwin>.broadcast();

  String? _subscriptionId;
  bool _loaded = false;
  Future<void>? _loadingFuture;

  Stream<AtlasDigitalTwin> get changes => _changesController.stream;

  List<AtlasDigitalTwin> get twins {
    final result = _twins.values.toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));

    return List<AtlasDigitalTwin>.unmodifiable(result);
  }

  AtlasDigitalTwin? byFarmId(String farmId) {
    return _twins[farmId];
  }

  AtlasDigitalTwin? get primaryTwin {
    if (_twins.isEmpty) {
      return null;
    }

    return twins.first;
  }

  bool get isStarted => _subscriptionId != null;

  Future<void> start() async {
    await load();

    if (_subscriptionId != null) {
      return;
    }

    _subscriptionId = AtlasEventBus.instance.subscribe(
      owner: 'atlas_digital_twin',
      filter: const AtlasEventFilter(),
      listener: _handleEvent,
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

    _twins.clear();

    if (stored != null && stored.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);

        if (decoded is List) {
          for (final raw in decoded.whereType<Map>()) {
            final twin = AtlasDigitalTwin.fromJson(
              Map<String, dynamic>.from(raw),
            );

            _twins[twin.farmId] = twin;
          }
        }
      } catch (_) {
        _twins.clear();
      }
    }

    _loaded = true;
    _loadingFuture = null;
  }

  Future<void> _handleEvent(AtlasEvent event) async {
    final farmId = event.farmId?.trim().isNotEmpty == true
        ? event.farmId!
        : 'global';

    final farmName = event.farmName?.trim().isNotEmpty == true
        ? event.farmName!
        : 'Operação';

    final current =
        _twins[farmId] ??
        AtlasDigitalTwin.initial(farmId: farmId, farmName: farmName);

    final updated = reducer.reduce(current: current, event: event);

    if (identical(current, updated)) {
      return;
    }

    _twins[farmId] = updated;

    await _save();

    if (!_changesController.isClosed) {
      _changesController.add(updated);
    }
  }

  Future<void> resetFarm(String farmId) async {
    _twins.remove(farmId);
    await _save();
  }

  Future<void> clear() async {
    _twins.clear();

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(_twins.values.map((item) => item.toJson()).toList()),
    );
  }
}
