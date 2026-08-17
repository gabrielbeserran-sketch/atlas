class AtlasFieldOperation {
  const AtlasFieldOperation({
    required this.operationType,
    required this.entityType,
    required this.entityIds,
    required this.payload,
  });

  final String operationType;
  final String entityType;
  final List<String> entityIds;
  final Map<String, dynamic> payload;

  bool get isBulk => entityIds.length > 1;
  bool get hasIdentification =>
      (payload['rfid']?.toString().isNotEmpty ?? false) ||
      (payload['qr_code']?.toString().isNotEmpty ?? false);
  bool get hasAttachment =>
      (payload['photo_path']?.toString().isNotEmpty ?? false) ||
      (payload['document_path']?.toString().isNotEmpty ?? false);
}
