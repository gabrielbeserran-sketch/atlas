class PaddockData {
  const PaddockData({
    this.id = '',
    required this.name,
    required this.area,
    required this.status,
    required this.animals,
    this.notes = '',
  });

  final String id;
  final String name;
  final double area;
  final String status;
  final int animals;
  final String notes;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'area': area,
    'status': status,
    'animals': animals,
    'notes': notes,
  };

  factory PaddockData.fromMap(Map<String, dynamic> map) => PaddockData(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    area: (map['area'] as num?)?.toDouble() ?? 0,
    status: map['status']?.toString() ?? 'Descanso',
    animals: (map['animals'] as num?)?.toInt() ?? 0,
    notes: map['notes']?.toString() ?? '',
  );
}
