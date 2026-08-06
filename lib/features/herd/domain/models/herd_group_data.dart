class HerdGroupData {
  const HerdGroupData({
    this.id = '',
    required this.name,
    required this.category,
    required this.capacity,
    required this.paddock,
    this.status = 'active',
    this.notes = '',
  });

  final String id;
  final String name;
  final String category;
  final int capacity;
  final String paddock;
  final String status;
  final String notes;

  bool get isRemote => id.trim().isNotEmpty;
  bool get isActive => status == 'active';

  HerdGroupData copyWith({
    String? id,
    String? name,
    String? category,
    int? capacity,
    String? paddock,
    String? status,
    String? notes,
  }) {
    return HerdGroupData(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      capacity: capacity ?? this.capacity,
      paddock: paddock ?? this.paddock,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'capacity': capacity,
      'paddock': paddock,
      'status': status,
      'notes': notes,
    };
  }

  Map<String, dynamic> toCreateBody(String farmId) {
    return {
      'farm_id': farmId,
      'name': name,
      'category': category,
      'capacity': capacity,
      'paddock': paddock,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateBody() {
    return {
      'name': name,
      'category': category,
      'capacity': capacity,
      'paddock': paddock,
      'status': status,
      'notes': notes,
    };
  }

  factory HerdGroupData.fromMap(Map<String, dynamic> map) {
    return HerdGroupData(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      capacity: (map['capacity'] as num?)?.toInt() ??
          (map['animals'] as num?)?.toInt() ??
          0,
      paddock: map['paddock']?.toString() ?? '',
      status: map['status']?.toString() ?? 'active',
      notes: map['notes']?.toString() ?? '',
    );
  }

  factory HerdGroupData.fromRemoteMap(Map<String, dynamic> map) {
    return HerdGroupData.fromMap(map);
  }
}
