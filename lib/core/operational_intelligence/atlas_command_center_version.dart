class AtlasCommandCenterVersion {
  const AtlasCommandCenterVersion({
    required this.number,
    required this.updatedAt,
    required this.reason,
    required this.eventId,
    required this.farmName,
  });

  final int number;
  final DateTime updatedAt;
  final String reason;
  final String? eventId;
  final String? farmName;
}
