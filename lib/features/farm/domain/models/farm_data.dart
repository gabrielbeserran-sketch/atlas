class FarmData {
  const FarmData({
    this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.animals,
    required this.area,
  });

  final String? id;
  final String name;
  final String city;
  final String state;
  final int animals;
  final int area;

  FarmData copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    int? animals,
    int? area,
  }) {
    return FarmData(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      animals: animals ?? this.animals,
      area: area ?? this.area,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'animals': animals,
      'area': area,
    };
  }

  factory FarmData.fromMap(Map<String, dynamic> map) {
    return FarmData(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      animals: (map['animals'] as num?)?.toInt() ?? 0,
      area: (map['area'] as num?)?.toInt() ?? 0,
    );
  }
}
