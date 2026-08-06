class AnimalPhotoData {
  const AnimalPhotoData({
    required this.id,
    required this.reference,
    required this.date,
    required this.title,
    required this.notes,
    required this.isPrimary,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final String date;
  final String title;
  final String notes;
  final bool isPrimary;
  final String createdAt;

  AnimalPhotoData copyWith({
    String? id,
    String? reference,
    String? date,
    String? title,
    String? notes,
    bool? isPrimary,
    String? createdAt,
  }) {
    return AnimalPhotoData(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference': reference,
      'date': date,
      'title': title,
      'notes': notes,
      'isPrimary': isPrimary,
      'createdAt': createdAt,
    };
  }

  factory AnimalPhotoData.fromMap(Map<String, dynamic> map) {
    return AnimalPhotoData(
      id: map['id']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      isPrimary: map['isPrimary'] == true,
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }
}
