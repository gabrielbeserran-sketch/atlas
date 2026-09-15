class AtlasRemoteFarm {
  const AtlasRemoteFarm({
    required this.id,
    required this.tenantId,
    required this.companyId,
    required this.name,
    required this.city,
    required this.state,
    required this.animals,
    required this.area,
    this.productionProfile = 'mixed',
    this.productionSystem = '',
    required this.active,
  });

  final String id;
  final String tenantId;
  final String companyId;
  final String name;
  final String city;
  final String state;
  final int animals;
  final double area;
  final String productionProfile;
  final String productionSystem;
  final bool active;

  bool get hasBeefProduction =>
      productionProfile == 'beef' || productionProfile == 'mixed';
  bool get hasDairyProduction =>
      productionProfile == 'dairy' || productionProfile == 'mixed';

  String get location {
    final parts = <String>[
      city.trim(),
      state.trim(),
    ].where((item) => item.isNotEmpty).toList();
    return parts.join(' - ');
  }

  factory AtlasRemoteFarm.fromMap(Map<String, dynamic> map) {
    return AtlasRemoteFarm(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      animals: (map['animals'] as num?)?.toInt() ?? 0,
      area: (map['area'] as num?)?.toDouble() ?? 0,
      productionProfile: _normalizeProductionProfile(
        map['production_profile']?.toString(),
      ),
      productionSystem: map['production_system']?.toString() ?? '',
      active: map['active'] as bool? ?? true,
    );
  }

  static String _normalizeProductionProfile(String? value) => switch (value) {
    'beef' || 'dairy' || 'mixed' => value!,
    _ => 'mixed',
  };
}
