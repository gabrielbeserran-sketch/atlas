import 'dart:convert';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/farm_agenda/domain/models/farm_agenda_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmAgendaStorageService {
  FarmAgendaStorageService({AtlasHttpClient? httpClient})
    : _http = httpClient ?? AtlasHttpClient();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasHttpClient _http;

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  String _createStorageKey(String farmName) =>
      'atlas_farm_agenda_${_normalize(farmName)}';

  Future<List<FarmAgendaData>> loadTasks(
    String farmName, {
    String farmId = '',
  }) async {
    final key = _createStorageKey(farmName);
    final resolvedFarmId = farmId.trim().isNotEmpty
        ? farmId.trim()
        : await _resolveFarmId(farmName);
    if (resolvedFarmId.isNotEmpty) {
      try {
        final remote = await _fetchRemoteTasks(resolvedFarmId);
        await _saveLocal(key, remote);
        return remote;
      } catch (_) {
        // Contingência offline: usa o cache persistido.
      }
    }
    return _loadLocal(key);
  }

  Future<FarmAgendaData> createTask({
    required String farmName,
    required String farmId,
    required FarmAgendaData task,
  }) async {
    final response = await _http.send(
      'POST',
      '/operations/tasks',
      body: _toCreateApi(task, farmId),
    );
    final created = _fromApi(response.asMap(), fallback: task);

    // Confirma persistência por uma segunda leitura do servidor.
    final remote = await _fetchRemoteTasks(farmId);
    final saved = remote.firstWhere(
      (item) => item.id == created.id,
      orElse: () => throw StateError(
        'O servidor respondeu à criação, mas o compromisso não foi encontrado ao recarregar a Agenda.',
      ),
    );
    await _saveLocal(_createStorageKey(farmName), remote);
    return saved;
  }

  Future<FarmAgendaData> updateTask({
    required String farmName,
    required String farmId,
    required FarmAgendaData task,
  }) async {
    await _http.send(
      'PATCH',
      '/operations/tasks/${task.id}',
      body: _toUpdateApi(task),
    );

    // Não confia apenas no PATCH: confirma a gravação por nova leitura.
    final remote = await _fetchRemoteTasks(farmId);
    final saved = remote.firstWhere(
      (item) => item.id == task.id,
      orElse: () => throw StateError(
        'A alteração foi enviada, mas o compromisso não foi encontrado ao recarregar a Agenda.',
      ),
    );
    await _saveLocal(_createStorageKey(farmName), remote);
    return saved;
  }

  Future<List<FarmAgendaData>> _fetchRemoteTasks(String farmId) async {
    final all = <FarmAgendaData>[];
    for (final status in const [
      'open',
      'in_progress',
      'completed',
      'cancelled',
    ]) {
      final response = await _http.send(
        'GET',
        '/operations/tasks',
        queryParameters: {'farm_id': farmId, 'status': status},
      );
      all.addAll(response.asMapList().map(_fromApi));
    }
    return <String, FarmAgendaData>{
      for (final item in all) item.id: item,
    }.values.toList();
  }

  Future<void> cancelTask({
    required String farmName,
    required FarmAgendaData task,
  }) async {
    await _http.send(
      'PATCH',
      '/operations/tasks/${task.id}',
      body: {'status': 'cancelled'},
    );
    final local = await _loadLocal(_createStorageKey(farmName));
    local.removeWhere((item) => item.id == task.id);
    await _saveLocal(_createStorageKey(farmName), local);
  }

  Future<void> saveTasks({
    required String farmName,
    required List<FarmAgendaData> tasks,
  }) async => _saveLocal(_createStorageKey(farmName), tasks);

  Future<List<FarmAgendaData>> _loadLocal(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) =>
                FarmAgendaData.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal(String key, List<FarmAgendaData> tasks) =>
      _preferences.setString(
        key,
        jsonEncode(tasks.map((task) => task.toMap()).toList()),
      );

  Future<String> _resolveFarmId(String farmName) async {
    try {
      final response = await _http.send('GET', '/farms');
      final normalized = farmName.trim().toLowerCase();
      for (final item in response.asMapList()) {
        if ((item['name']?.toString().trim().toLowerCase() ?? '') ==
            normalized) {
          return item['id']?.toString() ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  Map<String, dynamic> _toCreateApi(FarmAgendaData task, String farmId) => {
    'farm_id': farmId,
    'source_type': task.sourceType.trim().isNotEmpty
        ? task.sourceType.trim()
        : task.category,
    'source_id': task.sourceId,
    'title': task.title,
    'description': _description(task),
    'priority': _priorityToApi(task.priority),
    'due_at': _dueAt(task),
  };

  Map<String, dynamic> _toUpdateApi(FarmAgendaData task) => {
    'source_type': task.sourceType.trim().isNotEmpty
        ? task.sourceType.trim()
        : task.category,
    'title': task.title,
    'description': _description(task),
    'priority': _priorityToApi(task.priority),
    'due_at': _dueAt(task),
    'status': _statusToApi(task.status),
  };

  FarmAgendaData _fromApi(
    Map<String, dynamic> map, {
    FarmAgendaData? fallback,
  }) {
    final due = DateTime.tryParse(map['due_at']?.toString() ?? '')?.toLocal();
    final rawDescription =
        map['description']?.toString() ?? fallback?.notes ?? '';
    final parsedResponsible = _responsibleFromDescription(rawDescription);
    final parsedNotes = _notesFromDescription(rawDescription);
    return FarmAgendaData(
      id: map['id']?.toString() ?? fallback?.id ?? '',
      title: map['title']?.toString() ?? fallback?.title ?? 'Compromisso',
      category: _categoryFromSource(
        map['source_type']?.toString() ?? fallback?.sourceType ?? '',
        fallback?.category ?? 'Outro',
      ),
      date: due == null ? (fallback?.date ?? '') : _formatDate(due),
      time: due == null
          ? (fallback?.time ?? '')
          : '${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}',
      responsible: (fallback?.responsible.trim().isNotEmpty ?? false)
          ? fallback!.responsible.trim()
          : parsedResponsible,
      priority: _priorityFromApi(map['priority']?.toString() ?? ''),
      status: _statusFromApi(map['status']?.toString() ?? ''),
      notes: parsedNotes,
      sourceType:
          map['source_type']?.toString() ?? fallback?.sourceType ?? '',
      sourceId: map['source_id']?.toString() ?? fallback?.sourceId ?? '',
    );
  }

  String _description(FarmAgendaData task) {
    final cleanNotes = _notesFromDescription(task.notes).trim();
    final responsible = task.responsible.trim();
    if (responsible.isEmpty) {
      return cleanNotes;
    }
    final suffix = 'Responsável: $responsible';
    return cleanNotes.isEmpty ? suffix : '$cleanNotes\n$suffix';
  }

  String _responsibleFromDescription(String value) {
    final lines = value.split(RegExp(r'\r?\n'));
    for (final line in lines.reversed) {
      final match = RegExp(
        r'^\s*Respons[aá]vel\s*:\s*(.+?)\s*$',
        caseSensitive: false,
      ).firstMatch(line);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    return '';
  }

  String _notesFromDescription(String value) {
    final kept = <String>[];
    for (final line in value.split(RegExp(r'\r?\n'))) {
      if (RegExp(
        r'^\s*Respons[aá]vel\s*:',
        caseSensitive: false,
      ).hasMatch(line)) {
        continue;
      }
      kept.add(line);
    }
    return kept.join('\n').trim();
  }

  String _categoryFromSource(String sourceType, String fallback) {
    switch (sourceType.trim().toLowerCase()) {
      case 'reproduction_event':
        return 'Reprodução';
      case 'health_event':
        return 'Sanidade';
      case 'nutrition_plan':
      case 'nutrition_event':
        return 'Nutrição';
      case 'inventory_movement':
        return 'Estoque';
      default:
        return sourceType.trim().isEmpty ? fallback : sourceType;
    }
  }

  String _priorityToApi(String value) {
    final v = value.toLowerCase();
    if (v.contains('urgent')) {
      return 'urgent';
    }
    if (v.contains('alta')) {
      return 'high';
    }
    if (v.contains('baixa')) {
      return 'low';
    }
    return 'medium';
  }

  String _priorityFromApi(String value) {
    switch (value.toLowerCase()) {
      case 'urgent':
        return 'Urgente';
      case 'high':
        return 'Alta';
      case 'low':
        return 'Baixa';
      default:
        return 'Normal';
    }
  }

  String _statusToApi(String value) {
    final v = value.toLowerCase();
    if (v.contains('conclu')) {
      return 'completed';
    }
    if (v.contains('andamento')) {
      return 'in_progress';
    }
    if (v.contains('cancel')) {
      return 'cancelled';
    }
    return 'open';
  }

  String _statusFromApi(String value) {
    switch (value.toLowerCase()) {
      case 'completed':
        return 'Concluída';
      case 'in_progress':
        return 'Em andamento';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Pendente';
    }
  }

  String? _dueAt(FarmAgendaData task) {
    final match = RegExp(
      r'^(\d{2})/(\d{2})/(\d{4})$',
    ).firstMatch(task.date.trim());
    if (match == null) {
      return DateTime.tryParse(task.date)?.toUtc().toIso8601String();
    }
    var hour = 12;
    var minute = 0;
    final time = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(task.time.trim());
    if (time != null) {
      hour = int.tryParse(time.group(1)!) ?? hour;
      minute = int.tryParse(time.group(2)!) ?? minute;
    }
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
      hour,
      minute,
    ).toUtc().toIso8601String();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
