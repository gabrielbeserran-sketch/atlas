class AtlasExecutionAuditEntry {
  const AtlasExecutionAuditEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.changedAt,
    required this.changedBy,
    required this.source,
    required this.farmName,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String entityTitle;
  final String fieldName;
  final String oldValue;
  final String newValue;
  final DateTime changedAt;
  final String changedBy;
  final String source;
  final String? farmName;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'entityTitle': entityTitle,
      'fieldName': fieldName,
      'oldValue': oldValue,
      'newValue': newValue,
      'changedAt': changedAt.toIso8601String(),
      'changedBy': changedBy,
      'source': source,
      'farmName': farmName,
    };
  }

  factory AtlasExecutionAuditEntry.fromMap(Map<String, dynamic> map) {
    return AtlasExecutionAuditEntry(
      id: map['id']?.toString() ?? '',
      entityType: map['entityType']?.toString() ?? '',
      entityId: map['entityId']?.toString() ?? '',
      entityTitle: map['entityTitle']?.toString() ?? '',
      fieldName: map['fieldName']?.toString() ?? '',
      oldValue: map['oldValue']?.toString() ?? '',
      newValue: map['newValue']?.toString() ?? '',
      changedAt:
          DateTime.tryParse(map['changedAt']?.toString() ?? '') ??
          DateTime.now(),
      changedBy: map['changedBy']?.toString() ?? 'Usuário local',
      source: map['source']?.toString() ?? 'atlas',
      farmName: map['farmName']?.toString(),
    );
  }
}
