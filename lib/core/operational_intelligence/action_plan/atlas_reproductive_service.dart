import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_reproductive_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasReproductiveService {
  AtlasReproductiveService._();

  static final AtlasReproductiveService instance = AtlasReproductiveService._();

  static const String _protocolsKey = 'atlas_reproductive_protocols_v1';
  static const String _eventsKey = 'atlas_reproductive_events_v1';
  static const String _geneticsKey = 'atlas_genetic_animals_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasReproductiveProtocol>> loadProtocols({
    String? farmName,
  }) async {
    final encoded = await _preferences.getString(_protocolsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasReproductiveProtocol>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return _filterFarm(
        decoded
            .map(
              (item) => AtlasReproductiveProtocol.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        farmName,
        (item) => item.farmName,
      );
    } catch (_) {
      return <AtlasReproductiveProtocol>[];
    }
  }

  Future<void> saveProtocol(AtlasReproductiveProtocol protocol) async {
    final all = await _loadAllProtocols();
    final index = all.indexWhere((item) => item.id == protocol.id);
    if (index == -1) {
      all.add(protocol);
    } else {
      all[index] = protocol;
    }
    await _preferences.setString(
      _protocolsKey,
      jsonEncode(all.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> deleteProtocol(String id) async {
    final all = await _loadAllProtocols()
      ..removeWhere((item) => item.id == id);
    await _preferences.setString(
      _protocolsKey,
      jsonEncode(all.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<AtlasReproductiveEvent>> loadEvents({String? farmName}) async {
    final encoded = await _preferences.getString(_eventsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasReproductiveEvent>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final items = decoded
          .map(
            (item) => AtlasReproductiveEvent.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final filtered = _filterFarm(items, farmName, (item) => item.farmName);
      filtered.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return filtered;
    } catch (_) {
      return <AtlasReproductiveEvent>[];
    }
  }

  Future<void> saveEvent(AtlasReproductiveEvent event) async {
    final all = await _loadAllEvents();
    final index = all.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      all.add(event);
    } else {
      all[index] = event;
    }
    await _preferences.setString(
      _eventsKey,
      jsonEncode(all.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> deleteEvent(String id) async {
    final all = await _loadAllEvents()
      ..removeWhere((item) => item.id == id);
    await _preferences.setString(
      _eventsKey,
      jsonEncode(all.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<AtlasGeneticAnimal>> loadGenetics({String? farmName}) async {
    final encoded = await _preferences.getString(_geneticsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasGeneticAnimal>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final items = decoded
          .map(
            (item) => AtlasGeneticAnimal.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final filtered = _filterFarm(items, farmName, (item) => item.farmName);
      filtered.sort((a, b) => b.rankingScore.compareTo(a.rankingScore));
      return filtered;
    } catch (_) {
      return <AtlasGeneticAnimal>[];
    }
  }

  Future<void> saveGeneticAnimal(AtlasGeneticAnimal animal) async {
    final all = await _loadAllGenetics();
    final index = all.indexWhere((item) => item.id == animal.id);
    if (index == -1) {
      all.add(animal);
    } else {
      all[index] = animal;
    }
    await _preferences.setString(
      _geneticsKey,
      jsonEncode(all.map((item) => item.toMap()).toList()),
    );
  }

  AtlasReproductiveSummary buildSummary(List<AtlasReproductiveEvent> events) {
    final services = events.where((event) {
      return event.type == AtlasReproductiveEventType.insemination ||
          event.type == AtlasReproductiveEventType.fixedTimeAi ||
          event.type == AtlasReproductiveEventType.naturalMating ||
          event.type == AtlasReproductiveEventType.embryoTransfer;
    }).length;
    final diagnoses = events
        .where(
          (event) =>
              event.type == AtlasReproductiveEventType.pregnancyDiagnosis,
        )
        .length;
    final positives = events.where((event) => event.isPositivePregnancy).length;
    final negatives = events.where((event) => event.isNegativePregnancy).length;
    final calvings = events
        .where((event) => event.type == AtlasReproductiveEventType.calving)
        .length;
    final abortions = events
        .where((event) => event.type == AtlasReproductiveEventType.abortion)
        .length;
    final pregnancyRate = diagnoses == 0 ? 0.0 : positives / diagnoses * 100;
    final conceptionRate = services == 0 ? 0.0 : positives / services * 100;
    final repeatRate = services == 0 ? 0.0 : negatives / services * 100;

    return AtlasReproductiveSummary(
      totalServices: services,
      pregnancyDiagnoses: diagnoses,
      positivePregnancies: positives,
      negativePregnancies: negatives,
      calvings: calvings,
      abortions: abortions,
      pregnancyRatePercent: pregnancyRate,
      conceptionRatePercent: conceptionRate,
      repeatRatePercent: repeatRate,
      projectedCalvings: positives,
    );
  }

  List<DateTime> projectedCalvingDates(List<AtlasReproductiveEvent> events) {
    return events
        .where((event) => event.isPositivePregnancy)
        .map((event) => event.occurredAt.add(const Duration(days: 285)))
        .toList()
      ..sort();
  }

  List<String> buildAlerts(List<AtlasReproductiveEvent> events) {
    final alerts = <String>[];
    final now = DateTime.now();

    for (final event in events) {
      if (event.isPositivePregnancy) {
        final projected = event.occurredAt.add(const Duration(days: 285));
        final days = projected.difference(now).inDays;
        if (days >= 0 && days <= 30) {
          alerts.add(
            '${event.animalName.isEmpty ? event.animalId : event.animalName}: '
            'parto previsto em $days dia(s).',
          );
        }
      }
      if (event.isNegativePregnancy) {
        alerts.add(
          '${event.animalName.isEmpty ? event.animalId : event.animalName}: '
          'diagnóstico negativo; avaliar repetição ou descarte.',
        );
      }
    }

    if (alerts.isEmpty) {
      alerts.add('Nenhum alerta reprodutivo crítico no momento.');
    }
    return alerts;
  }

  Future<List<AtlasReproductiveProtocol>> _loadAllProtocols() async {
    final encoded = await _preferences.getString(_protocolsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasReproductiveProtocol>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map(
            (item) => AtlasReproductiveProtocol.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasReproductiveProtocol>[];
    }
  }

  Future<List<AtlasReproductiveEvent>> _loadAllEvents() async {
    final encoded = await _preferences.getString(_eventsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasReproductiveEvent>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map(
            (item) => AtlasReproductiveEvent.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasReproductiveEvent>[];
    }
  }

  Future<List<AtlasGeneticAnimal>> _loadAllGenetics() async {
    final encoded = await _preferences.getString(_geneticsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasGeneticAnimal>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map(
            (item) => AtlasGeneticAnimal.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasGeneticAnimal>[];
    }
  }

  List<T> _filterFarm<T>(
    List<T> items,
    String? farmName,
    String? Function(T item) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return items;
    }
    return items.where((item) {
      return readFarm(item)?.trim().toLowerCase() == normalized;
    }).toList();
  }
}
