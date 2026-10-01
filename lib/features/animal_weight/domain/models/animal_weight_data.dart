class AnimalWeightData {
  const AnimalWeightData({
    required this.id,
    required this.date,
    required this.weight,
    required this.notes,
    this.bodyConditionScore = 0,
    this.source = '',
    this.equipment = '',
    this.isRemote = false,
    this.clientOperationId = '',
  });

  final String id;
  final String date;
  final double weight;
  final String notes;
  final double bodyConditionScore;
  final String source;
  final String equipment;
  final bool isRemote;
  final String clientOperationId;

  bool isValidForIndicators(DateTime now) {
    final measuredOn = tryParseLocalDate(date);
    return measuredOn != null &&
        !measuredOn.isAfter(DateTime(now.year, now.month, now.day)) &&
        weight.isFinite &&
        weight > 0;
  }

  bool sameMeasurementAs(AnimalWeightData other) =>
      date == other.date &&
      (weight - other.weight).abs() < 1e-9 &&
      (bodyConditionScore - other.bodyConditionScore).abs() < 1e-9 &&
      notes.trim() == other.notes.trim() &&
      source.trim() == other.source.trim() &&
      equipment.trim() == other.equipment.trim();

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'weight': weight,
    'notes': notes,
    'bodyConditionScore': bodyConditionScore,
    'source': source,
    'equipment': equipment,
    'isRemote': isRemote,
    'clientOperationId': clientOperationId,
  };

  Map<String, dynamic> toRemoteBody() {
    final measuredAt = _toIsoDate(date);
    if (!weight.isFinite || weight <= 0) {
      throw const FormatException('Peso da pesagem inválido.');
    }
    if (!bodyConditionScore.isFinite ||
        bodyConditionScore < 0 ||
        bodyConditionScore > 5) {
      throw const FormatException('Escore corporal inválido.');
    }
    return {
      'weight': weight,
      'body_condition_score': bodyConditionScore,
      'source': source.trim(),
      'equipment': equipment.trim(),
      'measured_at': measuredAt,
      'notes': notes.trim(),
      if (clientOperationId.trim().isNotEmpty)
        'client_operation_id': clientOperationId.trim(),
    };
  }

  factory AnimalWeightData.fromMap(Map<String, dynamic> map) {
    return AnimalWeightData(
      id: map['id']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      notes: map['notes']?.toString() ?? '',
      bodyConditionScore: (map['bodyConditionScore'] as num?)?.toDouble() ?? 0,
      source: map['source']?.toString() ?? '',
      equipment: map['equipment']?.toString() ?? '',
      isRemote: map['isRemote'] == true,
      clientOperationId: map['clientOperationId']?.toString() ?? '',
    );
  }

  factory AnimalWeightData.fromRemoteMap(Map<String, dynamic> map) {
    return AnimalWeightData(
      id: map['id']?.toString() ?? '',
      date: _fromIsoDate(map['measured_at']?.toString() ?? ''),
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      notes: map['notes']?.toString() ?? '',
      bodyConditionScore:
          (map['body_condition_score'] as num?)?.toDouble() ?? 0,
      source: map['source']?.toString() ?? '',
      equipment: map['equipment']?.toString() ?? '',
      isRemote: true,
      clientOperationId: map['client_operation_id']?.toString() ?? '',
    );
  }

  static DateTime? tryParseLocalDate(String value) {
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value.trim())) return null;
    final parts = value.trim().split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    if (year < 1900) return null;
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day
        ? parsed
        : null;
  }

  static String _toIsoDate(String value) {
    final parsed = tryParseLocalDate(value);
    final today = DateTime.now();
    if (parsed == null ||
        parsed.isAfter(DateTime(today.year, today.month, today.day))) {
      throw const FormatException('Data da pesagem inválida ou futura.');
    }
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
      12,
    ).toUtc().toIso8601String();
  }

  static String _fromIsoDate(String value) {
    final prefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T').firstMatch(value);
    if (prefix == null) return '';
    final year = int.parse(prefix[1]!);
    final month = int.parse(prefix[2]!);
    final day = int.parse(prefix[3]!);
    final calendarDate = DateTime.utc(year, month, day);
    if (calendarDate.year != year ||
        calendarDate.month != month ||
        calendarDate.day != day) {
      return '';
    }
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
