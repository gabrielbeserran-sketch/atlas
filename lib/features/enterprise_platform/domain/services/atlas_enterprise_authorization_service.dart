import '../models/atlas_enterprise_24a_data.dart';
import '../models/atlas_enterprise_permission_data.dart';
import '../../data/services/atlas_enterprise_24a_repository.dart';
import '../../data/services/atlas_enterprise_permission_repository.dart';
import 'atlas_enterprise_audit_service.dart';
import 'atlas_enterprise_session_service.dart';

class AtlasAuthorizationException implements Exception {
  const AtlasAuthorizationException({
    required this.permissionKey,
    required this.message,
  });

  final String permissionKey;
  final String message;

  @override
  String toString() => message;
}

class AtlasEnterpriseAuthorizationService {
  AtlasEnterpriseAuthorizationService._();

  static final AtlasEnterpriseAuthorizationService instance =
      AtlasEnterpriseAuthorizationService._();

  final AtlasEnterprisePermissionRepository _permissions =
      AtlasEnterprisePermissionRepository.instance;
  final AtlasEnterprise24ARepository _enterprise =
      AtlasEnterprise24ARepository.instance;

  Future<AtlasEffectivePermissionSet> effectivePermissions({
    String? companyId,
    String? userId,
  }) async {
    final session = AtlasEnterpriseSessionService.instance;
    await session.ensureInitialized();

    final resolvedCompanyId = companyId ?? session.currentCompanyId;
    final resolvedUserId = userId ?? session.currentUserId;

    if (resolvedCompanyId == null || resolvedUserId == null) {
      return const AtlasEffectivePermissionSet(
        companyId: '',
        userId: '',
        membershipRole: AtlasEnterpriseMembershipRole.viewer,
        customRoleId: null,
        allowed: <String>{},
        denied: <String>{},
      );
    }

    final enterpriseSnapshot = await _enterprise.load();
    AtlasEnterpriseMembership? membership;

    for (final item in enterpriseSnapshot.memberships) {
      if (item.companyId == resolvedCompanyId &&
          item.userId == resolvedUserId &&
          item.active) {
        membership = item;
        break;
      }
    }

    if (membership == null) {
      return AtlasEffectivePermissionSet(
        companyId: resolvedCompanyId,
        userId: resolvedUserId,
        membershipRole: AtlasEnterpriseMembershipRole.viewer,
        customRoleId: null,
        allowed: const <String>{},
        denied: const <String>{},
      );
    }

    final base = AtlasEnterprisePermissions.defaultsForRole(membership.role);

    final policy = await _permissions.findPolicy(
      companyId: resolvedCompanyId,
      userId: resolvedUserId,
    );

    var allowed = <String>{...base};
    final denied = <String>{};

    if (policy?.customRoleId != null) {
      final roles = await _permissions.loadCustomRoles(
        companyId: resolvedCompanyId,
      );
      for (final role in roles) {
        if (role.id == policy!.customRoleId && role.active) {
          allowed = <String>{...role.permissionKeys};
          break;
        }
      }
    }

    for (final entry
        in policy?.effects.entries ??
            const <MapEntry<String, AtlasPermissionEffect>>[]) {
      switch (entry.value) {
        case AtlasPermissionEffect.allow:
          allowed.add(entry.key);
          denied.remove(entry.key);
        case AtlasPermissionEffect.deny:
          denied.add(entry.key);
          allowed.remove(entry.key);
      }
    }

    return AtlasEffectivePermissionSet(
      companyId: resolvedCompanyId,
      userId: resolvedUserId,
      membershipRole: membership.role,
      customRoleId: policy?.customRoleId,
      allowed: allowed,
      denied: denied,
    );
  }

  Future<bool> can(
    String permissionKey, {
    String? companyId,
    String? userId,
    String? farmId,
    bool auditDenied = false,
  }) async {
    final effective = await effectivePermissions(
      companyId: companyId,
      userId: userId,
    );

    var allowed = effective.allows(permissionKey);

    if (allowed && farmId != null) {
      allowed = await _enterprise.canUserAccessFarm(
        userId: effective.userId,
        companyId: effective.companyId,
        farmId: farmId,
      );
    }

    if (!allowed && auditDenied) {
      await AtlasEnterpriseAuditService.instance.record(
        action: 'access_denied',
        module: 'authorization',
        entityType: 'permission',
        entityId: permissionKey,
        description: 'Acesso negado à permissão $permissionKey.',
        result: 'denied',
        companyId: effective.companyId,
        userId: effective.userId,
        farmId: farmId,
        after: <String, dynamic>{'permissionKey': permissionKey},
      );
    }

    return allowed;
  }

  Future<void> require(
    String permissionKey, {
    String? companyId,
    String? userId,
    String? farmId,
    String? reason,
  }) async {
    final allowed = await can(
      permissionKey,
      companyId: companyId,
      userId: userId,
      farmId: farmId,
      auditDenied: true,
    );

    if (!allowed) {
      throw AtlasAuthorizationException(
        permissionKey: permissionKey,
        message:
            reason ??
            'Operação bloqueada. Permissão necessária: '
                '$permissionKey.',
      );
    }
  }
}
