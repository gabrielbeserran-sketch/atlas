import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_enterprise_24a_data.dart';
import 'atlas_enterprise_repository.dart';

class AtlasEnterprise24ARepository {
  AtlasEnterprise24ARepository._();

  static final AtlasEnterprise24ARepository instance =
      AtlasEnterprise24ARepository._();

  static const String _companiesKey = 'atlas_enterprise_24a_companies_v1';
  static const String _farmsKey = 'atlas_enterprise_24a_farms_v1';
  static const String _membershipsKey = 'atlas_enterprise_24a_memberships_v1';
  static const String _consultantsKey = 'atlas_enterprise_24a_consultants_v1';
  static const String _sessionKey = 'atlas_enterprise_24a_session_v1';
  static const String _migrationVersionKey =
      'atlas_enterprise_24a_migration_version';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<AtlasEnterprise24ASnapshot> load() async {
    var companies = await _decodeList(
      _companiesKey,
      AtlasEnterpriseCompany.fromMap,
    );
    var memberships = await _decodeList(
      _membershipsKey,
      AtlasEnterpriseMembership.fromMap,
    );

    if (companies.isEmpty) {
      final bootstrap = await _bootstrapFromLegacy();
      companies = bootstrap.$1;
      memberships = bootstrap.$2;
      await _saveList(
        _companiesKey,
        companies.map((item) => item.toMap()).toList(),
      );
      await _saveList(
        _membershipsKey,
        memberships.map((item) => item.toMap()).toList(),
      );
    }

    final farms = await _decodeList(_farmsKey, AtlasEnterpriseFarm.fromMap);
    final consultantLinks = await _decodeList(
      _consultantsKey,
      AtlasConsultantCompanyLink.fromMap,
    );
    final session = await _loadSession();
    final migrationVersion =
        await _preferences.getInt(_migrationVersionKey) ?? 0;

    final safeSession =
        session ??
        _defaultSession(companies: companies, memberships: memberships);

    if (session == null && safeSession != null) {
      await saveSession(safeSession);
    }

    return AtlasEnterprise24ASnapshot(
      companies: companies,
      farms: farms,
      memberships: memberships,
      consultantLinks: consultantLinks,
      session: safeSession,
      migrationVersion: migrationVersion,
    );
  }

  Future<void> saveSnapshot(AtlasEnterprise24ASnapshot snapshot) async {
    await _saveList(
      _companiesKey,
      snapshot.companies.map((item) => item.toMap()).toList(),
    );
    await _saveList(
      _farmsKey,
      snapshot.farms.map((item) => item.toMap()).toList(),
    );
    await _saveList(
      _membershipsKey,
      snapshot.memberships.map((item) => item.toMap()).toList(),
    );
    await _saveList(
      _consultantsKey,
      snapshot.consultantLinks.map((item) => item.toMap()).toList(),
    );
    if (snapshot.session != null) {
      await saveSession(snapshot.session!);
    }
    await setMigrationVersion(snapshot.migrationVersion);
  }

  Future<void> saveSession(AtlasEnterpriseSession session) {
    return _preferences.setString(_sessionKey, jsonEncode(session.toMap()));
  }

  Future<void> setMigrationVersion(int version) {
    return _preferences.setInt(_migrationVersionKey, version);
  }

