import '../models/atlas_enterprise_sync_data.dart';

class AtlasRemoteEntityState {
  const AtlasRemoteEntityState({
    required this.entityType,
    required this.entityId,
    required this.version,
    required this.payload,
    required this.deleted,
    required this.cursor,
  });

  final String entityType;
  final String entityId;
  final int version;
  final Map<String, dynamic> payload;
  final bool deleted;
  final String cursor;
}

class AtlasPushOperationResult {
  const AtlasPushOperationResult({
    required this.accepted,
    required this.conflict,
    required this.remoteVersion,
    required this.remotePayload,
    required this.error,
  });

  final bool accepted;
  final bool conflict;
  final int remoteVersion;
  final Map<String, dynamic> remotePayload;
  final String error;
}

abstract class AtlasEnterpriseSyncTransport {
  Future<AtlasPushOperationResult> push(
    AtlasEnterpriseSyncOperation operation,
  );

  Future<List<AtlasRemoteEntityState>> pull({
    required String companyId,
    required String cursor,
  });
}

/// Transporte local de validação.
/// Não representa backend de produção. O 24D substituirá esta
/// implementação por HTTP/API autenticada sem alterar o engine.
class AtlasLocalLoopbackSyncTransport
    implements AtlasEnterpriseSyncTransport {
  AtlasLocalLoopbackSyncTransport._();

  static final AtlasLocalLoopbackSyncTransport instance =
      AtlasLocalLoopbackSyncTransport._();

  final Map<String, AtlasRemoteEntityState> _remote =
      <String, AtlasRemoteEntityState>{};
  int _cursor = 0;

  String _key(
    String companyId,
    String entityType,
    String entityId,
  ) =>
      '$companyId|$entityType|$entityId';

  @override
  Future<AtlasPushOperationResult> push(
    AtlasEnterpriseSyncOperation operation,
  ) async {
    final key = _key(
      operation.companyId,
      operation.entityType,
      operation.entityId,
    );
    final current = _remote[key];
    final currentVersion = current?.version ?? 0;

    if (currentVersion != operation.baseVersion) {
      return AtlasPushOperationResult(
        accepted: false,
        conflict: true,
        remoteVersion: currentVersion,
        remotePayload:
            current?.payload ?? const <String, dynamic>{},
        error:
            'baseVersion=${operation.baseVersion}; '
            'remoteVersion=$currentVersion',
      );
    }

    _cursor += 1;
    final nextVersion = currentVersion + 1;
    _remote[key] = AtlasRemoteEntityState(
      entityType: operation.entityType,
      entityId: operation.entityId,
      version: nextVersion,
      payload: Map<String, dynamic>.from(operation.payload),
      deleted: operation.operationType ==
          AtlasEnterpriseSyncOperationType.delete,
      cursor: _cursor.toString(),
    );

    return AtlasPushOperationResult(
      accepted: true,
      conflict: false,
      remoteVersion: nextVersion,
      remotePayload:
          Map<String, dynamic>.from(operation.payload),
      error: '',
    );
  }

  @override
  Future<List<AtlasRemoteEntityState>> pull({
    required String companyId,
    required String cursor,
  }) async {
    final currentCursor = int.tryParse(cursor) ?? 0;

    return _remote.entries
        .where((entry) {
          final parts = entry.key.split('|');
          if (parts.isEmpty || parts.first != companyId) {
            return false;
          }
          return (int.tryParse(entry.value.cursor) ?? 0) >
              currentCursor;
        })
        .map((entry) => entry.value)
        .toList()
      ..sort(
        (a, b) => (int.tryParse(a.cursor) ?? 0)
            .compareTo(int.tryParse(b.cursor) ?? 0),
      );
  }
}
