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

  Map<String, dynamic> toRemoteBody() => {
    'weight': weight,
    'body_condition_score': bodyConditionScore,
    'source': source.trim(),
    'equipment': equipment.trim(),
    'measured_at': _toIsoDate(date),
    'notes': notes.trim(),
    if (clientOperationId.trim().isNotEmpty)
      'client_operation_id': clientOperationId.trim(),
  };

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

  static String _toIsoDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return DateTime.now().toUtc().toIso8601String();
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return DateTime.now().toUtc().toIso8601String();
    }
    return DateTime(year, month, day, 12).toUtc().toIso8601String();
  }

  static String _fromIsoDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
