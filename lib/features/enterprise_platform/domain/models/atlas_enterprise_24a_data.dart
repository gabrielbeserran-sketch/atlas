enum AtlasEnterpriseCompanyStatus {
  trial,
  active,
  suspended,
  archived,
}

enum AtlasEnterpriseMembershipRole {
  superAdministrator,
  companyAdministrator,
  owner,
  manager,
  consultant,
  veterinarian,
  technician,
  financial,
  operator,
  viewer,
  auditor,
}

String atlasEnterpriseMembershipRoleLabel(
  AtlasEnterpriseMembershipRole role,
) {
  switch (role) {
    case AtlasEnterpriseMembershipRole.superAdministrator:
      return 'Superadministrador';
    case AtlasEnterpriseMembershipRole.companyAdministrator:
      return 'Administrador da empresa';
    case AtlasEnterpriseMembershipRole.owner:
      return 'Proprietário';
    case AtlasEnterpriseMembershipRole.manager:
      return 'Gerente';
    case AtlasEnterpriseMembershipRole.consultant:
      return 'Consultor';
    case AtlasEnterpriseMembershipRole.veterinarian:
      return 'Veterinário';
    case AtlasEnterpriseMembershipRole.technician:
      return 'Técnico';
    case AtlasEnterpriseMembershipRole.financial:
      return 'Financeiro';
    case AtlasEnterpriseMembershipRole.operator:
      return 'Operador';
    case AtlasEnterpriseMembershipRole.viewer:
      return 'Visualizador';
    case AtlasEnterpriseMembershipRole.auditor:
      return 'Auditor';
  }
}

class AtlasEntityScope {
  const AtlasEntityScope({
    required this.tenantId,
    required this.companyId,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
  });

  final String tenantId;
  final String companyId;
  final String? farmId;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  AtlasEntityScope copyWith({
    String? tenantId,
    String? companyId,
    String? farmId,
    bool replaceFarmId = false,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return AtlasEntityScope(
      tenantId: tenantId ?? this.tenantId,
      companyId: companyId ?? this.companyId,
      farmId: replaceFarmId ? farmId : this.farmId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'tenantId': tenantId,
        'companyId': companyId,
        'farmId': farmId,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedBy': updatedBy,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AtlasEntityScope.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return AtlasEntityScope(
      tenantId: map['tenantId']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      farmId: map['farmId']?.toString(),
      createdBy: map['createdBy']?.toString() ?? 'system',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? now,
      updatedBy: map['updatedBy']?.toString() ?? 'system',
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? now,
    );
  }
}

class AtlasEnterpriseCompany {
  const AtlasEnterpriseCompany({
    required this.id,
    required this.name,
    required this.document,
    required this.status,
    required this.subscriptionPlan,
    required this.scope,
  });

  final String id;
  final String name;
  final String document;
  final AtlasEnterpriseCompanyStatus status;
  final String subscriptionPlan;
  final AtlasEntityScope scope;

