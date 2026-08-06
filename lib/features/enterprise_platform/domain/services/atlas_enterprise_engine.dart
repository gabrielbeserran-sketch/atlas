import '../models/atlas_enterprise_data.dart';

class AtlasEnterpriseSummary {
  const AtlasEnterpriseSummary({
    required this.tenants,
    required this.activeUsers,
    required this.twoFactorUsers,
    required this.auditEntries,
    required this.securityScore,
  });

  final int tenants;
  final int activeUsers;
  final int twoFactorUsers;
  final int auditEntries;
  final double securityScore;
}

class AtlasEnterpriseEngine {
  const AtlasEnterpriseEngine();

  AtlasEnterpriseSummary summarize(AtlasEnterpriseState state) {
    final int activeUsers = state.users.where((AtlasEnterpriseUser user) => user.active).length;
    final int twoFactorUsers = state.users
        .where((AtlasEnterpriseUser user) => user.active && user.twoFactorEnabled)
        .length;
    final double twoFactorRate = activeUsers == 0 ? 0 : twoFactorUsers / activeUsers;
    final double securityScore = (55 + twoFactorRate * 35 + (state.audit.isNotEmpty ? 10 : 0))
        .clamp(0, 100)
        .toDouble();

    return AtlasEnterpriseSummary(
      tenants: state.tenants.length,
      activeUsers: activeUsers,
      twoFactorUsers: twoFactorUsers,
      auditEntries: state.audit.length,
      securityScore: securityScore,
    );
  }
}
