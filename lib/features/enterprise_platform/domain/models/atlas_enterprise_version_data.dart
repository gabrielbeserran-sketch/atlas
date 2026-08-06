enum AtlasVersionMutationType {
  create,
  update,
  delete,
  restore,
  merge,
}

String atlasVersionMutationTypeLabel(
  AtlasVersionMutationType value,
) {
  switch (value) {
    case AtlasVersionMutationType.create:
      return 'Criação';
    case AtlasVersionMutationType.update:
      return 'Atualização';
    case AtlasVersionMutationType.delete:
      return 'Exclusão lógica';
    case AtlasVersionMutationType.restore:
      return 'Restauração';
    case AtlasVersionMutationType.merge:
      return 'Mesclagem';
  }
}

class AtlasVersionedEntitySnapshot {
  const AtlasVersionedEntitySnapshot({
    required this.versionId,
    required this.tenantId,
    required this.companyId,
    required this.farmId,
    required this.entityType,
    required this.entityId,
    required this.version,
    required this.mutationType,
    required this.payload,
    required this.deleted,
    required this.reason,
    required this.createdBy,
    required this.createdAt,
    required this.previousVersionId,
    required this.contentHash,
  });

  final String versionId;
  final String tenantId;
  final String companyId;
  final String? farmId;
  final String entityType;
  final String entityId;
  final int version;
  final AtlasVersionMutationType mutationType;
  final Map<String, dynamic> payload;
  final bool deleted;
  final String reason;
  final String createdBy;
  final DateTime createdAt;
  final String? previousVersionId;
  final String contentHash;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'versionId': versionId,
        'tenantId': tenantId,
        'companyId': companyId,
        'farmId': farmId,
        'entityType': entityType,
        'entityId': entityId,
        'version': version,
        'mutationType': mutationType.name,
        'payload': payload,
        'deleted': deleted,
        'reason': reason,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'previousVersionId': previousVersionId,
        'contentHash': contentHash,
      };

  factory AtlasVersionedEntitySnapshot.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasVersionedEntitySnapshot(
      versionId: map['versionId']?.toString() ?? '',
      tenantId: map['tenantId']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      farmId: map['farmId']?.toString(),
      entityType: map['entityType']?.toString() ?? '',
      entityId: map['entityId']?.toString() ?? '',
      version: (map['version'] as num?)?.toInt() ?? 0,
      mutationType:
          AtlasVersionMutationType.values.firstWhere(
        (item) =>
            item.name == map['mutationType']?.toString(),
        orElse: () => AtlasVersionMutationType.update,
      ),
      payload: Map<String, dynamic>.from(
        (map['payload'] as Map?) ??
            const <String, dynamic>{},
      ),
      deleted: map['deleted'] == true,
      reason: map['reason']?.toString() ?? '',
      createdBy: map['createdBy']?.toString() ?? 'system',
      createdAt:
          DateTime.tryParse(
            map['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      previousVersionId:
          map['previousVersionId']?.toString(),
      contentHash: map['contentHash']?.toString() ?? '',
    );
  }
}

class AtlasConcurrencyCheck {
  const AtlasConcurrencyCheck({
    required this.allowed,
    required this.expectedVersion,
    required this.currentVersion,
    required this.message,
  });

  final bool allowed;
  final int expectedVersion;
  final int currentVersion;
  final String message;
}

class AtlasVersionRestoreResult {
  const AtlasVersionRestoreResult({
    required this.restored,
    required this.sourceVersion,
    required this.newVersion,
  });

  final bool restored;
  final AtlasVersionedEntitySnapshot sourceVersion;
  final AtlasVersionedEntitySnapshot? newVersion;
}