  AtlasEnterpriseCompany copyWith({
    String? name,
    String? document,
    AtlasEnterpriseCompanyStatus? status,
    String? subscriptionPlan,
    AtlasEntityScope? scope,
  }) {
    return AtlasEnterpriseCompany(
      id: id,
      name: name ?? this.name,
      document: document ?? this.document,
      status: status ?? this.status,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      scope: scope ?? this.scope,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'document': document,
        'status': status.name,
        'subscriptionPlan': subscriptionPlan,
        'scope': scope.toMap(),
      };

  factory AtlasEnterpriseCompany.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasEnterpriseCompany(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      document: map['document']?.toString() ?? '',
      status: AtlasEnterpriseCompanyStatus.values.firstWhere(
        (item) => item.name == map['status']?.toString(),
        orElse: () => AtlasEnterpriseCompanyStatus.active,
      ),
      subscriptionPlan:
          map['subscriptionPlan']?.toString() ?? 'professional',
      scope: AtlasEntityScope.fromMap(
        Map<String, dynamic>.from(
          (map['scope'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class AtlasEnterpriseFarm {
  const AtlasEnterpriseFarm({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.active,
    required this.scope,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final bool active;
  final AtlasEntityScope scope;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'city': city,
        'state': state,
        'active': active,
        'scope': scope.toMap(),
      };

  factory AtlasEnterpriseFarm.fromMap(Map<String, dynamic> map) {
    return AtlasEnterpriseFarm(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      active: map['active'] != false,
      scope: AtlasEntityScope.fromMap(
        Map<String, dynamic>.from(
          (map['scope'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class AtlasEnterpriseMembership {
  const AtlasEnterpriseMembership({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    required this.companyId,
    required this.role,
    required this.active,
    required this.startedAt,
    required this.endedAt,
    required this.scope,
  });

  final String id;
  final String userId;
  final String userName;
  final String email;
  final String companyId;
  final AtlasEnterpriseMembershipRole role;
  final bool active;
  final DateTime startedAt;
  final DateTime? endedAt;
  final AtlasEntityScope scope;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'userName': userName,
        'email': email,
        'companyId': companyId,
        'role': role.name,
        'active': active,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'scope': scope.toMap(),
      };

  factory AtlasEnterpriseMembership.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasEnterpriseMembership(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      role: AtlasEnterpriseMembershipRole.values.firstWhere(
        (item) => item.name == map['role']?.toString(),
        orElse: () => AtlasEnterpriseMembershipRole.viewer,
      ),
      active: map['active'] != false,
      startedAt:
          DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
              DateTime.now(),
      endedAt: DateTime.tryParse(
        map['endedAt']?.toString() ?? '',
      ),
      scope: AtlasEntityScope.fromMap(
        Map<String, dynamic>.from(
          (map['scope'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class AtlasConsultantCompanyLink {
  const AtlasConsultantCompanyLink({
    required this.id,
    required this.consultantUserId,
    required this.consultantName,
    required this.companyId,
    required this.farmIds,
    required this.isLeadConsultant,
    required this.active,
    required this.startedAt,
    required this.endedAt,
    required this.scope,
  });

  final String id;
  final String consultantUserId;
  final String consultantName;
  final String companyId;
  final List<String> farmIds;
  final bool isLeadConsultant;
  final bool active;
  final DateTime startedAt;
  final DateTime? endedAt;
  final AtlasEntityScope scope;

  bool grantsFarm(String farmId) =>
      farmIds.isEmpty || farmIds.contains(farmId);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'consultantUserId': consultantUserId,
        'consultantName': consultantName,
        'companyId': companyId,
        'farmIds': farmIds,
        'isLeadConsultant': isLeadConsultant,
        'active': active,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'scope': scope.toMap(),
      };

  factory AtlasConsultantCompanyLink.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasConsultantCompanyLink(
      id: map['id']?.toString() ?? '',
      consultantUserId:
          map['consultantUserId']?.toString() ?? '',
      consultantName: map['consultantName']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      farmIds: ((map['farmIds'] as List?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      isLeadConsultant: map['isLeadConsultant'] == true,
      active: map['active'] != false,
      startedAt:
          DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
              DateTime.now(),
      endedAt:
          DateTime.tryParse(map['endedAt']?.toString() ?? ''),
      scope: AtlasEntityScope.fromMap(
        Map<String, dynamic>.from(
          (map['scope'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class AtlasEnterpriseSession {
  const AtlasEnterpriseSession({
    required this.userId,
    required this.companyId,
    required this.farmId,
    required this.startedAt,
  });

  final String userId;
  final String companyId;
  final String? farmId;
  final DateTime startedAt;

  AtlasEnterpriseSession copyWith({
    String? userId,
    String? companyId,
    String? farmId,
    bool replaceFarmId = false,
    DateTime? startedAt,
  }) {
    return AtlasEnterpriseSession(
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      farmId: replaceFarmId ? farmId : this.farmId,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'companyId': companyId,
        'farmId': farmId,
        'startedAt': startedAt.toIso8601String(),
      };

  factory AtlasEnterpriseSession.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasEnterpriseSession(
      userId: map['userId']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      farmId: map['farmId']?.toString(),
      startedAt:
          DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

class AtlasEnterprise24ASnapshot {
  const AtlasEnterprise24ASnapshot({
    required this.companies,
    required this.farms,
    required this.memberships,
    required this.consultantLinks,
    required this.session,
    required this.migrationVersion,
  });

  final List<AtlasEnterpriseCompany> companies;
  final List<AtlasEnterpriseFarm> farms;
  final List<AtlasEnterpriseMembership> memberships;
  final List<AtlasConsultantCompanyLink> consultantLinks;
  final AtlasEnterpriseSession? session;
  final int migrationVersion;

  AtlasEnterprise24ASnapshot copyWith({
    List<AtlasEnterpriseCompany>? companies,
    List<AtlasEnterpriseFarm>? farms,
    List<AtlasEnterpriseMembership>? memberships,
    List<AtlasConsultantCompanyLink>? consultantLinks,
    AtlasEnterpriseSession? session,
    bool replaceSession = false,
    int? migrationVersion,
  }) {
    return AtlasEnterprise24ASnapshot(
      companies: companies ?? this.companies,
      farms: farms ?? this.farms,
      memberships: memberships ?? this.memberships,
      consultantLinks:
          consultantLinks ?? this.consultantLinks,
      session:
          replaceSession ? session : session ?? this.session,
      migrationVersion: migrationVersion ?? this.migrationVersion,
    );
  }
}