  Future<AtlasEnterpriseCompany> createCompany({
    required String name,
    required String document,
    required String userId,
    required String userName,
    required String email,
  }) async {
    final snapshot = await load();
    final now = DateTime.now();
    final companyId = _buildId('company', name, now);
    final scope = AtlasEntityScope(
      tenantId: companyId,
      companyId: companyId,
      farmId: null,
      createdBy: userId,
      createdAt: now,
      updatedBy: userId,
      updatedAt: now,
    );

    final company = AtlasEnterpriseCompany(
      id: companyId,
      name: name.trim(),
      document: document.trim(),
      status: AtlasEnterpriseCompanyStatus.active,
      subscriptionPlan: 'enterprise',
      scope: scope,
    );

    final membership = AtlasEnterpriseMembership(
      id: _buildId('membership', '$userId-$companyId', now),
      userId: userId,
      userName: userName.trim(),
      email: email.trim(),
      companyId: companyId,
      role: AtlasEnterpriseMembershipRole.companyAdministrator,
      active: true,
      startedAt: now,
      endedAt: null,
      scope: scope,
    );

    await saveSnapshot(
      snapshot.copyWith(
        companies: <AtlasEnterpriseCompany>[...snapshot.companies, company],
        memberships: <AtlasEnterpriseMembership>[
          ...snapshot.memberships,
          membership,
        ],
      ),
    );
    return company;
  }

  Future<AtlasEnterpriseFarm> ensureFarm({
    required String companyId,
    required String name,
    required String city,
    required String state,
    required String userId,
  }) async {
    final snapshot = await load();
    final normalizedName = name.trim().toLowerCase();
    for (final farm in snapshot.farms) {
      if (farm.scope.companyId == companyId &&
          farm.name.trim().toLowerCase() == normalizedName) {
        return farm;
      }
    }

    final now = DateTime.now();
    final farmId = _buildId('farm', '$companyId-${name.trim()}', now);
    final farm = AtlasEnterpriseFarm(
      id: farmId,
      name: name.trim(),
      city: city.trim(),
      state: state.trim(),
      active: true,
      scope: AtlasEntityScope(
        tenantId: companyId,
        companyId: companyId,
        farmId: farmId,
        createdBy: userId,
        createdAt: now,
        updatedBy: userId,
        updatedAt: now,
      ),
    );

    await _saveList(_farmsKey, <Map<String, dynamic>>[
      ...snapshot.farms.map((item) => item.toMap()),
      farm.toMap(),
    ]);
    return farm;
  }

  Future<AtlasEnterpriseMembership> ensureMembership({
    required String companyId,
    required String userId,
    required String userName,
    required String email,
    required AtlasEnterpriseMembershipRole role,
  }) async {
    final snapshot = await load();
    for (final membership in snapshot.memberships) {
      if (membership.companyId == companyId && membership.userId == userId) {
        return membership;
      }
    }

    final now = DateTime.now();
    final membership = AtlasEnterpriseMembership(
      id: _buildId('membership', '$companyId-$userId', now),
      userId: userId,
      userName: userName.trim(),
      email: email.trim(),
      companyId: companyId,
      role: role,
      active: true,
      startedAt: now,
      endedAt: null,
      scope: AtlasEntityScope(
        tenantId: companyId,
        companyId: companyId,
        farmId: null,
        createdBy: userId,
        createdAt: now,
        updatedBy: userId,
        updatedAt: now,
      ),
    );

    await _saveList(_membershipsKey, <Map<String, dynamic>>[
      ...snapshot.memberships.map((item) => item.toMap()),
      membership.toMap(),
    ]);
    return membership;
  }

