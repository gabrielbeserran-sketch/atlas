class AtlasSubscriptionProfile {
  const AtlasSubscriptionProfile({
    required this.code,
    required this.name,
    required this.status,
    required this.limits,
    required this.features,
    required this.consultancyIncluded,
  });

  final String code;
  final String name;
  final String status;
  final Map<String, dynamic> limits;
  final List<String> features;
  final bool consultancyIncluded;

  bool get hasUnlimitedData => limits['data_entries'] == null;

  factory AtlasSubscriptionProfile.fromMap(Map<String, dynamic> map) {
    final rawLimits = map['limits'];
    final rawFeatures = map['features'];
    return AtlasSubscriptionProfile(
      code: map['code']?.toString() ?? 'basic',
      name: map['name']?.toString() ?? 'Plano Atlas',
      status: map['status']?.toString() ?? 'not_configured',
      limits: rawLimits is Map
          ? Map<String, dynamic>.from(rawLimits)
          : const <String, dynamic>{},
      features: rawFeatures is List
          ? rawFeatures.map((item) => item.toString()).toList()
          : const <String>[],
      consultancyIncluded: map['consultancy_included'] == true,
    );
  }
}
