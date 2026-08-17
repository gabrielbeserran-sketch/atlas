class AtlasEnterpriseAuditRecord {
  const AtlasEnterpriseAuditRecord({
    required this.id,
    required this.companyId,
    required this.farmId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    required this.entityType,
    required this.entityId,
    required this.description,
    required this.before,
    required this.after,
    required this.occurredAt,
    required this.device,
    required this.source,
    required this.result,
    required this.justification,
    required this.previousHash,
    required this.integrityHash,
  });

  final String id;
  final String companyId;
  final String? farmId;
  final String userId;
  final String userName;
  final String action;
  final String module;
  final String entityType;
  final String entityId;
  final String description;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final DateTime occurredAt;
  final String device;
  final String source;
  final String result;
  final String justification;
  final String previousHash;
  final String integrityHash;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'companyId': companyId,
    'farmId': farmId,
    'userId': userId,
    'userName': userName,
    'action': action,
    'module': module,
    'entityType': entityType,
    'entityId': entityId,
    'description': description,
    'before': before,
    'after': after,
    'occurredAt': occurredAt.toIso8601String(),
    'device': device,
    'source': source,
    'result': result,
    'justification': justification,
    'previousHash': previousHash,
    'integrityHash': integrityHash,
  };

  factory AtlasEnterpriseAuditRecord.fromMap(Map<String, dynamic> map) {
    return AtlasEnterpriseAuditRecord(
      id: map['id']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      farmId: map['farmId']?.toString(),
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      module: map['module']?.toString() ?? '',
      entityType: map['entityType']?.toString() ?? '',
      entityId: map['entityId']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      before: Map<String, dynamic>.from(
        (map['before'] as Map?) ?? const <String, dynamic>{},
      ),
      after: Map<String, dynamic>.from(
        (map['after'] as Map?) ?? const <String, dynamic>{},
      ),
      occurredAt:
          DateTime.tryParse(map['occurredAt']?.toString() ?? '') ??
          DateTime.now(),
      device: map['device']?.toString() ?? 'local_device',
      source: map['source']?.toString() ?? 'atlas_app',
      result: map['result']?.toString() ?? 'success',
      justification: map['justification']?.toString() ?? '',
      previousHash: map['previousHash']?.toString() ?? '',
      integrityHash: map['integrityHash']?.toString() ?? '',
    );
  }
}

class AtlasAuditIntegrityResult {
  const AtlasAuditIntegrityResult({
    required this.valid,
    required this.checkedRecords,
    required this.brokenRecordId,
  });

  final bool valid;
  final int checkedRecords;
  final String? brokenRecordId;
}