  Future<AtlasConsultantCompanyLink> saveConsultantLink({
    required String companyId,
    required String consultantUserId,
    required String consultantName,
    required List<String> farmIds,
    required bool isLeadConsultant,
    required String actorUserId,
  }) async {
    final snapshot = await load();
    final now = DateTime.now();
    final existingIndex = snapshot.consultantLinks.indexWhere(
      (item) =>
          item.companyId == companyId &&
          item.consultantUserId == consultantUserId &&
          item.active,
    );

    final link = AtlasConsultantCompanyLink(
      id: existingIndex >= 0
          ? snapshot.consultantLinks[existingIndex].id
          : _buildId('consultant', '$companyId-$consultantUserId', now),
      consultantUserId: consultantUserId,
      consultantName: consultantName.trim(),
      companyId: companyId,
      farmIds: farmIds.toSet().toList(),
      isLeadConsultant: isLeadConsultant,
      active: true,
      startedAt: existingIndex >= 0
          ? snapshot.consultantLinks[existingIndex].startedAt
          : now,
      endedAt: null,
      scope: AtlasEntityScope(
        tenantId: companyId,
        companyId: companyId,
        farmId: null,
        createdBy: existingIndex >= 0
            ? snapshot.consultantLinks[existingIndex].scope.createdBy
            : actorUserId,
        createdAt: existingIndex >= 0
            ? snapshot.consultantLinks[existingIndex].scope.createdAt
            : now,
        updatedBy: actorUserId,
        updatedAt: now,
      ),
    );

    final links = <AtlasConsultantCompanyLink>[...snapshot.consultantLinks];
    if (existingIndex >= 0) {
      links[existingIndex] = link;
    } else {
      links.add(link);
    }

    await _saveList(
      _consultantsKey,
      links.map((item) => item.toMap()).toList(),
    );
    return link;
  }

  Future<List<AtlasEnterpriseCompany>> companiesForUser(String userId) async {
    final snapshot = await load();
    final ids = snapshot.memberships
        .where((item) => item.userId == userId && item.active)
        .map((item) => item.companyId)
        .toSet();

    return snapshot.companies
        .where(
          (item) =>
              ids.contains(item.id) &&
              item.status != AtlasEnterpriseCompanyStatus.archived,
        )
        .toList();
  }

