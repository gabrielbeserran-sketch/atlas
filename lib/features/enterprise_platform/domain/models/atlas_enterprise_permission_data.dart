import 'atlas_enterprise_24a_data.dart';

enum AtlasPermissionEffect {
  allow,
  deny,
}

class AtlasEnterprisePermission {
  const AtlasEnterprisePermission({
    required this.key,
    required this.module,
    required this.operation,
    required this.label,
    required this.sensitive,
  });

  final String key;
  final String module;
  final String operation;
  final String label;
  final bool sensitive;
}

abstract final class AtlasEnterprisePermissions {
  static const List<AtlasEnterprisePermission> catalog =
      <AtlasEnterprisePermission>[
    AtlasEnterprisePermission(
      key: 'enterprise.companies.read',
      module: 'enterprise',
      operation: 'read',
      label: 'Visualizar empresas',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.companies.manage',
      module: 'enterprise',
      operation: 'manage',
      label: 'Administrar empresas',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.users.read',
      module: 'enterprise',
      operation: 'read',
      label: 'Visualizar usuários e consultores',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.users.invite',
      module: 'enterprise',
      operation: 'create',
      label: 'Convidar usuários e consultores',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.permissions.read',
      module: 'enterprise',
      operation: 'read',
      label: 'Visualizar permissões',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.permissions.manage',
      module: 'enterprise',
      operation: 'manage',
      label: 'Administrar permissões',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.audit.read',
      module: 'enterprise',
      operation: 'read',
      label: 'Visualizar auditoria',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.audit.export',
      module: 'enterprise',
      operation: 'export',
      label: 'Exportar auditoria',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.versions.read',
      module: 'enterprise',
      operation: 'read',
      label: 'Visualizar versões',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.versions.restore',
      module: 'enterprise',
      operation: 'manage',
      label: 'Restaurar versões',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.sync.read',
      module: 'enterprise',
      operation: 'read',
      label: 'Visualizar sincronização',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.sync.manage',
      module: 'enterprise',
      operation: 'manage',
      label: 'Executar sincronização',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.sync.conflicts.resolve',
      module: 'enterprise',
      operation: 'manage',
      label: 'Resolver conflitos de sincronização',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.backend.read',
      module: 'enterprise',
      operation: 'read',
      label: 'Visualizar backend Enterprise',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.backup.read',
      module: 'enterprise',
      operation: 'read',
      label: 'Visualizar backups',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'enterprise.backup.run',
      module: 'enterprise',
      operation: 'manage',
      label: 'Executar backups',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'farms.read',
      module: 'farms',
      operation: 'read',
      label: 'Visualizar fazendas',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'farms.create',
      module: 'farms',
      operation: 'create',
      label: 'Cadastrar fazendas',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'farms.update',
      module: 'farms',
      operation: 'update',
      label: 'Editar fazendas',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'farms.delete',
      module: 'farms',
      operation: 'delete',
      label: 'Excluir fazendas',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'animals.read',
      module: 'animals',
      operation: 'read',
      label: 'Visualizar rebanho',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'animals.create',
      module: 'animals',
      operation: 'create',
      label: 'Cadastrar animais',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'animals.update',
      module: 'animals',
      operation: 'update',
      label: 'Editar animais',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'animals.delete',
      module: 'animals',
      operation: 'delete',
      label: 'Excluir animais',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'reproduction.read',
      module: 'reproduction',
      operation: 'read',
      label: 'Visualizar reprodução',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'reproduction.manage',
      module: 'reproduction',
      operation: 'manage',
      label: 'Administrar reprodução',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'health.read',
      module: 'health',
      operation: 'read',
      label: 'Visualizar sanidade',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'health.manage',
      module: 'health',
      operation: 'manage',
      label: 'Administrar sanidade',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'nutrition.read',
      module: 'nutrition',
      operation: 'read',
      label: 'Visualizar nutrição',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'nutrition.manage',
      module: 'nutrition',
      operation: 'manage',
      label: 'Administrar nutrição',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'inventory.read',
      module: 'inventory',
      operation: 'read',
      label: 'Visualizar estoque',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'inventory.manage',
      module: 'inventory',
      operation: 'manage',
      label: 'Administrar estoque',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'finance.read',
      module: 'finance',
      operation: 'read',
      label: 'Visualizar financeiro',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'finance.create',
      module: 'finance',
      operation: 'create',
      label: 'Criar lançamentos financeiros',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'finance.update',
      module: 'finance',
      operation: 'update',
      label: 'Editar lançamentos financeiros',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'finance.approve',
      module: 'finance',
      operation: 'approve',
      label: 'Aprovar operações financeiras',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'finance.export',
      module: 'finance',
      operation: 'export',
      label: 'Exportar dados financeiros',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'commercial.read',
      module: 'commercial',
      operation: 'read',
      label: 'Visualizar comercial',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'commercial.manage',
      module: 'commercial',
      operation: 'manage',
      label: 'Administrar comercial',
      sensitive: true,
    ),
    AtlasEnterprisePermission(
      key: 'reports.read',
      module: 'reports',
      operation: 'read',
      label: 'Visualizar relatórios',
      sensitive: false,
    ),
    AtlasEnterprisePermission(
      key: 'reports.export',
      module: 'reports',
      operation: 'export',
      label: 'Exportar relatórios',
      sensitive: true,
    ),
  ];

