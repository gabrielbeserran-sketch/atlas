class AtlasConsultancyContactProfile {
  const AtlasConsultancyContactProfile({
    required this.displayName,
    required this.role,
    required this.whatsappNumber,
    required this.companyLabel,
    required this.configured,
    required this.active,
  });

  final String displayName;
  final String role;
  final String whatsappNumber;
  final String companyLabel;
  final bool configured;
  final bool active;

  factory AtlasConsultancyContactProfile.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasConsultancyContactProfile(
      displayName: map['display_name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'Veterinário responsável',
      whatsappNumber: map['whatsapp_number']?.toString() ?? '',
      companyLabel: map['company_label']?.toString() ?? '',
      configured: map['configured'] == true,
      active: map['active'] == true,
    );
  }

  static const unavailable = AtlasConsultancyContactProfile(
    displayName: 'Contato ainda não configurado',
    role: 'Veterinário responsável',
    whatsappNumber: '',
    companyLabel: 'Consultoria',
    configured: false,
    active: false,
  );

  String get normalizedWhatsappNumber =>
      whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');

  bool get hasValidWhatsapp =>
      configured &&
      active &&
      normalizedWhatsappNumber.length >= 10 &&
      normalizedWhatsappNumber.length <= 15;
}
