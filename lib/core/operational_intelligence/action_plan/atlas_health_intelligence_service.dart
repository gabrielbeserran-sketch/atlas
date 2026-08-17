import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_health_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasHealthIntelligenceService {
  AtlasHealthIntelligenceService._();

  static final AtlasHealthIntelligenceService instance =
      AtlasHealthIntelligenceService._();

  static const String _protocolsKey = 'atlas_health_protocols_v1';
  static const String _medicationsKey = 'atlas_health_medications_v1';
  static const String _eventsKey = 'atlas_health_events_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasHealthProtocol>> loadProtocols({String? farmName}) async {
    final encoded = await _preferences.getString(_protocolsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasHealthProtocol>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return _filter(
        decoded
            .map(
              (item) => AtlasHealthProtocol.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        farmName,
        (item) => item.farmName,
      );
    } catch (_) {
      return <AtlasHealthProtocol>[];
    }
  }

  Future<void> saveProtocol(AtlasHealthProtocol protocol) async {
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

  Future<List<AtlasMedication>> loadMedications({String? farmName}) async {
    final encoded = await _preferences.getString(_medicationsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasMedication>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return _filter(
        decoded
            .map(
              (item) => AtlasMedication.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        farmName,
        (item) => item.farmName,
      );
    } catch (_) {
      return <AtlasMedication>[];
    }
  }

  Future<void> saveMedication(AtlasMedication medication) async {
    final all = await _loadAllMedications();
    final index = all.indexWhere((item) => item.id == medication.id);
    if (index == -1) {
      all.add(medication);
    } else {
      all[index] = medication;
    }
    await _preferences.setString(
      _medicationsKey,
      jsonEncode(all.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<AtlasHealthEvent>> loadEvents({String? farmName}) async {
    final encoded = await _preferences.getString(_eventsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasHealthEvent>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final items = _filter(
        decoded
            .map(
              (item) => AtlasHealthEvent.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        farmName,
        (item) => item.farmName,
      );
      items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return items;
    } catch (_) {
      return <AtlasHealthEvent>[];
    }
  }

  Future<void> saveEvent(AtlasHealthEvent event) async {
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

  AtlasHealthSummary buildSummary({
    required List<AtlasHealthEvent> events,
    required List<AtlasMedication> medications,
    required List<AtlasHealthProtocol> protocols,
  }) {
    final animalIds = events
        .map((event) => event.animalId)
        .where((value) => value.trim().isNotEmpty)
        .toSet();
    final denominator = animalIds.isEmpty ? events.length : animalIds.length;
    final morbidity = events
        .where((event) => event.type == AtlasHealthEventType.morbidity)
        .length;
    final mortality = events
        .where((event) => event.type == AtlasHealthEventType.mortality)
        .length;
    final alerts = buildAlerts(
      events: events,
      medications: medications,
      protocols: protocols,
    );

    return AtlasHealthSummary(
      totalEvents: events.length,
      vaccinations: events
          .where((event) => event.type == AtlasHealthEventType.vaccination)
          .length,
      treatments: events
          .where((event) => event.type == AtlasHealthEventType.treatment)
          .length,
      morbidityCases: morbidity,
      mortalityCases: mortality,
      morbidityRatePercent: denominator == 0
          ? 0
          : morbidity / denominator * 100,
      mortalityRatePercent: denominator == 0
          ? 0
          : mortality / denominator * 100,
      totalCost: events.fold<double>(0, (total, event) => total + event.cost),
      activeAlerts: alerts.length,
    );
  }

  List<String> buildAlerts({
    required List<AtlasHealthEvent> events,
    required List<AtlasMedication> medications,
    required List<AtlasHealthProtocol> protocols,
  }) {
    final alerts = <String>[];
    final now = DateTime.now();

    for (final protocol in protocols.where((item) => item.active)) {
      final days = protocol.nextDueAt.difference(now).inDays;
      if (days < 0) {
        alerts.add('Protocolo "${protocol.name}" está atrasado.');
      } else if (days <= 15) {
        alerts.add('Protocolo "${protocol.name}" vence em $days dia(s).');
      }
    }

    for (final medication in medications) {
      if (medication.isExpired) {
        alerts.add('Medicamento "${medication.name}" está vencido.');
      } else if (medication.expiresSoon) {
        alerts.add('Medicamento "${medication.name}" vence em até 30 dias.');
      }
      if (medication.quantity <= 0) {
        alerts.add('Medicamento "${medication.name}" está sem estoque.');
      }
    }

    final recentMortality = events.where((event) {
      return event.type == AtlasHealthEventType.mortality &&
          now.difference(event.occurredAt).inDays <= 30;
    }).length;
    if (recentMortality >= 2) {
      alerts.add('$recentMortality mortes registradas nos últimos 30 dias.');
    }

    if (alerts.isEmpty) {
      alerts.add('Nenhum alerta sanitário crítico no momento.');
    }
    return alerts;
  }

  Map<String, int> epidemiologyByDiagnosis(List<AtlasHealthEvent> events) {
    final result = <String, int>{};
    for (final event in events) {
      final key = event.diagnosis.trim().isEmpty
          ? atlasHealthEventTypeLabel(event.type)
          : event.diagnosis.trim();
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  Map<String, int> healthMapByLocation(List<AtlasHealthEvent> events) {
    final result = <String, int>{};
    for (final event in events) {
      final location = event.paddockName.trim().isNotEmpty
          ? event.paddockName.trim()
          : event.lotName.trim().isNotEmpty
          ? event.lotName.trim()
          : 'Local não informado';
      result[location] = (result[location] ?? 0) + 1;
    }
    return result;
  }

  Future<List<AtlasHealthProtocol>> _loadAllProtocols() async {
    final encoded = await _preferences.getString(_protocolsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasHealthProtocol>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map(
            (item) => AtlasHealthProtocol.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasHealthProtocol>[];
    }
  }

  Future<List<AtlasMedication>> _loadAllMedications() async {
    final encoded = await _preferences.getString(_medicationsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasMedication>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                AtlasMedication.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return <AtlasMedication>[];
    }
  }

  Future<List<AtlasHealthEvent>> _loadAllEvents() async {
    final encoded = await _preferences.getString(_eventsKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasHealthEvent>[];
    }
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map(
            (item) => AtlasHealthEvent.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasHealthEvent>[];
    }
  }

  List<T> _filter<T>(
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
