class AtlasConsultancyContactProfile {
  const AtlasConsultancyContactProfile({
    required this.displayName,
    required this.role,
    required this.whatsappNumber,
    required this.companyLabel,
  });

  final String displayName;
  final String role;
  final String whatsappNumber;
  final String companyLabel;

  String get normalizedWhatsappNumber =>
      whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');

  bool get hasValidWhatsapp =>
      normalizedWhatsappNumber.length >= 10 &&
      normalizedWhatsappNumber.length <= 15;
}
