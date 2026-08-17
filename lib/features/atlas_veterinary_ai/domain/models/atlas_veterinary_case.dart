class AtlasVeterinaryCase {
  const AtlasVeterinaryCase({
    required this.id,
    required this.date,
    required this.title,
    required this.status,
    required this.symptoms,
    required this.temperatureCelsius,
    required this.heartRateBpm,
    required this.respiratoryRateBpm,
    required this.appetite,
    required this.hydration,
    required this.locomotion,
    required this.durationHours,
    required this.notes,
    required this.responsible,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final String title;
  final String status;
  final List<String> symptoms;
  final double temperatureCelsius;
  final int heartRateBpm;
  final int respiratoryRateBpm;
  final String appetite;
  final String hydration;
  final String locomotion;
  final int durationHours;
  final String notes;
  final String responsible;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'status': status,
      'symptoms': symptoms,
      'temperatureCelsius': temperatureCelsius,
      'heartRateBpm': heartRateBpm,
      'respiratoryRateBpm': respiratoryRateBpm,
      'appetite': appetite,
      'hydration': hydration,
      'locomotion': locomotion,
      'durationHours': durationHours,
      'notes': notes,
      'responsible': responsible,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasVeterinaryCase.fromMap(Map<String, dynamic> map) {
    return AtlasVeterinaryCase(
      id: map['id']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Em avaliação',
      symptoms: (map['symptoms'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      temperatureCelsius: (map['temperatureCelsius'] as num?)?.toDouble() ?? 0,
      heartRateBpm: (map['heartRateBpm'] as num?)?.toInt() ?? 0,
      respiratoryRateBpm: (map['respiratoryRateBpm'] as num?)?.toInt() ?? 0,
      appetite: map['appetite']?.toString() ?? 'Normal',
      hydration: map['hydration']?.toString() ?? 'Normal',
      locomotion: map['locomotion']?.toString() ?? 'Normal',
      durationHours: (map['durationHours'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasVeterinaryDate(String value) {
  final iso = DateTime.tryParse(value.trim());
  if (iso != null) return iso;

  final parts = value.trim().split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasVeterinaryDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
