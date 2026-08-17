enum AtlasWorkShiftStatus { planned, completed, absent, cancelled }

String atlasWorkShiftStatusLabel(AtlasWorkShiftStatus value) {
  switch (value) {
    case AtlasWorkShiftStatus.planned:
      return 'Planejado';
    case AtlasWorkShiftStatus.completed:
      return 'Concluído';
    case AtlasWorkShiftStatus.absent:
      return 'Ausente';
    case AtlasWorkShiftStatus.cancelled:
      return 'Cancelado';
  }
}

class AtlasWorkShift {
  const AtlasWorkShift({
    required this.id,
    required this.memberId,
    required this.startAt,
    required this.endAt,
    required this.activity,
    required this.location,
    required this.status,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String memberId;
  final DateTime startAt;
  final DateTime endAt;
  final String activity;
  final String location;
  final AtlasWorkShiftStatus status;
  final String? farmName;
  final String notes;

  double get plannedHours => endAt.difference(startAt).inMinutes / 60;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'memberId': memberId,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
    'activity': activity,
    'location': location,
    'status': status.name,
    'farmName': farmName,
    'notes': notes,
  };

  factory AtlasWorkShift.fromMap(Map<String, dynamic> map) {
    return AtlasWorkShift(
      id: map['id']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '',
      startAt:
          DateTime.tryParse(map['startAt']?.toString() ?? '') ?? DateTime.now(),
      endAt:
          DateTime.tryParse(map['endAt']?.toString() ?? '') ?? DateTime.now(),
      activity: map['activity']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      status: AtlasWorkShiftStatus.values.firstWhere(
        (item) => item.name == map['status']?.toString(),
        orElse: () => AtlasWorkShiftStatus.planned,
      ),
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasTrainingRecord {
  const AtlasTrainingRecord({
    required this.id,
    required this.memberId,
    required this.title,
    required this.completedAt,
    required this.validUntil,
    required this.scorePercent,
    required this.certificate,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String memberId;
  final String title;
  final DateTime completedAt;
  final DateTime? validUntil;
  final double scorePercent;
  final String certificate;
  final String? farmName;
  final String notes;

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'memberId': memberId,
    'title': title,
    'completedAt': completedAt.toIso8601String(),
    'validUntil': validUntil?.toIso8601String(),
    'scorePercent': scorePercent,
    'certificate': certificate,
    'farmName': farmName,
    'notes': notes,
  };

  factory AtlasTrainingRecord.fromMap(Map<String, dynamic> map) {
    return AtlasTrainingRecord(
      id: map['id']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      completedAt:
          DateTime.tryParse(map['completedAt']?.toString() ?? '') ??
          DateTime.now(),
      validUntil: DateTime.tryParse(map['validUntil']?.toString() ?? ''),
      scorePercent: (map['scorePercent'] as num?)?.toDouble() ?? 0,
      certificate: map['certificate']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasPerformanceReview {
  const AtlasPerformanceReview({
    required this.id,
    required this.memberId,
    required this.reviewedAt,
    required this.productivityPercent,
    required this.qualityPercent,
    required this.safetyPercent,
    required this.teamworkPercent,
    required this.managerNotes,
    required this.farmName,
  });

  final String id;
  final String memberId;
  final DateTime reviewedAt;
  final double productivityPercent;
  final double qualityPercent;
  final double safetyPercent;
  final double teamworkPercent;
  final String managerNotes;
  final String? farmName;

  double get overallScore =>
      (productivityPercent + qualityPercent + safetyPercent + teamworkPercent) /
      4;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'memberId': memberId,
    'reviewedAt': reviewedAt.toIso8601String(),
    'productivityPercent': productivityPercent,
    'qualityPercent': qualityPercent,
    'safetyPercent': safetyPercent,
    'teamworkPercent': teamworkPercent,
    'managerNotes': managerNotes,
    'farmName': farmName,
  };

  factory AtlasPerformanceReview.fromMap(Map<String, dynamic> map) {
    double value(String key) => (map[key] as num?)?.toDouble() ?? 0;

    return AtlasPerformanceReview(
      id: map['id']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '',
      reviewedAt:
          DateTime.tryParse(map['reviewedAt']?.toString() ?? '') ??
          DateTime.now(),
      productivityPercent: value('productivityPercent'),
      qualityPercent: value('qualityPercent'),
      safetyPercent: value('safetyPercent'),
      teamworkPercent: value('teamworkPercent'),
      managerNotes: map['managerNotes']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
    );
  }
}

class AtlasPeopleExecutiveSnapshot {
  const AtlasPeopleExecutiveSnapshot({
    required this.activeMembers,
    required this.plannedHours,
    required this.completedHours,
    required this.absences,
    required this.trainingCoveragePercent,
    required this.expiredTrainings,
    required this.averagePerformancePercent,
    required this.peopleScore,
  });

  final int activeMembers;
  final double plannedHours;
  final double completedHours;
  final int absences;
  final double trainingCoveragePercent;
  final int expiredTrainings;
  final double averagePerformancePercent;
  final double peopleScore;
}
