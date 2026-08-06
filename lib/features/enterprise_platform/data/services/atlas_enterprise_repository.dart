import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_enterprise_data.dart';

class AtlasEnterpriseRepository {
  static const String _tenantsKey = 'atlas_enterprise_tenants_v1';
  static const String _usersKey = 'atlas_enterprise_users_v1';
  static const String _auditKey = 'atlas_enterprise_audit_v1';
  static const String _currentTenantKey = 'atlas_enterprise_current_tenant_v1';

  Future<AtlasEnterpriseState> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<AtlasTenant> tenants = _decodeList(
      preferences.getString(_tenantsKey),
      AtlasTenant.fromJson,
    );
    final List<AtlasEnterpriseUser> users = _decodeList(
      preferences.getString(_usersKey),
      AtlasEnterpriseUser.fromJson,
    );
    final List<AtlasAuditEntry> audit = _decodeList(
      preferences.getString(_auditKey),
      AtlasAuditEntry.fromJson,
    );

    if (tenants.isNotEmpty) {
      return AtlasEnterpriseState(
        tenants: tenants,
        users: users,
        audit: audit,
        currentTenantId:
            preferences.getString(_currentTenantKey) ?? tenants.first.id,
      );
    }

    final AtlasEnterpriseState seeded = _seed();
    await save(seeded);
    return seeded;
  }

  Future<void> save(AtlasEnterpriseState state) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _tenantsKey,
      jsonEncode(
        state.tenants.map((AtlasTenant item) => item.toJson()).toList(),
      ),
    );
    await preferences.setString(
      _usersKey,
      jsonEncode(
        state.users.map((AtlasEnterpriseUser item) => item.toJson()).toList(),
      ),
    );
    await preferences.setString(
      _auditKey,
      jsonEncode(
        state.audit.map((AtlasAuditEntry item) => item.toJson()).toList(),
      ),
    );
    if (state.currentTenantId != null) {
      await preferences.setString(_currentTenantKey, state.currentTenantId!);
    }
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic item) => factory(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  AtlasEnterpriseState _seed() {
    final String tenantId = 'tenant_beserra';
    return AtlasEnterpriseState(
      tenants: <AtlasTenant>[
        AtlasTenant(
          id: tenantId,
          name: 'Beserra Consultoria Veterinária',
          document: '',
          status: AtlasTenantStatus.trial,
          plan: AtlasSubscriptionPlan.professional,
          createdAt: DateTime.now(),
          trialEndsAt: DateTime.now().add(const Duration(days: 30)),
          maxUsers: 15,
          maxFarms: 50,
        ),
      ],
      users: <AtlasEnterpriseUser>[
        AtlasEnterpriseUser(
          id: 'user_admin',
          tenantId: tenantId,
          name: 'Gabriel Beserra do Nascimento',
          email: 'administrador@atlas.local',
          role: AtlasUserRole.administrator,
          active: true,
          twoFactorEnabled: false,
        ),
      ],
      audit: <AtlasAuditEntry>[
        AtlasAuditEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          tenantId: tenantId,
          userName: 'Sistema Atlas',
          module: 'Enterprise Platform',
          action: AtlasAuditAction.create,
          description: 'Ambiente empresarial inicial criado.',
          createdAt: DateTime.now(),
        ),
      ],
      currentTenantId: tenantId,
    );
  }
}
