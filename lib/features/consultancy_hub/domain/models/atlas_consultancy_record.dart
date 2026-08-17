enum AtlasClientStatus { active, attention, inactive }

enum AtlasVisitStatus { scheduled, completed, cancelled }

class AtlasConsultancyRecord {
  const AtlasConsultancyRecord({
    required this.id,
    required this.clientName,
    required this.propertyName,
    required this.phone,
    required this.city,
    required this.status,
    required this.nextVisit,
    required this.executiveScore,
    required this.openActions,
    required this.monthlyFee,
    required this.notes,
  });

  final String id;
  final String clientName;
  final String propertyName;
  final String phone;
  final String city;
  final AtlasClientStatus status;
  final DateTime nextVisit;
  final double executiveScore;
  final int openActions;
  final double monthlyFee;
  final String notes;

  AtlasConsultancyRecord copyWith({
    String? clientName,
    String? propertyName,
    String? phone,
    String? city,
    AtlasClientStatus? status,
    DateTime? nextVisit,
    double? executiveScore,
    int? openActions,
    double? monthlyFee,
    String? notes,
  }) {
    return AtlasConsultancyRecord(
      id: id,
      clientName: clientName ?? this.clientName,
      propertyName: propertyName ?? this.propertyName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      status: status ?? this.status,
      nextVisit: nextVisit ?? this.nextVisit,
      executiveScore: executiveScore ?? this.executiveScore,
      openActions: openActions ?? this.openActions,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientName': clientName,
    'propertyName': propertyName,
    'phone': phone,
    'city': city,
    'status': status.name,
    'nextVisit': nextVisit.toIso8601String(),
    'executiveScore': executiveScore,
    'openActions': openActions,
    'monthlyFee': monthlyFee,
    'notes': notes,
  };

  factory AtlasConsultancyRecord.fromJson(Map<String, dynamic> json) {
    return AtlasConsultancyRecord(
      id: json['id'] as String,
      clientName: json['clientName'] as String? ?? '',
      propertyName: json['propertyName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      status: AtlasClientStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AtlasClientStatus.active,
      ),
      nextVisit:
          DateTime.tryParse(json['nextVisit'] as String? ?? '') ??
          DateTime.now(),
      executiveScore: (json['executiveScore'] as num? ?? 0).toDouble(),
      openActions: (json['openActions'] as num? ?? 0).toInt(),
      monthlyFee: (json['monthlyFee'] as num? ?? 0).toDouble(),
      notes: json['notes'] as String? ?? '',
    );
  }
}
