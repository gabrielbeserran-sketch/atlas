class AtlasSubscriptionProfile {
  const AtlasSubscriptionProfile({
    required this.code,
    required this.name,
    required this.status,
    required this.limits,
    required this.features,
    required this.consultancyIncluded,
    this.authorization,
  });

  final String code;
  final String name;
  final String status;
  final Map<String, dynamic> limits;
  final List<String> features;
  final bool consultancyIncluded;
  final Map<String, dynamic>? authorization;

  bool get isActive => status == 'active';

  bool get hasServerConfirmedConsultancy =>
      isActive &&
      authorization?['state'] == 'active' &&
      authorization?['code'] == 'consultancy' &&
      authorization?['consultancy_confirmed'] == true;

  bool get hasActiveConsultancy => authorization == null
      ? isActive && consultancyIncluded
      : hasServerConfirmedConsultancy;

  bool get hasUnlimitedData {
    if (authorization != null) {
      return isActive &&
          authorization?['state'] == 'active' &&
          const {'professional', 'consultancy'}.contains(authorization?['code']) &&
          authorization?['unlimited_data_confirmed'] == true;
    }
    return isActive &&
        const {'professional', 'consultancy'}.contains(code) &&
        limits.containsKey('data_entries') &&
        limits['data_entries'] == null;
  }

  int? get monthlyCredits {
    if (!isActive) return null;
    if (authorization != null) {
      if (authorization?['state'] != 'active' ||
          authorization?['code'] != 'basic') {
        return null;
      }
      final confirmed = authorization?['monthly_credits_confirmed'];
      return confirmed is int && confirmed >= 0 ? confirmed : null;
    }
    final value = limits['monthly_credits'];
    return value is int && value >= 0 ? value : null;
  }

  factory AtlasSubscriptionProfile.fromMap(Map<String, dynamic> map) {
    final rawLimits = map['limits'];
    final rawFeatures = map['features'];
    final rawAuthorization = map['authorization'];
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
      authorization: rawAuthorization is Map
          ? Map<String, dynamic>.from(rawAuthorization)
          : null,
    );
  }
}