  Future<List<AtlasEnterpriseFarm>> farmsForCompany(String companyId) async {
    final snapshot = await load();
    return snapshot.farms
        .where((item) => item.scope.companyId == companyId && item.active)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<AtlasEnterpriseFarm>> farmsAllowedForUser({
    required String companyId,
    required String userId,
  }) async {
    final snapshot = await load();
    final membership = snapshot.memberships.where(
      (item) =>
          item.companyId == companyId && item.userId == userId && item.active,
    );

    if (membership.isEmpty) {
      return <AtlasEnterpriseFarm>[];
    }

    final role = membership.first.role;
    final companyFarms = snapshot.farms
        .where((item) => item.scope.companyId == companyId && item.active)
        .toList();

    if (role != AtlasEnterpriseMembershipRole.consultant) {
      return companyFarms;
    }

    final activeLinks = snapshot.consultantLinks.where(
      (item) =>
          item.companyId == companyId &&
          item.consultantUserId == userId &&
          item.active,
    );

    if (activeLinks.isEmpty) {
      return <AtlasEnterpriseFarm>[];
    }

    final allowedIds = <String>{};
    var allFarms = false;
    for (final link in activeLinks) {
      if (link.farmIds.isEmpty) {
        allFarms = true;
      }
      allowedIds.addAll(link.farmIds);
    }

    if (allFarms) {
      return companyFarms;
    }

    return companyFarms.where((item) => allowedIds.contains(item.id)).toList();
  }

  Future<bool> canUserAccessCompany({
    required String userId,
    required String companyId,
  }) async {
    final snapshot = await load();
    return snapshot.memberships.any(
      (item) =>
          item.userId == userId && item.companyId == companyId && item.active,
    );
  }

  Future<bool> canUserAccessFarm({
    required String userId,
    required String companyId,
    required String farmId,
  }) async {
    final farms = await farmsAllowedForUser(
      companyId: companyId,
      userId: userId,
    );
    return farms.any((item) => item.id == farmId);
  }

  Future<(List<AtlasEnterpriseCompany>, List<AtlasEnterpriseMembership>)>
  _bootstrapFromLegacy() async {
    try {
      final legacy = await AtlasEnterpriseRepository().load();
      final now = DateTime.now();

      final companies = legacy.tenants.map((tenant) {
        final id = tenant.id.trim().isEmpty
            ? _buildId('company', tenant.name, now)
            : tenant.id;
        return AtlasEnterpriseCompany(
          id: id,
          name: tenant.name,
          document: tenant.document,
          status: switch (tenant.status.name) {
            'trial' => AtlasEnterpriseCompanyStatus.trial,
            'suspended' => AtlasEnterpriseCompanyStatus.suspended,
            _ => AtlasEnterpriseCompanyStatus.active,
          },
          subscriptionPlan: tenant.plan.name,
          scope: AtlasEntityScope(
            tenantId: id,
            companyId: id,
            farmId: null,
            createdBy: 'legacy_migration',
            createdAt: tenant.createdAt,
            updatedBy: 'legacy_migration',
            updatedAt: now,
          ),
        );
      }).toList();

      final memberships = legacy.users.map((user) {
        final companyId = user.tenantId;
        return AtlasEnterpriseMembership(
          id: 'legacy_membership_${user.id}_$companyId',
          userId: user.id,
          userName: user.name,
          email: user.email,
          companyId: companyId,
          role: switch (user.role.name) {
            'administrator' =>
              AtlasEnterpriseMembershipRole.companyAdministrator,
            'consultant' => AtlasEnterpriseMembershipRole.consultant,
            'veterinarian' => AtlasEnterpriseMembershipRole.veterinarian,
            'technician' => AtlasEnterpriseMembershipRole.technician,
            'employee' => AtlasEnterpriseMembershipRole.operator,
            'producer' => AtlasEnterpriseMembershipRole.owner,
            _ => AtlasEnterpriseMembershipRole.viewer,
          },
          active: user.active,
          startedAt: now,
          endedAt: null,
          scope: AtlasEntityScope(
            tenantId: companyId,
            companyId: companyId,
            farmId: null,
            createdBy: 'legacy_migration',
            createdAt: now,
            updatedBy: 'legacy_migration',
            updatedAt: now,
          ),
        );
      }).toList();

      return (companies, memberships);
    } catch (_) {
      final now = DateTime.now();
      const companyId = 'company_atlas_default';
      final scope = AtlasEntityScope(
        tenantId: companyId,
        companyId: companyId,
        farmId: null,
        createdBy: 'system',
        createdAt: now,
        updatedBy: 'system',
        updatedAt: now,
      );
      return (
        <AtlasEnterpriseCompany>[
          AtlasEnterpriseCompany(
            id: companyId,
            name: 'Empresa Atlas',
            document: '',
            status: AtlasEnterpriseCompanyStatus.trial,
            subscriptionPlan: 'professional',
            scope: scope,
          ),
        ],
        <AtlasEnterpriseMembership>[
          AtlasEnterpriseMembership(
            id: 'membership_admin_default',
            userId: 'user_admin',
            userName: 'Administrador',
            email: 'administrador@atlas.local',
            companyId: companyId,
            role: AtlasEnterpriseMembershipRole.companyAdministrator,
            active: true,
            startedAt: now,
            endedAt: null,
            scope: scope,
          ),
        ],
      );
    }
  }

  AtlasEnterpriseSession? _defaultSession({
    required List<AtlasEnterpriseCompany> companies,
    required List<AtlasEnterpriseMembership> memberships,
  }) {
    if (companies.isEmpty || memberships.isEmpty) {
      return null;
    }

    final membership = memberships.firstWhere(
      (item) => item.active,
      orElse: () => memberships.first,
    );

    return AtlasEnterpriseSession(
      userId: membership.userId,
      companyId: membership.companyId,
      farmId: null,
      startedAt: DateTime.now(),
    );
  }

  Future<AtlasEnterpriseSession?> _loadSession() async {
    final raw = await _preferences.getString(_sessionKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return AtlasEnterpriseSession.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) return <T>[];

    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> values) {
    return _preferences.setString(key, jsonEncode(values));
  }

  String _buildId(String prefix, String seed, DateTime now) {
    final slug = seed
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${prefix}_${slug.isEmpty ? 'item' : slug}_'
        '${now.microsecondsSinceEpoch}';
  }
}
