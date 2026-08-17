enum AtlasTeamMemberRole {
  owner,
  manager,
  veterinarian,
  consultant,
  technician,
  employee,
  other,
}

String atlasTeamMemberRoleLabel(AtlasTeamMemberRole role) {
  switch (role) {
    case AtlasTeamMemberRole.owner:
      return 'Proprietário';
    case AtlasTeamMemberRole.manager:
      return 'Gerente';
    case AtlasTeamMemberRole.veterinarian:
      return 'Veterinário';
    case AtlasTeamMemberRole.consultant:
      return 'Consultor';
    case AtlasTeamMemberRole.technician:
      return 'Técnico';
    case AtlasTeamMemberRole.employee:
      return 'Funcionário';
    case AtlasTeamMemberRole.other:
      return 'Outro';
  }
}

class AtlasTeamMember {
  const AtlasTeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.farmName,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final AtlasTeamMemberRole role;
  final String phone;
  final String email;
  final String? farmName;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  AtlasTeamMember copyWith({
    String? name,
    AtlasTeamMemberRole? role,
    String? phone,
    String? email,
    String? farmName,
    bool replaceFarmName = false,
    bool? active,
    DateTime? updatedAt,
  }) {
    return AtlasTeamMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      farmName: replaceFarmName ? farmName : this.farmName,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'role': role.name,
      'phone': phone,
      'email': email,
      'farmName': farmName,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AtlasTeamMember.fromMap(Map<String, dynamic> map) {
    return AtlasTeamMember(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: AtlasTeamMemberRole.values.firstWhere(
        (value) => value.name == map['role']?.toString(),
        orElse: () => AtlasTeamMemberRole.other,
      ),
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      active: map['active'] != false,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
