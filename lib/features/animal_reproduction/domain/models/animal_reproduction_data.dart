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
  bool get isInsemination =>
      eventCode == 'ai' ||
      eventCode == 'iatf' ||
      type == 'Inseminação artificial' ||
      type == 'IATF';
  bool get isPositivePregnancyDiagnosis =>
      eventCode == 'pregnancy_diagnosis' && reproductiveStatus == 'pregnant';
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
    'metadata_json': {},
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
