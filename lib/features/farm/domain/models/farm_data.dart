class FarmData {
  const FarmData({
    this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.animals,
    required this.area,
    this.productionProfile = 'mixed',
    this.productionSystem = '',
  });

  final String? id;
  final String name;
  final String city;
  final String state;
  final int animals;
  final int area;
  final String productionProfile;
  final String productionSystem;

  bool get hasBeefProduction =>
      productionProfile == 'beef' || productionProfile == 'mixed';
  bool get hasDairyProduction =>
      productionProfile == 'dairy' || productionProfile == 'mixed';

  String get productionProfileLabel => switch (productionProfile) {
    'beef' => 'Corte',
    'dairy' => 'Leite',
    _ => 'Misto',
  };

  FarmData copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    int? animals,
    int? area,
    String? productionProfile,
    String? productionSystem,
  }) {
    return FarmData(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      animals: animals ?? this.animals,
      area: area ?? this.area,
      productionProfile: productionProfile ?? this.productionProfile,
      productionSystem: productionSystem ?? this.productionSystem,
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
      'production_profile': productionProfile,
      'production_system': productionSystem,
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
      productionProfile: _normalizeProductionProfile(
        map['production_profile']?.toString(),
      ),
      productionSystem: map['production_system']?.toString() ?? '',
    );
  }

  static String _normalizeProductionProfile(String? value) => switch (value) {
    'beef' || 'dairy' || 'mixed' => value!,
    _ => 'mixed',
  };
}
