class AnimalReproductionData {
  const AnimalReproductionData({
    required this.id,
    required this.type,
    required this.date,
    required this.result,
    required this.bullOrSemen,
    required this.responsible,
    required this.notes,
    this.eventCode = 'observation',
    this.protocolName = '',
    this.protocolStage = '',
    this.expectedDate = '',
    this.reproductiveStatus = '',
    this.attemptNumber = 0,
    this.pregnancyDays = 0,
    this.calfId = '',
    this.calfSex = '',
    this.birthType = '',
    this.synced = false,
    this.animalId = '',
    this.metadata = const {},
  });
  final String id,
      type,
      date,
      result,
      bullOrSemen,
      responsible,
      notes,
      eventCode,
      protocolName,
      protocolStage,
      expectedDate,
      reproductiveStatus,
      calfId,
      calfSex,
      birthType;
  final int attemptNumber, pregnancyDays;
  final bool synced;
  final String animalId;
  final Map<String, dynamic> metadata;
  bool get hasConfirmedReturnResolution {
    final raw = metadata['atlas_return_resolution'];
    return returnResolutionStatus != null &&
        raw is Map &&
        raw['authenticated_user_id'] is String &&
        (raw['authenticated_user_id'] as String).trim().isNotEmpty;
  }

  /// Somente resolução explícita vinculada a este evento e previsão.
  String? get returnResolutionStatus {
    final raw = metadata['atlas_return_resolution'];
    if (raw is! Map || id.trim().isEmpty || expectedDate.trim().isEmpty) {
      return null;
    }
    final status = raw['status'];
    final at = raw['resolved_at'];
    final actor = raw['responsible'];
    if (!_validDisplayDate(date) || !_validDisplayDate(expectedDate)) {
      return null;
    }
    if (!{'completed', 'cancelled'}.contains(status) ||
        raw['event_id'] != id ||
        raw['occurred_date'] != _display(date) ||
        raw['expected_date'] != _display(expectedDate) ||
        actor is! String ||
        actor.trim().isEmpty ||
        at is! String) {
      return null;
    }
    final parsed = DateTime.tryParse(at);
    if (parsed == null ||
        parsed.toUtc().toIso8601String() != at ||
        parsed.isAfter(DateTime.now())) {
      return null;
    }
    if (status == 'cancelled' &&
        (raw['reason'] is! String ||
            (raw['reason'] as String).trim().isEmpty)) {
      return null;
    }
    return status as String;
  }

  bool get isInsemination =>
      eventCode == 'ai' ||
      eventCode == 'iatf' ||
      type == 'Inseminação artificial' ||
      type == 'IATF';