  static Set<String> keysWhere(
    bool Function(AtlasEnterprisePermission permission) test,
  ) {
    return catalog
        .where(test)
        .map((permission) => permission.key)
        .toSet();
  }

  static Set<String> defaultsForRole(
    AtlasEnterpriseMembershipRole role,
  ) {
    final all = catalog.map((item) => item.key).toSet();
    final readOnly = keysWhere(
      (item) => item.operation == 'read',
    );

    switch (role) {
      case AtlasEnterpriseMembershipRole.superAdministrator:
      case AtlasEnterpriseMembershipRole.companyAdministrator:
      case AtlasEnterpriseMembershipRole.owner:
        return all;
      case AtlasEnterpriseMembershipRole.manager:
        return all.difference(<String>{
          'enterprise.companies.manage',
          'enterprise.permissions.manage',
          'enterprise.audit.export',
        });
      case AtlasEnterpriseMembershipRole.consultant:
        return <String>{
          ...readOnly,
          'animals.create',
          'animals.update',
          'reproduction.manage',
          'health.manage',
          'nutrition.manage',
          'inventory.manage',
          'reports.export',
          'commercial.manage',
        };
      case AtlasEnterpriseMembershipRole.veterinarian:
        return <String>{
          ...readOnly,
          'animals.create',
          'animals.update',
          'reproduction.manage',
          'health.manage',
          'nutrition.manage',
        };
      case AtlasEnterpriseMembershipRole.technician:
        return <String>{
          ...readOnly,
          'animals.create',
          'animals.update',
          'inventory.manage',
        };
      case AtlasEnterpriseMembershipRole.financial:
        return <String>{
          ...readOnly,
          'finance.create',
          'finance.update',
          'finance.approve',
          'finance.export',
          'reports.export',
          'commercial.manage',
        };
      case AtlasEnterpriseMembershipRole.operator:
        return <String>{
          'farms.read',
          'animals.read',
          'animals.create',
          'animals.update',
          'reproduction.read',
          'health.read',
          'nutrition.read',
          'inventory.read',
          'inventory.manage',
        };
      case AtlasEnterpriseMembershipRole.auditor:
        return <String>{
          ...readOnly,
          'enterprise.audit.export',
          'reports.export',
          'finance.export',
        };
      case AtlasEnterpriseMembershipRole.viewer:
        return readOnly.difference(<String>{
          'enterprise.permissions.read',
          'enterprise.audit.read',
          'finance.read',
        });
    }
  }
}

class AtlasCustomEnterpriseRole {
  const AtlasCustomEnterpriseRole({
    required this.id,
    required this.companyId,
    required this.name,
    required this.description,
    required this.permissionKeys,
    required this.active,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String name;
  final String description;
  final Set<String> permissionKeys;
  final bool active;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'companyId': companyId,
        'name': name,
        'description': description,
        'permissionKeys': permissionKeys.toList()..sort(),
        'active': active,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AtlasCustomEnterpriseRole.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasCustomEnterpriseRole(
      id: map['id']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      permissionKeys:
          ((map['permissionKeys'] as List?) ?? const <dynamic>[])
              .map((item) => item.toString())
              .toSet(),
      active: map['active'] != false,
      createdBy: map['createdBy']?.toString() ?? 'system',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

class AtlasUserPermissionPolicy {
  const AtlasUserPermissionPolicy({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.customRoleId,
    required this.effects,
    required this.updatedBy,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String userId;
  final String? customRoleId;
  final Map<String, AtlasPermissionEffect> effects;
  final String updatedBy;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'companyId': companyId,
        'userId': userId,
        'customRoleId': customRoleId,
        'effects': effects.map(
          (key, value) => MapEntry(key, value.name),
        ),
        'updatedBy': updatedBy,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AtlasUserPermissionPolicy.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawEffects = Map<String, dynamic>.from(
      (map['effects'] as Map?) ?? const <String, dynamic>{},
    );

    return AtlasUserPermissionPolicy(
      id: map['id']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      customRoleId: map['customRoleId']?.toString(),
      effects: rawEffects.map(
        (key, value) => MapEntry(
          key,
          AtlasPermissionEffect.values.firstWhere(
            (item) => item.name == value.toString(),
            orElse: () => AtlasPermissionEffect.deny,
          ),
        ),
      ),
      updatedBy: map['updatedBy']?.toString() ?? 'system',
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

class AtlasEffectivePermissionSet {
  const AtlasEffectivePermissionSet({
    required this.companyId,
    required this.userId,
    required this.membershipRole,
    required this.customRoleId,
    required this.allowed,
    required this.denied,
  });

  final String companyId;
  final String userId;
  final AtlasEnterpriseMembershipRole membershipRole;
  final String? customRoleId;
  final Set<String> allowed;
  final Set<String> denied;

  bool allows(String permissionKey) =>
      allowed.contains(permissionKey) &&
      !denied.contains(permissionKey);
}
