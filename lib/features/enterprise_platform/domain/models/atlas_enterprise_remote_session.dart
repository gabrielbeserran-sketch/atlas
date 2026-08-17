class AtlasRemoteCompanySession {
  const AtlasRemoteCompanySession({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.document,
    required this.role,
  });

  final String id;
  final String tenantId;
  final String name;
  final String document;
  final String role;

  factory AtlasRemoteCompanySession.fromMap(Map<String, dynamic> map) {
    return AtlasRemoteCompanySession(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      document: map['document']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'tenant_id': tenantId,
    'name': name,
    'document': document,
    'role': role,
  };
}

class AtlasRemoteSession {
  const AtlasRemoteSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    required this.userId,
    required this.userName,
    required this.email,
    required this.companyId,
    required this.tenantId,
    required this.role,
    required this.companies,
    required this.effectivePermissions,
    required this.farmIds,
    required this.savedAt,
    this.mfaRequired = false,
    this.challengeToken = '',
  });

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final String userId;
  final String userName;
  final String email;
  final String companyId;
  final String tenantId;
  final String role;
  final List<AtlasRemoteCompanySession> companies;
  final Set<String> effectivePermissions;
  final List<String> farmIds;
  final DateTime savedAt;
  final bool mfaRequired;
  final String challengeToken;

  bool get hasUnrestrictedFarmAccess => const <String>{
    'owner',
    'admin',
    'companyAdministrator',
    'superAdministrator',
  }.contains(role);

  bool allows(String permissionKey) {
    if (hasUnrestrictedFarmAccess) {
      return true;
    }
    if (effectivePermissions.contains(permissionKey)) return true;
    final namespace = permissionKey.split('.').first;
    return effectivePermissions.contains('$namespace.*');
  }

  bool get hasUsableAccessToken =>
      accessToken.isNotEmpty &&
      DateTime.now().isBefore(
        savedAt.add(
          Duration(
            seconds: expiresInSeconds > 120
                ? expiresInSeconds - 120
                : expiresInSeconds,
          ),
        ),
      );

  AtlasRemoteSession copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresInSeconds,
    String? companyId,
    String? tenantId,
    String? role,
    List<AtlasRemoteCompanySession>? companies,
    Set<String>? effectivePermissions,
    List<String>? farmIds,
    DateTime? savedAt,
    bool? mfaRequired,
    String? challengeToken,
  }) {
    return AtlasRemoteSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
      userId: userId,
      userName: userName,
      email: email,
      companyId: companyId ?? this.companyId,
      tenantId: tenantId ?? this.tenantId,
      role: role ?? this.role,
      companies: companies ?? this.companies,
      effectivePermissions: effectivePermissions ?? this.effectivePermissions,
      farmIds: farmIds ?? this.farmIds,
      savedAt: savedAt ?? this.savedAt,
      mfaRequired: mfaRequired ?? this.mfaRequired,
      challengeToken: challengeToken ?? this.challengeToken,
    );
  }

  Map<String, dynamic> toMap() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresInSeconds': expiresInSeconds,
    'userId': userId,
    'userName': userName,
    'email': email,
    'companyId': companyId,
    'tenantId': tenantId,
    'role': role,
    'companies': companies.map((item) => item.toMap()).toList(),
    'effectivePermissions': effectivePermissions.toList()..sort(),
    'farmIds': farmIds,
    'savedAt': savedAt.toIso8601String(),
    'mfaRequired': mfaRequired,
    'challengeToken': challengeToken,
  };

  factory AtlasRemoteSession.fromMap(Map<String, dynamic> map) {
    final permissions =
        (map['effectivePermissions'] as List?) ??
        (map['effective_permissions'] as List?) ??
        const <dynamic>[];
    final farms =
        (map['farmIds'] as List?) ??
        (map['farm_ids'] as List?) ??
        const <dynamic>[];

    return AtlasRemoteSession(
      accessToken:
          map['accessToken']?.toString() ??
          map['access_token']?.toString() ??
          '',
      refreshToken:
          map['refreshToken']?.toString() ??
          map['refresh_token']?.toString() ??
          '',
      expiresInSeconds:
          (map['expiresInSeconds'] as num?)?.toInt() ??
          (map['expires_in_seconds'] as num?)?.toInt() ??
          3600,
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      userName:
          map['userName']?.toString() ?? map['user_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      companyId:
          map['companyId']?.toString() ?? map['company_id']?.toString() ?? '',
      tenantId:
          map['tenantId']?.toString() ?? map['tenant_id']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      companies: ((map['companies'] as List?) ?? const <dynamic>[])
          .map(
            (item) => AtlasRemoteCompanySession.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      effectivePermissions: permissions.map((item) => item.toString()).toSet(),
      farmIds: farms.map((item) => item.toString()).toList(),
      savedAt:
          DateTime.tryParse(map['savedAt']?.toString() ?? '') ?? DateTime.now(),
      mfaRequired: map['mfaRequired'] == true || map['mfa_required'] == true,
      challengeToken:
          map['challengeToken']?.toString() ??
          map['challenge_token']?.toString() ??
          '',
    );
  }
}
