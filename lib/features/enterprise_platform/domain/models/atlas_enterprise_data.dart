enum AtlasTenantStatus { active, trial, suspended }

enum AtlasSubscriptionPlan { free, professional, enterprise }

enum AtlasUserRole {
  administrator,
  consultant,
  veterinarian,
  technician,
  employee,
  producer,
  viewer,
}

enum AtlasAuditAction { create, update, delete, approve, export, login }

class AtlasTenant {
  const AtlasTenant({
    required this.id,
    required this.name,
    required this.document,
    required this.status,
    required this.plan,
    required this.createdAt,
    required this.trialEndsAt,
    required this.maxUsers,
    required this.maxFarms,
  });

  final String id;
  final String name;
  final String document;
  final AtlasTenantStatus status;
  final AtlasSubscriptionPlan plan;
  final DateTime createdAt;
  final DateTime? trialEndsAt;
  final int maxUsers;
  final int maxFarms;

  AtlasTenant copyWith({
    String? name,
    String? document,
    AtlasTenantStatus? status,
    AtlasSubscriptionPlan? plan,
    DateTime? trialEndsAt,
    int? maxUsers,
    int? maxFarms,
  }) {
    return AtlasTenant(
      id: id,
      name: name ?? this.name,
      document: document ?? this.document,
      status: status ?? this.status,
      plan: plan ?? this.plan,
      createdAt: createdAt,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      maxUsers: maxUsers ?? this.maxUsers,
      maxFarms: maxFarms ?? this.maxFarms,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'document': document,
    'status': status.name,
    'plan': plan.name,
    'createdAt': createdAt.toIso8601String(),
    'trialEndsAt': trialEndsAt?.toIso8601String(),
    'maxUsers': maxUsers,
    'maxFarms': maxFarms,
  };

  factory AtlasTenant.fromJson(Map<String, dynamic> json) {
    return AtlasTenant(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      document: json['document'] as String? ?? '',
      status: AtlasTenantStatus.values.byName(
        json['status'] as String? ?? AtlasTenantStatus.active.name,
      ),
      plan: AtlasSubscriptionPlan.values.byName(
        json['plan'] as String? ?? AtlasSubscriptionPlan.free.name,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      trialEndsAt: DateTime.tryParse(json['trialEndsAt'] as String? ?? ''),
      maxUsers: (json['maxUsers'] as num?)?.toInt() ?? 3,
      maxFarms: (json['maxFarms'] as num?)?.toInt() ?? 1,
    );
  }
}

class AtlasEnterpriseUser {
  const AtlasEnterpriseUser({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.twoFactorEnabled,
  });

  final String id;
  final String tenantId;
  final String name;
  final String email;
  final AtlasUserRole role;
  final bool active;
  final bool twoFactorEnabled;

  AtlasEnterpriseUser copyWith({
    String? name,
    String? email,
    AtlasUserRole? role,
    bool? active,
    bool? twoFactorEnabled,
  }) {
    return AtlasEnterpriseUser(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      active: active ?? this.active,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'tenantId': tenantId,
    'name': name,
    'email': email,
    'role': role.name,
    'active': active,
    'twoFactorEnabled': twoFactorEnabled,
  };

  factory AtlasEnterpriseUser.fromJson(Map<String, dynamic> json) {
    return AtlasEnterpriseUser(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: AtlasUserRole.values.byName(
        json['role'] as String? ?? AtlasUserRole.viewer.name,
      ),
      active: json['active'] as bool? ?? true,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
    );
  }
}

class AtlasAuditEntry {
  const AtlasAuditEntry({
    required this.id,
    required this.tenantId,
    required this.userName,
    required this.module,
    required this.action,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final String userName;
  final String module;
  final AtlasAuditAction action;
  final String description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'tenantId': tenantId,
    'userName': userName,
    'module': module,
    'action': action.name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AtlasAuditEntry.fromJson(Map<String, dynamic> json) {
    return AtlasAuditEntry(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Sistema',
      module: json['module'] as String? ?? 'Atlas',
      action: AtlasAuditAction.values.byName(
        json['action'] as String? ?? AtlasAuditAction.update.name,
      ),
      description: json['description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AtlasEnterpriseState {
  const AtlasEnterpriseState({
    required this.tenants,
    required this.users,
    required this.audit,
    required this.currentTenantId,
  });

  final List<AtlasTenant> tenants;
  final List<AtlasEnterpriseUser> users;
  final List<AtlasAuditEntry> audit;
  final String? currentTenantId;
}
