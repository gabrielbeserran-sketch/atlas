import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';

class AtlasPastureGrazingScope {
  const AtlasPastureGrazingScope._();

  static AtlasRemoteFarm? resolve({
    required AtlasRemoteSession? session,
    required String? activeFarmId,
    required List<AtlasRemoteFarm> portfolio,
    String? expectedFarmName,
    String? expectedFarmId,
  }) {
    if (session == null ||
        session.userId.isEmpty ||
        session.companyId.isEmpty ||
        session.tenantId.isEmpty ||
        activeFarmId == null ||
        activeFarmId.isEmpty) {
      return null;
    }
    final name = expectedFarmName?.trim().toLowerCase();
    for (final farm in portfolio) {
      if (!farm.active ||
          farm.id != activeFarmId ||
          (expectedFarmId != null && farm.id != expectedFarmId) ||
          farm.companyId != session.companyId ||
          farm.tenantId != session.tenantId ||
          (!session.hasUnrestrictedFarmAccess &&
              !session.farmIds.contains(farm.id)) ||
          (name != null &&
              name.isNotEmpty &&
              farm.name.trim().toLowerCase() != name)) {
        continue;
      }
      return farm;
    }
    return null;
  }
}
