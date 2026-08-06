class AtlasFoundationCheck {
  const AtlasFoundationCheck({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.isCompleted,
    required this.isCritical,
  });

  final String id;
  final String title;
  final String description;
  final String area;
  final bool isCompleted;
  final bool isCritical;

  AtlasFoundationCheck copyWith({bool? isCompleted}) {
    return AtlasFoundationCheck(
      id: id,
      title: title,
      description: description,
      area: area,
      isCompleted: isCompleted ?? this.isCompleted,
      isCritical: isCritical,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'area': area,
        'isCompleted': isCompleted,
        'isCritical': isCritical,
      };

  factory AtlasFoundationCheck.fromMap(Map<String, dynamic> map) {
    return AtlasFoundationCheck(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      area: map['area'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      isCritical: map['isCritical'] as bool? ?? false,
    );
  }
}

class AtlasFoundationSnapshot {
  const AtlasFoundationSnapshot({
    required this.checks,
    required this.lastReviewAt,
  });

  final List<AtlasFoundationCheck> checks;
  final DateTime? lastReviewAt;

  int get completed => checks.where((AtlasFoundationCheck item) => item.isCompleted).length;
  int get criticalPending => checks
      .where((AtlasFoundationCheck item) => item.isCritical && !item.isCompleted)
      .length;
  double get progress => checks.isEmpty ? 0 : completed / checks.length;
}