  /// Interpretação somente para leitura; não altera o registro persistido.
  String? get normalizedDiagnosisStatus =>
      switch (reproductiveStatus.trim().toLowerCase()) {
        'pregnant' || 'prenhe' => 'pregnant',
        'open' || 'vazia' => 'open',
        _ => null,
      };
  bool get isPositivePregnancyDiagnosis =>
      eventCode == 'pregnancy_diagnosis' &&
      normalizedDiagnosisStatus == 'pregnant';
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'date': date,
    'result': result,
    'bullOrSemen': bullOrSemen,
    'responsible': responsible,
    'notes': notes,
    'eventCode': eventCode,
    'protocolName': protocolName,
    'protocolStage': protocolStage,
    'expectedDate': expectedDate,
    'reproductiveStatus': reproductiveStatus,
    'attemptNumber': attemptNumber,
    'pregnancyDays': pregnancyDays,
    'calfId': calfId,
    'calfSex': calfSex,
    'birthType': birthType,
    'synced': synced,
    'animalId': animalId,
    'metadata': metadata,
  };
  Map<String, dynamic> toApi() => {
    'event_type': type,
    'event_code': eventCodeFor(type, eventCode),
    'protocol_name': protocolName,
    'protocol_stage': protocolStage,
    'sire_reference': bullOrSemen,
    'result': result,
    'reproductive_status': reproductiveStatus,
    'responsible': responsible,
    'attempt_number': attemptNumber,
    'pregnancy_days': pregnancyDays,
    'calf_id': calfId,
    'calf_sex': calfSex,
    'birth_type': birthType,
    'occurred_at': _toIso(date),
    'expected_date': expectedDate.isEmpty ? null : _toIso(expectedDate),
    'notes': notes,
    'metadata_json': metadata,
  };
  factory AnimalReproductionData.fromMap(Map<String, dynamic> m) =>
      AnimalReproductionData(
        id: '${m['id'] ?? ''}',
        type: '${m['type'] ?? m['event_type'] ?? 'Observação'}',
        date: _display('${m['date'] ?? m['occurred_at'] ?? ''}'),
        result: '${m['result'] ?? ''}',
        bullOrSemen: '${m['bullOrSemen'] ?? m['sire_reference'] ?? ''}',
        responsible: '${m['responsible'] ?? ''}',
        notes: '${m['notes'] ?? ''}',
        eventCode: '${m['eventCode'] ?? m['event_code'] ?? 'observation'}',
        protocolName: '${m['protocolName'] ?? m['protocol_name'] ?? ''}',
        protocolStage: '${m['protocolStage'] ?? m['protocol_stage'] ?? ''}',
        expectedDate: _display(
          '${m['expectedDate'] ?? m['expected_date'] ?? ''}',
        ),
        reproductiveStatus:
            '${m['reproductiveStatus'] ?? m['reproductive_status'] ?? ''}',
        attemptNumber: _i(m['attemptNumber'] ?? m['attempt_number']),
        pregnancyDays: _i(m['pregnancyDays'] ?? m['pregnancy_days']),
        calfId: '${m['calfId'] ?? m['calf_id'] ?? ''}',
        calfSex: '${m['calfSex'] ?? m['calf_sex'] ?? ''}',
        birthType: '${m['birthType'] ?? m['birth_type'] ?? ''}',
        synced: m['synced'] == true || m.containsKey('event_type'),
        animalId: '${m['animalId'] ?? m['animal_id'] ?? ''}',
        metadata: Map<String, dynamic>.from(
          (m['metadata'] ?? m['metadata_json']) is Map
              ? (m['metadata'] ?? m['metadata_json']) as Map
              : const {},
        ),
      );

  AnimalReproductionData withAnimalId(String value) => AnimalReproductionData(
    id: id,
    type: type,
    date: date,
    result: result,
    bullOrSemen: bullOrSemen,
    responsible: responsible,
    notes: notes,
    eventCode: eventCode,
    protocolName: protocolName,
    protocolStage: protocolStage,
    expectedDate: expectedDate,
    reproductiveStatus: reproductiveStatus,
    attemptNumber: attemptNumber,
    pregnancyDays: pregnancyDays,
    calfId: calfId,
    calfSex: calfSex,
    birthType: birthType,
    synced: synced,
    animalId: value,
    metadata: metadata,
  );
  static String eventCodeFor(String type, String current) {
    if (current != 'observation') return current;
    const x = {
      'Cio': 'estrus',
      'Inseminação artificial': 'ai',
      'IATF': 'iatf',
      'Monta natural': 'natural_service',
      'Diagnóstico de gestação': 'pregnancy_diagnosis',
      'Parto': 'calving',
      'Aborto': 'abortion',
      'Repetição de cio': 'repeat_estrus',
      'Descarte reprodutivo': 'reproductive_cull',
      'Protocolo hormonal': 'hormonal_protocol',
    };
    return x[type] ?? 'observation';
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static bool _validDisplayDate(String value) {
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(_display(value));
    if (match == null) {
      return false;
    }
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
      return false;
    }
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }

  static String _toIso(String v) {
    final p = v.split('/');
    if (p.length != 3) return v;
    return DateTime(
      int.parse(p[2]),
      int.parse(p[1]),
      int.parse(p[0]),
    ).toUtc().toIso8601String();
  }

  static String _display(String v) {
    if (v.isEmpty || !v.contains('-')) return v;
    final d = DateTime.tryParse(v);
    return d == null
        ? v
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
