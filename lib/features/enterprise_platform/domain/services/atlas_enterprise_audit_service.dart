import 'dart:convert';

import '../../data/services/atlas_enterprise_audit_repository.dart';
import '../models/atlas_enterprise_audit_data.dart';
import 'atlas_enterprise_session_service.dart';

class AtlasEnterpriseAuditService {
  AtlasEnterpriseAuditService._();

  static final AtlasEnterpriseAuditService instance =
      AtlasEnterpriseAuditService._();

  final AtlasEnterpriseAuditRepository _repository =
      AtlasEnterpriseAuditRepository.instance;

  Future<void> record({
    required String action,
    required String module,
    required String entityType,
    required String entityId,
    required String description,
    Map<String, dynamic> before = const <String, dynamic>{},
    Map<String, dynamic> after = const <String, dynamic>{},
    String? companyId,
    String? farmId,
    String? userId,
    String? userName,
    String device = 'local_device',
    String source = 'atlas_app',
    String result = 'success',
    String justification = '',
  }) async {
    final session = AtlasEnterpriseSessionService.instance;
    await session.ensureInitialized();

    final resolvedCompanyId = companyId ?? session.currentCompanyId ?? '';
    final resolvedFarmId = farmId ?? session.currentFarmId;
    final resolvedUserId = userId ?? session.currentUserId ?? 'anonymous';

    final all = await _repository.loadAll();
    final previousHash = all.isEmpty ? 'GENESIS' : all.last.integrityHash;
    final now = DateTime.now();
    final id =
        'audit_${now.microsecondsSinceEpoch}_'
        '${all.length + 1}';

    final canonical = <String, dynamic>{
      'id': id,
      'companyId': resolvedCompanyId,
      'farmId': resolvedFarmId,
      'userId': resolvedUserId,
      'userName': userName ?? resolvedUserId,
      'action': action,
      'module': module,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'before': before,
      'after': after,
      'occurredAt': now.toIso8601String(),
      'device': device,
      'source': source,
      'result': result,
      'justification': justification,
      'previousHash': previousHash,
    };

    final integrityHash = _fnv1a64('$previousHash|${jsonEncode(canonical)}');

    await _repository.append(
      AtlasEnterpriseAuditRecord(
        id: id,
        companyId: resolvedCompanyId,
        farmId: resolvedFarmId,
        userId: resolvedUserId,
        userName: userName ?? resolvedUserId,
        action: action,
        module: module,
        entityType: entityType,
        entityId: entityId,
        description: description,
        before: before,
        after: after,
        occurredAt: now,
        device: device,
        source: source,
        result: result,
        justification: justification,
        previousHash: previousHash,
        integrityHash: integrityHash,
      ),
    );
  }

  Future<List<AtlasEnterpriseAuditRecord>> search({
    String? companyId,
    String? farmId,
    String? userId,
    String? module,
    String? entityType,
    String? action,
    String? result,
  }) async {
    final all = await _repository.loadAll();
    final filtered =
        all.where((item) {
          return (companyId == null || item.companyId == companyId) &&
              (farmId == null || item.farmId == farmId) &&
              (userId == null || item.userId == userId) &&
              (module == null || item.module == module) &&
              (entityType == null || item.entityType == entityType) &&
              (action == null || item.action == action) &&
              (result == null || item.result == result);
        }).toList()..sort(
          (first, second) => second.occurredAt.compareTo(first.occurredAt),
        );
    return filtered;
  }

  Future<AtlasAuditIntegrityResult> verifyIntegrity() async {
    final all = await _repository.loadAll();
    var previous = 'GENESIS';

    for (final item in all) {
      if (item.previousHash != previous) {
        return AtlasAuditIntegrityResult(
          valid: false,
          checkedRecords: all.indexOf(item),
          brokenRecordId: item.id,
        );
      }

      final canonical = <String, dynamic>{
        'id': item.id,
        'companyId': item.companyId,
        'farmId': item.farmId,
        'userId': item.userId,
        'userName': item.userName,
        'action': item.action,
        'module': item.module,
        'entityType': item.entityType,
        'entityId': item.entityId,
        'description': item.description,
        'before': item.before,
        'after': item.after,
        'occurredAt': item.occurredAt.toIso8601String(),
        'device': item.device,
        'source': item.source,
        'result': item.result,
        'justification': item.justification,
        'previousHash': item.previousHash,
      };

      final expected = _fnv1a64('$previous|${jsonEncode(canonical)}');

      if (expected != item.integrityHash) {
        return AtlasAuditIntegrityResult(
          valid: false,
          checkedRecords: all.indexOf(item) + 1,
          brokenRecordId: item.id,
        );
      }
      previous = item.integrityHash;
    }

    return AtlasAuditIntegrityResult(
      valid: true,
      checkedRecords: all.length,
      brokenRecordId: null,
    );
  }

  String _fnv1a64(String input) {
    const int offset = 1469598103934665603;
    const int prime = 1099511628211;
    var hash = offset;

    for (final unit in utf8.encode(input)) {
      hash ^= unit;
      hash = (hash * prime) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
