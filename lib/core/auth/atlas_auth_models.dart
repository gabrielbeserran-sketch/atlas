enum AtlasRole {
  administrator,
  consultant,
  veterinarian,
  technician,
  employee,
  producer,
  viewer,
}

class AtlasSession {
  const AtlasSession({
    required this.userId,
    required this.tenantId,
    required this.role,
    required this.startedAt,
    this.isAuthenticated = true,
  });

  final String userId;
  final String tenantId;
  final AtlasRole role;
  final DateTime startedAt;
  final bool isAuthenticated;

  bool canWrite() {
    return role != AtlasRole.viewer;
  }

  bool canAdminister() {
    return role == AtlasRole.administrator;
  }
}
